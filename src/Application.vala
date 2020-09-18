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

using ThiefMD;
using ThiefMD.Widgets;
using ThiefMD.Controllers;

namespace ThiefMD {
    public class ThiefApp : Gtk.Application {
        private static ThiefApp _instance;
        public Gtk.ApplicationWindow main_window;
        public Headerbar toolbar;
        public Library library;
        public Gtk.Paned sheets_pane;
        public Gtk.Paned library_pane;
        public Gtk.ScrolledWindow library_view;
        public bool ready = false;

        public ThiefApp () {
            Object (
                application_id: "com.github.kmwallio.thiefmd",
                flags: ApplicationFlags.FLAGS_NONE
            );
        }

        public int pane_position {
            get {
                return sheets_pane.get_position ();
            }
        }

        public bool is_fullscreen {
            get {
                var settings = AppSettings.get_default ();
                return settings.fullscreen;
            }
            set {
                var settings = AppSettings.get_default ();
                settings.fullscreen = value;

                var toolbar_context = toolbar.get_style_context ();
                toolbar_context.add_class("thiefmd-toolbar");

                if (settings.fullscreen) {
                    main_window.fullscreen ();
                    settings.statusbar = false;
                } else {
                    main_window.unfullscreen ();
                    settings.statusbar = true;
                }
            }
        }

        public void refresh_library () {
            library.parse_library ();
        }

        protected override void activate () {
            var settings = AppSettings.get_default ();

            string start_dir = "";
            if (settings.last_file != "") {
                start_dir = settings.last_file.substring(0, settings.last_file.last_index_of("/"));
                debug ("Starting with %s\n", start_dir);
            }

            if (settings.library_list == "") {
                settings.last_file = "";
                start_dir = "";
            }

            main_window = new Gtk.ApplicationWindow (this);
            SheetManager.init ();

            // Attempt to set taskbar icon
            try {
                debug ("Settings the icon");
                main_window.icon = Gtk.IconTheme.get_default ().load_icon ("com.github.kmwallio.thiefmd", Gtk.IconSize.DIALOG, 0);
            } catch (Error e) {
                debug ("Could not set icon: %s\n", e.message);
            }

            // Reset UI if it seems "unusable"?
            if (settings.view_library_width < 10) {
                settings.view_library_width = 200;
            }
            if (settings.view_sheets_width < 10) {
                settings.view_sheets_width = 200;
            }
            if (settings.window_height < 600) {
                settings.window_height = 600;
            }
            if (settings.window_width < 800) {
                settings.window_width = 800;
            }

            toolbar = Headerbar.get_instance ();
            library = new Library ();
            sheets_pane = new Gtk.Paned (Gtk.Orientation.HORIZONTAL);
            library_pane = new Gtk.Paned (Gtk.Orientation.HORIZONTAL);
            library_view = new Gtk.ScrolledWindow (null, null);
            library_view.set_policy(Gtk.PolicyType.EXTERNAL, Gtk.PolicyType.AUTOMATIC);

            library_view.add (library);
            library_pane.add1 (library_view);
            library.expand_all ();
            Sheets start_sheet = library.get_sheets (start_dir);
            library_pane.add2 (start_sheet);
            library_pane.set_position (settings.view_library_width);
            
            sheets_pane.add1 (library_pane);
            sheets_pane.add2 (SheetManager.get_view ());
            sheets_pane.set_position (settings.view_library_width + settings.view_sheets_width);


            var provider = new Gtk.CssProvider ();
            provider.load_from_resource ("/com/github/kmwallio/thiefmd/app-main-stylesheet.css");
            Gtk.StyleContext.add_provider_for_screen (Gdk.Screen.get_default (), provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);

            main_window.set_titlebar (toolbar);
            debug ("Window (%d, %d)\n", settings.window_width, settings.window_height);

            main_window.set_default_size (settings.window_width, settings.window_height);
            main_window.title = "ThiefMD";
            main_window.add (sheets_pane);
            main_window.hide_titlebar_when_maximized = false;
            is_fullscreen = settings.fullscreen;

            settings.changed.connect (() => {
                is_fullscreen = settings.fullscreen;
            });

            new KeyBindings (main_window);

            UserData.create_data_directories ();

            ready = true;
            main_window.show_all ();

            // Restore preview view
            UI.show_view ();
            UI.set_sheets (start_sheet);
            library.set_active ();
            UI.load_user_themes ();

            // Save on close
            shutdown.connect (() => {
                SheetManager.save_active ();
            });
        }

        public void wiggle () {
            var settings = AppSettings.get_default ();
            if (!settings.fullscreen) {
                int w, h;
                main_window.get_size (out w, out h);
                main_window.set_size_request (w + 1, h + 1);
                main_window.set_size_request (w, h);
                main_window.show_all ();
                UI.show_view ();
            }
        }

        public static ThiefApp get_instance () {
            return _instance;
        }

        public static int main (string[] args) {
            var app = new ThiefApp ();
            _instance = app;
            return app.run (args);
        }
    }
}
