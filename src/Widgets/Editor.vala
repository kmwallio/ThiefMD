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
using Gspell;
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

        private Gspell.Checker? spell = null;
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
        private bool grammar_active = false;
        private bool no_hiding = false;
        private bool pointer_down = false;
        private bool selection_dragging = false;
        private double drag_start_y = 0.0;
        private double drag_pointer_y = 0.0;
        private uint drag_scroll_source = 0;

        private Gtk.TextTag focus_text;
        private Gtk.TextTag outoffocus_text;

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

            // Initialize spellchecker stub so attach/detach calls are safe
            spell = new Gspell.Checker ();

            // Initialize optional enrichments to avoid null derefs when toggled
            writegood = new WriteGood.Checker ();
            grammar = new GrammarChecker ();

            var click_controller = new Gtk.GestureClick ();
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

        /* GTK4 TODO: Drag-and-drop not yet reimplemented
        private void on_drag_data_received (
            Gtk.Widget widget,
            DragContext context,
            int x,
            int y,
            Gtk.SelectionData selection_data,
            uint target_type,
            uint time)
        {
            int mid =  get_allocated_height () / 2;
            debug ("%s: data (m: %d, %d)", widget.name, mid, y);

            string data = (string) selection_data.get_data();
            string raw_data = data;
            debug ("Got: %s", data);

            if (data != null) {
                data = data.chomp ();
            } else {
                data = "";
            }

            if (data.has_prefix ("file://")) {
                data = data.substring ("file://".length);
            }

            string ext = data.substring (data.last_index_of (".") + 1).down ().chug ().chomp ();
            string insert = "";
            if (ext == "png" || ext == "jpeg" ||
                ext == "jpg" || ext == "gif" ||
                ext == "svg" || ext == "bmp")
            {
                insert = "![](" + get_base_library_path(data) + ")\n";
            } else if (ext == "yml" || ext == "js" || ext == "hpp" || ext == "coffee" || ext == "sh" ||
                        ext == "vala" || ext == "c" || ext == "vapi" || ext == "ts" || ext == "toml" || ext == "ps1" ||
                        ext == "cpp" || ext == "rb" || ext == "css" || ext == "php" || ext == "scss" || ext == "less" ||
                        ext == "pl" || ext == "py" || ext == "sass" || ext == "json" || ext == "nim" || ext == "ps" ||
                        ext == "pm" || ext == "h" || ext == "log" || ext == "rs")
            {
                if (file.query_exists () &&
                    (!FileUtils.test(data, FileTest.IS_DIR)) &&
                    (FileUtils.test(data, FileTest.IS_REGULAR)))
                {
                    string code_data = FileManager.get_file_contents (data);
                    if (code_data.chug ().chomp () != "") {
                        insert = "\n```" + ext + "\n";
                        insert += code_data;
                        insert += "\n```\n";
                    }
                }
            } else if (ext == "pdf" || ext == "docx" || ext == "pptx" || ext == "html" || ext == "odt") {
                insert = "[" + data.substring (data.last_index_of (Path.DIR_SEPARATOR_S) + 1) + "](" + get_base_library_path(data) + ")\n";
            } else if (ext == "csv") {
                if (file.query_exists () &&
                    (!FileUtils.test(data, FileTest.IS_DIR)) &&
                    (FileUtils.test(data, FileTest.IS_REGULAR)))
                {
                    string code_data = FileManager.get_file_contents (data);
                    if (code_data.chug ().chomp () != "") {
                        insert = "\n" + csv_to_md(code_data) + "\n";
                    }
                }
            }

            if (insert != "") {
                Timeout.add (100, () => {
                    int start_of_raw = buffer.cursor_position - raw_data.length;
                    string wowzers = get_buffer_text ().substring (start_of_raw, raw_data.length);
                    if (wowzers == raw_data) {
                        disk_change_prompted.can_do_action ();
                        debug ("Found raw_data");
                        Gtk.TextIter start, end;
                        buffer.get_bounds (out start, out end);
                        start.forward_chars (start_of_raw);
                        end = start;
                        end.forward_chars (raw_data.length);
                        buffer.delete (ref start, ref end);
                        buffer.insert_at_cursor (insert, insert.length);
                    } else {
                        debug ("Found: %s", wowzers);
                    }
                    return false;
                });
            }
            return;
        }
        */

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
                        Timeout.add(Constants.TYPEWRITER_UPDATE_TIME, move_typewriter_scolling);
                        buffer.notify["cursor-position"].connect (move_typewriter_scolling_void);
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

                    if (settings.spellcheck) {
                        spell.attach (this);
                        spellcheck_active = true;
                    }

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

                        if (settings.writegood && writegood != null) {
                            writecheck_active = false;
                            writegood.detach ();
                        }

                        if (settings.grammar && grammar != null) {
                            grammar_active = false;
                            grammar.detach ();
                        }

                        if (settings.spellcheck && spell != null) {
                            spell.detach ();
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
            return buffer.get_text (start, end, true);
        }

        public bool spellcheck {
            set {
                if (value && !spellcheck_active) {
                    debug ("Activate spellcheck\n");
                    try {
                        var settings = AppSettings.get_default ();
                        var last_language = settings.spellcheck_language;
                        bool language_set = false;
                        var language_list = Gspell.Checker.get_language_list ();
                        foreach (var element in language_list) {
                            if (last_language == element) {
                                language_set = true;
                                spell.set_language (last_language);
                                break;
                            }
                        }

                        if (language_list.length () == 0) {
                            spell.set_language (null);
                        } else if (!language_set) {
                            last_language = language_list.data;
                            spell.set_language (last_language);
                        }
                        if (spell != null) {
                            spell.attach (this);
                            spellcheck_active = true;
                        }
                    } catch (Error e) {
                        warning (e.message);
                    }
                } else if (!value && spellcheck_active) {
                    debug ("Disable spellcheck\n");
                    if (spell != null) {
                        spell.detach ();
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
                spell.recheck_all ();
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

            modified_time = new DateTime.now_utc ();
            should_scroll = true;
            
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

        private void setup_enrichments_for_file (string filename, string text) {
            // Detach any previous enrichments before switching file types
            if (fountain != null) {
                fountain.detach ();
                fountain = null;
            }
            if (markdown != null) {
                markdown.detach ();
                markdown = null;
            }

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
                    markdown.recheck_all ();
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
                
                // Set margins to 20% of the visible viewport height
                int margin = (int)(page_size * 0.20);
                bottom_margin = margin;
                top_margin = margin;
                debug ("typewriter_scrolling: Set margins to %d based on page_size %.0f", margin, page_size);
            } else {
                bottom_margin = Constants.BOTTOM_MARGIN;
                top_margin = Constants.TOP_MARGIN;
            }
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
                Timeout.add(Constants.TYPEWRITER_UPDATE_TIME, move_typewriter_scolling);
                buffer.notify["cursor-position"].connect (move_typewriter_scolling_void);
                queue_draw ();
                move_typewriter_scolling ();
            } else if (typewriter_active && !settings.typewriter_scrolling) {
                debug ("Settings: disabling typewriter scrolling - disconnecting signal");
                typewriter_active = false;
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
            move_typewriter_scolling ();
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
            spell.detach ();
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
            spell.dispose ();
            buffer.dispose ();
            file = null;
        }
    }
}
