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
using Adw;

namespace ThiefMD {
    public class ThiefApp : Adw.ApplicationWindow {
        private static ThiefApp _instance;
        private static bool am_hidden = false;
        public Headerbar toolbar;
        public Library library;
        public Gtk.Paned main_content;
        public Gtk.Stack library_pane;
        public Gtk.Paned library_split;
        public Gtk.ScrolledWindow library_view;
        public SearchBar search_bar;
        public StatisticsBar stats_bar;
        public Controllers.Exporters exporters;
        public Gee.ConcurrentList<Connections.ConnectionBase> connections;
        public bool ready = false;
        public Gtk.Revealer notes;
        public Gtk.Box main_window_horizon_box;
        public Gtk.Box editor_widgets;
        public Gtk.Box editor_notes_widget;
        public Gtk.Box library_box;
        public Notes notes_widget;
        public bool show_touch_friendly = true;
        public SearchWidget search_widget;
        private MouseMotionListener mouse_listener;

        private string start_dir;
        private Gtk.Box desktop_box;
        private Sheets start_sheet;
        private Mutex rebuild_ui;
        private bool updating_sizes = false;
        private bool suppress_position_save = false;
        private int last_library_position = -1;
        private int last_main_position = -1;

        public void set_library_split_position_silent (int pos) {
            suppress_position_save = true;
            library_split.set_position (pos);
            suppress_position_save = false;
        }

        public void set_main_position_silent (int pos) {
            suppress_position_save = true;
            main_content.set_position (pos);
            suppress_position_save = false;
        }

        public ThiefApp (Gtk.Application app) {
            Object (application: app);
            _instance = this;
            rebuild_ui = Mutex ();
            build_ui ();
        }

        public static ThiefApp get_instance () {
            return _instance;
        }

        public static void hide_main_instance () {
            if (_instance != null) {
                am_hidden = true;
                _instance.hide ();
            }
        }

        public static void show_main_instance () {
            if (_instance != null) {
                am_hidden = false;
                _instance.show ();
                _instance.present ();
            }
        }

        public static bool main_instance_hidden () {
            if (_instance != null) {
                return am_hidden;
            }

            return false;
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
            library_pane.add_named (search_widget, "search");
            library_pane.set_visible_child (search_widget);
            library_pane.show ();
            set_main_position_silent (pane_position);
        }

        public void hide_search () {
            if (search_widget == null) {
                return;
            }
            search_widget.searcher.searching = false;
            library_pane.remove (search_widget);
            library_pane.set_visible_child (library_split);
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

            library_pane = new Gtk.Stack ();
            library_view = new Gtk.ScrolledWindow ();
            library_view.set_policy(Gtk.PolicyType.AUTOMATIC, Gtk.PolicyType.AUTOMATIC);
            main_window_horizon_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
            notes = new Gtk.Revealer ();
            notes.set_transition_type (Gtk.RevealerTransitionType.SLIDE_LEFT);
            notes.set_reveal_child (false);
            main_content = new Gtk.Paned (Gtk.Orientation.HORIZONTAL);
            main_content.hexpand = true;
            main_content.vexpand = true;

            library_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
            var library_header = new Adw.HeaderBar ();
            library_header.set_show_start_title_buttons (false);
            library_header.set_show_end_title_buttons (false);

            var library_title = new Gtk.Label (_("Library"));
            library_title.halign = Gtk.Align.START;
            library_title.hexpand = true;
            library_title.xalign = 0;
            library_header.set_title_widget (library_title);

            var add_library_button = new Gtk.Button ();
            add_library_button.has_tooltip = true;
            add_library_button.tooltip_text = (_("Add Folder to Library"));
            add_library_button.set_icon_name ("folder-new-symbolic");
            add_library_button.clicked.connect (() => {
                settings.menu_active = true;
                string new_lib = Dialogs.select_folder_dialog ();
                if (FileUtils.test(new_lib, FileTest.IS_DIR)) {
                    if (settings.add_to_library (new_lib)) {
                        // Refresh
                        ThiefApp instance = ThiefApp.get_instance ();
                        instance.refresh_library ();
                    }
                }
                settings.menu_active = false;
            });

            library_header.pack_end (add_library_button);

            var library_header_context = library_header.get_style_context ();
            library_header_context.add_class ("thiefmd-toolbar");

            library_box.append (library_header);
            library_box.append (library_view);
            library.vexpand = true;
            library.hexpand = true;

            editor_widgets = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
            editor_widgets.hexpand = true;
            editor_widgets.vexpand = true;
            editor_notes_widget = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
            editor_notes_widget.hexpand = true;
            editor_notes_widget.vexpand = true;

            library_view.set_child (library);
            library_box.width_request = settings.view_library_width;
            library_view.width_request = settings.view_library_width;
            stats_bar = new StatisticsBar ();
            start_sheet = library.get_sheets (start_dir);
            start_sheet.width_request = settings.view_sheets_width;
            library_split = new Gtk.Paned (Gtk.Orientation.HORIZONTAL);
            library_split.hexpand = true;
            library_split.vexpand = true;
            library_split.set_shrink_start_child (true);
            library_split.set_shrink_end_child (true);
            library_split.set_resize_start_child (true);
            library_split.set_resize_end_child (true);
            library_split.set_start_child (library_box);
            library_split.set_end_child (start_sheet);
            set_library_split_position_silent (settings.view_library_width);

            library_pane.add_named (library_split, "library");
            library_pane.set_visible_child (library_split);

            library_split.notify["position"].connect (() => {
                if (!ready) {
                    return;
                }
                if (updating_sizes) {
                    return;
                }
                if (suppress_position_save) {
                    return;
                }
                int current_pos = library_split.position;
                if (current_pos == last_library_position) {
                    return;
                }
                updating_sizes = true;
                var s = AppSettings.get_default ();

                int stack_width = library_split.get_allocated_width ();
                if (stack_width <= 0) {
                    updating_sizes = false;
                    return;
                }

                int new_library_width = current_pos;
                if (new_library_width < 50) {
                    new_library_width = 50;
                }

                int max_library_width = stack_width - 50;
                if (max_library_width < 50) {
                    max_library_width = 50;
                }

                if (new_library_width > max_library_width) {
                    new_library_width = max_library_width;
                }

                int sheets_width = stack_width - new_library_width;
                if (sheets_width < 50) {
                    sheets_width = 50;
                }

                s.view_library_width = new_library_width;
                s.view_sheets_width = sheets_width;
                last_library_position = new_library_width;
                updating_sizes = false;
            });
            var toolbar_context = toolbar.get_style_context ();
            toolbar_context.add_class("thiefmd-toolbar");
        }

