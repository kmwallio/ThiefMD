/*
 * Copyright (C) 2017 Lains
 * 
 * Modified July 5, 2018
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */

using ThiefMD.Controllers;
using Spelling;
using Gdk;
using ThiefMD.Enrichments;

namespace ThiefMD.Widgets {
    public class Editor : GtkSource.View {

        //
        // Things related to the file of this instance
        //

        private File file;
        public new GtkSource.Buffer buffer;
        private string opened_filename;
        public string preview_markdown = "";
        private bool active = true;
        private DateTime modified_time;
        private DateTime file_modified_time;
        private Mutex file_mutex;
        private bool no_change_prompt = false; // Trying to prevent too much file changed prompts?
        private TimedMutex disk_change_prompted;
        private TimedMutex dynamic_margin_update;
        public string file_path {
            get {
                return opened_filename;
            }
        }

        //
        // UI Items
        //

        private Spelling.TextBufferAdapter? spell_adapter = null;
        public WriteGood.Checker writegood = null;
        public GrammarChecker grammar = null;
        private TimedMutex writegood_limit;
        public Gtk.TextTag warning_tag;
        public Gtk.TextTag error_tag;
        public Gtk.TextTag highlight_tag;
        private int last_width = 0;
        private int last_height = 0;
        private bool spellcheck_active = false;
        private bool writecheck_active;
        private bool typewriter_active;
        private uint typewriter_timeout_id = 0;
        private int64 typewriter_last_edit_time = 0;
        private const int TYPEWRITER_IDLE_TIMEOUT_MS = 2000;
        private int64 typewriter_last_click_time = 0;
        private const int TYPEWRITER_CLICK_PAUSE_MS = 300;
        private bool grammar_active = false;
        private bool no_hiding = false;
        private bool pointer_down = false;
        private bool selection_dragging = false;
        private double drag_start_y = 0.0;
        private double drag_pointer_y = 0.0;
        private uint drag_scroll_source = 0;

        private Gtk.TextTag focus_text;
        private Gtk.TextTag outoffocus_text;

        // Word count tracking
        private int _buffer_word_count = 0;
        private TimedMutex word_count_update_limit;
        private Thread<void>? word_count_thread = null;
        private Mutex word_count_mutex;
        private bool word_count_processing = false;
        private int _pending_word_count = 0;

        // Context menu
        private EditorContextMenu? context_menu_helper = null;
        private string _text_to_count = "";

        //
        // Optional Enrichments
        //
        private FountainEnrichment? fountain = null;
        private MarkdownEnrichment? markdown = null;

        //
        // Maintaining state
        //

        public bool is_modified { get; set; default = false; }
        private bool should_scroll { get; set; default = false; }
        private bool should_save { get; set; default = false; }

        public Editor (string file_path) {
            var settings = AppSettings.get_default ();
            settings.changed.connect (update_settings);

            // Sync our local buffer reference with the View's default buffer
            buffer = (GtkSource.Buffer) this.get_buffer ();

            // Initialize mutex helpers before any debounced work runs
            disk_change_prompted = new TimedMutex (Constants.AUTOSAVE_TIMEOUT);
            dynamic_margin_update = new TimedMutex (250);
            writegood_limit = new TimedMutex (300);
            preview_mutex = new TimedMutex (250);
            word_count_update_limit = new TimedMutex (500);
            word_count_mutex = Mutex ();
            vexpand = true;

            // Initialize spell checking with libspelling (lazily created when enabled)
            // spell_adapter created in spellcheck property setter

            // Initialize optional enrichments to avoid null derefs when toggled
            writegood = new WriteGood.Checker ();
            writegood.show_tooltip = true;
            grammar = new GrammarChecker ();

            var click_controller = new Gtk.GestureClick ();
            click_controller.set_button (1);
            click_controller.pressed.connect ((n_press, x, y) => {
                pointer_down = true;
            });
            click_controller.released.connect ((n_press, x, y) => {
                // Check for Ctrl+Click on markdown links
                var event = click_controller.get_current_event ();
                if (event != null && markdown != null) {
                    var state = event.get_modifier_state ();
                    markdown.handle_click (x, y, state);
                }
                
                // Pause typewriter scrolling for 300ms after click to allow double-click/selection
                pause_typewriter_scrolling_on_click ();
                
                pointer_down = false;
                GLib.Idle.add (() => {
                    if (settings.typewriter_scrolling) {
                        move_typewriter_scolling ();
                    } else {
                        ensure_cursor_visible ();
                    }
                    return false;
                });
            });
            this.add_controller (click_controller);

            var drag_controller = new Gtk.GestureDrag ();
            drag_controller.drag_begin.connect ((start_x, start_y) => {
                selection_dragging = true;
                drag_start_y = start_y;
                drag_pointer_y = start_y;
                if (drag_scroll_source == 0) {
                    drag_scroll_source = Timeout.add (30, drag_autoscroll);
                }
            });
            drag_controller.drag_update.connect ((offset_x, offset_y) => {
                drag_pointer_y = drag_start_y + offset_y;
            });
            drag_controller.drag_end.connect ((offset_x, offset_y) => {
                selection_dragging = false;
                if (drag_scroll_source != 0) {
                    Source.remove (drag_scroll_source);
                    drag_scroll_source = 0;
                }
            });
            this.add_controller (drag_controller);

            setup_drop_target ();
            context_menu_helper = new EditorContextMenu (this);

            file_mutex = Mutex ();
            #if false
            // GTK4 TODO: rebuild editor context menu with Gtk.PopoverMenu
            var settings = AppSettings.get_default ();
            this.populate_popup.connect ((source, menu) => {
                no_change_prompt = true;
                if (!please_no_spell_prompt) {
                    please_no_spell_prompt = true;
                    Timeout.add (10000, () => {
                        if (no_change_prompt) {
                            no_change_prompt = false;
                        }
                        please_no_spell_prompt = false;
                        return false;
                    });
                }
                Gtk.SeparatorMenuItem sep = new Gtk.SeparatorMenuItem ();
                menu.add (sep);

                Gtk.MenuItem menu_insert_datetime = new Gtk.MenuItem.with_label (_("Insert Datetime"));
                menu_insert_datetime.activate.connect (() => {

                    string parent_path = file.get_parent ().get_path ().down ();
                    bool am_iso8601 = parent_path.contains ("content");

                    DateTime now = new DateTime.now_local ();
                    string new_text = now.format ("%F %T");

                    if (am_iso8601) {
                        new_text = now.format ("%FT%T%z");
                    }

                    // Set timer so we don't prompt for file modification?
                    disk_change_prompted.can_do_action ();
                    insert_at_cursor (new_text);
                });

                Gtk.MenuItem menu_insert_frontmatter = new Gtk.MenuItem.with_label (_("Insert YAML Frontmatter"));
                menu_insert_frontmatter.activate.connect (() => {
                    if (!get_buffer_text ().has_prefix ("---")) {
                        int new_cursor_location = 0;
                        Regex date = null;
                        try {
                            date = new Regex ("([0-9]{4}-[0-9]{1,2}-[0-9]{1,2}-?)?(.*?)$", RegexCompileFlags.MULTILINE | RegexCompileFlags.CASELESS, 0);
                        } catch (Error e) {
                            warning ("Could not compile regex: %s", e.message);
                        }

                        DateTime now = new DateTime.now_local ();
                        string current_time = now.format ("%F %T");

                        string parent_folder = file.get_parent ().get_basename ().down ();
                        string page_type = (parent_folder.contains ("post") || parent_folder.contains ("draft")) ? "post" : "page";
                        string current_title = file.get_basename ();
                        string parent_path = file.get_parent ().get_path ().down ();
                        string base_url = settings.site_url;
                        if (parent_path.contains ("content")) {
                            page_type = parent_path.substring (parent_path.last_index_of ("content") + 8, -1).replace ("/", "").replace ("\\", "");
                        }

                        if (parent_path.contains ("/posts")) {
                            base_url = settings.posts_url;
                        } else if (parent_path.contains ("/pages")) {
                            base_url = settings.pages_url;
                        }

                        // Setup defaults based on WordPress and Hugo archetypes
                        string frontmatter =
"---\n" +
"title: \"" + current_title + "\"\n" +
"date: " + current_time + "\n" +
"url: \"" + base_url + current_title + "\"\n" +
"type: \"" + page_type + "\"\n" +
"draft: true\n" +
"tags: []\n" +
"categories: []\n" +
"summary: \"\"\n" +
"---\n\n";

                        /*
                        // Blacklist frontmatter of posts or pages
                        if (parent_path.contains ("posts") || parent_path.contains ("pages")) {
                            frontmatter = "---\n";
                        }
                        */

                        if (settings.quarter_publishing) {
                            try {
                                var match = date.match (parent_path);
                                if (match != null) {
                                    if (match.fetch (2) != null) {
                                        current_title = match.fetch (2).replace ("/", "");
                                    }
                                }
                            } catch (Error e) {
                                warning ("Could not look for weekly filename title");
                            }
                        }

                        var copy = Gtk.Clipboard.get_default (Gdk.Display.get_default ());
                        copy.set_text (current_title, current_title.length);

                        insert_at_cursor (frontmatter);
                        TextIter cursor;
                        buffer.get_start_iter (out cursor);
                        cursor.forward_lines (9);
                        buffer.place_cursor (cursor);
                    }
                });

                menu.add (menu_insert_datetime);
                menu.add (menu_insert_frontmatter);
                menu.show_all ();
            });
            #endif

            if (!open_file (file_path)) {
                settings.validate_library ();
                string[] library_check = settings.library ();
                if (!settings.dont_show_tips || library_check.length == 0) {
                    set_text (Constants.FIRST_USE.printf (ThiefProperties.THIEF_TIPS.get (Random.int_range(0, ThiefProperties.THIEF_TIPS.size))), true);
                    editable = false;
                    // Ensure the welcome buffer uses the configured style scheme and markdown highlighting
                    buffer.set_language (UI.get_source_language ("welcome.md"));
                    set_scheme (settings.get_valid_theme_id ());
                }
            } else {
                modified_time = new DateTime.now_utc ();
            }

            // GTK4: file loading handled in open_file; constructor no longer performs disk checks.
            
            // Initialize spell checking after everything else is set up
            GLib.Idle.add (() => {
                spellcheck_enable ();
                return false;
            });
        }

