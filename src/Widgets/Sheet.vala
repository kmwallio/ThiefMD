namespace ThiefMD.Widgets {
    public class Sheet : Gtk.Button {
        private string _sheet_path;
        public Sheet (string sheet_path) {
            _sheet_path = sheet_path;
            label = sheet_path;
            stdout.printf("Creating %s\n", sheet_path);
        }
    }
}