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
using ThiefMD.Controllers;

namespace ThiefMD.Widgets {
    public class ThiefSheetsSerializable : Object {
        public string[] sheet_order { get; set; }
        public string[] hidden_folders { get; set; }
        public string[] folder_order { get; set; }
        public string notes { get; set; }
        public string icon { get; set ; }

        public ThiefSheetsSerializable (ThiefSheets sheets) {
            sheet_order = new string[sheets.sheet_order.size];
            for(int i = 0; i < sheets.sheet_order.size; i++) {
                sheet_order[i] = sheets.sheet_order.get (i);
            }

            folder_order = new string[sheets.folder_order.size];
            for(int i = 0; i < sheets.folder_order.size; i++) {
                folder_order[i] = sheets.folder_order.get (i);
            }

            hidden_folders = new string[sheets.hidden_folders.size];
            for(int i = 0; i < sheets.hidden_folders.size; i++) {
                hidden_folders[i] = sheets.hidden_folders.get (i);
            }

            notes = string_or_empty_string (sheets.notes);
            icon = string_or_empty_string (sheets.icon);
        }
    }

    public class ThiefSheets : Object {
        public Gee.List<string> sheet_order;
        public Gee.List<string> folder_order;
        public Gee.LinkedList<string> hidden_folders;
        public string notes { get; set; }
        public string icon { get; set; }

        public ThiefSheets () {
            sheet_order = new Gee.ArrayList<string> ();
            folder_order = new Gee.ArrayList<string> ();
            hidden_folders = new Gee.LinkedList<string> ();
            notes = "";
            icon = "";
        }

        public static ThiefSheets new_for_file (string file) throws Error {
            ThiefSheets t_sheets = new ThiefSheets ();

            Json.Parser parser = new Json.Parser ();
            parser.load_from_file (file);
            Json.Node data = parser.get_root ();
            ThiefSheetsSerializable thief_sheets = Json.gobject_deserialize (typeof (ThiefSheetsSerializable), data) as ThiefSheetsSerializable;
            if (thief_sheets != null) {
                foreach (var s in thief_sheets.sheet_order) {
                    t_sheets.add_sheet (s);
                }

                foreach (var s in thief_sheets.folder_order) {
                    t_sheets.add_folder (s);
                }

                foreach (var s in thief_sheets.hidden_folders) {
                    t_sheets.add_hidden_folder (s);
                }

                t_sheets.notes = string_or_empty_string (thief_sheets.notes);
                t_sheets.icon = string_or_empty_string (thief_sheets.icon);
            }

            return t_sheets;
        }

        public void add_sheet (string sheet_name) {
            if (!sheet_order.contains (sheet_name)) {
                sheet_order.add (sheet_name);
            }
        }

        public void add_folder (string folder) {
            if (!folder_order.contains (folder)) {
                folder_order.add (folder);
            }
        }

        public void add_hidden_folder (string folder) {
            if (!hidden_folders.contains (folder)) {
                hidden_folders.add (folder);
            }
        }
    }

    private int get_string_px_width (Gtk.Label lbl, string str) {
        int f_w = 14;
        var font_context = lbl.get_pango_context ();
        var font_desc = font_context.get_font_description ();
        var font_layout = new Pango.Layout (font_context);
        font_layout.set_font_description (font_desc);
        font_layout.set_text (str, str.length);
        Pango.Rectangle ink, logical;
        font_layout.get_pixel_extents (out ink, out logical);
        font_layout.dispose ();
        return int.max (ink.width, logical.width);
    }

    /**
     * Sheets View
     * 
     * Sheets View keeps track of *.md files in a provided directory
     */
    public class Sheets : Gtk.Box {
        public ThiefSheets metadata;
        private string _sheets_dir;
        private Gee.HashMap<string, Sheet> _sheets;
        private Gtk.ScrolledWindow _scroller;
        private Gtk.Box _view;
        private PreventDelayedDrop _reorderable;
        private FileMonitor _monitor;
        private NewSheet new_sheet_widget;
        public Gtk.MenuButton new_sheet;
        Gtk.Label _empty;

