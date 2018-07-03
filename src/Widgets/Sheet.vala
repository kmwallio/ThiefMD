using ThiefMD.Controllers;

namespace ThiefMD.Widgets {
    /**
     * Sheet
     * 
     * Button Widget pointing to a file on the system.
     */
    public class Sheet : Gtk.Button {
        private string _sheet_path;
        private bool _selected;

        public Sheet (string sheet_path) {
            _sheet_path = sheet_path;
            label = sheet_path;
            stdout.printf("Creating %s\n", sheet_path);

            clicked.connect (() => {
                stdout.printf ("Clicked\n");
                SheetManager.load_sheet (this);
            });
        }

        public string file_path () {
            return _sheet_path;
        }
    }
}