        /* GTK4 TODO: motion_notify_event replaced by Gtk.EventController
        private bool no_hiding = false;
        public override bool motion_notify_event (EventMotion event ) {
            if (((event.state & Gdk.ModifierType.BUTTON1_MASK) != 0) ||
                ((event.state & Gdk.ModifierType.BUTTON2_MASK) != 0) ||
                ((event.state & Gdk.ModifierType.BUTTON3_MASK) != 0) || 
                ((event.state & Gdk.ModifierType.BUTTON4_MASK) != 0) || 
                ((event.state & Gdk.ModifierType.BUTTON5_MASK) != 0))
            {
                no_hiding = true;
                if (markdown != null) {
                    markdown.active_selection = true;
                }
            } else if (no_hiding) {
                if (markdown != null) {
                    markdown.recheck_all ();
                }
                Timeout.add (300, () => {
                    no_hiding = false;
                    if (markdown != null) {
                        markdown.recheck_all ();
                        markdown.active_selection = false;
                    }
                    return false;
                });
            }

            base.motion_notify_event (event);
            return false;
        }
        */

        private void setup_drop_target () {
            var drop_target = new Gtk.DropTarget (Type.INVALID, Gdk.DragAction.COPY);
            drop_target.set_gtypes ({ typeof (File), typeof (string) });
            drop_target.drop.connect ((value, x, y) => {
                return handle_drop_value (value, x, y);
            });
            add_controller (drop_target);
        }

        private void get_drop_iter_at (double x, double y, out Gtk.TextIter drop_iter) {
            int trailing = 0;
            this.get_iter_at_position (out drop_iter, out trailing, (int) x, (int) y);

            Gdk.Rectangle rect;
            this.get_iter_location (drop_iter, out rect);
            int win_x = 0;
            int win_y = 0;
            this.buffer_to_window_coords (Gtk.TextWindowType.TEXT, rect.x, rect.y, out win_x, out win_y);

            int line_height = rect.height;
            if (line_height > 0) {
                int adjusted_y = (int) y - (line_height / 2);
                if (adjusted_y < 0) {
                    adjusted_y = 0;
                }
                this.get_iter_at_position (out drop_iter, out trailing, (int) x, adjusted_y);
            }
        }

        private bool handle_drop_value (Value value, double x, double y) {
            var paths = new Gee.ArrayList<string> ();
            if (value.type () == typeof (File)) {
                var dropped_file = (File) value;
                string? path = dropped_file.get_path ();
                if (path != null && path.chomp () != "") {
                    paths.add (path);
                }
            } else if (value.type () == typeof (string)) {
                string drop_text = (string) value;
                if (drop_text != null) {
                    collect_drop_paths_from_text (drop_text, paths);
                }
            }

            bool inserted = false;
            if (paths.size > 0) {
                StringBuilder combined = new StringBuilder ();
                foreach (var path in paths) {
                    string insert = build_drop_insert (path);
                    if (insert == "") {
                        continue;
                    }

                    if (combined.len > 0) {
                        bool ends_with_newline = combined.str.has_suffix ("\n");
                        bool starts_with_newline = insert.has_prefix ("\n");
                        if (!ends_with_newline && !starts_with_newline) {
                            combined.append ("\n");
                        }
                    }
                    combined.append (insert);
                }

                if (combined.len > 0) {
                    disk_change_prompted.can_do_action ();
                    Gtk.TextIter drop_iter;
                    get_drop_iter_at (x, y, out drop_iter);
                    buffer.insert (ref drop_iter, combined.str, (int) combined.len);
                    buffer.place_cursor (drop_iter);
                    inserted = true;
                }
            }

            if (!inserted && value.type () == typeof (string)) {
                string drop_text = (string) value;
                if (drop_text != null && drop_text.chomp () != "") {
                    string? drop_path = extract_drop_path (drop_text);
                    if (drop_path != null) {
                        string insert = build_drop_insert (drop_path);
                        if (insert != "") {
                            disk_change_prompted.can_do_action ();
                            Gtk.TextIter drop_iter;
                            get_drop_iter_at (x, y, out drop_iter);
                            buffer.insert (ref drop_iter, insert, (int) insert.length);
                            buffer.place_cursor (drop_iter);
                            return true;
                        }
                    }

                    disk_change_prompted.can_do_action ();
                    Gtk.TextIter drop_iter;
                    get_drop_iter_at (x, y, out drop_iter);
                    buffer.insert (ref drop_iter, drop_text, drop_text.length);
                    buffer.place_cursor (drop_iter);
                    return true;
                }
            }

            return inserted;
        }

        private void collect_drop_paths_from_text (string drop_text, Gee.ArrayList<string> paths) {
            string cleaned = drop_text.replace ("\r", "");
            string[] lines = cleaned.split ("\n");
            if (lines.length <= 1) {
                string? single = extract_drop_path (drop_text);
                if (single != null) {
                    paths.add (single);
                }
                return;
            }

            foreach (var line in lines) {
                if (line == null) {
                    continue;
                }
                string trimmed = line.chomp ();
                if (trimmed == "" || trimmed.has_prefix ("#")) {
                    continue;
                }
                string? path = extract_drop_path (trimmed);
                if (path != null) {
                    paths.add (path);
                }
            }
        }

        private string? extract_drop_path (string text) {
            string trimmed = text.chomp ();
            if (trimmed == "") {
                return null;
            }

            if (trimmed.has_prefix ("file://") || trimmed.has_prefix ("file:")) {
                File file_from_uri = File.new_for_uri (trimmed);
                string? uri_path = file_from_uri.get_path ();
                if (uri_path != null && uri_path.chomp () != "") {
                    return uri_path;
                }
                return null;
            }

            if (FileUtils.test (trimmed, FileTest.EXISTS)) {
                return trimmed;
            }

            return null;
        }

        private string build_drop_insert (string data) {
            if (data == null || data.chomp () == "") {
                return "";
            }

            string ext = data.substring (data.last_index_of (".") + 1).down ().chug ().chomp ();
            string insert = "";
            if (ext == "png" || ext == "jpeg" ||
                ext == "jpg" || ext == "gif" ||
                ext == "svg" || ext == "bmp")
            {
                insert = "![](" + get_base_library_path (data) + ")\n";
            } else if (ext == "yml" || ext == "js" || ext == "hpp" || ext == "coffee" || ext == "sh" ||
                        ext == "vala" || ext == "c" || ext == "vapi" || ext == "ts" || ext == "toml" || ext == "ps1" ||
                        ext == "cpp" || ext == "rb" || ext == "css" || ext == "php" || ext == "scss" || ext == "less" ||
                        ext == "pl" || ext == "py" || ext == "sass" || ext == "json" || ext == "nim" || ext == "ps" ||
                        ext == "pm" || ext == "h" || ext == "log" || ext == "rs")
            {
                if (file.query_exists () &&
                    (!FileUtils.test (data, FileTest.IS_DIR)) &&
                    (FileUtils.test (data, FileTest.IS_REGULAR)))
                {
                    string code_data = FileManager.get_file_contents (data);
                    if (code_data.chug ().chomp () != "") {
                        insert = "\n```" + ext + "\n";
                        insert += code_data;
                        insert += "\n```\n";
                    }
                }
            } else if (ext == "pdf" || ext == "docx" || ext == "pptx" ||
                        ext == "html" || ext == "odt" || ext == "md" ||
                        ext == "markdown" || ext == "txt" || ext == "" ||
                        ext == "doc" || ext == "xls" || ext == "xlsx" || ext == "ppt") {
                insert = "[" + data.substring (data.last_index_of (Path.DIR_SEPARATOR_S) + 1) + "](" + get_base_library_path (data) + ")\n";
            } else if (ext == "csv") {
                if (file.query_exists () &&
                    (!FileUtils.test (data, FileTest.IS_DIR)) &&
                    (FileUtils.test (data, FileTest.IS_REGULAR)))
                {
                    string code_data = FileManager.get_file_contents (data);
                    if (code_data.chug ().chomp () != "") {
                        insert = "\n" + csv_to_md (code_data) + "\n";
                    }
                }
            } else {
                insert = "[" + data.substring (data.last_index_of (Path.DIR_SEPARATOR_S) + 1) + "](" + get_base_library_path (data) + ")\n";
            }

            return insert;
        }

        public signal void changed ();

        public void on_change_notification () {
            is_modified = true;
            on_text_modified ();
        }

        public bool disk_matches_buffer (out string disk_text, out DateTime disk_time) {
            bool match = false;
            disk_text = "";
            disk_time = new DateTime.now_utc ().add_years (-1);
            
            try {
                if (file_mutex.trylock ()) {
                    FileInfo last_modified = file.query_info (FileAttribute.TIME_MODIFIED, FileQueryInfoFlags.NONE);
                    disk_time = last_modified.get_modification_date_time ();

                    string checksum_on_close = Checksum.compute_for_string (ChecksumType.MD5, get_buffer_text ());
                    string filename = file.get_path ();
                    debug ("Checking: %s, against %s", filename, checksum_on_close);
                    GLib.FileUtils.get_contents (filename, out disk_text);
                    string checksum_on_open = Checksum.compute_for_string (ChecksumType.MD5, disk_text);
                    if (checksum_on_close != checksum_on_open) {
                        warning ("File changed on disk (%s != %s), rereading", checksum_on_open, checksum_on_close);
                    } else {
                        debug ("File matches: %s, %s against %s", filename, checksum_on_open, checksum_on_close);
                        match = true;
                    }

                    file_mutex.unlock ();
                } else {
                    // File is loading, don't overwrite the buffer
                    match = true;
                }
            } catch (Error e) {
                warning ("Could not load file from disk: %s", e.message);
            }

            return match;
        }