        public Sheets (string path) {
            orientation = Gtk.Orientation.VERTICAL;

            var settings = AppSettings.get_default ();
            _sheets_dir = path;
            _view = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
            _scroller = new Gtk.ScrolledWindow ();

            _scroller.set_policy (Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC);
            _scroller.set_child (_view);
            _scroller.vexpand = true;
            _scroller.hexpand = true;

            string title = "";
            if (path != "") {
                title = make_title (path.substring (path.last_index_of (Path.DIR_SEPARATOR_S) + 1));
            }

            var bar = new Adw.HeaderBar ();
            var bar_label = new Gtk.Label ("<b>" + title + "</b>");
            bar_label.use_markup = true;
            while (title.length > 12 && get_string_px_width(bar_label, title + "...") > 180) {
                title = title.substring (0, title.length - 2);
                bar_label.set_markup ("<b>" + title + "...</b>");
            }
            bar_label.halign = Gtk.Align.START;
            bar_label.hexpand = true;
            bar_label.xalign = 0;
            bar_label.set_ellipsize (Pango.EllipsizeMode.END);
            var window_title = new Adw.WindowTitle ("", "");
            bar.set_title_widget (window_title);
            bar.set_show_start_title_buttons (false);
            // Keep the end container visible for our custom button while hiding window controls
            bar.set_show_end_title_buttons (false);
            bar.set_decoration_layout (null);
            bar.set_hexpand (true);

            new_sheet = new Gtk.MenuButton ();
            new_sheet_widget = new NewSheet ();
            new_sheet.has_tooltip = true;
            new_sheet.tooltip_text = (_("New Sheet"));
            new_sheet.set_icon_name ("document-new-symbolic");
            new_sheet.popover = new_sheet_widget;
            new_sheet.hexpand = false;
            new_sheet.vexpand = false;
            new_sheet.margin_start = 5;
            new_sheet.margin_end = 15;

            bar.pack_start (new_sheet);
            bar.pack_start (bar_label);

            var header_context = bar.get_style_context ();
            header_context.add_class ("thiefmd-toolbar");

            append (bar);
            append (_scroller);

            debug ("Got %s\n", _sheets_dir);
            if (_sheets_dir == "" || !FileUtils.test(path, FileTest.IS_DIR)) {
                show_empty ();
            } else {
                load_sheets ();
            }

            var sheets_context = this.get_style_context ();
            sheets_context.add_class ("thief-sheets");
            _reorderable = new PreventDelayedDrop ();

            File current_directory = File.new_for_path (_sheets_dir);
            if (current_directory.query_exists () && FileUtils.test (_sheets_dir, FileTest.IS_DIR)) {
                try {
                    _monitor = current_directory.monitor_directory (FileMonitorFlags.SEND_MOVED | FileMonitorFlags.WATCH_MOVES);
                    _monitor.changed.connect (folder_changed);
                    destroy.connect (() => {
                        _monitor.changed.disconnect (folder_changed);
                    });
                } catch (Error e) {
                    warning ("Unable to monitor for folder changes: %s", e.message);
                }
            }
            width_request = settings.view_sheets_width;
        }

        public void make_new_sheet () {
            new_sheet_widget.popup ();
        }

        public void folder_changed (File file, File? other_file, FileMonitorEvent event_type) {
            if (event_type == FileMonitorEvent.CREATED || event_type == FileMonitorEvent.MOVED ||
                event_type == FileMonitorEvent.MOVED_IN || event_type == FileMonitorEvent.MOVED_OUT ||
                event_type == FileMonitorEvent.DELETED || event_type == FileMonitorEvent.RENAMED)
            {
                if (FileUtils.test (file.get_path (), FileTest.IS_DIR) || (other_file != null && FileUtils.test (other_file.get_path (), FileTest.IS_DIR))) {
                    ThiefApp.get_instance ().library.refresh_dir (this);
                }

                File my_dir = File.new_for_path (_sheets_dir);
                if (my_dir.query_exists ()) {
                    refresh ();
                } else {
                    _monitor.changed.disconnect (folder_changed);
                    ThiefApp.get_instance ().library.remove_item (_sheets_dir);
                }
            }

            // @TODO: Folder unmount support
        }

