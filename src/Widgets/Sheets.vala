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
        }
    }

    public class ThiefSheets : Object {
        public Gee.List<string> sheet_order;
        public Gee.List<string> folder_order;
        public Gee.LinkedList<string> hidden_folders;

        public ThiefSheets () {
            sheet_order = new Gee.ArrayList<string> ();
            folder_order = new Gee.ArrayList<string> ();
            hidden_folders = new Gee.LinkedList<string> ();
        }

        public static ThiefSheets new_for_file (string file) throws Error {
            ThiefSheets t_sheets = new ThiefSheets ();

            Json.Parser parser = new Json.Parser ();
            parser.load_from_file (file);
            Json.Node data = parser.get_root ();
            ThiefSheetsSerializable thief_sheets = Json.gobject_deserialize (typeof (ThiefSheetsSerializable), data) as ThiefSheetsSerializable;
            if (thief_sheets != null) {
                foreach (var s in thief_sheets.sheet_order) {
                    t_sheets.add_sheet(s);
                }

                foreach (var s in thief_sheets.folder_order) {
                    t_sheets.add_folder (s);
                }

                foreach (var s in thief_sheets.hidden_folders) {
                    t_sheets.add_hidden_folder (s);
                }
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

    /**
     * Sheets View
     * 
     * Sheets View keeps track of *.md files in a provided directory
     */
    public class Sheets : Gtk.ScrolledWindow {
        public ThiefSheets metadata;
        private string _sheets_dir;
        private Gee.HashMap<string, Sheet> _sheets;
        private Gtk.Box _view;
        private PreventDelayedDrop _reorderable;
        private FileMonitor _monitor;
        Gtk.Label _empty;

        public Sheets (string path) {
            _sheets_dir = path;
            _view = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);

            set_policy (Gtk.PolicyType.EXTERNAL, Gtk.PolicyType.AUTOMATIC);
            add (_view);

            debug ("Got %s\n", _sheets_dir);
            if (_sheets_dir == "" || !FileUtils.test(path, FileTest.IS_DIR)) {
                show_empty ();
            } else {
                load_sheets ();
            }

            var header_context = this.get_style_context ();
            header_context.add_class ("thief-sheets");
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
            _empty = new Gtk.Label("Select an item from the Library to open or create a new Sheet.");
            _empty.set_ellipsize (Pango.EllipsizeMode.END);
            _empty.lines = 30;
            _view.add(_empty);
        }

        public void remove_sheet (Sheet sheet) {
            if (sheet != null) {
                Sheet val;
                debug ("Removing sheet %s", sheet.file_path ());
                _sheets.unset (sheet.file_name (), out val);
                _view.remove (val);
                metadata.sheet_order.remove (sheet.file_name ());
                if (_sheets.is_empty) {
                    show_empty ();
                }
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
            foreach (var file_check in metadata.sheet_order) {
                string path = Path.build_filename(_sheets_dir, file_check);
                File file = File.new_for_path (path);
                if (!file.query_exists ()) {
                    Sheet bad_sheet = null;
                    _sheets.unset (file_check, out bad_sheet);
                    if (bad_sheet != null) {
                        _view.remove (bad_sheet);
                    }
                }
            }
            reload_sheets ();

            if (am_empty && (_sheets.keys.size != 0)) {
                _view.remove (_empty);
            }
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
            if (_empty != null) {
                _view.remove (_empty);
            }

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
                        (path.down ().has_suffix(".md") || path. down().has_suffix(".markdown"))) {

                        Sheet sheet = new Sheet (path, this);
                        _sheets.set (file_name, sheet);
                        _view.add (sheet);

                        if (settings.last_file == path) {
                            sheet.active_sheet = true;
                            SheetManager.load_sheet (sheet);
                        }
                    }
                }
            }

            // Load anything new in the folder
            reload_sheets ();

            if (metadata.sheet_order.size == 0) {
                show_empty();
            } else if (settings.save_library_order) {
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
                            (path.has_suffix(".md") || path.has_suffix(".markdown"))) {

                            Sheet sheet = new Sheet (path, this);
                            _sheets.set (file_name, sheet);
                            _view.add (sheet);
                            metadata.add_sheet (file_name);

                            if (settings.last_file == path) {
                                sheet.active_sheet = true;
                                SheetManager.load_sheet (sheet);
                            }
                        }
                    }
                }
            } catch (Error e) {
                warning (e.message);
            }
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

        public void redraw_sheets () {
            foreach (var s in metadata.sheet_order) {
                Sheet show = _sheets.get (s);
                _view.remove (show);
                _view.add (show);
            }
            _view.show ();
        }

        private void save_library_order () {
            save_metadata_file ();
            //  File metadata_file = File.new_for_path (Path.build_filename (_sheets_dir, ".thiefsheets"));
            //  if (metadata_file.query_exists ())
            //  {
            //      warning ("Deleting: %s", metadata_file.get_path ());
            //      metadata_file.delete();
            //  }
            //  File thief_file = File.new_for_path (Path.build_filename (_sheets_dir, ".thiefignore"));
            //  if (thief_file.query_exists ())
            //  {
            //      warning ("Deleting: %s", thief_file.get_path ());
            //      thief_file.delete();
            //  }
        }

        private void save_metadata_file (bool create = false) {
            var settings = AppSettings.get_default ();
            File metadata_file = File.new_for_path (Path.build_filename (_sheets_dir, ".thiefsheets"));

            if (!settings.save_library_order && metadata.hidden_folders.size == 0) {
                return;
            }

            if (!metadata_file.query_exists () && metadata.hidden_folders.size == 0 && !create) {
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