        private int cursor_location;
        public bool am_active {
            get {
                return active;
            }
            set {
                // Log the Editor's own vscroll policy (GtkSourceView is a Scrollable)
                Gtk.ScrollablePolicy vpolicy = this.vscroll_policy;
                print ("Editor am_active: GtkSourceView vscroll policy = %s", vpolicy.to_string ());

                var settings = AppSettings.get_default ();
                if (value){
                    bool move_screen = false;
                    // Update the file if it was changed from disk
                    if (opened_filename != "" && file.query_exists ())
                    {
                        string text;
                        try {
                            string checksum_on_close = Checksum.compute_for_string (ChecksumType.MD5, get_buffer_text ());
                            string filename = file.get_path ();
                            GLib.FileUtils.get_contents (filename, out text);
                            string checksum_on_open = Checksum.compute_for_string (ChecksumType.MD5, text);
                            if (checksum_on_close != checksum_on_open) {
                                warning ("File changed on disk (%s != %s), rereading", checksum_on_open, checksum_on_close);
                                set_text (text, true);
                                move_screen = true;
                            }
                            if (cursor_location > text.length) {
                                cursor_location = text.length - 1;
                            }
                        } catch (Error e) {
                            warning ("Could not load file from disk: %s", e.message);
                        }

                        editable = true;
                    }

                    preview_markdown = get_buffer_text ();
                    active = true;

                    set_scheme (settings.get_valid_theme_id ());

                    if (move_screen) {
                        debug ("Cursor found at: %d", cursor_location);
                        // Move the cursor
                        set_cursor_visible (true);
                        Gtk.TextIter new_cursor_location;
                        buffer.get_start_iter (out new_cursor_location);
                        new_cursor_location.forward_chars (cursor_location);
                        buffer.place_cursor (new_cursor_location);
                        scroll_to_iter (new_cursor_location, 0.0, true, 0.0, Constants.TYPEWRITER_POSITION);
                    }

                    buffer.changed.connect (on_change_notification);
                    settings.changed.connect (update_settings);

                    typewriter_active = settings.typewriter_scrolling;
                    if (typewriter_active) {
                        debug ("File open: connecting typewriter scrolling signals");
                        buffer.notify["cursor-position"].connect (move_typewriter_scolling_void);
                    } else {
                        stop_typewriter_timer ();
                    }

                    if (settings.autosave) {
                        Timeout.add (Constants.AUTOSAVE_TIMEOUT, autosave);
                    }

                    if (settings.writegood) {
                        writecheck_active = true;
                        if (writegood != null) {
                            writegood.attach (this);
                            write_good_recheck ();
                        }
                    }

                    if (settings.grammar && !grammar_active) {
                        grammar_active = true;
                        if (grammar != null) {
                            grammar.attach (this);
                            GLib.Idle.add (grammar_recheck);
                        }
                    }

                    // Spell checking is handled by lazy initialization in the Idle callback below

                    //
                    // Register for redrawing of window for handling margins and other
                    // redrawing
                    //
                    left_margin = 0;
                    right_margin = 0;
                    move_margins ();
                    should_scroll = true;
                    update_preview ();
                    spellcheck_enable();
                } else {
                    if (active != value) {
                        cursor_location = buffer.cursor_position;
                        debug ("Cursor saved at: %d", cursor_location);

                        preview_markdown = "";
                        save ();

                        buffer.changed.disconnect (on_change_notification);
                        settings.changed.disconnect (update_settings);

                        stop_typewriter_timer ();

                        if (settings.writegood && writegood != null) {
                            writecheck_active = false;
                            writegood.detach ();
                        }

                        if (settings.grammar && grammar != null) {
                            grammar_active = false;
                            grammar.detach ();
                        }

                        if (settings.spellcheck && spell_adapter != null) {
                            spell_adapter.set_enabled (false);
                        }
                    }
                    editable = false;
                    active = false;
                    spellcheck = false;
                }
            }
        }

        public string active_markdown () {
            if (preview_markdown == "") {
                return get_buffer_text ();
            }

            return preview_markdown;
        }

        public string get_buffer_text () {
            Gtk.TextIter start, end;
            buffer.get_bounds (out start, out end);
            // Strip U+FFFC (object replacement char) — that's what GTK uses to
            // represent child anchors and embedded objects in the text.
            // We don't want those sneaking into saved markdown files!
            return buffer.get_text (start, end, true).replace ("\xef\xbf\xbc", "");
        }

        public int get_buffer_word_count () {
            return _buffer_word_count;
        }

        public unowned Spelling.TextBufferAdapter? get_spell_adapter () {
            return spell_adapter;
        }

        private void update_buffer_word_count () {
            if (!word_count_update_limit.can_do_action ()) {
                return;
            }
            
            word_count_mutex.lock ();
            if (word_count_processing) {
                // Already counting, skip this update
                word_count_mutex.unlock ();
                return;
            }
            
            // Join any previous thread
            if (word_count_thread != null) {
                word_count_thread.join ();
            }
            
            // Capture buffer text on main thread before spawning worker
            // This is critical - GTK operations must happen on the main thread
            _text_to_count = get_buffer_text ();
            
            word_count_processing = true;
            word_count_mutex.unlock ();
            
            // Spawn background thread to calculate word count
            word_count_thread = new Thread<void> ("word-counter", count_words_background);
            GLib.Idle.add (apply_word_count_result);
        }
        
        private void count_words_background () {
            _pending_word_count = FileManager.get_word_count_from_string (_text_to_count);
            word_count_processing = false;
            Thread.exit (0);
        }
        
        private bool apply_word_count_result () {
            word_count_mutex.lock ();
            bool still_processing = word_count_processing;
            word_count_mutex.unlock ();
            
            if (still_processing) {
                // Keep checking until processing is complete
                return true;
            }
            
            // Update the count on the main thread
            _buffer_word_count = _pending_word_count;
            
            var settings = AppSettings.get_default ();
            settings.writing_changed ();
            
            return false;
        }

        public bool spellcheck {
            set {
                if (value && !spellcheck_active) {
                    if (spell_adapter == null) {
                        try {
                            var spell_checker = Spelling.Checker.get_default ();
                            if (spell_checker == null) {
                                warning ("spell_checker is null");
                                return;
                            }
                            spell_adapter = new Spelling.TextBufferAdapter (buffer, spell_checker);
                            if (spell_adapter == null) {
                                warning ("spell_adapter creation failed");
                                return;
                            }
                        } catch (Error e) {
                            warning ("Error creating spell adapter: %s", e.message);
                            return;
                        }
                    }
                    
                    if (spell_adapter != null) {
                        try {
                            // Try to set saved language, otherwise use first available
                            try {
                                var settings = AppSettings.get_default ();
                                var last_language = settings.spellcheck_language;
                                var provider = Spelling.Provider.get_default ();
                                if (provider != null) {
                                    var languages_model = provider.list_languages ();
                                    uint n_items = languages_model.get_n_items ();
                                    
                                    if (n_items > 0) {
                                        // Try to set to saved language, otherwise use first available
                                        bool language_found = false;
                                        for (uint i = 0; i < n_items; i++) {
                                            var lang_obj = languages_model.get_object (i);
                                            if (lang_obj is Spelling.Language) {
                                                var lang = (Spelling.Language)lang_obj;
                                                if (last_language != null && last_language == lang.get_code ()) {
                                                    spell_adapter.set_language (last_language);
                                                    language_found = true;
                                                    break;
                                                }
                                            }
                                        }
                                        
                                        // Use first language if saved one not found
                                        if (!language_found) {
                                            var first_lang = languages_model.get_object (0);
                                            if (first_lang is Spelling.Language) {
                                                var lang = (Spelling.Language)first_lang;
                                                spell_adapter.set_language (lang.get_code ());
                                            }
                                        }
                                    }
                                }
                            } catch (Error e) {
                                debug ("Error setting language: %s", e.message);
                            }
                            
                            spell_adapter.set_enabled (true);
                            
                            // Defer invalidate_all to background to avoid blocking UI with large files
                            new Thread<bool> (null, () => {
                                spell_adapter.invalidate_all ();
                                return true;
                            });
                            
                            spellcheck_active = true;
                            
                            // Refresh context menu now that spell adapter is available
                            if (context_menu_helper != null) {
                                context_menu_helper.refresh_context_menu ();
                            }
                        } catch (Error e) {
                            warning ("Error enabling spellcheck: %s", e.message);
                        }
                    }
                } else if (!value && spellcheck_active) {
                    if (spell_adapter != null) {
                        spell_adapter.set_enabled (false);
                    }
                    spellcheck_active = false;
                }
            }
        }

        public void bold () {
            markdown.bold ();
        }

        public void italic () {
            markdown.italic ();
        }

        public void strikethrough () {
            markdown.strikethrough ();
        }

        public void link () {
            markdown.link ();
        }

        // Navigate to next heading (Markdown) or scene (Fountain)
        public void next_marker () {
            if (fountain != null) {
                navigate_to_next_fountain_scene ();
            } else if (markdown != null) {
                navigate_to_next_heading ();
            }
        }

        // Navigate to previous heading (Markdown) or scene (Fountain)
        public void prev_marker () {
            if (fountain != null) {
                navigate_to_prev_fountain_scene ();
            } else if (markdown != null) {
                navigate_to_prev_heading ();
            }
        }

        // Find and jump to the next Markdown heading
        private void navigate_to_next_heading () {
            Gtk.TextIter cursor_iter;
            var cursor_mark = buffer.get_insert ();
            buffer.get_iter_at_mark (out cursor_iter, cursor_mark);

            // Move to start of next line to begin search
            if (!cursor_iter.forward_line ()) {
                return; // Already at end of buffer
            }

            Gtk.TextIter end;
            buffer.get_end_iter (out end);
            string remaining_text = cursor_iter.get_text (end);

            try {
                // Regex to match Markdown headings: # Heading
                var heading_regex = new Regex ("^(#+)\\s+(.+)$", RegexCompileFlags.MULTILINE);
                MatchInfo match_info;

                if (heading_regex.match (remaining_text, 0, out match_info)) {
                    int match_start, match_end;
                    if (match_info.fetch_pos (0, out match_start, out match_end)) {
                        // Calculate absolute offset in buffer
                        int offset = cursor_iter.get_offset () + match_start;
                        Gtk.TextIter target_iter;
                        buffer.get_iter_at_offset (out target_iter, offset);

                        // Place cursor at start of heading
                        buffer.place_cursor (target_iter);

                        // Respect typewriter scrolling if enabled
                        var settings = AppSettings.get_default ();
                        if (settings.typewriter_scrolling) {
                            move_typewriter_scolling ();
                        } else {
                            scroll_to_iter (target_iter, 0.0, false, 0.0, 0.0);
                        }
                    }
                }
            } catch (RegexError e) {
                warning ("Regex error in navigate_to_next_heading: %s", e.message);
            }
        }

