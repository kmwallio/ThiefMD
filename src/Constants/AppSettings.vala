namespace ThiefMD { 
    public class Constants {
        // Margin Constants
        public const int NARROW_MARGIN = 5;
        public const int MEDIUM_MARGIN = 10;
        public const int WIDE_MARGIN = 20;

        public const int BOTTOM_MARGIN = 20;
        public const int TOP_MARGIN = 20;

        // Typewriter Position
        public const double TYPEWRITER_POSITION = 0.45;

        // Number of lines to preview
        public const int SHEET_PREVIEW_LINES = 3;

        // Max time for animations in milliseconds
        public const int ANIMATION_TIME = 150;
        public const int ANIMATION_FRAMES = 15;
    }

    public class AppSettings : Granite.Services.Settings {
        public bool fullscreen { get; set; }
        public bool show_num_lines { get; set; }
        public bool autosave { get; set; }
        public bool spellcheck { get; set; }
        public bool statusbar { get; set; }
        public bool show_filename { get; set; }
        public bool typewriter_scrolling { get; set; }
        public int margins { get; set; }
        public int spacing { get; set; }
        public int window_height { get; set; }
        public int window_width { get; set; }
        public int window_x { get; set; }
        public int window_y { get; set; }
        public int view_state { get; set; }
        public int view_sheets_width { get; set; }
        public int view_library_width { get; set; }
        public string last_file { get; set; }
        public string spellcheck_language { get; set; }
        public string library_list { get; set; }

        public string[] library () {
            return library_list.split(";");
        }

        public void validate_library () {
            string[] current_library = library();
            string new_library = "";

            foreach (string item in current_library) {
                if ((item.chomp() != "") && (FileUtils.test(item, FileTest.IS_DIR))) {
                    if (new_library == "") {
                        new_library = item;
                    } else {
                        new_library += ";" + item;
                    }
                }
            }

            library_list = new_library;
        }

        public void remove_from_library (string path) {
            string[] current_library = library();
            string new_library = "";

            foreach (string item in current_library) {
                if ((item.chomp() != "") && (FileUtils.test(item, FileTest.IS_DIR)) && (item != path)) {
                    if (new_library == "") {
                        new_library = item;
                    } else {
                        new_library += ";" + item;
                    }
                }
            }

            library_list = new_library;
        }

        public bool add_to_library (string folder) {
            string[] current_library = library();

            // Validate the directory exists
            if ((folder.chomp() == "") || (!FileUtils.test(folder, FileTest.IS_DIR))) {
                return false;
            }

            foreach (string item in current_library) {
                if (item == folder) {
                    return true;
                }
            }

            if (library_list.chomp () == "") {
                library_list = folder;
            } else {
                library_list += ";" + folder;
            }

            return true;
        }

        private static AppSettings? instance;
        public static unowned AppSettings get_default () {
            if (instance == null) {
                instance = new AppSettings ();
            }

            return instance;
        }

        private AppSettings () {
            base ("com.github.kmwallio.thiefmd");
        }
    }
}