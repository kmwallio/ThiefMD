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
using Gdk;

namespace ThiefMD.Widgets {
    public class Editor : Gtk.SourceView {

        //
        // Things related to the file of this instance
        //

        private File file;
        public new Gtk.SourceBuffer buffer;
        private string opened_filename;
        public string preview_markdown = "";
        private bool active = true;
        private DateTime modified_time;
        private DateTime file_modified_time;
        private Mutex file_mutex;
        private bool no_change_prompt = false; // Trying to prevent too much file changed prompts?
        private TimedMutex disk_change_prompted;
        private TimedMutex dynamic_margin_update;

        //
        // UI Items
        //

        public GtkSpell.Checker spell = null;
        public WriteGood.Checker writegood = null;
        private TimedMutex writegood_limit;
        public Gtk.TextTag warning_tag;
        public Gtk.TextTag error_tag;
        public Gtk.TextTag highlight_tag;
        private int last_width = 0;
        private int last_height = 0;
        private bool spellcheck_active = false;
        private bool writecheck_active;
        private bool typewriter_active;

        private Gtk.TextTag focus_text;
        private Gtk.TextTag outoffocus_text;
        private Gtk.TextTag[] heading_text;
        private Gtk.TextTag code_block;
        private Gtk.TextTag markdown_link;
        private Gtk.TextTag markdown_url;

        //
        // Regexes
        // 
        private Regex is_list;
        private Regex is_partial_list;
        private Regex numerical_list;
        private Regex is_url;
        private Regex is_markdown_url;
        private Regex is_heading;
        private Regex is_codeblock;

        //
        // Maintaining state
        //

        public bool is_modified { get; set; default = false; }
        private bool should_scroll { get; set; default = false; }
        private bool should_save { get; set; default = false; }
        private bool markup_inserted_around_selection = false;

        public Editor (string file_path) {
            var settings = AppSettings.get_default ();
            settings.changed.connect (update_settings);

            try {
                is_heading = new Regex ("(#+\\s[^\\n\\r]+?)[\\n\\r]", RegexCompileFlags.BSR_ANYCRLF | RegexCompileFlags.NEWLINE_ANYCRLF | RegexCompileFlags.CASELESS, 0);
                is_list = new Regex ("^(\\s*([\\*\\-\\+\\>]|[0-9]+(\\.|\\)))\\s)\\s*(.+)", RegexCompileFlags.CASELESS, 0);
                is_partial_list = new Regex ("^(\\s*([\\*\\-\\+\\>]|[0-9]+\\.))\\s+$", RegexCompileFlags.CASELESS, 0);
                numerical_list = new Regex ("^(\\s*)([0-9]+)((\\.|\\))\\s+)$", RegexCompileFlags.CASELESS, 0);
                is_url = new Regex ("^(http|ftp|ssh|mailto|tor|torrent|vscode|atom|rss|file)?s?(:\\/\\/)?(www\\.)?([a-zA-Z0-9\\.\\-]+)\\.([a-z]+)([^\\s]+)$", RegexCompileFlags.CASELESS, 0);
                is_codeblock = new Regex ("(```[a-zA-Z]*[\\n\\r]((.*?)[\\n\\R])*?```[\\n\\r])", RegexCompileFlags.MULTILINE | RegexCompileFlags.CASELESS, 0);
                is_markdown_url = new Regex ("(?<text_group>\\[(?>[^\\[\\]]+|(?&text_group))+\\])(?:\\((?<url>\\S+?)(?:[ ]\"(?<title>(?:[^\"]|(?<=\\\\)\")*?)\")?\\))", RegexCompileFlags.CASELESS, 0);
            } catch (Error e) {
                warning ("Could not initialize regexes: %s", e.message);
            }

            file_mutex = Mutex ();
            disk_change_prompted = new TimedMutex (10000);
            dynamic_margin_update = new TimedMutex (250);

            if (!open_file (file_path)) {
                set_text (Constants.FIRST_USE.printf (ThiefProperties.THIEF_TIPS[Random.int_range(0, ThiefProperties.THIEF_TIPS.length)]), true);
                editable = false;
            } else {
                modified_time = new DateTime.now_utc ();
            }

            build_menu ();
            update_settings ();
            dynamic_margins ();
        }

        public string get_buffer_text () {
            Gtk.TextIter start, end;
            buffer.get_bounds (out start, out end);
            return buffer.get_text (start, end, true);
        }