        // Find and jump to the previous Markdown heading
        private void navigate_to_prev_heading () {
            Gtk.TextIter cursor_iter;
            var cursor_mark = buffer.get_insert ();
            buffer.get_iter_at_mark (out cursor_iter, cursor_mark);

            Gtk.TextIter start;
            buffer.get_start_iter (out start);
            string preceding_text = start.get_text (cursor_iter);

            try {
                // Regex to match Markdown headings: # Heading
                var heading_regex = new Regex ("^(#+)\\s+(.+)$", RegexCompileFlags.MULTILINE);
                MatchInfo match_info;

                // Find all matches
                int last_match_start = -1;
                if (heading_regex.match (preceding_text, 0, out match_info)) {
                    do {
                        int match_start, match_end;
                        if (match_info.fetch_pos (0, out match_start, out match_end)) {
                            // Only consider matches that end before cursor (with margin)
                            if (match_end < preceding_text.length - 1) {
                                last_match_start = match_start;
                            }
                        }
                    } while (match_info.next ());

                    if (last_match_start >= 0) {
                        // Calculate absolute offset in buffer
                        Gtk.TextIter target_iter;
                        buffer.get_iter_at_offset (out target_iter, last_match_start);

                        // Place cursor at start of heading
                        buffer.place_cursor (target_iter);

                        // Respect typewriter scrolling if enabled
                        var settings = AppSettings.get_default ();
                        if (settings.typewriter_scrolling) {
                            move_typewriter_scolling ();
                        } else {
                            scroll_to_iter (target_iter, 0.0, false, 0.0, 0.0);
                        }
                    }
                }
            } catch (RegexError e) {
                warning ("Regex error in navigate_to_prev_heading: %s", e.message);
            }
        }

        // Find and jump to the next Fountain scene heading
        private void navigate_to_next_fountain_scene () {
            Gtk.TextIter cursor_iter;
            var cursor_mark = buffer.get_insert ();
            buffer.get_iter_at_mark (out cursor_iter, cursor_mark);

            // Move to start of next line to begin search
            if (!cursor_iter.forward_line ()) {
                return; // Already at end of buffer
            }

            Gtk.TextIter end;
            buffer.get_end_iter (out end);
            string remaining_text = cursor_iter.get_text (end);

            try {
                // Regex to match Fountain scene headings: INT/EXT/EST/I/E. LOCATION - TIME
                var scene_regex = new Regex ("^(ИНТ|НАТ|инт|нат|INT|EXT|EST|I\\/E|int|ext|est|i\\/e)[\\. \\/]", RegexCompileFlags.MULTILINE | RegexCompileFlags.CASELESS);
                MatchInfo match_info;

                if (scene_regex.match (remaining_text, 0, out match_info)) {
                    int match_start, match_end;
                    if (match_info.fetch_pos (0, out match_start, out match_end)) {
                        // Calculate absolute offset in buffer
                        int offset = cursor_iter.get_offset () + match_start;
                        Gtk.TextIter target_iter;
                        buffer.get_iter_at_offset (out target_iter, offset);

                        // Place cursor at start of scene heading
                        buffer.place_cursor (target_iter);

                        // Respect typewriter scrolling if enabled
                        var settings = AppSettings.get_default ();
                        if (settings.typewriter_scrolling) {
                            move_typewriter_scolling ();
                        } else {
                            scroll_to_iter (target_iter, 0.0, false, 0.0, 0.0);
                        }
                    }
                }
            } catch (RegexError e) {
                warning ("Regex error in navigate_to_next_fountain_scene: %s", e.message);
            }
        }

        // Find and jump to the previous Fountain scene heading
        private void navigate_to_prev_fountain_scene () {
            Gtk.TextIter cursor_iter;
            var cursor_mark = buffer.get_insert ();
            buffer.get_iter_at_mark (out cursor_iter, cursor_mark);

            Gtk.TextIter start;
            buffer.get_start_iter (out start);
            string preceding_text = start.get_text (cursor_iter);

            try {
                // Regex to match Fountain scene headings: INT/EXT/EST/I/E. LOCATION - TIME
                var scene_regex = new Regex ("^(ИНТ|НАТ|инт|нат|INT|EXT|EST|I\\/E|int|ext|est|i\\/e)[\\. \\/]", RegexCompileFlags.MULTILINE | RegexCompileFlags.CASELESS);
                MatchInfo match_info;

                // Find all matches
                int last_match_start = -1;
                if (scene_regex.match (preceding_text, 0, out match_info)) {
                    do {
                        int match_start, match_end;
                        if (match_info.fetch_pos (0, out match_start, out match_end)) {
                            // Only consider matches that end before cursor (with margin)
                            if (match_end < preceding_text.length - 1) {
                                last_match_start = match_start;
                            }
                        }
                    } while (match_info.next ());

                    if (last_match_start >= 0) {
                        // Calculate absolute offset in buffer
                        Gtk.TextIter target_iter;
                        buffer.get_iter_at_offset (out target_iter, last_match_start);

                        // Place cursor at start of scene heading
                        buffer.place_cursor (target_iter);

                        // Respect typewriter scrolling if enabled
                        var settings = AppSettings.get_default ();
                        if (settings.typewriter_scrolling) {
                            move_typewriter_scolling ();
                        } else {
                            scroll_to_iter (target_iter, 0.0, false, 0.0, 0.0);
                        }
                    }
                }
            } catch (RegexError e) {
                warning ("Regex error in navigate_to_prev_fountain_scene: %s", e.message);
            }
        }

        public bool save () {
            bool result = false;
            var settings = AppSettings.get_default ();
            if (opened_filename != "" && file.query_exists () && !FileUtils.test (file.get_path (), FileTest.IS_DIR)) {
                file_mutex.lock ();
                try {
                    FileManager.save_file (file, get_buffer_text ().data);
                    modified_time = new DateTime.now_utc ();
                    result = true;
                } catch (Error e) {
                    warning ("Could not save file: %s", e.message);
                }
                file_mutex.unlock ();
            } else if (opened_filename == "" && get_buffer_text () != "" && settings.dont_show_tips && editable) {
                Sheets? target = SheetManager.get_sheets ();
                if (target != null) {
                    file_mutex.lock ();
                    try {
                        DateTime now = new DateTime.now_utc ();
                        string buff_text = get_buffer_text ();
                        string first_words = get_some_words (buff_text);
                        string new_text = (first_words != "") ? now.format ("%Y-%m-%d") : now.format ("%Y-%m-%d_%H-%M-%S");
                        string new_file = new_text + first_words + ".md";
                        string new_path = Path.build_filename (target.get_sheets_path (), new_file);
                        file = File.new_for_path (new_path);
                        FileManager.save_file (file, buff_text.data);
                        opened_filename = new_path;
                        modified_time = new DateTime.now_utc ();
                        result = true;
                    } catch (Error e) {
                        warning ("Could not save file: %s", e.message);
                    }
                    file_mutex.unlock ();
                }
            }
            return result;
        }

        private bool autosave () {
            if (!active) {
                return false;
            }

            var settings = AppSettings.get_default ();
            modified_time = new DateTime.now_utc ();

            //
            // Make sure we're not swapping files
            //
            if (should_save) {
                save ();
                SheetManager.redraw ();
                should_save = false;
            }

            // Jamming this here for now to prevent
            // reinit of spellcheck on resize
            int w, h;
            ThiefApp.get_instance ().get_default_size (out w, out h);
            settings.window_width = w;
            settings.window_height = h;

            if (spellcheck_active && buffer.text != "") {
                // Gspell automatically rechecks, no manual call needed
            }

            return settings.autosave;
        }

        public void undo () {
            if (buffer != null) {
                buffer.undo ();
            }
        }

        public void redo () {
            if (buffer != null) {
                buffer.redo ();
            }
        }

        public void insert_datetime () {
            if (file == null || opened_filename == "" || !file.query_exists ()) {
                return;
            }

            var parent = file.get_parent ();
            if (parent == null) {
                return;
            }

            string parent_path = parent.get_path ().down ();
            bool am_iso8601 = parent_path.contains ("content");

            DateTime now = new DateTime.now_local ();
            string new_text = now.format ("%F %T");

            if (am_iso8601) {
                new_text = now.format ("%FT%T%z");
            }

            disk_change_prompted.can_do_action ();
            insert_at_cursor (new_text);
        }

        public void insert_yaml_frontmatter () {
            if (file == null || opened_filename == "" || !file.query_exists ()) {
                return;
            }

            if (get_buffer_text ().has_prefix ("---")) {
                return;
            }

            var settings = AppSettings.get_default ();
            Regex date = null;
            try {
                date = new Regex ("([0-9]{4}-[0-9]{1,2}-[0-9]{1,2}-?)?(.*?)$", RegexCompileFlags.MULTILINE | RegexCompileFlags.CASELESS, 0);
            } catch (Error e) {
                warning ("Could not compile regex: %s", e.message);
            }

            DateTime now = new DateTime.now_local ();
            string current_time = now.format ("%F %T");

            var parent = file.get_parent ();
            if (parent == null) {
                return;
            }

            string parent_folder = parent.get_basename ().down ();
            string page_type = (parent_folder.contains ("post") || parent_folder.contains ("draft")) ? "post" : "page";
            string current_title = file.get_basename ();
            string parent_path = parent.get_path ().down ();
            if (parent_path.contains ("content")) {
                int content_idx = parent_path.last_index_of ("content");
                if (content_idx != -1) {
                    page_type = parent_path.substring (content_idx + 8, -1).replace ("/", "").replace ("\\", "");
                }
            }

            string frontmatter =
"---\n" +
"title: \"" + current_title + "\"\n" +
"date: " + current_time + "\n" +
"type: \"" + page_type + "\"\n" +
"draft: true\n" +
"tags: []\n" +
"categories: []\n" +
"summary: \"\"\n" +
"---\n\n";

            if (date != null) {
                try {
                    MatchInfo match_info;
                    if (date.match (parent_path, 0, out match_info)) {
                        string extracted = match_info.fetch (2);
                        if (extracted != null && extracted != "") {
                            current_title = extracted.replace ("/", "");
                        }
                    }
                } catch (Error e) {
                    warning ("Could not look for weekly filename title");
                }
            }

            var display = Gdk.Display.get_default ();
            if (display != null) {
                var clipboard = display.get_clipboard ();
                clipboard.set_text (current_title);
            }

            insert_at_cursor (frontmatter);
            Gtk.TextIter cursor;
            buffer.get_start_iter (out cursor);
            cursor.forward_lines (9);
            buffer.place_cursor (cursor);
        }

