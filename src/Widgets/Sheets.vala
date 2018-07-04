using ThiefMD;
using ThiefMD.Controllers;

namespace ThiefMD.Widgets {
    /**
     * Sheets View
     * 
     * Sheets View keeps track of *.md files in a provided directory
     */
    public class Sheets : Gtk.ScrolledWindow {
        private string _sheets_dir;
        private List<Sheet> _sheets;
        private Gtk.Box _view;

        public Sheets (string path) {
            _sheets_dir = path;
            _view = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);

            set_policy(Gtk.PolicyType.EXTERNAL, Gtk.PolicyType.AUTOMATIC);
            add (_view);

            debug ("Got %s\n", _sheets_dir);
            if (_sheets_dir == "") {
                show_empty ();
            } else {
                load_sheets ();
            }
        }

        private void show_empty () {
            Gtk.Label empty = new Gtk.Label("Select an item from the Library to open.");
            _view.add(empty);
        }

        public void load_sheets () {
            var settings = AppSettings.get_default ();
            _sheets = new List<Sheet>();

            //
            // Scan over provided directory for Markdown files
            //
            try {
                Dir dir = Dir.open(_sheets_dir, 0);
                string? file_name = null;
                while ((file_name = dir.read_name()) != null) {
                    stdout.printf("Found %s \n", file_name);
                    string path = Path.build_filename(_sheets_dir, file_name);
                    if ((!FileUtils.test(path, FileTest.IS_DIR)) &&
                        (path.has_suffix(".md"))) {

                        Sheet sheet = new Sheet (path);
                        _sheets.append (sheet);
                        _view.add (sheet);
                        
                        if (settings.last_file == path) {
                            sheet.active = true;
                            SheetManager.load_sheet (sheet);
                        }
                    }
                }
            } catch (Error e) {
                stderr.printf(e.message);
            }
        }
    }
}