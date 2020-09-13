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

        public ThiefSheetsSerializable (ThiefSheets sheets) {
            sheet_order = new string[(int)sheets.sheet_order.length ()];
            for(int i = 0; i < (int)(sheets.sheet_order.length ()); i++) {
                sheet_order[i] = sheets.sheet_order.nth_data (i);
            }
        }
    }

    public class ThiefSheets : Object {
        public List<string> sheet_order;

        public ThiefSheets () {
            sheet_order = new List<string> ();
        }

        public static ThiefSheets new_for_file (string file) {
            ThiefSheets t_sheets = new ThiefSheets ();

            Json.Parser parser = new Json.Parser ();
            parser.load_from_file (file);
            Json.Node data = parser.get_root ();
            ThiefSheetsSerializable thief_sheets = Json.gobject_deserialize (typeof (ThiefSheetsSerializable), data) as ThiefSheetsSerializable;
            if (thief_sheets != null) {
                foreach (var s in thief_sheets.sheet_order) {
                    t_sheets.sheet_order.append (s);
                }
            }

            return t_sheets;
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
        Gtk.Label _empty;

        public Sheets (string path) {
            _sheets_dir = path;
            _view = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);

            set_policy(Gtk.PolicyType.EXTERNAL, Gtk.PolicyType.AUTOMATIC);
            add (_view);

            debug ("Got %s\n", _sheets_dir);
            if (_sheets_dir == "" || !FileUtils.test(path, FileTest.IS_DIR)) {
                show_empty ();
            } else {
                load_sheets ();
            }

            var header_context = this.get_style_context ();
            header_context.add_class ("thief-sheets");
        }

        public string get_sheets_path () {
            return _sheets_dir;
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
            }
        }

        public bool has_active_sheet () {
            foreach (var sheet in _sheets) {
                if (sheet.value.active) {
                    return true;
                }
            }
            return false;
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
                _sheets.unset_all (_sheets);
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
            try {
                foreach (var file_name in metadata.sheet_order) {
                    debug("Loading %s \n", file_name);
                    string path = Path.build_filename(_sheets_dir, file_name);
                    File file = File.new_for_path (path);
                    if (file.query_exists () && !_sheets.has_key (file_name)) {
                        if ((!FileUtils.test(path, FileTest.IS_DIR)) &&
                            (path.has_suffix(".md") || path.has_suffix(".markdown"))) {

                            Sheet sheet = new Sheet (path, this);
                            _sheets.set (file_name, sheet);
                            _view.add (sheet);
                            metadata.sheet_order.append (file_name);

                            if (settings.last_file == path) {
                                sheet.active = true;
                                SheetManager.load_sheet (sheet);
                            }
                        }
                    }
                }
            } catch (Error e) {
                warning ("Could not load file cache information: %s", e.message);
            }

            // Load anything new in the folder
            reload_sheets ();

            if (metadata.sheet_order.length () == 0) {
                show_empty();
            } else if (settings.save_library_order) {
                save_library_order ();
            }

            // Toggle saving of sheets
            settings.changed.connect (() => {
                save_library_order ();
            });
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
                            metadata.sheet_order.append (file_name);

                            if (settings.last_file == path) {
                                sheet.active = true;
                                SheetManager.load_sheet (sheet);
                            }
                        }
                    }
                }
            } catch (Error e) {
                warning (e.message);
            }
        }

        public void sort_sheets_by_name (bool asc = true) {
            metadata.sheet_order.sort (GLib.strcmp);
            if (!asc) {
                metadata.sheet_order.reverse ();
            }

            foreach (var s in metadata.sheet_order) {
                Sheet show = _sheets.get (s);
                _view.remove (show);
                _view.add (show);
            }
            _view.show ();
            save_library_order ();
        }

        private void save_library_order () {
            var settings = AppSettings.get_default ();
            if (!settings.save_library_order) {
                return;
            }
            File metadata_file = File.new_for_path (Path.build_filename (_sheets_dir, ".thiefsheets"));
            List<weak string> current_order = metadata.sheet_order.copy ();
            foreach (var file_check in current_order) {
                string path = Path.build_filename(_sheets_dir, file_check);
                File file = File.new_for_path (path);
                if (!file.query_exists ()) {
                    metadata.sheet_order.remove (file_check);
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