        public void insert_citation (string citation) {
            if (citation == "") {
                return;
            }

            string insert_citation_string = citation;
            var cursor = buffer.get_insert ();
            Gtk.TextIter start;
            buffer.get_iter_at_mark (out start, cursor);
            if (start.backward_char ()) {
                if (start.get_char () != '@') {
                    insert_citation_string = "@" + insert_citation_string;
                }
            }
            insert_at_cursor (insert_citation_string);
        }

        public Gee.HashMap<string, string> get_citation_labels () {
            var labels = new Gee.HashMap<string, string> ();
            if (file == null || opened_filename == "") {
                return labels;
            }

            string bib_file = "";
            if (!Pandoc.get_bibtex_path (get_buffer_text (), ref bib_file)) {
                bib_file = find_bibtex_for_sheet_local (opened_filename);
            } else {
                bib_file = Pandoc.find_file (bib_file);
            }

            if (bib_file == "") {
                return labels;
            }

            try {
                BibTex.Parser bib_parser = new BibTex.Parser (bib_file);
                bib_parser.parse_file ();
                var cite_labels = bib_parser.get_labels ();
                foreach (var label in cite_labels) {
                    labels.set (label, bib_parser.get_title (label));
                }
            } catch (Error e) {
                warning ("Could not parse bibliography: %s", e.message);
            }

            return labels;
        }

        private string find_bibtex_for_sheet_local (string path = "") {
            string result = "";
            string search_path = Path.get_dirname (path);
            if (search_path == "") {
                Sheet? search_sheet = SheetManager.get_sheet ();
                if (search_sheet != null) {
                    search_path = Path.get_dirname (search_sheet.file_path ());
                }
            }
            if (search_path != "") {
                int idx = 0;
                while (search_path != "") {
                    try {
                        Dir dir = Dir.open (search_path, 0);
                        string? file_name = null;
                        while ((file_name = dir.read_name ()) != null) {
                            if (!file_name.has_prefix (".")) {
                                string file_path = Path.build_filename (search_path, file_name);
                                if (is_bibtex_file (file_path)) {
                                    result = file_path;
                                    break;
                                }
                            }
                        }
                    } catch (Error e) {
                        warning ("Could not scan directory: %s", e.message);
                        break;
                    }
                    if (result != "") {
                        break;
                    }
                    idx = search_path.last_index_of_char (Path.DIR_SEPARATOR);
                    if (idx != -1) {
                        search_path = search_path[0:idx];
                    } else {
                        search_path = "";
                    }
                }
            }

            return result;
        }

        private bool is_bibtex_file (string file_name) {
            string check = file_name.down ();
            return check.has_suffix (".bib") || check.has_suffix (".bibtex");
        }

        private bool writecheck_scheduled = false;
        private void write_good_recheck () {
            if (writegood_limit.can_do_action () && writecheck_active) {
                writegood.quick_check ();
            } else if (writecheck_active) {
                if (!writecheck_scheduled) {
                    writecheck_scheduled = true;
                    Timeout.add (1500, () => {
                        if (writecheck_active) {
                            writegood.quick_check ();
                        }
                        writecheck_scheduled = false;
                        return false;
                    });
                }
            }
        }

        /* GTK4 TODO: get_selected used for Gtk.Menu manipulation
        private Gtk.MenuItem? get_selected (Gtk.Menu? menu) {
            if (menu == null) return null;
            var active = menu.get_active () as Gtk.MenuItem;

            if (active == null) return null;
            var sub_menu = active.get_submenu () as Gtk.Menu;
            if (sub_menu != null) {
                return sub_menu.get_active () as Gtk.MenuItem;
            }

            return null;
        }
        */

        public void on_text_modified () {
            SheetManager.last_modified (this);
            if (file != null && opened_filename != "" && file.query_exists ()) {
                editable = true;
            }

            idle_margins ();

            // Update word count from buffer
            update_buffer_word_count ();

            modified_time = new DateTime.now_utc ();
            should_scroll = true;
            track_typewriter_edit_activity ();
            
            // Only ensure cursor visibility when typewriter mode is disabled
            // When typewriter mode is enabled, move_typewriter_scolling handles scrolling
            var settings = AppSettings.get_default ();
            if (!settings.typewriter_scrolling) {
                debug ("on_text_modified: Calling ensure_cursor_visible (typewriter mode disabled)");
                ensure_cursor_visible ();
            }

            // Mark as we should save the file
            // If no autosave, schedule a save.
            if (!should_save) {
                if (!settings.autosave) {
                    Timeout.add (Constants.AUTOSAVE_TIMEOUT, autosave);
                }
                should_save = true;
            }

            if (is_modified) {
                changed ();
                is_modified = false;
            }

            if (writecheck_active) {
                write_good_recheck ();
            }

            if (grammar_active) {
                grammar_recheck ();
            }

            // Move the preview if present
            update_preview ();
        }

        private TimedMutex preview_mutex;
        private bool preview_scheduled = false;
        public void update_preview () {
            if (!preview_mutex.can_do_action ()) {
                if (!preview_scheduled) {
                    preview_scheduled = true;
                    Timeout.add (750, () => {
                        preview_scheduled = false;
                        update_preview ();
                        return false;
                    });
                }
                return;
            }
            var cursor = buffer.get_insert ();
            if (cursor != null) {
                Gtk.TextIter cursor_iter;
                Gtk.TextIter start, end;
                buffer.get_bounds (out start, out end);
                buffer.get_iter_at_mark (out cursor_iter, cursor);

                string text_before = buffer.get_text (start, cursor_iter, true);
                bool whoa_there_will_robinson = text_before == "" || (text_before.has_prefix ("-") && text_before.index_of ("\n---") == -1);

                if (!whoa_there_will_robinson) {
                    string before = buffer.get_text (start, cursor_iter, true);
                    string last_line = before.substring (before.last_index_of ("\n") + 1);
                    string after = buffer.get_text (cursor_iter, end, true);
                    int nl_loc = after.index_of ("\n");
                    string first_line = after;
                    if (nl_loc != -1) {
                        first_line = after.substring (0, nl_loc);
                    }
                    int adjustment = get_scrollmark_adjustment (last_line, first_line);
                    adjustment = skip_special_chars (after, adjustment);

                    preview_markdown = before;
                    preview_markdown += after.substring (0, adjustment);
                    preview_markdown += ThiefProperties.THIEF_MARK_CONST;
                    preview_markdown += after.substring (adjustment);
                } else {
                    preview_markdown = get_buffer_text ();
                }

                UI.update_preview ();
            }
        }

        private int skip_special_chars (string haystack, int index = 0) {
            const string special_chars = "#>*`-+ ";

            while (haystack.length != 0 && special_chars.contains (haystack.substring (index, 1)) && index < haystack.length - 2) {
                index++;
            }

            return index;
        }

        private int get_scrollmark_adjustment (string before, string after) {
            int open_p = before.last_index_of ("(");
            int open_t = before.last_index_of ("<");
            int close_p = before.last_index_of (")");
            int close_t = before.last_index_of (">");

            if (open_p == -1 && open_t == -1) {
                return 0;
            }

            if (open_p > close_p && open_t > close_t) {
                close_p = after.index_of (")");
                close_t = after.index_of (">");
                return int.max(close_p, close_t) + 1;
            }

            if (open_p > close_p) {
                close_p = after.index_of (")");
                return close_p + 1;
            }

            if (open_t > close_t) {
                close_t = after.index_of (")");
                return close_t + 1;
            }

            return 0;
        }

        public bool open_file (string file_name) {
            idle_margins ();

            bool res = false;
            opened_filename = file_name;
            debug ("Opening file: %s", file_name);
            file = File.new_for_path (file_name);

            // We do this after creating the file in case
            // we switched files or are caching this editor.
            // We don't want this to become active again and
            // corrupt a file.
            if (file_name == "") {
                return res;
            }

            if (file.query_exists ()) {
                file_mutex.lock ();
                try {
                    string text;
                    FileInfo last_modified = file.query_info (FileAttribute.TIME_MODIFIED, FileQueryInfoFlags.NONE);
                    file_modified_time = last_modified.get_modification_date_time ();
                    int64 file_size = last_modified.get_size ();

                    string filename = file.get_path ();
                    GLib.FileUtils.get_contents (filename, out text);

                    // Tear down current enrichments before replacing buffer text.
                    // This avoids callbacks touching text regions during file open.
                    detach_enrichments ();
                    
                    // For large files, defer markdown processing
                    bool defer_enrichments = file_size > 100000; // 100KB threshold
                    
                    set_text (text, true);
                    editable = true;
                    debug ("%s opened (size: %lld bytes)", file_name, file_size);
                    res = true;
                    buffer.set_language (UI.get_source_language (opened_filename));
                    
                    if (defer_enrichments) {
                        // Process enrichments after a delay for large files
                        Timeout.add (100, () => {
                            setup_enrichments_for_file (filename, text);
                            return false;
                        });
                    } else {
                        setup_enrichments_for_file (filename, text);
                    }
                } catch (Error e) {
                    warning ("Error: %s", e.message);
                    SheetManager.show_error ("Unexpected Error: " + e.message);
                }
                file_mutex.unlock ();
            }

            return res;
        }

        private bool is_markdown_file (string filename) {
            string check = filename.down ();
            return check.has_suffix (".md") || check.has_suffix (".markdown");
        }

        private void detach_enrichments () {
            if (fountain != null) {
                fountain.detach ();
                fountain = null;
            }
            if (markdown != null) {
                markdown.detach ();
                markdown = null;
            }
        }