        public void add_hidden_item (string directory_path) {
            File ignore_dir = File.new_for_path (directory_path);
            if (ignore_dir.query_exists () ||
                ignore_dir.get_basename ().down () == "_site" ||
                ignore_dir.get_basename ().down () == "public")
            {
                metadata.add_hidden_folder (ignore_dir.get_basename ());
            }
            save_library_order ();
        }

        public void remove_hidden_items () {
            metadata.hidden_folders.clear ();
            save_library_order ();
        }

        public string get_sheets_path () {
            return _sheets_dir;
        }

        public string get_parent_sheets_path () {
            File path = File.new_for_path (_sheets_dir);
            File? parent = path.get_parent ();
            if (parent != null) {
                return parent.get_path ();
            } else {
                return "";
            }
        }

        private void show_empty () {
            if (_empty == null) {
                _empty = new Gtk.Label(_("Select an item from the Library to open or create a new Sheet."));
                _empty.set_ellipsize (Pango.EllipsizeMode.END);
                _empty.lines = 30;
                _empty.set_margin_top (12); // avoid header overlap
                _empty.set_margin_start (6);
                _empty.set_margin_end (6);
            }

            if (_empty.get_parent () == null) {
                _view.append (_empty);
            }
        }

        private void remove_empty_label () {
            if (_empty != null && _empty.get_parent () != null) {
                _view.remove (_empty);
            }
        }

        private void update_empty_label_state () {
            if (_sheets != null && _sheets.keys.size > 0) {
                remove_empty_label ();
            } else {
                show_empty ();
            }
        }

        public string guess_extension () {
            string ext = ".md";
            if (_sheets.is_empty) {
                Sheets? parent = ThiefApp.get_instance ().library.find_sheets_for_path (get_parent_sheets_path ());
                if (parent != null) {
                    ext = parent.guess_extension ();
                }
            } else {
                foreach (var sheet in _sheets) {
                    if (is_fountain (sheet.value.file_path ())) {
                        ext = ".fountain";
                    }
                }
            }

            return ext;
        }

        public void remove_sheet (Sheet sheet) {
            if (sheet != null) {
                Sheet val;
                debug ("Removing sheet %s", sheet.file_path ());
                _sheets.unset (sheet.file_name (), out val);
                _view.remove (val);
                metadata.sheet_order.remove (sheet.file_name ());
                update_empty_label_state ();
            }
        }

        public bool has_active_sheet () {
            foreach (var sheet in _sheets) {
                if (sheet.value.active_sheet) {
                    return true;
                }
            }
            return false;
        }

        public void close_active_files () {
            foreach (var sheet in _sheets) {
                if (sheet.value.active_sheet) {
                    SheetManager.close_active_file (sheet.value.file_path ());
                }
            }
        }

        public Gee.List<Sheet> get_active_sheets () {
            Gee.LinkedList<Sheet> active_sheets = new Gee.LinkedList<Sheet> ();
            foreach (var sheet in _sheets) {
                if (sheet.value.active_sheet) {
                    active_sheets.add (sheet.value);
                }
            }

            return active_sheets;
        }

        public void refresh () {
            bool am_empty = (_sheets.keys.size == 0);
            var keys = _sheets.keys;
            Gee.LinkedList<string> doublecheck = new Gee.LinkedList<string> ();
            foreach (var key in keys) {
                doublecheck.add (key);
            }
            foreach (var key in doublecheck) {
                string path = Path.build_filename(_sheets_dir, key);
                File file = File.new_for_path (path);
                if (!file.query_exists ()) {
                    Sheet bad_sheet = null;
                    _sheets.unset (key, out bad_sheet);
                    if (bad_sheet != null) {
                        _view.remove (bad_sheet);
                    }
                }
            }
            reload_sheets ();

            update_empty_label_state ();
        }

        public List<Sheet> get_sheets () {
            List<Sheet> list = new List<Sheet> ();
            foreach (var sheet in metadata.sheet_order) {
                if (_sheets.has_key (sheet)) {
                    list.append (_sheets.get (sheet));
                }
            }
            return list;
        }