        private void create_window () {
            var settings = AppSettings.get_default ();
            debug ("Building desktop UI");

            main_content.set_shrink_start_child (true);
            main_content.set_shrink_end_child (true);
            main_content.set_resize_start_child (true);
            main_content.set_resize_end_child (true);
            main_content.set_start_child (library_pane);
            editor_widgets.append (toolbar);
            editor_notes_widget.append (SheetManager.get_view ());
            editor_notes_widget.append (notes);
            editor_widgets.append (editor_notes_widget);
            main_content.set_end_child (editor_widgets);
            set_main_position_silent (settings.view_library_width + settings.view_sheets_width);
            last_main_position = main_content.position;
            main_content.notify["position"].connect (() => {
                if (!ready) {
                    return;
                }
                if (updating_sizes) {
                    return;
                }
                if (suppress_position_save) {
                    return;
                }
                int current_pos = main_content.position;
                if (current_pos == last_main_position) {
                    return;
                }
                updating_sizes = true;
                var s = AppSettings.get_default ();
                int left_width = current_pos;
                if (left_width < 100) {
                    left_width = 100;
                }

                int lib_width = library_split.position;
                if (lib_width < 50) {
                    lib_width = 50;
                }

                int max_lib = left_width - 50;
                if (max_lib < 50) {
                    max_lib = 50;
                }

                if (lib_width > max_lib) {
                    lib_width = max_lib;
                }

                int sheets_width = left_width - lib_width;
                if (sheets_width < 50) {
                    sheets_width = 50;
                }

                s.view_library_width = lib_width;
                s.view_sheets_width = sheets_width;
                last_main_position = current_pos;
                updating_sizes = false;
            });
            main_window_horizon_box.append (main_content);
            notes.set_child (notes_widget);
            notes.set_reveal_child (false);

            desktop_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
            desktop_box.append (main_window_horizon_box);
            desktop_box.append (stats_bar);

            is_fullscreen = settings.fullscreen;

            set_default_size (settings.window_width, settings.window_height);
            set_content (desktop_box);
            show ();
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
            set_icon_name ("com.github.kmwallio.thiefmd");

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
                settings.changed ();
                return false;
            });

            show_touch_friendly = false;

            close_request.connect (() => {
                bool can_close = ThiefApplication.close_window (this);
                debug ("Can close (%u): %s", ThiefApplication.active_window_count (), can_close ? "Yes" : "No");
                if (!can_close) {
                    am_hidden = true;
                    debug ("Hiding instead of closing");
                    hide ();
                    return true;
                }
                SheetManager.save_active ();
                notes_widget.save_notes ();
                foreach (var c in _instance.connections) {
                    c.connection_close ();
                }
                ThiefApplication.exit ();
                return false;
            });

            // Go go go!
            ready = true;
            show ();
        }
    }
}