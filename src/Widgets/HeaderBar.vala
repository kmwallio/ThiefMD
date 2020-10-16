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
    public class Headerbar : Gtk.Revealer {
        private Gtk.HeaderBar the_bar;
        private static Headerbar? instance = null;

        private Gtk.Button change_view_button;
        private Gtk.Button add_library_button;
        private Gtk.MenuButton new_sheet;
        private Gtk.MenuButton menu_button;
        private NewSheet new_sheet_widget;

        public Headerbar () {
            the_bar = new Gtk.HeaderBar ();
            var header_context = the_bar.get_style_context ();
            header_context.add_class (Gtk.STYLE_CLASS_FLAT);
            header_context.add_class ("thief-toolbar");

            header_context = this.get_style_context ();
            header_context.add_class (Gtk.STYLE_CLASS_FLAT);
            header_context.add_class ("thief-toolbar");

            build_ui ();
        }

        public bool hidden {
            get {
                return !child_revealed;
            }
        }

        public void make_new_sheet () {
            new_sheet_widget.popup ();
        }

        public static Headerbar get_instance () {
            if (instance == null) {
                instance = new Widgets.Headerbar ();
            }
    
            return instance;
        }

        public void toggle_headerbar () {
            if (child_revealed) {
                hide_headerbar ();
            } else {
                show_headerbar ();
            }
            this.show_all ();
        }

        public void hide_headerbar () {
            if (child_revealed) {
                set_reveal_child (false);
            }
        }

        public void show_headerbar () {
            if (!child_revealed) {
                set_reveal_child (true);
            }
        }

        private void build_ui () {
            var settings = AppSettings.get_default ();
            new_sheet = new Gtk.MenuButton ();
            new_sheet_widget = new NewSheet ();
            new_sheet.has_tooltip = true;
            new_sheet.tooltip_text = (_("New Sheet"));
            new_sheet.set_image (new Gtk.Image.from_icon_name ("document-new-symbolic", Gtk.IconSize.LARGE_TOOLBAR));
            new_sheet.popover = new_sheet_widget;
            new_sheet.clicked.connect(() => {
                settings.menu_active = true;
                new_sheet.popover.hide.connect (() => {
                    settings.menu_active = false;
                });
            });

            change_view_button = new Gtk.Button ();
            change_view_button.has_tooltip = true;
            change_view_button.tooltip_text = (_("Change View"));
            change_view_button.set_image (new Gtk.Image.from_icon_name("document-page-setup-symbolic", Gtk.IconSize.LARGE_TOOLBAR));
            change_view_button.clicked.connect (() => {
                UI.toggle_view();
            });

            add_library_button = new Gtk.Button ();
            add_library_button.has_tooltip = true;
            add_library_button.tooltip_text = (_("Add Folder to Library"));
            add_library_button.set_image (new Gtk.Image.from_icon_name ("folder-new-symbolic", Gtk.IconSize.LARGE_TOOLBAR));
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


            //  search_button = new Gtk.Button ();
            //  search_button.has_tooltip = true;
            //  search_button.tooltip_text = (_("Search"));
            //  search_button.set_image (new Gtk.Image.from_icon_name ("edit-find", Gtk.IconSize.LARGE_TOOLBAR));

            menu_button = new Gtk.MenuButton ();
            menu_button.has_tooltip = true;
            menu_button.tooltip_text = (_("Settings"));
            menu_button.set_image (new Gtk.Image.from_icon_name ("open-menu-symbolic", Gtk.IconSize.LARGE_TOOLBAR));
            menu_button.popover = new QuickPreferences ();
            menu_button.clicked.connect (() => {
                settings.menu_active = true;
                menu_button.popover.hide.connect (() => {
                    settings.menu_active = false;
                });
                menu_button.popover.destroy.connect (() => {
                    settings.menu_active = false;
                });
            });

            the_bar.pack_start (change_view_button);
            the_bar.pack_start (add_library_button);
            // @TODO: Need to find a better way to do this
            the_bar.pack_start (new Gtk.Label("                          "));
            the_bar.pack_start (new_sheet);

            the_bar.pack_end (menu_button);

            the_bar.set_show_close_button (true);
            settings.changed.connect (update_header);
            update_header ();
            the_bar.show_all ();
            add (the_bar);
            set_reveal_child (true);
            this.show_all ();
        }

        public void update_header () {
            var settings = AppSettings.get_default ();

            if (!settings.brandless) {
                if (settings.show_filename && settings.last_file != "") {
                    string file_name = settings.last_file.substring(settings.last_file.last_index_of (Path.DIR_SEPARATOR_S) + 1);
                    the_bar.set_title ("ThiefMD");
                    File lf = File.new_for_path (settings.last_file);
                    if (lf.query_exists ()) {
                        the_bar.set_subtitle (file_name);
                    } else {
                        the_bar.set_subtitle ("");
                    }
                } else {
                    the_bar.set_title ("ThiefMD");
                    the_bar.set_subtitle ("");
                }
            } else {
                the_bar.set_title ("");
                the_bar.set_subtitle ("");
            }
        }
    }
}
