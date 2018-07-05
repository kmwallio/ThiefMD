using ThiefMD;
using ThiefMD.Widgets;
using ThiefMD.Controllers;
using Gtk;

namespace ThiefMD.Widgets {
    /**
     * Library or file tree view
     */
    public class Library : TreeView {

        private TreeStore _lib_store;

        public Library () {
            stdout.printf ("Setting up library\n");
            _lib_store = new TreeStore (2, typeof (string), typeof (LibPair));
            parse_library();
            set_model (_lib_store);
            insert_column_with_attributes (-1, "Library", new CellRendererText (), "text", 0, null);
            get_selection ().changed.connect (on_selection);
        }

        private void on_selection (TreeSelection selected) {
            TreeModel model;
            TreeIter iter;
            if (selected.get_selected (out model, out iter)) {
                LibPair p = convert_selection (model, iter);
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

        private void parse_library () {
            var settings = AppSettings.get_default ();
            settings.validate_library ();
            string[] library = settings.library ();

            TreeIter root;
            _lib_store.append (out root, null);

            foreach (string lib in library) {
                stdout.printf (lib + "\n");
                LibPair pair = new LibPair(lib);
                _lib_store.set (root, 0, pair._title, 1, pair, -1);
                parse_dir(lib, root);
            }
        }

        private void parse_dir (string str_dir, TreeIter iter) {
            try {
                // Create child iter
                TreeIter child;
    
                // Loop through the directory
                Dir dir = Dir.open (str_dir, 0);
                string? file_name = null;
                while ((file_name = dir.read_name()) != null) {
                    debug ("Found %s \n", file_name);
                    string path = Path.build_filename (str_dir, file_name);
                    if (FileUtils.test(path, FileTest.IS_DIR)) {
                        _lib_store.append (out child, iter);
                        LibPair pair = new LibPair(path);
                        // Append dir to list
                        _lib_store.set (child, 0, pair._title, 1, pair, -1);
                        parse_dir (path, child);
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
            stdout.printf ("Got path : %s\n", _path);
            _title = _path.substring (_path.last_index_of ("/") + 1);
            _sheets = new Sheets(_path);
        }

        public string to_string () {
            return _title;
        }
    }
}