        construct {
            var settings = AppSettings.get_default ();

            buffer = new Gtk.SourceBuffer.with_language (UI.get_source_language ());
            buffer.highlight_syntax = true;
            buffer.set_max_undo_levels (Constants.MAX_UNDO_LEVELS);

            warning_tag = new Gtk.TextTag ("warning_bg");
            warning_tag.underline = Pango.Underline.ERROR;
            warning_tag.underline_rgba = Gdk.RGBA () { red = 0.13, green = 0.55, blue = 0.13, alpha = 1.0 };

            error_tag = new Gtk.TextTag ("error_bg");
            error_tag.underline = Pango.Underline.ERROR;

            highlight_tag = new Gtk.TextTag ("search-match");
            highlight_tag.background_rgba = Gdk.RGBA () { red = 1.0, green = 0.8, blue = 0.13, alpha = 1.0 };
            highlight_tag.foreground_rgba = Gdk.RGBA () { red = 0.0, green = 0.0, blue = 0.0, alpha = 1.0 };
            highlight_tag.background_set = true;
            highlight_tag.foreground_set = true;


            buffer.tag_table.add (error_tag);
            buffer.tag_table.add (warning_tag);

            is_modified = false;

            this.set_buffer (buffer);
            this.set_wrap_mode (Gtk.WrapMode.WORD_CHAR);
            this.top_margin = Constants.TOP_MARGIN;
            this.bottom_margin = Constants.BOTTOM_MARGIN;
            this.expand = true;
            this.has_focus = true;
            this.set_tab_width (4);
            this.set_insert_spaces_instead_of_tabs (true);
            this.smart_backspace = true;
            Timeout.add (250, () => {
                set_scheme (settings.get_valid_theme_id ());
                return false;
            });

            spell = new GtkSpell.Checker ();
            writegood = new WriteGood.Checker ();
            writegood.show_tooltip = true;

            focus_text = buffer.create_tag ("focus-text");
            outoffocus_text = buffer.create_tag ("outoffocus-text");

            double r, g, b;
            UI.get_focus_color (out r, out g, out b);
            focus_text.foreground_rgba = Gdk.RGBA () { red = r, green = g, blue = b, alpha = 1.0 };
            focus_text.foreground_set = true;
            UI.get_focus_bg_color (out r, out g, out b);
            focus_text.background_rgba = Gdk.RGBA () { red = r, green = g, blue = b, alpha = 1.0 };
            focus_text.background_set = true;
            // out of focus settings
            outoffocus_text.background_rgba = Gdk.RGBA () { red = r, green = g, blue = b, alpha = 1.0 };
            outoffocus_text.background_set = true;
            UI.get_out_of_focus_color (out r, out g, out b);
            outoffocus_text.foreground_rgba = Gdk.RGBA () { red = r, green = g, blue = b, alpha = 1.0 };
            outoffocus_text.foreground_set = true;

            heading_text = new Gtk.TextTag[6];
            for (int h = 0; h < 6; h++) {
                heading_text[h] = buffer.create_tag ("heading%d-text".printf (h + 1));
            }

            code_block = buffer.create_tag ("code-block");
            //  code_block.accumulative_margin = true;
            //  code_block.left_margin = 5;
            //  code_block.left_margin_set = true;
            //  code_block.right_margin = 5;
            //  code_block.right_margin_set = true;

            markdown_link = buffer.create_tag ("markdown-link");
            markdown_url = buffer.create_tag ("markdown-url");
            markdown_url.invisible = true;
            markdown_url.invisible_set = true;

            last_width = settings.window_width;
            last_height = settings.window_height;
            preview_mutex = new TimedMutex ();
            writegood_limit = new TimedMutex (1500);
            drag_data_received.connect (on_drag_data_received);

            focus_in_event.connect ((in_event) => {
                prompt_on_disk_modifications ();

                return false;
            });
        }

        private bool on_keypress (Gdk.EventKey key) {
            uint keycode = key.hardware_keycode;
            bool skip_request = false;

            if (is_list == null || is_partial_list == null || numerical_list == null) {
                return false;
            }

            // Move outside of selection if we just inserted formatting and get a right -> key from the user
            if (match_keycode (Gdk.Key.Right, keycode) && markup_inserted_around_selection && buffer.has_selection) {
                skip_request = true;
            }

            markup_inserted_around_selection = false;

            if (match_keycode (Gdk.Key.Return, keycode) || match_keycode (Gdk.Key.Tab, keycode) || skip_request) {
                debug ("Got enter or tab key or skip request");
                var cursor = buffer.get_insert ();
                Gtk.TextIter start, end;
                if (!skip_request) {
                    buffer.get_iter_at_mark (out start, cursor);
                    buffer.get_iter_at_mark (out end, cursor);
                } else {
                    buffer.get_selection_bounds (out start, out end);
                }
                unichar end_char = end.get_char ();

                // Tab to next item in link, or outside of current markup
                if ((skip_request || match_keycode (Gdk.Key.Tab, keycode)) && 
                    (end_char == '*' ||
                     end_char == ']' ||
                     end_char == ')' ||
                     end_char == '_' ||
                     end_char == '~'))
                {
                    if (end_char == ']') {
                        while (end_char == ']' || end_char == '(') {
                            end.forward_char ();
                            end_char = end.get_char ();
                        }
                    } else {
                        while (end_char == '~' || end_char == '*' || end_char == '_' || end_char == ')') {
                            end.forward_char ();
                            end_char = end.get_char ();
                        }
                    }
                    buffer.place_cursor (end);
                    return true;

                // List movements
                } else if (!start.starts_line ()) {
                    while (!start.starts_line ()) {
                        start.backward_char ();
                    }
                    string line_text = buffer.get_text (start, end, true);
                    debug ("Checking '%s'", line_text);
                    MatchInfo match_info;
                    try {
                        if (is_list.match_full (line_text, line_text.length, 0, 0, out match_info)) {
                            debug ("Is a list");
                            if (match_info == null) {
                                return false;
                            }

                            string list_item = match_info.fetch (1);
                            if (match_keycode (Gdk.Key.Return, keycode)) {
                                insert_at_cursor ("\n");
                                if (numerical_list.match_full (list_item, list_item.length, 0, 0, out match_info)) {
                                    string spaces = match_info.fetch (1);
                                    string close_char = match_info.fetch (3);
                                    int number = int.parse (match_info.fetch (2)) + 1;
                                    insert_at_cursor (spaces);
                                    insert_at_cursor (number.to_string ());
                                    insert_at_cursor (close_char);
                                } else {
                                    insert_at_cursor (list_item);
                                }
                            } else {
                                if ((key.state & Gdk.ModifierType.SHIFT_MASK) == 0) {
                                    int diff = end.get_offset () - start.get_offset ();
                                    buffer.place_cursor (start);
                                    insert_at_cursor ("    ");
                                    buffer.get_iter_at_mark (out start, cursor);
                                    start.forward_chars (diff);
                                    buffer.place_cursor (start);
                                } else {
                                    return false;
                                }
                            }
                            return true;
                        } else if (is_partial_list.match_full (line_text, line_text.length, 0, 0, out match_info)) {
                            if (match_keycode (Gdk.Key.Return, keycode)) {
                                Gtk.TextIter doc_start, doc_end;
                                buffer.get_bounds (out doc_start, out doc_end);
                                while (!end.starts_line () && end.in_range(doc_start, doc_end)) {
                                    end.forward_char ();
                                }
                                buffer.@delete (ref start, ref end);
                            } else {
                                if ((key.state & Gdk.ModifierType.SHIFT_MASK) == 0) {
                                    int diff = end.get_offset () - start.get_offset ();
                                    buffer.place_cursor (start);
                                    insert_at_cursor ("    ");
                                    buffer.get_iter_at_mark (out start, cursor);
                                    start.forward_chars (diff);
                                    buffer.place_cursor (start);
                                    return true;
                                } else {
                                    return false;
                                }
                            }
                        }
                    } catch (Error e) {
                        warning ("Error parsing key presses: %s", e.message);
                    }
                }
            }

            return false;
        }

