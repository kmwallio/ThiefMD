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
    public class ThiefApp : Hdy.ApplicationWindow {
        private static ThiefApp _instance;
        public Headerbar toolbar;
        public Library library;
        public ThiefPane sheets_pane;
        public Gtk.Paned library_pane;
        public Gtk.ScrolledWindow library_view;
        public SearchBar search_bar;
        public StatisticsBar stats_bar;
        public Controllers.Exporters exporters;
        public Gee.ConcurrentList<Connections.ConnectionBase> connections;
        public bool ready = false;
        private Gtk.Application app_parent;

        public ThiefApp (Gtk.Application app) {
            Object (application: app);
            _instance = this;
            build_ui ();
        }

        public static ThiefApp get_instance () {
            return _instance;
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
                    fullscreen ();
                    settings.statusbar = false;
                } else {
                    unfullscreen ();
                    settings.statusbar = true;
                }
            }
        }

        public void refresh_library () {
            library.parse_library ();
        }

        protected void build_ui () {
            var settings = AppSettings.get_default ();

            string start_dir = "";
            settings.validate_library ();
            if (settings.library_list == "") {
                settings.last_file = "";
                start_dir = "";
            } else {
                if (!settings.page_in_library (settings.last_file)) {
                    settings.last_file = "";
                }
            }

            if (settings.last_file != "") {
                start_dir = settings.last_file.substring(0, settings.last_file.last_index_of(Path.DIR_SEPARATOR_S));
                debug ("Starting with %s\n", start_dir);
            }

            // Attempt to set taskbar icon
            try {
                debug ("Settings the icon");
                icon = Gtk.IconTheme.get_default ().load_icon ("com.github.kmwallio.thiefmd", Gtk.IconSize.DIALOG, 0);
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

            toolbar = new Headerbar (this);
            // Have to init search bar before sheet manager
            search_bar = new SearchBar ();
            SheetManager.init ();
            library = new Library ();

            sheets_pane = new ThiefPane (Gtk.Orientation.HORIZONTAL, this);
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

            debug ("Window (%d, %d)\n", settings.window_width, settings.window_height);

            var vbox = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
            vbox.add (toolbar);
            vbox.add (sheets_pane);
            stats_bar = new StatisticsBar ();
            vbox.add (stats_bar);

            set_default_size (settings.window_width, settings.window_height);
            add (vbox);
            hide_titlebar_when_maximized = false;
            is_fullscreen = settings.fullscreen;

            settings.changed.connect (() => {
                is_fullscreen = settings.fullscreen;
            });

            new KeyBindings (this);

            UserData.create_data_directories ();

            // Load exporters
            exporters = new Controllers.Exporters ();
            exporters.register (Constants.DEFAULT_EXPORTER, new Exporters.ExportEpub ());
            exporters.register (_("HTML"), new Exporters.ExportHtml ());
            exporters.register (_("PDF"), new Exporters.ExportPdf ());
            exporters.register (_("MHTML"), new Exporters.ExportMhtml ());
            exporters.register (_("Markdown"), new Exporters.ExportMarkdown ());
            exporters.register (_("LaTeX"), new Exporters.ExportLatex ());
            exporters.register (_("DocX"), new Exporters.ExportDocx ());

            // Load connections
            connections = new Gee.ConcurrentList<Connections.ConnectionBase> ();

            // Restore preview view
            UI.show_view ();
            UI.set_sheets (start_sheet);
            library.set_active ();
            UI.load_user_themes_and_connections ();
            UI.load_font ();
            UI.load_css_scheme ();

            destroy.connect (() => {
                SheetManager.save_active ();
                foreach (var c in _instance.connections) {
                    c.connection_close ();
                }
            });

            // Go go go!
            ready = true;
            show_all ();
        }
    }
}