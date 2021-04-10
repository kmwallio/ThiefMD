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

//////////////////////////////////////////////////////////////////////
//
//
//
//     THIS IS A SET OF MOCKS/STUBS SO TESTS CAN COMPILE AND RUN
//
//
//
//////////////////////////////////////////////////////////////////////
using ThiefMD.Controllers;

namespace ThiefMD {
    namespace Widgets {
        public class Editor {
            public string open_file;
            public Editor (string filename) {
                open_file = filename;
            }
        }

        public class Thinking {
            public delegate void ThinkingCallback ();
            public Thinking (string set_title, ThinkingCallback callback, Gee.List<string>? custom_messages = null) { }

            public void run () { }
        }
    }
    namespace Connections { }
    public enum FocusType {
        PARAGRAPH = 0,
        SENTENCE,
        WORD,
    }

    public class ThiefSheets : Object {
        public Gee.List<string> sheet_order;
        public Gee.List<string> folder_order;
        public Gee.LinkedList<string> hidden_folders;
        public string notes { get; set; }
        public string icon { get; set; }

        public ThiefSheets () {
            sheet_order = new Gee.ArrayList<string> ();
            folder_order = new Gee.ArrayList<string> ();
            hidden_folders = new Gee.LinkedList<string> ();
            notes = "";
            icon = "";
        }

