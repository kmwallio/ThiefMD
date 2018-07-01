
namespace ThiefMD.Widgets {
    /**
     * Sheets View
     * 
     * Sheets View keeps track of *.md files in a provided directory
     */
    public class Sheets : Gtk.ScrolledWindow {
        private string _sheets_dir;
        private List<Sheet> _sheets;
        public Sheets (string path) {
            _sheets_dir = path;
        }
    }
}