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
        public Hdy.Leaflet main_content;
        public Hdy.Leaflet library_pane;
        public Gtk.ScrolledWindow library_view;
        public SearchBar search_bar;
        public StatisticsBar stats_bar;
        public Controllers.Exporters exporters;
        public Gee.ConcurrentList<Connections.ConnectionBase> connections;
        public bool ready = false;
        public Gtk.Revealer notes;
        public Gtk.Box editor_notes_pane;
        public Notes notes_widget;
        public bool show_touch_friendly = true;
        public SearchWidget search_widget;
        private MouseMotionListener mouse_listener;

        private string start_dir;
        private Gtk.Box desktop_box;
        private Sheets start_sheet;
        private Mutex rebuild_ui;

        public ThiefApp (Gtk.Application app) {
            Object (application: app);
            _instance = this;
            rebuild_ui = Mutex ();
            add_events (Gdk.EventMask.POINTER_MOTION_MASK);
            build_ui ();
        }

        public static ThiefApp get_instance () {
            return _instance;
        }

        public int pane_position {
            get {
                var settings = AppSettings.get_default ();
                return settings.view_library_width + settings.view_sheets_width;
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

        public void show_search () {
            if (search_widget != null) {
                return;
            }
            search_widget = new SearchWidget ();
            search_widget.show_all ();
            library_pane.add (search_widget);
            library_pane.set_visible_child (search_widget);
            main_content.set_visible_child (library_pane);
        }

        public void hide_search () {
            if (search_widget == null) {
                return;
            }
            search_widget.searcher.searching = false;
            library_pane.remove (search_widget);
            search_widget = null;
        }

        private void create_widgets () {
            if (ready) {
                return;
            }
            search_widget = null;
            var settings = AppSettings.get_default ();
            toolbar = new Headerbar (this);
            // Have to init search bar before sheet manager
            search_bar = new SearchBar ();
            SheetManager.init ();
            library = new Library ();
            notes_widget = new Notes ();
            var notes_context = notes_widget.get_style_context ();
            notes_context.add_class ("thief-notes");

            library_pane = new Hdy.Leaflet ();
            library_pane.transition_type = Hdy.LeafletTransitionType.SLIDE;
            library_pane.set_homogeneous (true, Gtk.Orientation.HORIZONTAL, false);
            library_pane.set_orientation (Gtk.Orientation.HORIZONTAL);
            library_view = new Gtk.ScrolledWindow (null, null);
            library_view.set_policy(Gtk.PolicyType.EXTERNAL, Gtk.PolicyType.AUTOMATIC);
            editor_notes_pane = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
            notes = new Gtk.Revealer ();
            notes.set_transition_type (Gtk.RevealerTransitionType.SLIDE_LEFT);
            notes.set_reveal_child (false);
            main_content = new Hdy.Leaflet ();
            main_content.transition_type = Hdy.LeafletTransitionType.SLIDE;
            main_content.set_homogeneous (true, Gtk.Orientation.HORIZONTAL, false);
            main_content.set_orientation (Gtk.Orientation.HORIZONTAL);

            library_view.add (library);
            library_view.width_request = settings.view_library_width;
            stats_bar = new StatisticsBar ();
            start_sheet = library.get_sheets (start_dir);
            library_pane.add (library_view);
            library_view.show_all ();
            start_sheet.width_request = settings.view_sheets_width;
            library_pane.add (start_sheet);
            library_pane.show_all ();
            var toolbar_context = toolbar.get_style_context ();
            toolbar_context.add_class("thiefmd-toolbar");
        }

        private void create_window () {
            var settings = AppSettings.get_default ();
            debug ("Building desktop UI");

            main_content.add (library_pane);
            library_pane.width_request = settings.view_library_width + settings.view_sheets_width;
            main_content.add (SheetManager.get_view ());
            editor_notes_pane.add (main_content);
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
        }

        protected void build_ui () {
            var settings = AppSettings.get_default ();
            desktop_box = null;

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

            create_widgets ();
            create_window ();

            settings.changed.connect (() => {
                is_fullscreen = settings.fullscreen;
            });

            new KeyBindings (this);
            // KeyBindings doesn't refer to itself, so losing the reference is fine.
            // MouseMotionListener has members to keep state, so reference needs to
            // be kept or variables will be freed.
            mouse_listener = new MouseMotionListener (this);

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
            exporters.register (_("Fountain"), new Exporters.ExportFountain ());

            // Load connections
            connections = new Gee.ConcurrentList<Connections.ConnectionBase> ();

            // Restore preview view
            UI.show_view ();
            UI.set_sheets (start_sheet);
            library.expand_all ();
            library.set_active ();
            UI.load_user_themes_and_connections ();
            UI.load_font ();
            UI.load_css_scheme ();

            Timeout.add (350, () => {
                if (!ready) {
                    return false;
                }
                if (main_content.folded) {
                    show_touch_friendly = true;
                    library_pane.hexpand = true;
                    library.hexpand = true;
                    library_view.hexpand = true;
                    UI.widen_sheets ();
                    settings.changed ();
                } else {
                    show_touch_friendly = false;
                    library_pane.hexpand = false;
                    library.hexpand = false;
                    library_view.hexpand = false;
                    library.width_request = settings.view_library_width;
                    UI.shrink_sheets ();
                    settings.changed ();
                }
                return false;
            });

            size_allocate.connect (() => {
                if (!ready) {
                    return;
                }
                if (main_content.folded && !show_touch_friendly) {
                    show_touch_friendly = true;
                    library_pane.hexpand = true;
                    library.hexpand = true;
                    library_view.hexpand = true;
                    UI.widen_sheets ();
                    settings.changed ();
                } else if (!main_content.folded && show_touch_friendly) {
                    show_touch_friendly = false;
                    library_pane.hexpand = false;
                    library.hexpand = false;
                    library_view.hexpand = false;
                    library.width_request = settings.view_library_width;
                    UI.shrink_sheets ();
                    settings.changed ();
                }
            });

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
    }
}