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
    public class ThiefApplication : Gtk.Application {
        public ThiefApplication () {
            Object (
                application_id: "com.github.kmwallio.thiefmd",
                flags: ApplicationFlags.FLAGS_NONE
            );
        }

        protected override void activate () {
            var window = this.active_window;
            if (window == null) {
                window = new ThiefApp (this);
            }
            window.present ();
        }

        public static int main (string[] args) {
            Intl.setlocale (LocaleCategory.ALL, "");
            Intl.bind_textdomain_codeset (Build.GETTEXT_PACKAGE, "UTF-8");
            Intl.textdomain (Build.GETTEXT_PACKAGE);
            Intl.bindtextdomain (Build.GETTEXT_PACKAGE, Build.PACKAGE_LOCALEDIR);

            var app = new ThiefApplication ();
            app.startup.connect (() => {
                Hdy.init ();
                if (Build.HOST == "darwin") {
                    Gtk.OSXApplication osxApp = Gtk.OSXApplication.get_instance();
                    Gtk.MenuBar menushell = new Gtk.MenuBar ();

                    Gtk.MenuItem menu_file = new Gtk.MenuItem.with_label (_("File"));
                    Gtk.Menu file_menu = new Gtk.Menu ();
                    {
                        Gtk.MenuItem file_add_folder = new Gtk.MenuItem.with_label (_("Add Folder to Library"));
                        file_add_folder.activate.connect (() => {
                            add_folder_to_library ();
                        });
                        file_menu.add (file_add_folder);
                    }
                    menu_file.submenu = file_menu;
                    menushell.add (menu_file);

                    menushell.show_all ();

                    Gtk.MenuItem menu_about = new Gtk.MenuItem.with_label (_("About ThiefMD"));
                    menu_about.activate.connect (() => {
                        About abt = new About();
                    });
                    menu_about.show ();

                    osxApp.set_menu_bar (menushell);
                    osxApp.set_use_quartz_accelerators (true);
                    osxApp.set_about_item (menu_about);
                    osxApp.sync_menu_bar ();
                    osxApp.ready ();
                }
            });
            return app.run (args);
        }
    }
}