        public bool prompt_on_disk_modifications () {
            if (!editable) {
                return false;
            }

            if (!disk_change_prompted.can_do_action ()) {
                return false;
            }

            string disk_text;
            DateTime disk_time;
            bool have_match = disk_matches_buffer (out disk_text, out disk_time);

            debug ("Mod: %s, LFT: %s, CFT: %s", modified_time.to_string (), file_modified_time.to_string (), disk_time.to_string ());

            // File is different, disable save?
            if (have_match) {
                return false;
            }
            should_save = false;

            // Load newer contents from disk?
            if (modified_time.compare (disk_time) < 0) {
                set_text (disk_text);
                have_match = true;
            }

            if (file_modified_time.compare (disk_time) == 0 || modified_time.compare (disk_time) == 0) {
                have_match = true;
            }

            // Trying to account for right-click menu changes?
            if ((modified_time.to_unix () - file_modified_time.to_unix ()).abs () < 10) {
                return false;
            }

            if (!have_match && !no_change_prompt) {
                var dialog = new Gtk.Dialog.with_buttons (
                    "Contents changed on disk",
                    ThiefApp.get_instance (),
                    Gtk.DialogFlags.MODAL,
                    _("_Load from disk"),
                    Gtk.ResponseType.ACCEPT,
                    _("_Keep what's in editor"),
                    Gtk.ResponseType.REJECT,
                    null);

                dialog.response.connect ((response_val) => {
                    if (response_val == Gtk.ResponseType.ACCEPT) {
                        set_text (disk_text);
                    } else {
                        should_save = true;
                        autosave ();
                    }
                    dialog.destroy ();
                });

                if (dialog.run () == Gtk.ResponseType.ACCEPT) {
                    set_text (disk_text);
                } else {
                    should_save = true;
                    autosave ();
                }
            } else {
                no_change_prompt = false;
            }

            return have_match;
        }