        public static ThiefSheets new_for_file (string file) throws Error {
            ThiefSheets t_sheets = new ThiefSheets ();
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

    public class Sheets {
        public ThiefSheets metadata;
        public Sheets () {
            metadata = new ThiefSheets ();
        }

        public void refresh () { }

        public string get_sheets_path () {
            return Environment.get_current_dir ();
        }
    }

    public class Sheet {
        public Sheet () { }

        public string file_path () {
            return "";
        }
    }

    public class SheetManager {
        public SheetManager () { }
        public static Sheet? get_sheet () {
            return null;
        }

        public static Sheets? get_sheets () {
            return null;
        }

        public static bool close_active_file (string file) {
            return true;
        }
        public static void save_active () { }

        public static void redraw () { }

        public static bool show_error (string error) {
            return true;
        }
    }

    public class Notes {
        public Notes () { }
    }

    public class Library {
        public Library () { }
        public void refresh_dir (Sheets dir) { }
    }

    public class Folder {
        public bool folded = false;
        public Folder () { }
    }

    public class Build {
        public const string PKGDATADIR = "/dev/null";
        public const string VERSION = "test";
    }

    public class UI {
        public static Gtk.SourceStyleSchemeManager thief_schemes = null;
        public static Gtk.SourceStyleSchemeManager UserSchemes () {
            if (thief_schemes == null) {
                thief_schemes = new Gtk.SourceStyleSchemeManager ();
            }
    
            return thief_schemes;
        }
    }

    public class ThiefApp {
        public int pane_position = 200;
        public Notes notes;
        public Library library;
        public Folder main_content;
        public bool ready = true;
        public ThiefApp () {
            notes = new Notes ();
        }

        public static ThiefApp get_instance () {
            return new ThiefApp ();
        }

        public void get_size (out int w, out int h) {
            w = 800;
            h = 400;
        }
    }

    public class Constants {
        public const string COLLECTION_THIEFMD = Secret.COLLECTION_DEFAULT;
        // Default exporter
        public const string DEFAULT_EXPORTER = "ePUB";

        // Margin Constants
        public const int NARROW_MARGIN = 5;
        public const int MEDIUM_MARGIN = 10;
        public const int WIDE_MARGIN = 20;

        public const int BOTTOM_MARGIN = 20;
        public const int TOP_MARGIN = 20;

        // Timing Constants
        public const int AUTOSAVE_TIMEOUT = 3000;

        // Autohide Toolbar settings
        // Distance mouse has to travel from last hiding time ^ 2
        public const double MOUSE_SENSITIVITY = 225;
        // Time in milliseconds to check if mouse still in motion
        // After MOUSE_IN_MOTION_TIME of no motion, the headerbar will hide
        public const int MOUSE_IN_MOTION_TIME = 1000;
        // Frequency in time to check if the mouse is still in motion
        // once motion is detected. Should be > MOUSE_IN_MOTION_TIME
        public const int MOUSE_MOTION_CHECK_TIME = 2500;

        // Default number of sheets to keep history of
        public const int KEEP_X_SHEETS_IN_MEMORY = 10;
        // Pool allows for faster file opens. If it's greater
        // than the sheets to keep in memory, there shouldn't be
        // lag, but we hold more stuff doing nothing. Once
        // KEEP_X_SHEETS_IN_MEMORY + EDITOR_POOL_SIZE files have
        // been opened, we should have a responsive editor?
        public const int EDITOR_POOL_SIZE = 5;
        public const int MAX_UNDO_LEVELS = 25;

        // Typewriter Position
        public const int TYPEWRITER_UPDATE_TIME = 500;
        public const double TYPEWRITER_POSITION = 0.45;

        // Number of lines to preview
        public const int SHEET_PREVIEW_LINES = 3;
        public const int SEARCH_PREVIEW_LINES = 4;
        public const int CSS_PREVIEW_WIDTH = 75;
        public const int CSS_PREVIEW_HEIGHT = 100;

        // Max time for animations in milliseconds
        public const int ANIMATION_TIME = 150;
        public const int ANIMATION_FRAMES = 15;

        // Data Directories
        public const string DATA_BASE = "ThiefMD";
        public const string DATA_STYLES = "styles";
        public const string DATA_SCHEMES = "schemes";
        public const string DATA_CSS = "css";

        // Reading Statistics
        public const int WORDS_PER_MINUTE = 200;
        public const int WORDS_PER_SECOND = WORDS_PER_MINUTE / 60;

        // Font settings
        public const double SIZE_1_REM_IN_PT = 12;
        public const double SINGLE_SPACING = 1.0;

        // Citation length limit
        public const int CITATION_TITLE_MAX_LEN = 30;

        // Some Grammar settings
        public const int GRAMMAR_SENTENCE_CACHE_SIZE = 50;
        public const int GRAMMAR_SENTENCE_CHECK_TIMEOUT = 500;

        // Visual Settings
        public const double MINIMUM_CONTRAST_RATIO = 1.2;

        // Arbitrary strings
        public const string FIRST_USE = _("""# Click on a sheet to get started

First time here?  Drag a folder into the library, or click on the Folder icon to select a folder to add.

## Thief Tip:

%s""");
    }

    public class AppSettings : Object {
        private GLib.Settings app_settings;
        public bool fullscreen { get; set; default = false; }
        public bool show_num_lines { get; set; default = false; }
        public bool autosave { get; set; default = true; }
        public bool spellcheck { get; set; default = false; }
        public bool statusbar { get; set; default = false; }
        public bool show_filename { get; set; default = false; }
        public bool typewriter_scrolling { get; set; default = false; }
        public int margins { get; set; default = 10; }
        public int spacing { get; set; default = 10; }
        public int window_height { get; set; default = 1000; }
        public int window_width { get; set; default = 100; }
        public int window_x { get; set; default = 100; }
        public int window_y { get; set; default = 100; }
        public int view_state { get; set; default = 1; }
        public int view_sheets_width { get; set; default = 100; }
        public int view_library_width { get; set; default = 100; }
        public string last_file { get; set; default = ""; }
        public string spellcheck_language { get; set; default = "en_US"; }
        public string library_list { get; set; default = ""; }
        public string theme_id { get; set; default = "thiefmd"; }
        public string custom_theme { get; set; default = ""; }
        public bool dark_mode { get; set; default = false; }
        public bool ui_editor_theme { get; set; default = false; }
        public bool save_library_order { get; set; default = true; }
        public bool export_break_folders { get; set; default = false; }
        public bool export_break_sheets { get; set; default = false; }
        public bool export_resolve_paths { get; set; default = false; }
        public double export_side_margins { get; set; default = 1.0; }
        public double export_top_bottom_margins { get; set; default = 1.0; }
        public bool export_include_metadata_file { get; set; default = true; }
        public bool export_include_yaml_title { get; set; default = true; }
        public bool brandless { get; set; default = false; }
        public string preview_css { get; set; default = ""; }
        public string print_css { get; set; default = ""; }
        public string export_paper_size { get; set; default = "Letter"; }
        public bool show_writing_statistics { get; set; default = false; }
        public string font_family { get; set; default = ""; }
        public int font_size { get; set; default = 12; }
        public double line_spacing { get; set; default = 1; }
        public bool experimental { get; set; default = false; }
        public bool dont_show_tips { get; set; default = false; }
        public int num_preview_lines { get; set; default = Constants.SHEET_PREVIEW_LINES; }

        // Transient settings
        private bool hiding_toolbar { get; set; default = false; }
        public bool hide_toolbar {
            set {
                if (value != hiding_toolbar) {
                    hiding_toolbar = value;
                    changed ();
                }
            }
            get {
                return hiding_toolbar;
            }
        }
        public bool menu_active { get; set; default = false; }

        private bool focusmode_enabled = false;
        public int focus_type { get; set; }
        public bool focus_mode {
            set {
                if (value != focusmode_enabled) {
                    focusmode_enabled = value;
                    changed ();
                }
            }
            get {
                return focusmode_enabled;
            }
        }

        private bool writegood_enabled = false;
        public bool writegood {
            set {
                if (value != writegood_enabled) {
                    writegood_enabled = value;
                    changed ();
                }
            }
            get {
                return writegood_enabled;
            }
        }

        public string get_valid_theme_id () {
            return "thiefmd";
        }

        public string get_css_font_family () {
            var set_font_desc = Pango.FontDescription.from_string (font_family);
            string? set_font_fam = set_font_desc.get_family ();
            if (font_family == null || set_font_fam == null || font_family.chug ().chomp () == "") {
                return "font-family: 'iA Writer Duospace'";
            } else {
                return "font-family: '%s'".printf (set_font_fam.chomp ().chug ());
            }
        }

        public int get_css_font_size () {
            if (font_size <= 0 || font_size > 240) {
                return (int)Constants.SIZE_1_REM_IN_PT;
            } else {
                return font_size;
            }
        }

        public double get_css_line_spacing () {
            if (line_spacing <= 1 || line_spacing > 3.5) {
                return Constants.SINGLE_SPACING;
            } else {
                return line_spacing;
            }
        }

        public string[] library () {
            return library_list.split(";");
        }

        public bool page_in_library (string page) {
            string[] checks = library ();
            foreach (var check in checks) {
                if (page.down ().has_prefix (check.down())) {
                    return true;
                }
            }

            return false;
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

        public bool is_in_library (string path) {
            string[] current_library = library();

            foreach (string item in current_library) {
                if (item == path) {
                    return true;
                }
            }

            return false;
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

        public bool can_update_theme () {
            return app_settings.is_writable ("dark-mode") && app_settings.is_writable ("custom-theme");
        }

        public signal void changed ();

        public signal void sheet_changed ();

        public signal void writing_changed ();

        private AppSettings () {
            preview_css = "";
            print_css = "";
        }
    }
}