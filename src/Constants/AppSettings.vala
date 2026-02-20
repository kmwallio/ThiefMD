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

using ThiefMD.Controllers;

namespace ThiefMD {
    public enum FocusType {
        PARAGRAPH = 0,
        SENTENCE,
        WORD,
    }

    public class Constants : Object {
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
        public const double TYPEWRITER_POSITION = 0.2;

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
        public string theme_id { get; set; }
        public string custom_theme { get; set; }
        public bool dark_mode { get; set; }
        public bool ui_editor_theme { get; set; }
        public bool save_library_order { get; set; }
        public bool show_sheet_filenames { get; set; }
        public bool export_break_folders { get; set; }
        public bool export_break_sheets { get; set; }
        public bool export_resolve_paths { get; set; }
        public double export_side_margins { get; set; }
        public double export_top_bottom_margins { get; set; }
        public bool export_include_metadata_file { get; set; }
        public bool export_include_yaml_title { get; set; }
        public bool brandless { get; set; }
        public string preview_css { get; set; }
        public string print_css { get; set; }
        public string export_paper_size { get; set; }
        public bool show_writing_statistics { get; set; }
        public string font_family { get; set; }
        public int font_size { get; set; default = 12; }
        public double line_spacing { get; set; default = 1; }
        public bool experimental { get; set; }
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

        private bool grammar_enabled = false;
        public bool grammar {
            set {
                if (value != grammar_enabled) {
                    grammar_enabled = value;
                    changed ();
                }
            }
            get {
                return grammar_enabled;
            }
        }

        public string get_valid_theme_id () {
            UI.UserSchemes ().force_rescan ();
            foreach (var id in UI.UserSchemes ().scheme_ids) {
                if (id == theme_id) {
                    return theme_id;
                }
            }

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
            app_settings = new GLib.Settings ("com.github.kmwallio.thiefmd");
            app_settings.bind ("fullscreen", this, "fullscreen", SettingsBindFlags.DEFAULT);
            app_settings.bind ("show-num-lines", this, "show_num_lines", SettingsBindFlags.DEFAULT);
            app_settings.bind ("autosave", this, "autosave", SettingsBindFlags.DEFAULT);
            app_settings.bind ("spellcheck", this, "spellcheck", SettingsBindFlags.DEFAULT);
            app_settings.bind ("statusbar", this, "statusbar", SettingsBindFlags.DEFAULT);
            app_settings.bind ("show-filename", this, "show_filename", SettingsBindFlags.DEFAULT);
            app_settings.bind ("typewriter-scrolling", this, "typewriter_scrolling", SettingsBindFlags.DEFAULT);
            app_settings.bind ("margins", this, "margins", SettingsBindFlags.DEFAULT);
            app_settings.bind ("spacing", this, "spacing", SettingsBindFlags.DEFAULT);
            app_settings.bind ("window-height", this, "window_height", SettingsBindFlags.DEFAULT);
            app_settings.bind ("window-width", this, "window_width", SettingsBindFlags.DEFAULT);
            app_settings.bind ("window-x", this, "window_x", SettingsBindFlags.DEFAULT);
            app_settings.bind ("window-y", this, "window_y", SettingsBindFlags.DEFAULT);
            app_settings.bind ("view-state", this, "view_state", SettingsBindFlags.DEFAULT);
            app_settings.bind ("view-sheets-width", this, "view_sheets_width", SettingsBindFlags.DEFAULT);
            app_settings.bind ("view-library-width", this, "view_library_width", SettingsBindFlags.DEFAULT);
            app_settings.bind ("last-file", this, "last_file", SettingsBindFlags.DEFAULT);
            app_settings.bind ("spellcheck-language", this, "spellcheck_language", SettingsBindFlags.DEFAULT);
            app_settings.bind ("library-list", this, "library_list", SettingsBindFlags.DEFAULT);
            app_settings.bind ("theme-id", this, "theme_id", SettingsBindFlags.DEFAULT);
            app_settings.bind ("custom-theme", this, "custom_theme", SettingsBindFlags.DEFAULT);
            app_settings.bind ("dark-mode", this, "dark_mode", SettingsBindFlags.DEFAULT);
            app_settings.bind ("ui-editor-theme", this, "ui_editor_theme", SettingsBindFlags.DEFAULT);
            app_settings.bind ("brandless", this, "brandless", SettingsBindFlags.DEFAULT);
            app_settings.bind ("save-library-order", this, "save_library_order", SettingsBindFlags.DEFAULT);
            app_settings.bind ("show-sheet-filenames", this, "show_sheet_filenames", SettingsBindFlags.DEFAULT);
            app_settings.bind ("export-break-folders", this, "export_break_folders", SettingsBindFlags.DEFAULT);
            app_settings.bind ("export-break-sheets", this, "export_break_sheets", SettingsBindFlags.DEFAULT);
            app_settings.bind ("export-resolve-paths", this, "export_resolve_paths", SettingsBindFlags.DEFAULT);
            app_settings.bind ("export-side-margins", this, "export_side_margins", SettingsBindFlags.DEFAULT);
            app_settings.bind ("export-top-bottom-margins", this, "export_top_bottom_margins", SettingsBindFlags.DEFAULT);
            app_settings.bind ("export-include-metadata-file", this, "export_include_metadata_file", SettingsBindFlags.DEFAULT);
            app_settings.bind ("export-include-yaml-title", this, "export_include_yaml_title", SettingsBindFlags.DEFAULT);
            app_settings.bind ("preview-css", this, "preview_css", SettingsBindFlags.DEFAULT);
            app_settings.bind ("print-css", this, "print_css", SettingsBindFlags.DEFAULT);
            app_settings.bind ("export-paper-size", this, "export_paper_size", SettingsBindFlags.DEFAULT);
            app_settings.bind ("show-writing-statistics", this, "show_writing_statistics", SettingsBindFlags.DEFAULT);
            app_settings.bind ("font-size", this, "font_size", SettingsBindFlags.DEFAULT);
            app_settings.bind ("font-family", this, "font_family", SettingsBindFlags.DEFAULT);
            app_settings.bind ("focus-type", this, "focus_type", SettingsBindFlags.DEFAULT);
            app_settings.bind ("line-spacing", this, "line_spacing", SettingsBindFlags.DEFAULT);
            app_settings.bind ("experimental", this, "experimental", SettingsBindFlags.DEFAULT);
            app_settings.bind ("dont-show-tips", this, "dont_show_tips", SettingsBindFlags.DEFAULT);
            app_settings.bind ("num-preview-lines", this, "num_preview_lines", SettingsBindFlags.DEFAULT);

            app_settings.changed.connect (() => {
                changed ();
            });
        }
    }
}