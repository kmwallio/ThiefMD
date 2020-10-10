/*
 * Copyright (C) 2020 kmwallio
 * 
 * Modified August 29, 2020
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

using ThiefMD;
using ThiefMD.Widgets;

namespace ThiefMD.Controllers.SheetManager {
    private SheetPair _currentSheet;
    private weak Sheets _current_sheets;
    private Gee.LinkedList<Widgets.Editor> _editor_pool;
    private Gee.LinkedList<SheetPair> _editors;
    private Gee.LinkedList<SheetPair> _active_editors;
    private Gtk.Box _box_view;
    private Gtk.ScrolledWindow _view;
    private Gtk.InfoBar _bar;
    private Widgets.Editor _welcome_screen;
    private bool show_welcome = false;
    private SheetPair _search_sheet = null;
    private Gtk.SourceSearchContext _search_context;
    private Gtk.SourceSearchSettings _search_settings;
    private Gtk.TextIter? _last_search;
    private bool _search_buffer_changed;

    public void init () {
        if (_editors == null) {
            _editors = new Gee.LinkedList<SheetPair> ();
        }

        if (_editor_pool == null) {
            _editor_pool = new Gee.LinkedList<Widgets.Editor> ();
            for (int i = 0; i < Constants.EDITOR_POOL_SIZE; i++) {
                Widgets.Editor new_editor = new Widgets.Editor ("");
                new_editor.am_active = false;
                _editor_pool.add (new_editor);
            }
        }

        if (_active_editors == null) {
            _active_editors = new Gee.LinkedList<SheetPair> ();
        }

        if (_view == null) {
            _welcome_screen = new Widgets.Editor ("");
            _view = new Gtk.ScrolledWindow (null, null);
        }

        if (_box_view == null) {
            _box_view = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);

            _box_view.add (ThiefApp.get_instance ().search_bar);
            _bar = new Gtk.InfoBar ();
            _bar.revealed = false;
            _bar.show_close_button = true;
            _box_view.add (_bar);
            _box_view.add (_view);
            _box_view.show_all ();
            _search_buffer_changed = true;
        }
    }

    public Gtk.Widget get_view () {
        clear_view ();

        return _box_view;
    }

    public void search_for (string? text) {
        if (_search_settings != null && text == null) {
            _search_settings.search_text = text;
        }

        if (_currentSheet == null) {
            return;
        }

        if (_search_settings != null) {
            _search_settings.search_text = null;
            _search_context.dispose ();
            _search_settings.dispose ();
            _search_context = null;
            _search_settings = null;
            _last_search = null;
        }

        if (_search_settings == null) {
            _search_settings = new Gtk.SourceSearchSettings ();
            _search_settings.case_sensitive = false;
            _search_settings.wrap_around = true;
        }

        debug ("Searching for: %s", text);
        _search_settings.search_text = text;

        _search_sheet = _currentSheet;
        _search_context = new Gtk.SourceSearchContext (_search_sheet.editor.buffer, _search_settings);
        _search_context.set_highlight (true);

        ThiefApp.get_instance ().search_bar.set_match_count (_search_sheet.editor.buffer.text.down ().split (text.down ()).length - 1);
    }

    public void search_next () {
        if (_search_buffer_changed) {
            search_for (ThiefApp.get_instance ().search_bar.get_search_text ());
            _search_buffer_changed = false;
            return;
        }

        if (_search_context != null && _search_sheet != null) {
            var cursor = _search_sheet.editor.buffer.get_insert ();
            Gtk.TextIter start, search_start, end, match_start, match_end;
            bool wrap;
            _search_sheet.editor.buffer.get_bounds (out start, out end);
            if (cursor != null) {
                Gtk.TextIter cursor_iter;
                _search_sheet.editor.buffer.get_iter_at_mark (out cursor_iter, cursor);
                search_start = cursor_iter;
            } else {
                search_start = start;
            }

            if (_last_search != null) {
                search_start = _last_search;
            }
            bool found = _search_context.forward (search_start, out match_start, out match_end, out wrap);
            if (!found) {
                found = _search_context.forward (start, out match_start, out match_end, out wrap);
            }
            if (found) {
                _search_sheet.editor.scroll_to_iter (match_start, 0.0, true, 0.0, Constants.TYPEWRITER_POSITION);
                _last_search = match_end;
            }
        }
    }

    public string get_current_file_path () {
        if (_currentSheet != null) {
            return _currentSheet.sheet.file_path ();
        }

        return _("No file opened.");
    }

    public void get_word_count_stats (out int word_count, out int reading_hours, out int reading_minutes, out int reading_seconds) {
        word_count = 0;
        foreach (var editor in _active_editors) {
            word_count += editor.sheet.get_word_count ();
        }
        int timereadings = word_count / Constants.WORDS_PER_SECOND;
        reading_hours = timereadings / 3600;
        timereadings = timereadings % 3600;
        reading_minutes = timereadings / 60;
        timereadings = timereadings % 60;
        reading_seconds = timereadings;
    }

    public void search_prev () {
        if (_search_buffer_changed) {
            search_for (ThiefApp.get_instance ().search_bar.get_search_text ());
            _search_buffer_changed = false;
            return;
        }

        if (_search_context != null && _search_sheet != null) {
            var cursor = _search_sheet.editor.buffer.get_insert ();
            Gtk.TextIter start, search_start, end, match_start, match_end;
            bool wrap;
            _search_sheet.editor.buffer.get_bounds (out start, out end);
            if (cursor != null) {
                Gtk.TextIter cursor_iter;
                _search_sheet.editor.buffer.get_iter_at_mark (out cursor_iter, cursor);
                search_start = cursor_iter;
            } else {
                search_start = end;
            }

            if (_last_search != null) {
                search_start = _last_search;
            }
            bool found = _search_context.backward (search_start, out match_start, out match_end, out wrap);
            if (!found) {
                found = _search_context.backward (end, out match_start, out match_end, out wrap);
            }
            if (found) {
                _search_sheet.editor.scroll_to_iter (match_start, 0.0, true, 0.0, Constants.TYPEWRITER_POSITION);
                _last_search = match_start;
            }
        }
    }

    public void show_error (string error_message) {
        _bar.set_message_type (Gtk.MessageType.ERROR);
        var content = _bar.get_content_area ();
        var error_label = new Gtk.Label ("<b>" + error_message + "</b>");
        error_label.use_markup = true;
        content.add (error_label);
        _bar.show ();

        _bar.close.connect (() => {
            content.remove (error_label);
        });

        _box_view.show_all ();
    }

    private void update_view () {
        // Clear the view
        _view.hide ();
        if (show_welcome) {
            _view.remove (_welcome_screen);
        }

        // Load the view
        if (_active_editors.size == 0) {
            show_welcome = true;
            _view.add (_welcome_screen);
        } else {
            foreach (var editor in _active_editors) {
                _view.add (editor.editor);
            }
        }
        _view.show_all ();

        _view.set_policy (Gtk.PolicyType.AUTOMATIC, Gtk.PolicyType.ALWAYS);
        _view.queue_draw ();
        _view.set_policy (Gtk.PolicyType.AUTOMATIC, Gtk.PolicyType.AUTOMATIC);

        foreach (var editor in _active_editors) {
            editor.editor.queue_draw ();
        }
    }

    public string get_markdown () {
        StringBuilder builder = new StringBuilder ();
        foreach (var sp in _active_editors) {
            string text = (Sheet.areEqual(sp.sheet, _currentSheet.sheet)) ? sp.editor.active_markdown () : sp.editor.buffer.text;
            builder.append (FileManager.get_yamlless_markdown (text, 0, true, true, false));
        }

        return builder.str;
    }

    public double get_cursor_position () {
        return 0.1;
    }

    private Thread<bool> sheet_worker_thread;
    Mutex loading_sheets;
    public void set_sheets (Sheets? sheets) {
        _current_sheets = sheets;
        UI.set_sheets (sheets);
    }

    private bool preload_sheets () {
        warning ("Thread start");
        if (_current_sheets == null) {
            return false;
        }

        if (loading_sheets.trylock ()) {
            GLib.List<Sheet> sheets_to_cache = _current_sheets.get_sheets ();
            foreach (var sheet in sheets_to_cache) {
                warning ("Loaded: %s", sheet.file_path ());
                silent_load_sheet (sheet);
            }

            check_queue ();
            loading_sheets.unlock ();
        }

        return false;
    }

    public Sheets get_sheets () {
        return _current_sheets;
    }

    public static void refresh_sheet () {
        foreach (var editor in _active_editors) {
            editor.sheet.redraw ();
        }
    }

    public static Sheet? get_sheet () {
        if (_currentSheet != null) {
            return _currentSheet.sheet;
        }

        return null;
    }

    private bool open_file (string file_path, out Widgets.Editor editor) {
        if (_editor_pool.size > 0) {
            editor = _editor_pool.poll ();
            return editor.open_file (file_path);
        } else {
            FileManager.open_file (file_path, out editor);
            return editor != null;
        }
    }

    public static bool load_sheet (Sheet sheet) {
        if (_currentSheet != null && Sheet.areEqual(sheet, _currentSheet.sheet) && _active_editors.size == 1) {
            debug ("Tried loading current sheet");
            return true;
        }

        var settings = AppSettings.get_default ();
        if (sheet == null) {
            debug ("Invalid sheet provided");
            return false;
        }

        debug ("Opening sheet: %s", sheet.file_path ());

        drain_and_save_active ();

        bool success = false;
        _currentSheet = null;
        foreach (var editor in _editors) {
            if (Sheet.areEqual(editor.sheet, sheet)) {
                debug ("Sheet found in queue");
                _currentSheet = editor;
                success = true;
            }
        }

        if (_currentSheet == null) {
            _currentSheet = new SheetPair ();
            _currentSheet.sheet = sheet;
            debug ("Opening sheet from disk");
            success = open_file (sheet.file_path (), out _currentSheet.editor);
        } else {
            _editors.remove (_currentSheet);
        }

        if (success) {
            _currentSheet.sheet.active_sheet = true;
            _currentSheet.editor.am_active = true;
            _active_editors.add (_currentSheet);
            settings.last_file = sheet.file_path ();
        }

        debug ("Tried to load %s (%s)\n", sheet.file_path (), (success) ? "success" : "failed");

        update_view ();

        if (ThiefApp.get_instance ().search_bar.search_enabled ()) {
            Timeout.add (250, () => {
                search_for (ThiefApp.get_instance ().search_bar.get_search_text ());
                return false;
            });
        }
        return success;
    }

    public static void silent_load_sheet (Sheet sheet) {
        if (sheet == null) {
            return;
        }

        foreach (var editor in _editors) {
            if (Sheet.areEqual(editor.sheet, sheet)) {
                return;
            }
        }

        foreach (var editor in _active_editors) {
            if (Sheet.areEqual(editor.sheet, sheet)) {
                return;
            }
        }


        SheetPair cached_sheet = new SheetPair ();
        cached_sheet.sheet = sheet;
        open_file (sheet.file_path (), out cached_sheet.editor);

        if (cached_sheet.editor != null) {
            _editors.insert (0, cached_sheet);
        }

        debug ("Tried to load %s (%s)\n", sheet.file_path (), (cached_sheet.editor != null) ? "success" : "failed");
    }

    public static void new_sheet (string file_name) {
        string parent_dir = "";
        Sheets sheet = null;

        if (_current_sheets == null) {
            // Save the current file
            save_active ();

            // Attempt to create the sheet and switch to it
            if (_currentSheet != null) {
                sheet = _currentSheet.sheet.get_parent_sheets ();
                parent_dir = sheet.get_sheets_path ();
            }
        } else {
            sheet = _current_sheets;
            parent_dir = sheet.get_sheets_path ();
        }

        // Create the file and refresh
        if (parent_dir != "" && sheet != null && sheet.get_sheets_path () != "") {
            if (FileManager.create_sheet(sheet.get_sheets_path (), file_name)) {
                sheet.refresh ();
                sheet.show_all ();
            }
        } else {
            warning ("Could not create file, no current sheet");
        }
    }

    // Just finds headers and makes the bold...
    public string mini_mark (string contents) {
        string result = contents;
        try {
            Regex headers = new Regex ("^(#+)\\s(.+)", RegexCompileFlags.MULTILINE | RegexCompileFlags.CASELESS, 0);
            result = result.replace ("&", "&amp;");
            result = result.replace ("<", "&lt;").replace (">", "&gt;");
            result = headers.replace (result, -1, 0, "<b>\\1 \\2</b>");
        } catch (Error e) {
            warning ("Error: %s", e.message);
        }
        return result;
    }

    public void drain_and_save_active () {
        foreach (var editor in _active_editors) {
            try {
                _view.remove (editor.editor);
                editor.sheet.active_sheet = false;
                editor.editor.am_active = false;
                editor.editor.save ();
                editor.sheet.redraw ();
            } catch (Error e) {
                warning ("Could not save file %s: %s", editor.sheet.file_path (), e.message);
            }
        }

        _active_editors.drain (_editors);
        check_queue ();
    }

    private void save_active () {
        foreach (var editor in _active_editors) {
            try {
                editor.editor.save ();
                editor.sheet.redraw ();
                UI.update_preview ();
            } catch (Error e) {
                warning ("Could not save file %s: %s", editor.sheet.file_path (), e.message);
            }
        }
    }

    public static void bold () {
        if (_currentSheet != null) {
            _currentSheet.editor.bold ();
        }
    }

    public static void italic () {
        if (_currentSheet != null) {
            _currentSheet.editor.italic ();
        }
    }

    public static void strikethrough () {
        if (_currentSheet != null) {
            _currentSheet.editor.strikethrough ();
        }
    }

    private static void refresh_scheme () {
        var settings = AppSettings.get_default ();
        var scheme_id = settings.get_valid_theme_id ();
        foreach (var editor in _active_editors) {
            editor.editor.set_scheme (scheme_id);
        }
    }

    public static bool close_active_file (string file_path) {
        SheetPair remove_this = null;
        foreach (var editor in _active_editors) {
            if (editor.sheet.file_path () == file_path) {
                remove_this = editor;
                try {
                    editor.editor.save ();
                    editor.sheet.redraw ();
                } catch (Error e) {
                    warning ("Could not save file %s: %s", editor.sheet.file_path (), e.message);
                }
            }
        }

        if (remove_this != null) {
            remove_this.editor.am_active = false;
            remove_this.sheet.active_sheet = false;
            _active_editors.remove (remove_this);
            _editors.remove (remove_this);
            _view.remove (remove_this.editor);
            remove_this.editor.clean ();
            remove_this.editor = null;
            remove_this.sheet = null;
            clear_view ();
        }

        return false;
    }

    public void redraw () {
        foreach (var editor in _active_editors) {
            editor.editor.show ();
            editor.sheet.redraw ();
        }
    }

    private void clear_view () {
        foreach (var editor in _active_editors) {
            _view.remove (editor.editor);
        }
        update_view ();
    }

    public void last_modified (Widgets.Editor modified_editor) {
        _search_buffer_changed = true;
        if (_currentSheet != null && _currentSheet.editor == modified_editor) {
            return;
        }

        foreach (var editor in _active_editors) {
            if (editor.editor == modified_editor) {
                _currentSheet = editor;
            }
        }
    }

    public void check_queue () {
        while (_editors.size > Constants.KEEP_X_SHEETS_IN_MEMORY) {
            SheetPair clean = _editors.poll ();
            clean.editor.am_active = false;
            clean.sheet = null;
            if (_editor_pool.size < Constants.EDITOR_POOL_SIZE) {
                clean.editor.open_file ("");
                _editor_pool.add (clean.editor);
            } else {
                clean.editor.clean ();
                clean.editor = null;
                clean.sheet.active_sheet = false;
                clean.sheet = null;
                clean = null;
            }
        }
    }

    public void redo () {
        if (_currentSheet != null) {
            _currentSheet.editor.redo ();
        }
    }

    public void undo () {
        if (_currentSheet != null) {
            _currentSheet.editor.undo ();
        }
    }

    private class SheetPair {
        public weak Sheet sheet;
        public Widgets.Editor editor;
    }
}
