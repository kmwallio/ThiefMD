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
    private SheetPair? _currentSheet;
    private unowned Sheets? _current_sheets;
    private Gee.LinkedList<Widgets.Editor> _editor_pool;
    private Gee.LinkedList<SheetPair> _editors;
    private Gee.LinkedList<SheetPair> _active_editors;
    private Gtk.Box _box_view;
    private Gtk.ScrolledWindow _view;
    private Gtk.Box _view_container;
    private Gtk.Box _bar;
    private Widgets.Editor _welcome_screen;
    private bool show_welcome = false;
    private SheetPair _search_sheet = null;
    private GtkSource.SearchContext _search_context;
    private GtkSource.SearchSettings _search_settings;
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
            _view = new Gtk.ScrolledWindow ();
            _view.set_policy (Gtk.PolicyType.AUTOMATIC, Gtk.PolicyType.AUTOMATIC);
            _view_container = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
            _view.hexpand = true;
            _view.vexpand = true;
            _view_container.hexpand = true;
            _view_container.vexpand = true;
            _view.set_child (_view_container);
        }

        if (_box_view == null) {
            _box_view = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
            _box_view.append (ThiefApp.get_instance ().search_bar);
            _bar = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
            _bar.set_visible (false);
            _box_view.append (_bar);
            _box_view.append (_view);
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
            _search_settings = new GtkSource.SearchSettings ();
            _search_settings.case_sensitive = false;
            _search_settings.wrap_around = true;
        }

        debug ("Searching for: %s", text);
        _search_settings.search_text = text;

        _search_sheet = _currentSheet;
        _search_context = new GtkSource.SearchContext (_search_sheet.editor.buffer, _search_settings);
        _search_context.set_highlight (true);

        ThiefApp.get_instance ().search_bar.set_match_count (_search_sheet.editor.get_buffer_text ().down ().split (text.down ()).length - 1);
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

        return _("No file opened");
    }

    public void update_margins () {
        foreach (var editor in _active_editors) {
            editor.editor.move_margins ();
        }
    }

    public void get_word_count_stats (out int word_count, out int reading_hours, out int reading_minutes, out int reading_seconds) {
        word_count = 0;
        foreach (var editor in _active_editors) {
            // Use buffer word count instead of reading from disk
            word_count += editor.editor.get_buffer_word_count ();
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
        while (_bar.get_first_child () != null) {
            _bar.remove (_bar.get_first_child ());
        }
        var error_label = new Gtk.Label ("<b>" + error_message + "</b>");
        error_label.use_markup = true;
        _bar.append (error_label);
        _bar.set_visible (true);
    }

    private void update_view () {
        // Clear the view
        while (_view_container.get_first_child () != null) {
            _view_container.remove (_view_container.get_first_child ());
        }
        if (show_welcome && _welcome_screen != null) {
            _welcome_screen.am_active = false;
            _view_container.remove (_welcome_screen);
            _welcome_screen.clean ();
            _welcome_screen = null;
        }

        // Load the view
        if (_active_editors.size == 0) {
            show_welcome = true;
            _welcome_screen = new Widgets.Editor ("");
            _welcome_screen.am_active = true;
            _view_container.append (_welcome_screen);
        } else {
            foreach (var editor in _active_editors) {
                _view_container.append (editor.editor);
            }
        }
        _view.set_policy (Gtk.PolicyType.AUTOMATIC, Gtk.PolicyType.ALWAYS);
        _view.queue_draw ();
        _view.set_policy (Gtk.PolicyType.AUTOMATIC, Gtk.PolicyType.AUTOMATIC);

        foreach (var editor in _active_editors) {
            editor.editor.queue_draw ();
        }
    }

    public string get_markdown () {
        var settings = AppSettings.get_default ();
        StringBuilder builder = new StringBuilder ();
        int i = 0;
        foreach (var sp in _active_editors) {
            string text = (Sheet.areEqual(sp.sheet, _currentSheet.sheet)) ? sp.editor.active_markdown () : sp.editor.get_buffer_text ();
            string title, date;
            builder.append (i == 0 ?
                text
                :
                FileManager.get_yamlless_markdown (
                text,
                0,
                out title,
                out date,
                true,
                settings.export_include_yaml_title,
                false));
            i++;
        }

        return builder.str;
    }

    public double get_cursor_position () {
        return 0.1;
    }

    public void set_sheets (Sheets? sheets) {
        _current_sheets = sheets;
        sync_all_sheet_indicators ();
        UI.set_sheets (sheets);
    }

    public void redraw_sheets () {
        sync_all_sheet_indicators ();
    }

    private static void sync_all_sheet_indicators () {
        string active_path = "";
        if (_currentSheet != null) {
            active_path = _currentSheet.sheet.file_path ();
        }

        var app = ThiefApp.get_instance ();
        if (app != null && app.library != null) {
            foreach (var sheets in app.library.get_all_sheets ()) {
                sheets.update_sheet_indicators (active_path);
            }
        } else if (_current_sheets != null) {
            _current_sheets.update_sheet_indicators (active_path);
        }
    }

    public void reapply_editor_theme () {
        var settings = AppSettings.get_default ();
        string scheme_id = settings.get_valid_theme_id ();

        foreach (var editor in _active_editors) {
            editor.editor.set_scheme (scheme_id, false);
        }

        if (_welcome_screen != null && _welcome_screen.am_active) {
            _welcome_screen.set_scheme (scheme_id, false);
        }
    }

    public Sheets? get_sheets () {
        return _current_sheets;
    }

    public static void refresh_sheet () {
        foreach (var editor in _active_editors) {
            editor.sheet.redraw ();
        }
    }

    public static Sheet? get_sheet () {
        var settings = AppSettings.get_default ();
        if (_currentSheet == null && _welcome_screen != null && _welcome_screen.am_active && settings.dont_show_tips && _welcome_screen.file_path != "") {
            Sheet? welcome_mapped_sheet = ThiefApp.get_instance ().library.find_sheet_for_path (_welcome_screen.file_path);
            if (welcome_mapped_sheet != null) {
                return welcome_mapped_sheet;
            }
        }

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

        if (_currentSheet != null && !Sheet.areEqual (sheet, _currentSheet.sheet)) {
            _currentSheet.sheet.active_sheet = false;
            _currentSheet.sheet.redraw ();
            _currentSheet.editor.am_active = false;
        }

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
            _currentSheet.sheet.redraw ();
            _currentSheet.editor.am_active = true;
            _active_editors.add (_currentSheet);
            settings.last_file = sheet.file_path ();

            // Ensure margins are calculated once the editor is realized
            Idle.add (() => {
                _currentSheet.editor.move_margins ();
                return false;
            });
        }

        debug ("Tried to load %s (%s)\n", sheet.file_path (), (success) ? "success" : "failed");

        update_view ();
        sync_all_sheet_indicators ();

        if (ThiefApp.get_instance ().search_bar.search_enabled ()) {
            Timeout.add (250, () => {
                search_for (ThiefApp.get_instance ().search_bar.get_search_text ());
                return false;
            });
        }
        settings.sheet_changed ();
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
                sheet.set_visible (true);
            }
        } else {
            warning ("Could not create file, no current sheet");
        }
    }

    // Just finds headers and makes the bold...
    public string mini_mark (string contents) {
        string result = contents;
        try {
            Regex headers = new Regex ("^(I\\/E\\.?|EST\\.?|INT\\.?\\/EXT|INT\\.?|EXT\\.?|#+)\\s(.+)", RegexCompileFlags.MULTILINE | RegexCompileFlags.CASELESS, 0);
            result = result.replace ("&", "&amp;");
            result = result.replace ("<", "&lt;").replace (">", "&gt;");
            result = headers.replace (result, -1, 0, "<b>\\1 \\2</b>");
        } catch (Error e) {
            warning ("Error: %s", e.message);
        }
        return result;
    }

    public void drain_and_save_active () {
        if (_active_editors == null || _view == null) {
            return;
        }

        foreach (var editor in _active_editors) {
            editor.editor.save ();
            editor.sheet.active_sheet = false;
            editor.sheet.redraw ();
            editor.editor.am_active = false;
            _view_container.remove (editor.editor);
        }

        _active_editors.drain (_editors);
        check_queue ();
    }

    private void save_active () {
        foreach (var editor in _active_editors) {
            editor.editor.save ();
            editor.sheet.redraw ();
            UI.update_preview ();
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

    public static void link () {
        if (_currentSheet != null) {
            _currentSheet.editor.link ();
        }
    }

    // Navigate to next heading (Markdown) or scene (Fountain)
    public static void next_marker () {
        if (_currentSheet != null) {
            _currentSheet.editor.next_marker ();
        }
    }

    // Navigate to previous heading (Markdown) or scene (Fountain)
    public static void prev_marker () {
        if (_currentSheet != null) {
            _currentSheet.editor.prev_marker ();
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
        var settings = AppSettings.get_default ();
        SheetPair remove_this = null;
        foreach (var editor in _active_editors) {
            if (editor.sheet.file_path () == file_path) {
                remove_this = editor;
                editor.editor.save ();
                editor.sheet.redraw ();
            }
        }

        if (_welcome_screen != null && _welcome_screen.file_path == file_path) {
            settings.sheet_changed (); // Save notes
            _view_container.remove (_welcome_screen);
            _welcome_screen.clean ();
            _welcome_screen = null;
            _welcome_screen = new Widgets.Editor ("");
            clear_view ();
        }

        if (remove_this != null) {
            settings.sheet_changed (); // Save notes
            remove_this.editor.am_active = false;
            remove_this.sheet.active_sheet = false;
            _active_editors.remove (remove_this);
            _editors.remove (remove_this);
            _view_container.remove (remove_this.editor);
            remove_this.editor.clean ();
            remove_this.editor = null;
            remove_this.sheet = null;
            clear_view ();
        }

        sync_all_sheet_indicators ();
        settings.sheet_changed (); // Clear notes
        return false;
    }

    public void redraw () {
        var settings = AppSettings.get_default ();
        foreach (var editor in _active_editors) {
            editor.editor.show ();
            editor.sheet.redraw ();
            editor.editor.move_margins ();
        }

        if (settings.dont_show_tips) {
            if (_welcome_screen != null && _welcome_screen.am_active && _welcome_screen.file_path != "") {
                Sheet? should_refresh = ThiefApp.get_instance ().library.find_sheet_for_path (_welcome_screen.file_path);
                if (should_refresh != null) {
                    should_refresh.redraw ();
                }
            }
        }

        settings.sheet_changed ();
    }

    private void clear_view () {
        foreach (var editor in _active_editors) {
            _view_container.remove (editor.editor);
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
            if (_editor_pool.size < Constants.EDITOR_POOL_SIZE) {
                Widgets.Editor new_editor = new Widgets.Editor ("");
                new_editor.am_active = false;
                _editor_pool.add (new_editor);
            }
            clean.editor.clean ();
            clean.editor = null;
            clean.sheet.active_sheet = false;
            clean.sheet = null;
            clean = null;
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

    private class SheetPair : Object {
        public unowned Sheet sheet;
        public Widgets.Editor editor;
    }
}
