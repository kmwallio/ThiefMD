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
        public string last_file { get; set; }
        public string spellcheck_language { get; set; }

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