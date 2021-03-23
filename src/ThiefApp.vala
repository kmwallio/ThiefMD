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
        public bool am_mobile = false;
        public Gtk.Revealer notes;
        public Gtk.Box editor_notes_pane;
        public Notes notes_widget;

        private string start_dir;
        private Gtk.Box desktop_box;
        private Gtk.Box mobile_box;
        public Gtk.Stack mobile_stack;
        private Sheets start_sheet;
        private Mutex rebuild_ui;
        public bool mobile_mode = false;
        private SearchWidget mobile_search;

        public ThiefApp (Gtk.Application app) {
            Object (application: app);
            _instance = this;
            rebuild_ui = Mutex ();
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

        private bool toolbar_already_hidden = false;
        private bool am_fullscreen = false;
        public bool is_fullscreen {
            get {
                var settings = AppSettings.get_default ();
                return settings.fullscreen;
            }
            set {
                var settings = AppSettings.get_default ();
                if (am_fullscreen != value){
                    am_fullscreen = value;

                    if (settings.fullscreen) {
                        fullscreen ();
                        toolbar_already_hidden = settings.hide_toolbar;
                        settings.hide_toolbar = true;
                        toolbar.hide_headerbar ();
                        settings.statusbar = false;
                    } else {
                        unfullscreen ();
                        settings.hide_toolbar = toolbar_already_hidden;
                        if (!settings.hide_toolbar) {
                            toolbar.show_headerbar ();
                        }
                        settings.statusbar = true;
                    }
                }
            }
        }

        public void refresh_library () {
            library.parse_library ();
        }

        private void create_widgets () {
            var settings = AppSettings.get_default ();
            toolbar = null;
            search_bar = null;
            library = null;
            sheets_pane = null;
            library_pane = null;
            library_view = null;
            editor_notes_pane = null;
            notes = null;
            notes_widget = null;

            SheetManager.drain_and_save_active ();

            toolbar = new Headerbar (this);
            // Have to init search bar before sheet manager
            search_bar = new SearchBar ();
            SheetManager.init ();
            library = new Library ();

            sheets_pane = new ThiefPane (Gtk.Orientation.HORIZONTAL, this);
            library_pane = new Gtk.Paned (Gtk.Orientation.HORIZONTAL);
            library_view = new Gtk.ScrolledWindow (null, null);
            library_view.set_policy(Gtk.PolicyType.EXTERNAL, Gtk.PolicyType.AUTOMATIC);
            editor_notes_pane = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
            notes = new Gtk.Revealer ();
            notes.set_transition_type (Gtk.RevealerTransitionType.SLIDE_LEFT);
            notes.set_reveal_child (false);
            notes_widget = new Notes ();
            var notes_context = notes_widget.get_style_context ();
            notes_context.add_class ("thief-notes");

            library_view.add (library);
            stats_bar = new StatisticsBar ();
            start_sheet = library.get_sheets (start_dir);
            library_pane.add1 (library_view);
            library_pane.add2 (start_sheet);
            library_pane.set_position (settings.view_library_width);
            var toolbar_context = toolbar.get_style_context ();
            toolbar_context.add_class("thiefmd-toolbar");
        }

        private void build_desktop () {
            var settings = AppSettings.get_default ();

            if (desktop_box != null) {
                return;
            }

            if (mobile_box != null) {
                debug ("Deconstructing mobile UI");
                mobile_box.remove (toolbar);
                mobile_box.remove (mobile_stack);
                mobile_box.remove (stats_bar);
                mobile_stack.remove (library_pane);
                mobile_stack.remove (mobile_search);
                mobile_stack.remove (notes_widget);
                mobile_stack.remove (SheetManager.get_view ());
                remove (mobile_box);
                mobile_search = null;
                mobile_box = null;
            }

            am_mobile = false;
            debug ("Building desktop UI");
            create_widgets ();

            sheets_pane.add1 (library_pane);
            sheets_pane.add2 (SheetManager.get_view ());
            sheets_pane.set_position (settings.view_library_width + settings.view_sheets_width);
            editor_notes_pane.add (sheets_pane);
            editor_notes_pane.add (notes);
            notes.add (notes_widget);
            notes.set_reveal_child (false);

            desktop_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
            desktop_box.add (toolbar);
            desktop_box.add (editor_notes_pane);
            desktop_box.add (stats_bar);

            hide_titlebar_when_maximized = true;
            is_fullscreen = settings.fullscreen;

            set_default_size (settings.window_width, settings.window_height);
            add (desktop_box);
            show_all ();
            library.expand_all ();
            library.set_active ();
        }

        private void build_mobile () {
            var settings = AppSettings.get_default ();

            if (mobile_box != null) {
                return;
            }

            settings.view_state = 0;
            UI.show_view ();

            if (desktop_box != null) {
                debug ("Deconstructing desktop UI");
                sheets_pane.remove (library_pane);
                sheets_pane.remove (SheetManager.get_view ());
                editor_notes_pane.remove (notes);
                editor_notes_pane.remove (sheets_pane);
                notes.remove (notes_widget);

                desktop_box.remove (toolbar);
                desktop_box.remove (editor_notes_pane);
                desktop_box.remove (stats_bar);

                remove (desktop_box);
                desktop_box = null;
            }

            am_mobile = true;
            debug ("Building mobile UI");
            create_widgets ();

            mobile_search = new SearchWidget ();

            mobile_stack = new Gtk.Stack ();
            mobile_stack.add_titled (library_pane, _("Library"), _("Library"));
            mobile_stack.add_titled (SheetManager.get_view (), _("Editor"), _("Editor"));
            mobile_stack.add_titled (mobile_search, _("Search"), _("Search"));
            mobile_stack.add_titled (notes_widget, _("Notes"), _("Notes"));

            mobile_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
            mobile_box.add (toolbar);
            mobile_box.add (mobile_stack);
            mobile_box.add (stats_bar);

            add (mobile_box);
            show_all ();
            library.expand_all ();
            library.set_active ();
        }

        protected void build_ui () {
            var settings = AppSettings.get_default ();
            desktop_box = null;
            mobile_box = null;

            start_dir = "";
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

            //
            // Get screen size to see if we should start in mobile mode
            //

            var monitor = Gdk.Display.get_default ().get_primary_monitor ();
            int screen_width = settings.window_width;
            if (monitor != null) {
                Gdk.Rectangle screen_size = monitor.get_workarea ();
                screen_width = screen_size.width;
                debug ("Screen (%d, %d)", screen_size.width, screen_size.height);
                if (screen_size.width <= 600 || screen_size.height <= 600) {
                    mobile_mode = true;
                    am_mobile = true;
                }
            }

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

            if  (screen_width < 600) {
                build_mobile ();
            } else {
                if (settings.window_width >= 600) {
                    build_desktop ();
                } else {
                    build_mobile ();
                }
                set_default_size (settings.window_width, settings.window_height);
            }

            size_allocate.connect (() => {
                if (this.get_allocated_width () < 600 && !am_mobile) {
                    if (rebuild_ui.trylock ()) {
                        debug ("Switching to mobile");
                        build_mobile ();
                        UI.set_sheets (start_sheet);
                        rebuild_ui.unlock ();
                    }
                } else if (this.get_allocated_width () >= 600 && am_mobile) {
                    if (rebuild_ui.trylock ()) {
                        debug ("Switching to desktop");
                        build_desktop ();
                        UI.set_sheets (start_sheet);
                        rebuild_ui.unlock ();
                    }
                }
            });

            // Restore preview view
            UI.show_view ();
            UI.set_sheets (start_sheet);
            library.expand_all ();
            UI.load_user_themes_and_connections ();
            UI.load_font ();
            UI.load_css_scheme ();

            destroy.connect (() => {
                SheetManager.save_active ();
                notes_widget.save_notes ();
                foreach (var c in _instance.connections) {
                    c.connection_close ();
                }
            });

            // Go go go!
            ready = true;
            show_all ();
        }

        public void save_pane_position () {
            if (!mobile_mode) {
                var settings = AppSettings.get_default ();
                if (settings.view_library_width != library_pane.get_position ()) {
                    settings.view_library_width = library_pane.get_position ();
                }

                if (settings.view_library_width + settings.view_sheets_width != sheets_pane.get_position ()) {
                    settings.view_sheets_width = sheets_pane.get_position () - settings.view_library_width;
                }
            }
        }
    }
}