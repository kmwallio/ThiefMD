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
using ThiefMD.Controllers;

namespace ThiefMD.Widgets {
    public class Headerbar : Gtk.Box {
        private Gtk.Revealer revealer;
        private Adw.HeaderBar the_bar;
        private Adw.WindowTitle window_title;
        private ThiefApp _instance;
        private Gtk.Button change_view_button;
        private Gtk.MenuButton menu_button;
        private Gtk.Button sidebar_button;
        private Gtk.Label spacer;

        public Headerbar (ThiefApp instance) {
            Object (orientation: Gtk.Orientation.VERTICAL, spacing: 0);

            revealer = new Gtk.Revealer ();
            the_bar = new Adw.HeaderBar ();
            _instance = instance;
            var header_context = the_bar.get_style_context ();
            header_context.add_class ("thief-toolbar");

            header_context = revealer.get_style_context ();
            header_context.add_class ("thief-toolbar");

            build_ui ();
        }

        public bool hidden {
            get {
                return !revealer.child_revealed;
            }
        }

        public void toggle_headerbar () {
            if (revealer.child_revealed) {
                hide_headerbar ();
            } else {
                show_headerbar ();
            }
        }

        public void hide_headerbar () {
            var settings = AppSettings.get_default ();
            if (settings.hide_toolbar) {
                if (revealer.child_revealed) {
                    revealer.set_reveal_child (false);
                }
            }
        }

        public void show_headerbar () {
            if (!revealer.child_revealed) {
                revealer.set_reveal_child (true);
            }
        }

        private void build_ui () {
            var settings = AppSettings.get_default ();
            change_view_button = new Gtk.Button ();
            change_view_button.has_tooltip = true;
            change_view_button.tooltip_text = (_("Change View"));
            change_view_button.set_icon_name ("sidebar-show-symbolic");
            change_view_button.clicked.connect (() => {
                UI.toggle_view();
            });


            //  search_button = new Gtk.Button ();
            //  search_button.has_tooltip = true;
            //  search_button.tooltip_text = (_("Search"));
            //  search_button.set_image (new Gtk.Image.from_icon_name ("edit-find", Gtk.IconSize.LARGE_TOOLBAR));

            menu_button = new Gtk.MenuButton ();
            menu_button.has_tooltip = true;
            menu_button.tooltip_text = (_("Settings"));
            menu_button.set_icon_name ("open-menu-symbolic");
            var prefs_popover = new QuickPreferences (_instance);
            menu_button.set_popover (prefs_popover);
            prefs_popover.notify["visible"].connect (() => {
                settings.menu_active = prefs_popover.get_visible ();
            });
            prefs_popover.closed.connect (() => {
                settings.menu_active = false;
            });

            sidebar_button = new Gtk.Button ();
            sidebar_button.has_tooltip = true;
            sidebar_button.tooltip_text = (_("Show Notes"));
            sidebar_button.set_icon_name ("sidebar-show-right-symbolic");
            sidebar_button.clicked.connect (() => {
                if (!ThiefApp.get_instance ().notes.child_revealed) {
                    ThiefApp.get_instance ().notes_widget.show ();
                }
                ThiefApp.get_instance ().notes.set_reveal_child (!ThiefApp.get_instance ().notes.child_revealed);
                Timeout.add (ThiefApp.get_instance ().notes.get_transition_duration () + 15, () => {
                    SheetManager.update_margins ();
                    return false;
                });
            });

            window_title = new Adw.WindowTitle ("", "");
            the_bar.set_title_widget (window_title);

            the_bar.pack_start (change_view_button);

            the_bar.pack_end (sidebar_button);
            the_bar.pack_end (menu_button);

            the_bar.set_show_end_title_buttons (true);
            the_bar.set_show_start_title_buttons (true);
            settings.changed.connect (update_header);
            update_header ();
            revealer.set_child (the_bar);
            revealer.set_reveal_child (true);
            append (revealer);
        }

        public void update_header () {
            var settings = AppSettings.get_default ();

            if (!settings.brandless) {
                if (settings.show_filename && settings.last_file != "") {
                    string file_name = settings.last_file.substring(settings.last_file.last_index_of (Path.DIR_SEPARATOR_S) + 1);
                    window_title.set_title ("ThiefMD");
                    File lf = File.new_for_path (settings.last_file);
                    if (lf.query_exists ()) {
                        window_title.set_subtitle (file_name);
                    } else {
                        window_title.set_subtitle ("");
                    }
                } else {
                    window_title.set_title ("ThiefMD");
                    window_title.set_subtitle ("");
                }
            } else {
                window_title.set_title ("");
                window_title.set_subtitle ("");
            }

            if (ThiefApp.get_instance ().ready) {
                if (!settings.hide_toolbar) {
                    show_headerbar ();
                }
            }
        }
    }
}