        public void load_sheets () {
            var settings = AppSettings.get_default ();
            remove_empty_label ();

            if (_sheets != null) {
                foreach (var sheet in _sheets) {
                    _view.remove (sheet.value);
                }
                foreach (var file_check in metadata.sheet_order) {
                    Sheet rem_sheet;
                    _sheets.unset (file_check, out rem_sheet);
                }
                _sheets = null;
            }

            _sheets = new Gee.HashMap<string, Sheet>();

            // Load file ordering information
            metadata = null;
            File metadata_file = File.new_for_path (Path.build_filename (_sheets_dir, ".thiefsheets"));
            if (metadata_file.query_exists ()) {
                try {
                    metadata = ThiefSheets.new_for_file (metadata_file.get_path ());
                } catch (Error e) {
                    warning ("Could not load metafile: %s", e.message);
                }
            }

            if (metadata == null) {
                metadata = new ThiefSheets ();
            }

            // Load from metadata file
            foreach (var file_name in metadata.sheet_order) {
                debug("Loading %s \n", file_name);
                string path = Path.build_filename(_sheets_dir, file_name);
                File file = File.new_for_path (path);
                if (file.query_exists () && !_sheets.has_key (file_name)) {
                    if ((!FileUtils.test(path, FileTest.IS_DIR)) &&
                        can_open_file (path.down ())) {

                        Sheet sheet = new Sheet (path, this);
                        _sheets.set (file_name, sheet);
                        _view.append (sheet);
                        remove_empty_label ();

                        if (!settings.dont_show_tips){
                            if (settings.last_file == path) {
                                sheet.active_sheet = true;
                                SheetManager.load_sheet (sheet);
                            }
                        }
                    }
                }
            }

            // Load anything new in the folder
            reload_sheets ();

            update_empty_label_state ();

            if (metadata.sheet_order.size != 0 && (settings.save_library_order || metadata.notes != "")) {
                save_library_order ();
            }
        }

        public void reload_sheets () {
            var settings = AppSettings.get_default ();
            //
            // Scan over provided directory for Markdown files
            //
            try {
                Dir dir = Dir.open(_sheets_dir, 0);
                string? file_name = null;
                while ((file_name = dir.read_name()) != null) {
                    debug("Found %s \n", file_name);
                    if (!_sheets.has_key (file_name)) {
                        string path = Path.build_filename(_sheets_dir, file_name);
                        if ((!FileUtils.test(path, FileTest.IS_DIR)) &&
                            can_open_file (path.down ())) {

                            Sheet sheet = new Sheet (path, this);
                            _sheets.set (file_name, sheet);
                            _view.append (sheet);
                            metadata.add_sheet (file_name);
                            remove_empty_label ();

                            if (!settings.dont_show_tips){
                                if (settings.last_file == path) {
                                    sheet.active_sheet = true;
                                    SheetManager.load_sheet (sheet);
                                }
                            }
                        }
                    }
                }
            } catch (Error e) {
                warning (e.message);
            }

            update_empty_label_state ();
        }

        public void sort_sheets_by_date (bool asc = true) {
            if (asc) {
                metadata.sheet_order.sort ((a, b) => {
                    string date_a = _sheets.get (a).get_date ();
                    string date_b = _sheets.get (b).get_date ();
                    return GLib.strcmp (date_a, date_b);
                });
            } else {
                metadata.sheet_order.sort ((a, b) => {
                    string date_a = _sheets.get (a).get_date ();
                    string date_b = _sheets.get (b).get_date ();
                    return -1 * GLib.strcmp (date_a, date_b);
                });
            }

            redraw_sheets ();
            save_metadata_file (true);
        }

        public void sort_sheets_by_title (bool asc = true) {
            if (asc) {
                metadata.sheet_order.sort ((a, b) => {
                    string title_a = _sheets.get (a).get_title ();
                    string title_b = _sheets.get (b).get_title ();
                    return GLib.strcmp (title_a, title_b);
                });
            } else {
                metadata.sheet_order.sort ((a, b) => {
                    string title_a = _sheets.get (a).get_title ();
                    string title_b = _sheets.get (b).get_title ();
                    return -1 * GLib.strcmp (title_a, title_b);
                });
            }

            redraw_sheets ();
            save_metadata_file (true);
        }

        public void sort_sheets_by_name (bool asc = true) {
            if (asc) {
                metadata.sheet_order.sort ((a, b) => {
                    return GLib.strcmp (a, b);
                });
            } else {
                metadata.sheet_order.sort ((a, b) => {
                    return -1 * GLib.strcmp (a, b);
                });
            }

            redraw_sheets ();
            save_metadata_file (true);
        }