        private bool no_hiding = false;
        public override bool motion_notify_event (EventMotion event ) {
            if (((event.state & Gdk.ModifierType.BUTTON1_MASK) != 0) ||
                ((event.state & Gdk.ModifierType.BUTTON2_MASK) != 0) ||
                ((event.state & Gdk.ModifierType.BUTTON3_MASK) != 0) || 
                ((event.state & Gdk.ModifierType.BUTTON4_MASK) != 0) || 
                ((event.state & Gdk.ModifierType.BUTTON5_MASK) != 0))
            {
                no_hiding = true;
            } else if (no_hiding) {
                update_heading_margins (true);
                Timeout.add (300, () => {
                    no_hiding = false;
                    update_heading_margins ();
                    return false;
                });
            }

            base.motion_notify_event (event);
            return false;
        }

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
                        ext == "vala" || ext == "c" || ext == "vapi" || ext == "ts" || ext == "toml" ||
                        ext == "cpp" || ext == "rb" || ext == "css" || ext == "php" || ext == "scss" || ext == "less" ||
                        ext == "pl" || ext == "py" || ext == "sass" || ext == "json" ||
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
            } else if (ext == "pdf" || ext == "docx" || ext == "pptx" || ext == "html") {
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

        public signal void changed ();

        public void on_change_notification () {
            is_modified = true;
            on_text_modified ();
        }

        public bool disk_matches_buffer (out string disk_text, out DateTime disk_time) {
            bool match = false;
            
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
            set {
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
                        Timeout.add(Constants.TYPEWRITER_UPDATE_TIME, move_typewriter_scolling);
                        buffer.notify["cursor-position"].connect (move_typewriter_scolling_void);
                    }

                    if (settings.autosave) {
                        Timeout.add (Constants.AUTOSAVE_TIMEOUT, autosave);
                        buffer.notify["cursor-position"].disconnect (move_typewriter_scolling_void);
                    }

                    if (settings.writegood) {
                        writecheck_active = true;
                        writegood.attach (this);
                        write_good_recheck ();
                    }

                    if (settings.spellcheck) {
                        spell.attach (this);
                        spellcheck_active = true;
                    }

                    key_press_event.connect (on_keypress);

                    //
                    // Register for redrawing of window for handling margins and other
                    // redrawing
                    //
                    size_allocate.connect (dynamic_margins);
                    left_margin = 0;
                    right_margin = 0;
                    show_all ();
                    move_margins ();
                    should_scroll = true;
                    update_preview ();
                    spellcheck_enable();
                    show_all ();
                } else {
                    if (active != value) {
                        cursor_location = buffer.cursor_position;
                        debug ("Cursor saved at: %d", cursor_location);

                        preview_markdown = "";
                        try {
                            save ();
                        } catch (Error e) {
                            warning ("Unable to save file " + file.get_basename () + ": " + e.message);
                            SheetManager.show_error ("Unable to save file " + file.get_basename () + ": " + e.message);
                        }

                        buffer.changed.disconnect (on_change_notification);
                        size_allocate.disconnect (dynamic_margins);
                        settings.changed.disconnect (update_settings);
                        key_press_event.disconnect (on_keypress);

                        if (settings.writegood) {
                            writecheck_active = false;
                            writegood.detach ();
                        }

                        if (settings.spellcheck) {
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

        public bool spellcheck {
            set {
                if (value && !spellcheck_active) {
                    debug ("Activate spellcheck\n");
                    try {
                        var settings = AppSettings.get_default ();
                        var last_language = settings.spellcheck_language;
                        bool language_set = false;
                        var language_list = GtkSpell.Checker.get_language_list ();
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
                            last_language = language_list.first ().data;
                            spell.set_language (last_language);
                        }
                        spell.attach (this);
                        spellcheck_active = true;
                    } catch (Error e) {
                        warning (e.message);
                    }
                } else if (!value && spellcheck_active) {
                    debug ("Disable spellcheck\n");
                    spell.detach ();
                    spellcheck_active = false;
                }
            }
        }

        private void insert_markup_around_cursor (string markup) {
            if (!buffer.get_has_selection ()) {
                Gtk.TextIter iter;
                insert_at_cursor (markup + markup);
                buffer.get_iter_at_offset (out iter, buffer.cursor_position - markup.length);
                if (buffer.cursor_position - markup.length > 0) {
                    buffer.place_cursor (iter);
                }
            } else {
                Gtk.TextIter iter_start, iter_end;
                if (buffer.get_selection_bounds (out iter_start, out iter_end)) {
                    buffer.insert (ref iter_start, markup, -1);
                    if (buffer.get_selection_bounds (out iter_start, out iter_end)) {
                        buffer.insert (ref iter_end, markup, -1);
                        buffer.get_selection_bounds (out iter_start, out iter_end);
                        iter_end.backward_chars (markup.length);
                        buffer.select_range (iter_start, iter_end);
                        markup_inserted_around_selection = true;
                    }
                }
            }
        }

        public void bold () {
            insert_markup_around_cursor ("**");
        }

        public void italic () {
            insert_markup_around_cursor ("*");
        }

        public void strikethrough () {
            insert_markup_around_cursor ("~~");
        }

        public void link () {
            if (buffer.has_selection) {
                Gtk.TextIter iter_start, iter_end;
                if (buffer.get_selection_bounds (out iter_start, out iter_end)) {
                    string selected_text = buffer.get_text (iter_start, iter_end, true);
                    MatchInfo match_info;
                    try {
                        if (!is_url.match_full (selected_text, selected_text.length, 0, 0, out match_info)) {
                            buffer.insert (ref iter_start, "[", -1);
                            if (buffer.get_selection_bounds (out iter_start, out iter_end)) {
                                buffer.insert (ref iter_end, "]()", -1);
                                buffer.get_selection_bounds (out iter_start, out iter_end);
                                iter_end.backward_chars (1);
                                buffer.place_cursor (iter_end);
                            }
                        } else {
                            buffer.insert (ref iter_start, "[](", -1);
                            if (buffer.get_selection_bounds (out iter_start, out iter_end)) {
                                buffer.insert (ref iter_end, ")", -1);
                                buffer.get_selection_bounds (out iter_start, out iter_end);
                                iter_start.backward_chars (2);
                                buffer.place_cursor (iter_start);
                            }
                        }
                    } catch (Error e) {
                        warning ("Could not determine URL status, hit exception: %s", e.message);
                    }
                }
            } else {
                insert_at_cursor ("[]()");
                var cursor = buffer.get_insert ();
                Gtk.TextIter start;
                buffer.get_iter_at_mark (out start, cursor);
                start.backward_chars (3);
                buffer.place_cursor (start);
            }
        }

        public bool save () throws Error {
            if (opened_filename != "" && file.query_exists () && !FileUtils.test (file.get_path (), FileTest.IS_DIR)) {
                file_mutex.lock ();
                FileManager.save_file (file, get_buffer_text ().data);
                modified_time = new DateTime.now_utc ();
                file_mutex.unlock ();
                return true;
            }
            return false;
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
                try {
                    save ();
                    SheetManager.redraw ();
                } catch (Error e) {
                    warning ("Unable to save file " + file.get_basename () + ": " + e.message);
                    SheetManager.show_error ("Unable to save file " + file.get_basename () + ": " + e.message);
                }
                should_save = false;
            }

            // Jamming this here for now to prevent
            // reinit of spellcheck on resize
            int w, h;
            ThiefApp.get_instance ().get_size (out w, out h);
            settings.window_width = w;
            settings.window_height = h;

            if (spellcheck_active) {
                spell.recheck_all ();
            }

            return settings.autosave;
        }

        private bool writecheck_scheduled = false;
        private void write_good_recheck () {
            if (writegood_limit.can_do_action () && writecheck_active) {
                writegood.recheck_all ();
            } else if (writecheck_active) {
                if (!writecheck_scheduled) {
                    writecheck_scheduled = true;
                    Timeout.add (1500, () => {
                        if (writecheck_active) {
                            writegood.recheck_all ();
                        }
                        writecheck_scheduled = false;
                        return false;
                    });
                }
            }
        }

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

        public void on_text_modified () {
            SheetManager.last_modified (this);
            if (file != null && opened_filename != "" && file.query_exists ()) {
                editable = true;
            }

            idle_margins ();

            modified_time = new DateTime.now_utc ();
            should_scroll = true;

            // Mark as we should save the file
            // If no autosave, schedule a save.
            if (!should_save) {
                var settings = AppSettings.get_default ();
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

                    string filename = file.get_path ();
                    GLib.FileUtils.get_contents (filename, out text);
                    set_text (text, true);
                    editable = true;
                    debug ("%s opened", file_name);
                    res = true;
                } catch (Error e) {
                    warning ("Error: %s", e.message);
                    SheetManager.show_error ("Unexpected Error: " + e.message);
                }
                file_mutex.unlock ();
            }

            return res;
        }

        public void set_text (string text, bool opening = true) {
            if (opening) {
                buffer.set_max_undo_levels (0);
                buffer.begin_not_undoable_action ();
                buffer.changed.disconnect (on_text_modified);
            }

            buffer.text = text;

            if (opening) {
                buffer.set_max_undo_levels (Constants.MAX_UNDO_LEVELS);
                buffer.end_not_undoable_action ();
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

        public void dynamic_margins () {
            if (!ThiefApp.get_instance ().ready) {
                return;
            }

            int w, h;
            ThiefApp.get_instance ().get_size (out w, out h);

            w = w - ThiefApp.get_instance ().pane_position;
            last_height = h;

            if (w == last_width) {
                return;
            }

            move_margins ();
            idle_margins ();
        }

        public void move_margins () {
            var settings = AppSettings.get_default ();

            if (!ThiefApp.get_instance ().ready) {
                return;
            }

            int w, h, m, p;
            ThiefApp.get_instance ().get_size (out w, out h);

            w = w - ThiefApp.get_instance ().pane_position;
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

            update_heading_margins (UI.moving ());

            typewriter_scrolling ();

            // Keep the curson in view?
            should_scroll = true;
            move_typewriter_scolling ();
        }

        private bool cursor_at_interesting_location = false;
        private void cursor_update_heading_margins () {
            var settings = AppSettings.get_default ();

            if (settings.experimental) {
                var cursor = buffer.get_insert ();
                Gtk.TextIter cursor_location;
                buffer.get_iter_at_mark (out cursor_location, cursor);
                if (cursor_location.has_tag (markdown_link) || cursor_location.has_tag (markdown_url) || buffer.has_selection) {
                    update_heading_margins ();
                    cursor_at_interesting_location = true;
                } else if (cursor_at_interesting_location) {
                    update_heading_margins ();
                    Gtk.TextIter before, after;
                    Gtk.TextIter bound_start, bound_end;
                    buffer.get_bounds (out bound_start, out bound_end);
                    buffer.get_iter_at_mark (out before, cursor);
                    buffer.get_iter_at_mark (out after, cursor);
                    if (!before.backward_line()) {
                        before = bound_start;
                    }
                    if (!after.forward_line ()) {
                        after = bound_end;
                    }
                    string sample_text = buffer.get_text (before, after, true);
                    // Keep interesting location if we're potentially in something we can remove a link to.
                    if (!is_markdown_url.match (sample_text, RegexMatchFlags.BSR_ANYCRLF | RegexMatchFlags.NEWLINE_ANYCRLF)) {
                        cursor_at_interesting_location = false;
                    }
                }
            }
        }

        bool header_redraw_scheduled = false;
        private void update_heading_margins (bool skip_links = false) {
            bool try_later = false;
            // Update heading margins
            if (UI.moving ()) {
                try_later = true;
            } else if (!dynamic_margin_update.can_do_action ()) {
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

            var settings = AppSettings.get_default ();

            if (settings.focus_mode) {
                code_block.background_set = false;
                code_block.paragraph_background_set = false;
                code_block.background_full_height_set = false;
            } else {
                double r, g, b;
                UI.get_codeblock_bg_color (out r, out g, out b);
                code_block.background_rgba = Gdk.RGBA () { red = r, green = g, blue = b, alpha = 1.0 };
                code_block.background_set = true;
                code_block.paragraph_background_rgba = Gdk.RGBA () { red = r, green = g, blue = b, alpha = 1.0 };
                code_block.paragraph_background_set = true;
                code_block.background_full_height = true;
                code_block.background_full_height_set = true;
            }

            if (settings.experimental) {
                if (no_hiding) {
                    markdown_link.weight = Pango.Weight.NORMAL;
                    markdown_link.weight_set = true;
                    markdown_url.weight = Pango.Weight.NORMAL;
                    markdown_url.weight_set = true;
                } else {
                    markdown_link.weight_set = false;
                    markdown_url.weight_set = false;
                }
            }

            int m = left_margin;
            try {
                Gtk.TextIter start, end;
                buffer.get_bounds (out start, out end);
                for (int h = 0; h < 6; h++) {
                    buffer.remove_tag (heading_text[h], start, end);
                }
                buffer.remove_tag (code_block, start, end);
                if (!skip_links) {
                    buffer.remove_tag (markdown_link, start, end);
                    buffer.remove_tag (markdown_url, start, end);
                }

                int f_w = (int)(settings.get_css_font_size () * ((settings.fullscreen ? 1.4 : 1)));
                int hashtag_w = f_w;
                int space_w = f_w;
                int avg_w = f_w;

                if (get_realized ()) {
                    var font_desc = Pango.FontDescription.from_string (settings.font_family);
                    font_desc.set_size ((int)(f_w * Pango.SCALE * Pango.Scale.LARGE));
                    var font_context = get_pango_context ();
                    var font_layout = new Pango.Layout (font_context);
                    font_layout.set_font_description (font_desc);
                    font_layout.set_text ("#", 1);
                    Pango.Rectangle ink, logical;
                    font_layout.get_pixel_extents (out ink, out logical);
                    debug ("# Ink: %d, Logical: %d", ink.width, logical.width);
                    hashtag_w = int.max (ink.width, logical.width);
                    font_layout.set_text (" ", 1);
                    font_layout.get_pixel_extents (out ink, out logical);
                    debug ("  Ink: %d, Logical: %d", ink.width, logical.width);
                    space_w = int.max (ink.width, logical.width);
                    if (space_w + hashtag_w <= 0) {
                        hashtag_w = f_w;
                        space_w = f_w;
                    }
                    if (space_w < (hashtag_w / 2)) {
                        avg_w = (int)((hashtag_w + hashtag_w + space_w) / 3.0);
                    } else {
                        avg_w = (int)((hashtag_w + space_w) / 2.0);
                    }
                    debug ("%s Hashtag: %d, Space: %d, AvgChar: %d", font_desc.get_family (), hashtag_w, space_w, avg_w);
                    if (m - ((hashtag_w * 6) + space_w) <= 0) {
                        heading_text[0].left_margin = m;
                        heading_text[1].left_margin = m;
                        heading_text[2].left_margin = m;
                        heading_text[3].left_margin = m;
                        heading_text[4].left_margin = m;
                        heading_text[5].left_margin = m;
                    } else {
                        heading_text[0].left_margin = m - ((hashtag_w * 1) + space_w);
                        heading_text[1].left_margin = m - ((hashtag_w * 2) + space_w);
                        heading_text[2].left_margin = m - ((hashtag_w * 3) + space_w);
                        heading_text[3].left_margin = m - ((hashtag_w * 4) + space_w);
                        heading_text[4].left_margin = m - ((hashtag_w * 5) + space_w);
                        heading_text[5].left_margin = m - ((hashtag_w * 6) + space_w);
                        //  heading_text[0].left_margin = m - (avg_w * 2);
                        //  heading_text[1].left_margin = m - (avg_w * 3);
                        //  heading_text[2].left_margin = m - (avg_w * 4);
                        //  heading_text[3].left_margin = m - (avg_w * 5);
                        //  heading_text[4].left_margin = m - (avg_w * 6);
                        //  heading_text[5].left_margin = m - (avg_w * 7);
                    }
                }

                MatchInfo match_info;
                string checking_copy = get_buffer_text ();
                // Tag code blocks as such (regex hits issues on large text)
                int block_occurrences = checking_copy.down ().split ("\n```").length - 1;
                if (block_occurrences % 2 == 0) {
                    int offset = checking_copy.index_of ("\n```");
                    while (offset > 0) {
                        offset = offset + 1;
                        int next_offset = checking_copy.index_of ("\n```", offset + 1);
                        if (next_offset > 0) {
                            int start_pos, end_pos;
                            start_pos = checking_copy.char_count ((ssize_t) offset);
                            end_pos = checking_copy.char_count ((ssize_t)(next_offset + 4));
                            buffer.get_iter_at_offset (out start, start_pos);
                            buffer.get_iter_at_offset (out end, end_pos);
                            buffer.apply_tag (code_block, start, end);
                            offset = checking_copy.index_of ("\n```", next_offset + 1);
                        } else {
                            break;
                        }
                    }
                }

                // Tag headings and make sure they're not in code blocks
                if (is_heading.match_full (checking_copy, checking_copy.length, 0, RegexMatchFlags.BSR_ANYCRLF | RegexMatchFlags.NEWLINE_ANYCRLF, out match_info)) {
                    do {
                        int start_pos, end_pos;
                        string heading = match_info.fetch (1);
                        bool headify = match_info.fetch_pos (1, out start_pos, out end_pos) && (heading.index_of ("\n") < 0);
                        if (headify) {
                            start_pos = checking_copy.char_count ((ssize_t) start_pos);
                            end_pos = checking_copy.char_count ((ssize_t) end_pos);
                            buffer.get_iter_at_offset (out start, start_pos);
                            buffer.get_iter_at_offset (out end, end_pos);
                            if (start.has_tag (code_block) || end.has_tag (code_block)) {
                                continue;
                            }
                            int heading_depth = heading.index_of (" ") - 1;
                            if (heading_depth >= 0 && heading_depth < 6) {
                                buffer.apply_tag (heading_text[heading_depth], start, end);
                            }
                        }
                    } while (match_info.next ());
                }

                if (settings.experimental) {
                    //
                    // Skip high CPU stuff when skippable
                    //
                    if (skip_links) {
                        return;
                    }
                    Gtk.TextIter bound_start, bound_end;
                    buffer.get_bounds (out bound_start, out bound_end);
                    bool check_selection = buffer.get_has_selection ();
                    Gtk.TextIter? select_start = null, select_end = null;
                    if (check_selection) {
                        buffer.get_selection_bounds (out select_start, out select_end);
                    }
                    if (is_markdown_url.match_full (checking_copy, checking_copy.length, 0, RegexMatchFlags.BSR_ANYCRLF | RegexMatchFlags.NEWLINE_ANYCRLF, out match_info)) {
                        Gtk.TextIter cursor_location;
                        var cursor = buffer.get_insert ();
                        buffer.get_iter_at_mark (out cursor_location, cursor);
                        do {
                            buffer.get_bounds (out bound_start, out bound_end);
                            int start_link_pos, end_link_pos;
                            int start_url_pos, end_url_pos;
                            int start_full_pos, end_full_pos;
                            //  warning ("Link Found, Text: %s, URL: %s", match_info.fetch (1), match_info.fetch (2));
                            bool linkify = match_info.fetch_pos (1, out start_link_pos, out end_link_pos);
                            bool urlify = match_info.fetch_pos (2, out start_url_pos, out end_url_pos);
                            bool full_found = match_info.fetch_pos (0, out start_full_pos, out end_full_pos);
                            if (linkify && urlify && full_found) {
                                start_full_pos = checking_copy.char_count ((ssize_t)start_full_pos);
                                end_full_pos = checking_copy.char_count ((ssize_t)end_full_pos);
                                //
                                // Don't hide active link's where the cursor is present
                                //
                                buffer.get_iter_at_offset (out start, start_full_pos);
                                buffer.get_iter_at_offset (out end, end_full_pos);

                                if (cursor_location.in_range (start, end)) {
                                    buffer.apply_tag (markdown_link, start, end);
                                    continue;
                                }

                                if (check_selection) {
                                    if (start.in_range (select_start, select_end) || end.in_range (select_start, select_end)) {
                                        buffer.apply_tag (markdown_link, start, end);
                                        continue;
                                    }
                                }

                                // Check if we're in inline code
                                if (start.backward_line ()) {
                                    buffer.get_iter_at_offset (out end, start_full_pos);
                                    if (start.in_range (bound_start, bound_end) && end.in_range (bound_start, bound_end)) {
                                        string sanity_check = buffer.get_text (start, end, true);
                                        if (sanity_check.index_of_char ('`') >= 0) {
                                            buffer.get_iter_at_offset (out end, end_full_pos);
                                            if (end.forward_line ()) {
                                                buffer.get_iter_at_offset (out start, end_full_pos);
                                                sanity_check = buffer.get_text (start, end, true);
                                                if (sanity_check.index_of_char ('`') >= 0) {
                                                    continue;
                                                }
                                            }
                                        }
                                    } else {
                                        // Bail, our calculations are now out of range
                                        continue;
                                    }
                                }

                                //
                                // Link Text [Text]
                                //
                                start_link_pos = checking_copy.char_count ((ssize_t) start_link_pos);
                                end_link_pos = checking_copy.char_count ((ssize_t) end_link_pos);
                                buffer.get_iter_at_offset (out start, start_link_pos);
                                buffer.get_iter_at_offset (out end, end_link_pos);
                                if (start.has_tag (code_block) || end.has_tag (code_block)) {
                                    continue;
                                }
                                if (start.in_range (bound_start, bound_end) && end.in_range (bound_start, bound_end)) {
                                    buffer.apply_tag (markdown_link, start, end);
                                } else  {
                                    // Bail, our calculations are now out of range
                                    continue;
                                }

                                if (!UI.show_link_brackets () && !settings.focus_mode) {
                                    //
                                    // Starting [
                                    //
                                    buffer.get_iter_at_offset (out start, start_link_pos);
                                    buffer.get_iter_at_offset (out end, start_link_pos);
                                    bool not_at_start = start.backward_chars (1);
                                    end.forward_char ();
                                    if (start.in_range (bound_start, bound_end) && end.in_range (bound_start, bound_end)) {
                                        if (start.get_char () != '!') {
                                            if (not_at_start) {
                                                start.forward_char ();
                                            }
                                            buffer.apply_tag (markdown_url, start, end);
                                            //
                                            // Closing ]
                                            //
                                            buffer.get_iter_at_offset (out start, end_link_pos);
                                            buffer.get_iter_at_offset (out end, end_link_pos);
                                            start.backward_char ();
                                            buffer.apply_tag (markdown_url, start, end);
                                        }
                                    } else {
                                        // Bail, our calculations are now out of range
                                        continue;
                                    }
                                }

                                //
                                // Link URL (https://thiefmd.com)
                                //
                                start_url_pos = checking_copy.char_count ((ssize_t) start_url_pos);
                                buffer.get_iter_at_offset (out start, start_url_pos);
                                start.backward_char ();
                                buffer.get_iter_at_offset (out end, end_full_pos);
                                if (start.has_tag (code_block) || end.has_tag (code_block)) {
                                    continue;
                                }
                                if (start.in_range (bound_start, bound_end) && end.in_range (bound_start, bound_end)) {
                                    buffer.apply_tag (markdown_url, start, end);
                                } else  {
                                    // Bail, our calculations are now out of range
                                    continue;
                                }
                            }
                        } while (match_info.next ());
                    }
                }
            } catch (Error e) {
                warning ("Could not adjust headers: %s", e.message);
            }
        }

        private void typewriter_scrolling () {
            var settings = AppSettings.get_default ();

            // Check for typewriter scrolling and adjust bottom margin to
            // compensate
            if (settings.typewriter_scrolling) {
                bottom_margin = (int)(last_height * (1 - Constants.TYPEWRITER_POSITION)) - 20;
                top_margin = (int)(last_height * Constants.TYPEWRITER_POSITION) - 20;
            } else {
                bottom_margin = Constants.BOTTOM_MARGIN;
                top_margin = Constants.TOP_MARGIN;
            }
        }

        private void update_settings () {
            var settings = AppSettings.get_default ();
            this.set_pixels_above_lines ((int)(settings.spacing + (settings.line_spacing - 1.0) * settings.font_size));
            this.set_pixels_inside_wrap ((int)(settings.spacing + (settings.line_spacing - 1.0) * settings.font_size));
            this.set_show_line_numbers (settings.show_num_lines);

            double r, g, b;
            UI.get_focus_color (out r, out g, out b);
            focus_text.foreground_rgba = Gdk.RGBA () { red = r, green = g, blue = b, alpha = 1.0 };
            focus_text.foreground_set = true;
            focus_text.underline = Pango.Underline.NONE;
            focus_text.underline_set = true;
            UI.get_focus_bg_color (out r, out g, out b);
            focus_text.background_rgba = Gdk.RGBA () { red = r, green = g, blue = b, alpha = 1.0 };
            focus_text.background_set = true;
            // out of focus settings
            outoffocus_text.background_rgba = Gdk.RGBA () { red = r, green = g, blue = b, alpha = 1.0 };
            outoffocus_text.background_set = true;
            UI.get_out_of_focus_color (out r, out g, out b);
            outoffocus_text.foreground_rgba = Gdk.RGBA () { red = r, green = g, blue = b, alpha = 1.0 };
            outoffocus_text.foreground_set = true;
            outoffocus_text.underline = Pango.Underline.NONE;
            outoffocus_text.underline_set = true;

            if (!settings.focus_mode) {
                UI.get_codeblock_bg_color (out r, out g, out b);
                code_block.background_rgba = Gdk.RGBA () { red = r, green = g, blue = b, alpha = 1.0 };
                code_block.background_set = true;
                code_block.paragraph_background_rgba = Gdk.RGBA () { red = r, green = g, blue = b, alpha = 1.0 };
                code_block.paragraph_background_set = true;
                code_block.background_full_height = true;
                code_block.background_full_height_set = true;
            } else {
                code_block.background_set = false;
                code_block.paragraph_background_set = false;
                code_block.background_full_height = false;
                code_block.background_full_height_set = false;
            }

            typewriter_scrolling ();
            if (!typewriter_active && settings.typewriter_scrolling) {
                typewriter_active = true;
                Timeout.add(Constants.TYPEWRITER_UPDATE_TIME, move_typewriter_scolling);
                queue_draw ();
                should_scroll = true;
                move_typewriter_scolling ();
            } else if (typewriter_active && !settings.typewriter_scrolling) {
                typewriter_active = false;
                queue_draw ();
                should_scroll = true;
                move_typewriter_scolling ();
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

            if (settings.experimental) {
                buffer.notify["cursor-position"].connect (cursor_update_heading_margins);
            } else {
                buffer.notify["cursor-position"].connect (cursor_update_heading_margins);
            }

            if (!header_redraw_scheduled) {
                update_heading_margins ();
            }
        }

        private void spellcheck_enable () {
            var settings = AppSettings.get_default ();
            spellcheck = settings.spellcheck;
        }

        public void set_scheme (string id) {
            if (id == "thiefmd") {
                // Reset application CSS to coded
                var style_manager = Gtk.SourceStyleSchemeManager.get_default ();
                var style = style_manager.get_scheme (id);
                buffer.set_style_scheme (style);
            } else {
                UI.UserSchemes ().force_rescan ();
                var style = UI.UserSchemes ().get_scheme (id);
                buffer.set_style_scheme (style);
            }

            UI.load_css_scheme ();
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
                        } while (!start.starts_line () && (start.has_tag (markdown_link) || start.has_tag (markdown_url)));
                    }
                    if (!end.ends_sentence () || end.has_tag (markdown_url) || end.has_tag (markdown_link)) {
                        do {
                            end.forward_sentence_end ();
                        } while (end.has_tag (markdown_link) || end.has_tag (markdown_url));
                    }
                } else if (settings.focus_type == FocusType.PARAGRAPH) {
                    if (!start.starts_line () || start.has_tag (code_block)) {
                        do {
                            start.backward_line ();
                        } while (start.has_tag (code_block));
                    }
                    if (!end.ends_line () || end.has_tag (code_block)) {
                        do {
                            end.forward_to_line_end ();
                        } while (end.has_tag (code_block));
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
            move_typewriter_scolling ();
        }

        public bool move_typewriter_scolling () {
            if (!active || buffer.has_selection) {
                return false;
            }

            var settings = AppSettings.get_default ();
            var cursor = buffer.get_insert ();

            if (should_scroll && !UI.moving ()) {
                this.scroll_to_mark(cursor, 0.0, true, 0.0, Constants.TYPEWRITER_POSITION);
                should_scroll = false;
            }

            return settings.typewriter_scrolling;
        }

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

        public void clean () {
            preview_markdown = "";
            buffer.text = "";
            editable = false;
            spell.detach ();
            spell.dispose ();
            buffer.dispose ();
            file = null;
        }
    }
}