        private void setup_enrichments_for_file (string filename, string text) {
            // Detach any previous enrichments before switching file types
            detach_enrichments ();

            if (is_fountain (filename)) {
                // Normalize Windows newlines for fountain parsing
                if (text.contains ("\r\n")) {
                    text.replace ("\r\n", "\n");
                    set_text (text, true);
                }
                fountain = new FountainEnrichment ();
                fountain.attach (this);
            } else if (is_markdown_file (filename)) {
                markdown = new MarkdownEnrichment ();
                if (markdown.attach (this)) {
                    // Run first pass on idle so file-open text replacement settles.
                    GLib.Idle.add (() => {
                        if (markdown != null) {
                            markdown.recheck_all ();
                        }
                        return false;
                    });
                }
            }
        }

        public void set_text (string text, bool opening = true) {
            if (opening) {
                buffer.set_max_undo_levels (0);
                buffer.changed.disconnect (on_text_modified);
            }

            buffer.text = text;

            if (opening) {
                buffer.set_max_undo_levels (Constants.MAX_UNDO_LEVELS);
                buffer.changed.connect (on_text_modified);
                // Initialize word count on file open
                _buffer_word_count = FileManager.get_word_count_from_string (text);
            }

            Gtk.TextIter? start = null;
            buffer.get_start_iter (out start);
            buffer.place_cursor (start);
        }

        private void idle_margins () {
            GLib.Idle.add (() => {
                move_margins ();
                return false;
            });
        }

        private uint resize_timeout_id = 0;
        
        public override void size_allocate (int width, int height, int baseline) {
            base.size_allocate (width, height, baseline);
            
            // Debounce resize events to avoid excessive recalculations
            if (resize_timeout_id != 0) {
                Source.remove (resize_timeout_id);
            }
            
            resize_timeout_id = Timeout.add (50, () => {
                resize_timeout_id = 0;
                dynamic_margins ();
                return false;
            });
        }

        public void dynamic_margins () {
            int w, h;
            SoloEditor se = ThiefApplication.get_solo (file);
            if (se == null) {
                int alloc_w = this.get_allocated_width ();
                int alloc_h = this.get_allocated_height ();
                bool has_alloc = alloc_w > 0 && alloc_h > 0;

                if (has_alloc) {
                    w = alloc_w;
                    h = alloc_h;
                } else {
                    ThiefApp.get_instance ().get_default_size (out w, out h);
                }

                int note_w = 0;
                if (ThiefApp.get_instance ().notes != null) {
                    note_w = (ThiefApp.get_instance ().notes.child_revealed) ? Notes.get_notes_width () : 0;
                }
                w = w - note_w;
                if (!has_alloc) {
                    w = w - ThiefApp.get_instance ().pane_position;
                }
            } else {
                se.get_editor_size (out w, out h);
            }

            if (!this.get_realized () || w <= 0 || h <= 0) {
                return;
            }

            last_height = h;

            // Only update if width actually changed
            if (w == last_width) {
                return;
            }

            // Single call to move_margins is sufficient
            move_margins ();
        }

        public void move_margins () {
            var settings = AppSettings.get_default ();
            int w, h, m, p;
            SoloEditor se = ThiefApplication.get_solo (file);
            if (se == null) {
                int alloc_w = this.get_allocated_width ();
                int alloc_h = this.get_allocated_height ();
                bool has_alloc = alloc_w > 0 && alloc_h > 0;

                if (has_alloc) {
                    w = alloc_w;
                    h = alloc_h;
                } else {
                    ThiefApp.get_instance ().get_default_size (out w, out h);
                }

                int note_w = 0;
                if (ThiefApp.get_instance ().notes != null) {
                    note_w = (ThiefApp.get_instance ().notes.child_revealed) ? Notes.get_notes_width () : 0;
                }
                w = w - note_w;
                if (!has_alloc) {
                    w = w - ThiefApp.get_instance ().pane_position;
                }
            } else {
                se.get_editor_size (out w, out h);
            }

            if (!this.get_realized () || w <= 0 || h <= 0) {
                return;
            }

            last_height = h;
            last_width = w;

            // If ThiefMD is Full Screen, add additional padding
            p = (settings.fullscreen) ? 5 : 0;

            // Narrow margins on smaller devices
            if (w < 600) {
                m = (int)(w * ((Constants.NARROW_MARGIN + p) / 100.0));
            } else if (w < 800) {
                m = (int)(w * ((Constants.MEDIUM_MARGIN + p) / 100.0));
            } else {
                var margins = settings.margins;
                switch (margins) {
                    case Constants.NARROW_MARGIN:
                        m = (int)(w * ((Constants.NARROW_MARGIN + p) / 100.0));
                        break;
                    case Constants.WIDE_MARGIN:
                        m = (int)(w * ((Constants.WIDE_MARGIN + p) / 100.0));
                        break;
                    default:
                    case Constants.MEDIUM_MARGIN:
                        m = (int)(w * ((Constants.MEDIUM_MARGIN + p) / 100.0));
                        break;
                }
            }

            // Update margins
            left_margin = m;
            right_margin = m;

            update_heading_margins ();

            typewriter_scrolling ();

            // Keep the curson in view?
            should_scroll = true;
            move_typewriter_scolling ();
        }

        bool header_redraw_scheduled = false;
        private void update_heading_margins () {
            bool try_later = false;
            if (!dynamic_margin_update.can_do_action ()) {
                try_later = true;
            }

            if (try_later && !no_hiding && !buffer.has_selection) {
                if (!header_redraw_scheduled) {
                    header_redraw_scheduled = true;
                    Timeout.add (350, () => {
                        header_redraw_scheduled = false;
                        update_heading_margins ();
                        return false;
                    });
                }
                return;
            }

            // Only recheck if we're active to avoid reprocessing on background editors
            if (!am_active) {
                return;
            }

            if (markdown != null) {
                markdown.recheck_all ();
            }

            if (fountain != null) {
                if (!buffer.has_selection) {
                    fountain.recheck_all ();
                }
            }
        }

        private void typewriter_scrolling () {
            var settings = AppSettings.get_default ();

            // For typewriter mode, set margins to allow content centering
            if (settings.typewriter_scrolling) {
                // Calculate margins based on the visible viewport (page_size)
                // Try to get parent ScrolledWindow to find actual page_size
                double page_size = last_height; // fallback to allocated height
                Gtk.Widget? parent = this.get_parent ();
                while (parent != null) {
                    if (parent is Gtk.ScrolledWindow) {
                        Gtk.ScrolledWindow scrolled = (Gtk.ScrolledWindow) parent;
                        Gtk.Adjustment vadjust = scrolled.get_vadjustment ();
                        if (vadjust != null) {
                            page_size = vadjust.get_page_size ();
                        }
                        break;
                    }
                    parent = parent.get_parent ();
                }
                
                // Keep enough room above/below the document so the cursor can sit at TYPEWRITER_POSITION
                double typewriter_position = Constants.TYPEWRITER_POSITION.clamp (0.0, 1.0);
                top_margin = (int)(page_size * typewriter_position);
                bottom_margin = (int)(page_size * (1.0 - typewriter_position));
                debug ("typewriter_scrolling: Set top=%d bottom=%d based on page_size %.0f and position %.2f",
                       top_margin, bottom_margin, page_size, typewriter_position);
            } else {
                bottom_margin = Constants.BOTTOM_MARGIN;
                top_margin = Constants.TOP_MARGIN;
            }
        }

        private void track_typewriter_edit_activity () {
            var settings = AppSettings.get_default ();
            if (!typewriter_active || !settings.typewriter_scrolling) {
                return;
            }

            typewriter_last_edit_time = GLib.get_monotonic_time ();
            start_typewriter_timer_if_needed ();
        }

        private void start_typewriter_timer_if_needed () {
            if (typewriter_timeout_id != 0) {
                return;
            }

            typewriter_timeout_id = Timeout.add (Constants.TYPEWRITER_UPDATE_TIME, typewriter_timer_tick);
        }

        private void stop_typewriter_timer () {
            if (typewriter_timeout_id != 0) {
                Source.remove (typewriter_timeout_id);
                typewriter_timeout_id = 0;
            }

            typewriter_last_edit_time = 0;
        }

        private bool typewriter_timer_tick () {
            var settings = AppSettings.get_default ();
            if (!typewriter_active || !settings.typewriter_scrolling || !am_active) {
                stop_typewriter_timer ();
                return false;
            }

            int64 last_edit = typewriter_last_edit_time;
            if (last_edit == 0) {
                stop_typewriter_timer ();
                return false;
            }

            int64 now = GLib.get_monotonic_time ();
            int64 elapsed_us = now - last_edit;
            if (elapsed_us > TYPEWRITER_IDLE_TIMEOUT_MS * 1000) {
                stop_typewriter_timer ();
                return false;
            }

            move_typewriter_scolling ();
            return true;
        }

        private void update_settings () {
            var settings = AppSettings.get_default ();
            // Wrap long lines at word boundaries so the full file stays visible without horizontal scrolling
            this.set_wrap_mode (Gtk.WrapMode.WORD_CHAR);
            this.set_pixels_above_lines ((int)(settings.spacing + (settings.line_spacing - 1.0) * settings.font_size));
            this.set_pixels_inside_wrap ((int)(settings.spacing + (settings.line_spacing - 1.0) * settings.font_size));
            this.set_show_line_numbers (settings.show_num_lines);

            double r, g, b;
            UI.get_focus_color (out r, out g, out b);
            focus_text.foreground_rgba = Gdk.RGBA () { red = (float) r, green = (float) g, blue = (float) b, alpha = 1.0f };
            focus_text.foreground_set = true;
            focus_text.underline = Pango.Underline.NONE;
            focus_text.underline_set = true;
            UI.get_focus_bg_color (out r, out g, out b);
            focus_text.background_rgba = Gdk.RGBA () { red = (float) r, green = (float) g, blue = (float) b, alpha = 1.0f };
            focus_text.background_set = true;
            // out of focus settings
            outoffocus_text.background_rgba = Gdk.RGBA () { red = (float) r, green = (float) g, blue = (float) b, alpha = 1.0f };
            outoffocus_text.background_set = true;
            UI.get_out_of_focus_color (out r, out g, out b);
            outoffocus_text.foreground_rgba = Gdk.RGBA () { red = (float) r, green = (float) g, blue = (float) b, alpha = 1.0f };
            outoffocus_text.foreground_set = true;
            outoffocus_text.underline = Pango.Underline.NONE;
            outoffocus_text.underline_set = true;

            typewriter_scrolling ();
            if (!typewriter_active && settings.typewriter_scrolling) {
                debug ("Settings: enabling typewriter scrolling - connecting signal");
                typewriter_active = true;
                buffer.notify["cursor-position"].connect (move_typewriter_scolling_void);
                queue_draw ();
                move_typewriter_scolling ();
            } else if (typewriter_active && !settings.typewriter_scrolling) {
                debug ("Settings: disabling typewriter scrolling - disconnecting signal");
                typewriter_active = false;
                stop_typewriter_timer ();
                buffer.notify["cursor-position"].disconnect (move_typewriter_scolling_void);
                queue_draw ();
            }

            if (settings.focus_mode) {
                buffer.notify["cursor-position"].connect (update_focus);
                update_focus ();
            } else {
                buffer.notify["cursor-position"].disconnect (update_focus);
                remove_focus ();
            }

            var buffer_context = this.get_style_context ();
            if (settings.fullscreen) {
                buffer_context.add_class ("full-text");
                buffer_context.remove_class ("small-text");
            } else {
                buffer_context.add_class ("small-text");
                buffer_context.remove_class ("full-text");
            }

            set_scheme (settings.get_valid_theme_id ());

            spellcheck_enable();

            if (!settings.writegood && writecheck_active) {
                writecheck_active = false;
                writegood.detach ();
            } else if (settings.writegood && !writecheck_active) {
                writecheck_active = true;
                writegood.attach (this);
                write_good_recheck ();
            }

            if (!settings.grammar && grammar_active) {
                grammar_active = false;
                grammar.detach ();
            } else if (settings.grammar && !grammar_active) {
                grammar_active = true;
                grammar.attach (this);
                if (am_active) {
                    GLib.Idle.add (grammar_recheck);
                }
            }

            if (!header_redraw_scheduled) {
                update_heading_margins ();
            }
        }

