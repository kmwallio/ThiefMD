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
    public class Constants {
        // Margin Constants
        public const int NARROW_MARGIN = 5;
        public const int MEDIUM_MARGIN = 10;
        public const int WIDE_MARGIN = 20;

        public const int BOTTOM_MARGIN = 20;
        public const int TOP_MARGIN = 20;

        // Timing Constants
        public const int AUTOSAVE_TIMEOUT = 3000;

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

        // Arbitrary strings
        public const string FIRST_USE = """# Click on a sheet to get started

First time here?  Drag a folder into the library, or click on the Folder icon to select a folder to add.""";
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
        public bool export_break_folders { get; set; }
        public bool export_break_sheets { get; set; }
        public bool export_resolve_paths { get; set; }
        public double export_side_margins { get; set; }
        public double export_top_bottom_margins { get; set; }
        public bool export_include_metadata_file { get; set; }
        public bool brandless { get; set; }
        public string preview_css { get; set; }
        public string print_css { get; set; }
        public string export_paper_size { get; set; }

        private bool writegood_enabled = false;
        public bool writegood {
            set {
                writegood_enabled = value;
                changed ();
            }
            get {
                return writegood_enabled;
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
            app_settings.bind ("export-break-folders", this, "export_break_folders", SettingsBindFlags.DEFAULT);
            app_settings.bind ("export-break-sheets", this, "export_break_sheets", SettingsBindFlags.DEFAULT);
            app_settings.bind ("export-resolve-paths", this, "export_resolve_paths", SettingsBindFlags.DEFAULT);
            app_settings.bind ("export-side-margins", this, "export_side_margins", SettingsBindFlags.DEFAULT);
            app_settings.bind ("export-top-bottom-margins", this, "export_top_bottom_margins", SettingsBindFlags.DEFAULT);
            app_settings.bind ("export-include-metadata-file", this, "export_include_metadata_file", SettingsBindFlags.DEFAULT);
            app_settings.bind ("preview-css", this, "preview_css", SettingsBindFlags.DEFAULT);
            app_settings.bind ("print-css", this, "print_css", SettingsBindFlags.DEFAULT);
            app_settings.bind ("export-paper-size", this, "export_paper_size", SettingsBindFlags.DEFAULT);

            app_settings.changed.connect (() => {
                changed ();
            });
        }
    }
}