        public void move_folder_after (string destination, string moved) {
            if (!_reorderable.can_get_drop () || (destination == moved)) {
                return;
            }

            metadata.folder_order.remove (moved);
            int index = metadata.folder_order.index_of (destination);

            if (index + 1 < metadata.folder_order.size && index >= 0) {
                metadata.folder_order.insert (index + 1, moved);
            } else {
                metadata.folder_order.add (moved);
            }

            save_metadata_file (true);
        }

        public void move_folder_before (string destination, string moved) {
            if (!_reorderable.can_get_drop () || (destination == moved)) {
                return;
            }

            metadata.folder_order.remove (moved);
            int index = metadata.folder_order.index_of (destination);
            if (index >= 0) {
                metadata.folder_order.insert (index, moved);
            } else {
                metadata.folder_order.add (moved);
            }

            save_metadata_file (true);
        }

        public void move_sheet_after (string destination, string moved) {
            if (!_reorderable.can_get_drop () || (destination == moved)) {
                return;
            }

            debug ("Moving %s after %s", moved, destination);

            metadata.sheet_order.remove (moved);
            int index = metadata.sheet_order.index_of (destination);

            if (index + 1 < metadata.sheet_order.size) {
                metadata.sheet_order.insert (index + 1, moved);
            } else {
                metadata.sheet_order.add (moved);
            }

            redraw_sheets ();
            save_metadata_file (true);
        }

        public void move_sheet_before (string destination, string moved) {
            if (!_reorderable.can_get_drop () || (destination == moved)) {
                return;
            }

            debug ("Moving %s before %s", moved, destination);

            metadata.sheet_order.remove (moved);
            int index = metadata.sheet_order.index_of (destination);

            metadata.sheet_order.insert (index, moved);

            redraw_sheets ();
            save_metadata_file (true);
        }

        public void update_sheet_indicators (string active_file = "") {
            foreach (var s in metadata.sheet_order) {
                Sheet show = _sheets.get (s);
                bool should_be_active = (active_file != "" && show.file_path () == active_file);
                if (show.active_sheet != should_be_active) {
                    show.active_sheet = should_be_active;
                } else {
                    show.redraw ();
                }
            }
        }

        public void redraw_sheets () {
            foreach (var s in metadata.sheet_order) {
                Sheet show = _sheets.get (s);
                show.redraw ();
                _view.remove (show);
                _view.append (show);
            }
            _view.show ();
        }

        public void save_notes () {
            save_metadata_file (metadata.notes != "");
        }

        public void persist_metadata () {
            save_metadata_file (true);
        }

        private void save_library_order () {
            save_metadata_file ();
        }

        private void save_metadata_file (bool create = false) {
            var settings = AppSettings.get_default ();
            File metadata_file = File.new_for_path (Path.build_filename (_sheets_dir, ".thiefsheets"));

            if (!settings.save_library_order && metadata.hidden_folders.size == 0 && metadata.notes == "") {
                return;
            }

            if (!metadata_file.query_exists () && metadata.hidden_folders.size == 0 && !create && metadata.notes == "") {
                return;
            }

            for (int i = 0; i < metadata.sheet_order.size; i++) {
                string file_check = metadata.sheet_order.get (i);
                string path = Path.build_filename(_sheets_dir, file_check);
                File file = File.new_for_path (path);
                if (!file.query_exists ()) {
                    metadata.sheet_order.remove_at (i);
                    i--;
                }
            }

            try {
                ThiefSheetsSerializable cereal = new ThiefSheetsSerializable (metadata);
                Json.Node root = Json.gobject_serialize (cereal);
                Json.Generator generate = new Json.Generator ();
                generate.set_root (root);
                generate.set_pretty (true);
                if (metadata_file.query_exists ()) {
                    metadata_file.delete ();
                }
                debug ("Saving to: %s", metadata_file.get_path ());
                FileManager.save_file (metadata_file, generate.to_data (null).data);
            } catch (Error e) {
                warning ("Could not serialize data: %s", e.message);
            }
        }
    }
}
