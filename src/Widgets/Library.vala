using ThiefMD;
using ThiefMD.Widgets;
using ThiefMD.Controllers;
using Gtk;

namespace ThiefMD.Widgets {
    /**
     * Library or file tree view
     */
    public class Library : TreeView {
        private List<LibPair> _all_sheets;
        private TreeStore _lib_store;
        private LibPair _selected;
        private TreeIter _selected_node;

        public Library () {
            debug ("Setting up library\n");
            _lib_store = new TreeStore (2, typeof (string), typeof (LibPair));
            parse_library();
            set_model (_lib_store);
            insert_column_with_attributes (-1, "Library", new CellRendererText (), "text", 0, null);
            get_selection ().changed.connect (on_selection);
        }

        public override bool button_press_event(Gdk.EventButton event) {
            base.button_press_event (event);

            if (event.type == Gdk.EventType.BUTTON_PRESS && event.button == 3) {
                Gtk.Menu menu = new Gtk.Menu ();
                Gtk.MenuItem menu_item = new Gtk.MenuItem.with_label ("Remove from Library");
                menu.attach_to_widget (this, null);
                menu.add (menu_item);
                menu_item.activate.connect (() => {
                    var settings = AppSettings.get_default ();
                    TreeIter remove_node = _selected_node;
                    if (_selected != null && _all_sheets.find (_selected) != null) {
                        debug ("Removing %s\n", _selected._path);
                        _all_sheets.remove (_selected);
                        settings.remove_from_library (_selected._path);
                        _lib_store.remove (ref remove_node);
                        //ThiefApp.get_instance ().refresh_library ();
                    }
                });
                menu.show_all ();
                menu.popup (null, null, null, event.button, event.time);
            }
            return true;
        }

        public bool has_sheets (string path) {
            foreach (LibPair pair in _all_sheets) {
                if (pair._sheets.get_sheets_path() == path) {
                    return true;
                }
            }

            return false;
        }

        public Sheets get_sheets (string path) {
            foreach (LibPair pair in _all_sheets) {
                debug ("Checking if %s is %s\n", path, pair._sheets.get_sheets_path());
                if (pair._sheets.get_sheets_path() == path) {
                    debug ("Found %s\n", path);
                    return pair._sheets;
                }
            }

            debug ("Could not find last opened project in library\n");
            return new Sheets(path);
        }

        private void on_selection (TreeSelection selected) {
            TreeModel model;
            TreeIter iter;
            if (selected.get_selected (out model, out iter)) {
                LibPair p = convert_selection (model, iter);
                _selected = p;
                _selected_node = iter;
                debug ("Selected: %s\n", p._path);
                SheetManager.set_sheets(p._sheets);
                return;
            }
        }

        private LibPair convert_selection (TreeModel model, TreeIter iter) {
            LibPair p;
            string title = "";
            model.get (iter, 0, out title, 1, out p);
            return p;
        }

        public void parse_library () {
            var settings = AppSettings.get_default ();
            settings.validate_library ();
            string[] library = settings.library ();

            TreeIter root;

            foreach (string lib in library) {
                if (lib.chomp () == "") {
                    continue;
                }
                if (!has_sheets (lib)) {
                    _lib_store.append (out root, null);
                    debug (lib + "\n");
                    LibPair pair = new LibPair(lib);
                    _lib_store.set (root, 0, pair._title, 1, pair, -1);
                    _all_sheets.append (pair);
                    parse_dir(lib, root);
                }
            }
        }

        private void parse_dir (string str_dir, TreeIter iter) {
            try {
                // Create child iter
                TreeIter child;

                string excludeds = FileManager.get_file_contents (Path.build_filename (str_dir, ".thiefignore"));
                string[] excluded = excludeds.split("\n");

                // Loop through the directory
                Dir dir = Dir.open (str_dir, 0);
                string? file_name = null;
                while ((file_name = dir.read_name()) != null) {
                    if (!file_name.has_prefix(".") && !(file_name in excluded)) {
                        debug ("Found %s \n", file_name);
                        string path = Path.build_filename (str_dir, file_name);
                        if (FileUtils.test(path, FileTest.IS_DIR)) {
                            _lib_store.append (out child, iter);
                            LibPair pair = new LibPair(path);
                            _all_sheets.append (pair);
                            // Append dir to list
                            _lib_store.set (child, 0, pair._title, 1, pair, -1);
                            parse_dir (path, child);
                        }
                    }
                }
            } catch (Error e) {
                debug ("Error: %s", e.message);
            }
        }
    }

    private class LibPair : Object {
        public Sheets _sheets;
        public string _title;
        public string _path;

        public LibPair (string path) {
            if (path.has_suffix ("/")) {
                _path = path.substring(0, -1);
            } else {
                _path = path;
            }
            debug ("Got path : %s\n", _path);
            _title = _path.substring (_path.last_index_of ("/") + 1);
            _sheets = new Sheets(_path);
        }

        public string to_string () {
            return _title;
        }
    }
}