        private void spellcheck_enable () {
            var settings = AppSettings.get_default ();
            spellcheck = settings.spellcheck;
        }

        private bool grammar_recheck () {
            var settings = AppSettings.get_default ();
            if (settings.grammar) {
                if (editable) {
                    if (grammar != null) {
                        grammar.recheck_all ();
                    }
                }
            }

            return false;
        }

        public void set_scheme (string id, bool reload_css = true) {
            if (id == "thiefmd") {
                // Reset application CSS to coded
                var style_manager = UI.UserSchemes ();
                var style = style_manager.get_scheme (id);
                buffer.set_style_scheme (style);
            } else {
                UI.UserSchemes ().force_rescan ();
                var style = UI.UserSchemes ().get_scheme (id);
                buffer.set_style_scheme (style);
            }

            if (reload_css) {
                UI.load_css_scheme ();
            }
        }

        public void remove_focus () {
            Gtk.TextIter start, end;
            buffer.get_bounds (out start, out end);
            buffer.remove_tag (focus_text, start, end);
            buffer.remove_tag (outoffocus_text, start, end);
        }

        public void update_focus () {
            var settings = AppSettings.get_default ();
            if (settings.focus_mode) {
                Gtk.TextIter start, end;
                buffer.get_bounds (out start, out end);
                buffer.remove_tag (focus_text, start, end);
                buffer.apply_tag (outoffocus_text, start, end);

                var cursor = buffer.get_insert ();
                buffer.get_iter_at_mark (out start, cursor);
                end = start;
                if (settings.focus_type == FocusType.WORD) {
                    if (!start.starts_word ()) {
                        start.backward_word_start ();
                    }
                    if (!end.ends_word ()) {
                        end.forward_word_end ();
                    }
                } else if (settings.focus_type == FocusType.SENTENCE) {
                    if (!start.starts_sentence ()) {
                        do {
                            start.backward_sentence_start ();
                            if (start.get_char () == '[') {
                                start.backward_char ();
                            }
                        } while (!start.starts_line () && markdown != null && (start.has_tag (markdown.markdown_link) || start.has_tag (markdown.markdown_url)));
                    }
                    if (!end.ends_sentence () || (markdown != null && (end.has_tag (markdown.markdown_url) || end.has_tag (markdown.markdown_link)))) {
                        do {
                            end.forward_sentence_end ();
                        } while (markdown != null && (end.has_tag (markdown.markdown_url) || end.has_tag (markdown.markdown_link)));
                    }
                } else if (settings.focus_type == FocusType.PARAGRAPH) {
                    if (!start.starts_line () || (markdown != null && start.has_tag (markdown.code_block))) {
                        do {
                            start.backward_line ();
                        } while (markdown != null && start.has_tag (markdown.code_block));
                    }
                    if (!end.ends_line () || (markdown != null && end.has_tag (markdown.code_block))) {
                        do {
                            end.forward_to_line_end ();
                        } while (markdown != null && end.has_tag (markdown.code_block));
                    }
                }

                while (end.get_offset () > start.get_offset () && end.get_char () != 0 && end.get_char () != ' ' && end.get_char () != '\n' && !end.ends_word () && !end.ends_line ()) {
                    end.backward_char ();
                }

                while (end.get_offset () < get_buffer_text ().length && end.get_char () != 0 && end.get_char () != ' ' && end.get_char () != '\n' && !end.ends_word () && !end.ends_line ()) {
                    end.forward_char ();
                }

                while (start.get_offset () > 0 && start.get_char () != 0 && start.get_char () != ' ' && start.get_char () != '\n' && !start.starts_word () && !start.starts_line ()) {
                    start.backward_char ();
                }

                buffer.remove_tag (outoffocus_text, start, end);
                buffer.apply_tag (focus_text, start, end);
            }
        }

        public void move_typewriter_scolling_void () {
            debug ("move_typewriter_scolling_void: Called from signal");
            if (!should_pause_typewriter_scrolling ()) {
                move_typewriter_scolling ();
            }
        }

        private void pause_typewriter_scrolling_on_click () {
            typewriter_last_click_time = GLib.get_monotonic_time ();
        }

        private bool should_pause_typewriter_scrolling () {
            if (typewriter_last_click_time == 0) {
                return false;
            }
            int64 now = GLib.get_monotonic_time ();
            int64 elapsed_us = now - typewriter_last_click_time;
            return elapsed_us < (TYPEWRITER_CLICK_PAUSE_MS * 1000);
        }

        public bool move_typewriter_scolling () {
            debug ("move_typewriter_scolling: Called! has_selection=%s", buffer.has_selection.to_string ());

            // Don't scroll if completion popup is active
            if (this.get_data<bool> ("completion-active")) {
                debug ("move_typewriter_scolling: Skipping - completion popup is active");
                return false;
            }

            if (selection_dragging) {
                return false;
            }
            
            if (buffer.has_selection && !selection_dragging) {
                return false;
            }

            if (pointer_down && !selection_dragging) {
                return false;
            }

            var settings = AppSettings.get_default ();
            debug ("move_typewriter_scolling: typewriter_scrolling setting = %s", settings.typewriter_scrolling.to_string ());
            
            if (settings.typewriter_scrolling) {
                var cursor = buffer.get_insert ();
                Gtk.TextIter cursor_iter;
                buffer.get_iter_at_mark (out cursor_iter, cursor);
                
                int line = cursor_iter.get_line ();
                debug ("move_typewriter_scolling: Cursor at line %d", line + 1);
                
                // Get cursor position relative to the entire document (not viewport)
                Gdk.Rectangle cursor_loc;
                this.get_iter_location (cursor_iter, out cursor_loc);
                
                // Find parent ScrolledWindow and adjust it
                Gtk.Widget? parent = this.get_parent ();
                while (parent != null) {
                    if (parent is Gtk.ScrolledWindow) {
                        Gtk.ScrolledWindow scrolled = (Gtk.ScrolledWindow) parent;
                        Gtk.Adjustment vadjust = scrolled.get_vadjustment ();
                        if (vadjust != null) {
                            double current_value = vadjust.get_value ();
                            double page_size = vadjust.get_page_size ();
                            double lower = vadjust.get_lower ();
                            double upper = vadjust.get_upper ();
                            
                            debug ("move_typewriter_scolling: cursor_loc.y=%d, page_size=%.0f (viewport height), TYPEWRITER_POSITION=%.2f", 
                                   cursor_loc.y, page_size, Constants.TYPEWRITER_POSITION);
                            debug ("move_typewriter_scolling: current scroll=%.0f, lower=%.0f, upper=%.0f", 
                                   current_value, lower, upper);
                            
                            // cursor_loc.y is absolute position in document
                            // page_size is the visible viewport height
                            // We want cursor to appear at (page_size * TYPEWRITER_POSITION) from top of viewport
                            // So scroll_value should be: cursor_loc.y - (page_size * TYPEWRITER_POSITION)
                            double target_scroll = cursor_loc.y - (page_size * Constants.TYPEWRITER_POSITION);
                            
                            // Clamp to valid range
                            double new_value = target_scroll.clamp(lower, upper - page_size);
                            
                            // Calculate actual position cursor will be at
                            double cursor_viewport_pos = cursor_loc.y - new_value;
                            double cursor_percentage = cursor_viewport_pos / page_size;
                            
                            debug ("move_typewriter_scolling: target_scroll=%.0f, new_value=%.0f (was %.0f)", 
                                   target_scroll, new_value, current_value);
                            debug ("move_typewriter_scolling: Cursor will be at %.0f px from top (%.1f%% of viewport)", 
                                   cursor_viewport_pos, cursor_percentage * 100.0);
                            
                            vadjust.set_value (new_value);
                        }
                        break;
                    }
                    parent = parent.get_parent ();
                }
                
                return true;
            }

            return false;
        }

