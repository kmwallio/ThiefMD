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
        private bool spellcheck_active;
        private bool writecheck_active;
        private bool typewriter_active;

        private Gtk.TextTag focus_text;
        private Gtk.TextTag outoffocus_text;

        //
        // Maintaining state
        //

        public bool is_modified { get; set; default = false; }
        private bool should_scroll { get; set; default = false; }
        private bool should_save { get; set; default = false; }

        public Editor (string file_path) {
            var settings = AppSettings.get_default ();
            settings.changed.connect (update_settings);

            file_mutex = Mutex ();
            disk_change_prompted = new TimedMutex (10000);

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
            Timeout.add (250, () => {
                set_scheme (settings.get_valid_theme_id ());
                return false;
            });
            dynamic_margins ();
            spell = new GtkSpell.Checker ();
            writegood = new WriteGood.Checker ();
            writegood.show_tooltip = true;

            if (settings.spellcheck) {
                debug ("Spellcheck active");
                spell.attach (this);
                spellcheck_active = true;
            } else {
                debug ("Spellcheck inactive");
                spellcheck_active = false;
            }

            if (settings.writegood) {
                writegood.attach (this);
                writecheck_active = true;
            } else {
                writegood.detach ();
                writecheck_active = false;
            }

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

            if (!have_match) {
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
            }

            return have_match;
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
            var header_context = this.get_style_context ();

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
                File local = File.new_for_path (data);
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
                File local = File.new_for_path (data);
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
                    string wowzers = buffer.text.substring (start_of_raw, raw_data.length);
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

                    string checksum_on_close = Checksum.compute_for_string (ChecksumType.MD5, buffer.text);
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
                            string checksum_on_close = Checksum.compute_for_string (ChecksumType.MD5, buffer.text);
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

                    preview_markdown = buffer.text;
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
                    }

                    if (settings.autosave) {
                        Timeout.add (Constants.AUTOSAVE_TIMEOUT, autosave);
                    }

                    if (settings.writegood) {
                        writecheck_active = true;
                        writegood.attach (this);
                        write_good_recheck ();
                    }

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
                        if (settings.spellcheck) {
                            spell.detach ();
                        }

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
                        if (settings.writegood) {
                            writecheck_active = false;
                            writegood.detach ();
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
                return buffer.text;
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

        public bool save () throws Error {
            if (opened_filename != "" && file.query_exists () && !FileUtils.test (file.get_path (), FileTest.IS_DIR)) {
                file_mutex.lock ();
                FileManager.save_file (file, buffer.text.data);
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

            int w, h, m, p;
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

            // Update margins
            left_margin = m;
            right_margin = m;

            typewriter_scrolling ();

            // Keep the curson in view?
            should_scroll = true;
            move_typewriter_scolling ();
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
            this.set_pixels_above_lines(settings.spacing);
            this.set_pixels_inside_wrap(settings.spacing);
            this.set_show_line_numbers (settings.show_num_lines);

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

            if (settings.focusmode_enabled) {
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
                        start.backward_sentence_start ();
                    }
                    if (!end.ends_sentence ()) {
                        end.forward_sentence_end ();
                    }
                } else if (settings.focus_type == FocusType.PARAGRAPH) {
                    if (!start.starts_line ()) {
                        start.backward_line ();
                    }
                    if (!end.ends_line ()) {
                        end.forward_to_line_end ();
                    }
                }

                Gtk.TextIter end2 = end;
                while (end.get_offset () > start.get_offset () && end.get_char () != 0 && end.get_char () != ' ' && end.get_char () != '\n' && !end.ends_word () && !end.ends_line ()) {
                    end.backward_char ();
                }

                while (end.get_offset () < buffer.text.length && end.get_char () != 0 && end.get_char () != ' ' && end.get_char () != '\n' && !end.ends_word () && !end.ends_line ()) {
                    end.forward_char ();
                }

                while (start.get_offset () > 0 && start.get_char () != 0 && start.get_char () != ' ' && start.get_char () != '\n' && !start.starts_word () && !start.starts_line ()) {
                    start.backward_char ();
                }

                buffer.remove_tag (outoffocus_text, start, end);
                buffer.apply_tag (focus_text, start, end);
            }
        }

        public bool move_typewriter_scolling () {
            if (!active) {
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

        private void build_menu () {
            if (file == null) {
                return;
            }

            bool no_change_prompt = true;
            // Set timer so we don't prompt for file modification?
            disk_change_prompted.can_do_action ();

            var settings = AppSettings.get_default ();
            this.populate_popup.connect ((source, menu) => {
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
                    if (!buffer.text.has_prefix ("---")) {
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
                        buffer.text = frontmatter + buffer.text;

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