        public bool ensure_cursor_visible () {
            int view_height = this.get_allocated_height ();
            int view_width = this.get_allocated_width ();
            
            debug ("ensure_cursor_visible: view size w=%d, h=%d", view_width, view_height);

            if (selection_dragging) {
                return false;
            }

            if (pointer_down && !selection_dragging) {
                return false;
            }
            
            // Don't try to scroll if the view isn't actually visible/realized
            if (view_width <= 0 || view_height <= 0) {
                debug ("ensure_cursor_visible: View not realized");
                return false;
            }

            var cursor = buffer.get_insert ();
            Gtk.TextIter cursor_iter;
            buffer.get_iter_at_mark (out cursor_iter, cursor);
            
            int line = cursor_iter.get_line ();
            int col = cursor_iter.get_line_offset ();
            debug ("ensure_cursor_visible: Cursor at line %d, col %d", line + 1, col + 1);
            
            // Get cursor location on screen
            Gdk.Rectangle cursor_loc;
            this.get_iter_location (cursor_iter, out cursor_loc);
            debug ("ensure_cursor_visible: Cursor location y=%d, height=%d", cursor_loc.y, cursor_loc.height);
            
            // Find parent ScrolledWindow and scroll it to keep cursor visible
            Gtk.Widget? parent = this.get_parent ();
            while (parent != null) {
                if (parent is Gtk.ScrolledWindow) {
                    Gtk.ScrolledWindow scrolled = (Gtk.ScrolledWindow) parent;
                    Gtk.Adjustment vadjust = scrolled.get_vadjustment ();
                    if (vadjust != null) {
                        double current_value = vadjust.get_value ();
                        double page_size = vadjust.get_page_size ();
                        double lower = vadjust.get_lower ();
                        double upper = vadjust.get_upper ();
                        
                        // Convert cursor screen position to adjustment value
                        double cursor_top = cursor_loc.y;
                        double cursor_bottom = cursor_loc.y + cursor_loc.height;
                        
                        // Check if cursor is visible in current viewport
                        bool is_visible = (current_value <= cursor_top && cursor_bottom <= current_value + page_size);
                        
                        debug ("ensure_cursor_visible: scroll adj value=%.0f, page=%.0f, cursor_top=%.0f, cursor_bottom=%.0f, visible=%s", 
                               current_value, page_size, cursor_top, cursor_bottom, is_visible.to_string ());
                        
                        if (!is_visible) {
                            // Scroll to show cursor with some margin
                            double margin = 50;
                            double new_value = cursor_top - margin;
                            new_value = new_value.clamp(lower, upper - page_size);
                            
                            debug ("ensure_cursor_visible: Scrolling to %.0f (was %.0f)", new_value, current_value);
                            vadjust.set_value (new_value);
                        }
                    }
                    break;
                }
                parent = parent.get_parent ();
            }
            
            return true;
        }

        private bool drag_autoscroll () {
            if (!selection_dragging) {
                drag_scroll_source = 0;
                return false;
            }

            int view_height = this.get_allocated_height ();
            if (view_height <= 0) {
                return true;
            }

            const int edge_px = 28;
            const double scroll_step = 14.0;

            double direction = 0.0;
            if (drag_pointer_y < edge_px) {
                direction = -scroll_step;
            } else if (drag_pointer_y > view_height - edge_px) {
                direction = scroll_step;
            }

            if (direction == 0.0) {
                return true;
            }

            Gtk.Widget? parent = this.get_parent ();
            while (parent != null) {
                if (parent is Gtk.ScrolledWindow) {
                    Gtk.ScrolledWindow scrolled = (Gtk.ScrolledWindow) parent;
                    Gtk.Adjustment vadjust = scrolled.get_vadjustment ();
                    if (vadjust != null) {
                        double current_value = vadjust.get_value ();
                        double page_size = vadjust.get_page_size ();
                        double lower = vadjust.get_lower ();
                        double upper = vadjust.get_upper ();
                        double new_value = (current_value + direction).clamp (lower, upper - page_size);
                        vadjust.set_value (new_value);
                    }
                    break;
                }
                parent = parent.get_parent ();
            }

            return true;
        }

        /* GTK4 TODO: Context menu needs Gtk4 PopoverMenu/GMenu reimplementation
        private bool please_no_spell_prompt = false;
        private void build_menu () {
            if (file == null) {
                return;
            }

            // Set timer so we don't prompt for file modification?
            disk_change_prompted.can_do_action ();

            var settings = AppSettings.get_default ();
            this.populate_popup.connect ((source, menu) => {
                no_change_prompt = true;
                if (!please_no_spell_prompt) {
                    please_no_spell_prompt = true;
                    Timeout.add (10000, () => {
                        if (no_change_prompt) {
                            no_change_prompt = false;
                        }
                        please_no_spell_prompt = false;
                        return false;
                    });
                }
                Gtk.SeparatorMenuItem sep = new Gtk.SeparatorMenuItem ();
                menu.add (sep);

                Gtk.MenuItem menu_insert_datetime = new Gtk.MenuItem.with_label (_("Insert Datetime"));
                menu_insert_datetime.activate.connect (() => {

                    string parent_path = file.get_parent ().get_path ().down ();
                    bool am_iso8601 = parent_path.contains ("content");

                    DateTime now = new DateTime.now_local ();
                    string new_text = now.format ("%F %T");

                    if (am_iso8601) {
                        new_text = now.format ("%FT%T%z");
                    }

                    // Set timer so we don't prompt for file modification?
                    disk_change_prompted.can_do_action ();
                    insert_at_cursor (new_text);
                });

                Gtk.MenuItem menu_insert_frontmatter = new Gtk.MenuItem.with_label (_("Insert YAML Frontmatter"));
                menu_insert_frontmatter.activate.connect (() => {
                    if (!get_buffer_text ().has_prefix ("---")) {
                        int new_cursor_location = 0;
                        Regex date = null;
                        try {
                            date = new Regex ("([0-9]{4}-[0-9]{1,2}-[0-9]{1,2}-?)?(.*?)$", RegexCompileFlags.MULTILINE | RegexCompileFlags.CASELESS, 0);
                        } catch (Error e) {
                            warning ("Could not compile regex: %s", e.message);
                        }

                        DateTime now = new DateTime.now_local ();
                        string current_time = now.format ("%F %T");

                        string parent_folder = file.get_parent ().get_basename ().down ();
                        string page_type = (parent_folder.contains ("post") || parent_folder.contains ("draft")) ? "post" : "page";
                        string current_title = file.get_basename ();
                        string parent_path = file.get_parent ().get_path ().down ();
                        bool add_draftmatter = parent_path.contains ("content");
                        current_title = current_title.substring (0, current_title.last_index_of ("."));

                        if (add_draftmatter) {
                            current_time = now.format ("%FT%T%z");
                        }

                        // Attempt to convert the file name into a title for the post
                        try {
                            if (date != null) {
                                current_title = date.replace_eval (
                                    current_title,
                                    (ssize_t) current_title.length,
                                    0,
                                    RegexMatchFlags.NOTEMPTY,
                                    (match_info, result) =>
                                    {
                                        result.append (match_info.fetch (match_info.get_match_count () - 1));
                                        return false;
                                    }
                                );
                            }
                        } catch (Error e) {
                            warning ("Could not generate title");
                        }

                        current_title = make_title (current_title);

                        // Build the front matter
                        string frontmatter = "---\n";
                        frontmatter += "layout: " + page_type + "\n";
                        frontmatter += "title: ";
                        new_cursor_location = frontmatter.length;
                        frontmatter += current_title + "\n";
                        // Only insert datetime if we think it's a post
                        if (page_type == "post") {
                            frontmatter += "date: " + current_time + "\n";
                            if (add_draftmatter) {
                                frontmatter += "draft: true\n";
                            }
                        }
                        frontmatter += "---\n";

                        // Set timer so we don't prompt for file modification?
                        disk_change_prompted.can_do_action ();

                        // Place the text
                        buffer.text = frontmatter + get_buffer_text ();

                        // Move the cursor to select the title
                        Gtk.TextIter start, end;
                        buffer.get_bounds (out start, out end);
                        start.forward_chars (new_cursor_location);
                        end = start;
                        end.forward_line ();
                        end.backward_char ();
                        buffer.place_cursor (start);
                        buffer.select_range (start, end);

                        // Move the frontmatter onscreen
                        should_scroll = true;
                        move_typewriter_scolling ();
                    }
                });

                menu.append (menu_insert_datetime);
                menu.append (menu_insert_frontmatter);

                string bib_file = "";
                if (!Pandoc.get_bibtex_path (get_buffer_text (), ref bib_file)){
                    bib_file = find_bibtex_for_sheet (opened_filename);
                } else {
                    bib_file = Pandoc.find_file (bib_file);
                }

                if (bib_file != "") {
                    BibTex.Parser bib_parser = new BibTex.Parser (bib_file);
                    bib_parser.parse_file ();
                    var cite_labels = bib_parser.get_labels ();
                    if (!cite_labels.is_empty) {
                        Gtk.MenuItem insert_citation = new Gtk.MenuItem.with_label (_("Insert Citation"));
                        Gtk.Menu citation_menu = new Gtk.Menu ();
                        foreach (var citation in cite_labels) {
                            Gtk.MenuItem citation_item = new Gtk.MenuItem.with_label (citation);
                            citation_item.set_has_tooltip (true);
                            citation_item.set_tooltip_text (bib_parser.get_title (citation));
                            citation_menu.add (citation_item);
                            citation_item.activate.connect (() => {
                                string insert_citation_string = citation;
                                var cursor = buffer.get_insert ();
                                Gtk.TextIter start;
                                buffer.get_iter_at_mark (out start, cursor);
                                if (start.backward_char ()) {
                                    if (start.get_char () != '@') {
                                        insert_citation_string = "@" + insert_citation_string;
                                    }
                                }
                                insert_at_cursor (insert_citation_string);
                            });
                        }
                        citation_menu.show_all ();
                        insert_citation.submenu = citation_menu;
                        menu.append (insert_citation);
                    }
                }

                menu.show_all ();

                menu.selection_done.connect (() => {
                    var selected = get_selected (menu);

                    if (selected != null) {
                        try {
                            spell.set_language (selected.label);
                            settings.spellcheck_language = selected.label;
                        } catch (Error e) {
                        }
                    }
                });
            });
        }
        */

        public void clean () {
            editable = false;
            
            // Clean up word count thread
            word_count_mutex.lock ();
            if (word_count_thread != null) {
                word_count_thread.join ();
                word_count_thread = null;
            }
            word_count_mutex.unlock ();
            
            if (spell_adapter != null) {
                spell_adapter.set_enabled (false);
            }
            if (fountain != null) {
                fountain.detach ();
                fountain = null;
            }
            if (markdown != null) {
                markdown.detach ();
                markdown = null;
            }
            writegood.detach ();
            grammar.detach ();

            preview_markdown = "";
            buffer.text = "";
            buffer.dispose ();
            file = null;
        }
    }
}
