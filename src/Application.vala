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
                this.add_window (window);
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

                /* Try Menu Stuff? */
                {
                    {
                        var settings = AppSettings.get_default ();
                        GLib.Menu app_menu = new Menu ();

                        // About
                        GLib.Menu about_section = new Menu ();
                        about_section.append (_("About ThiefMD"), "app.about");
                        var about = new SimpleAction ("about", null);
                        about.activate.connect (() => {
                            About abt = new About();
                            abt.run ();
                        });
                        app.add_action (about);
                        app_menu.append_section (_("About"), about_section);

                        // Preferences
                        GLib.Menu pref_section = new Menu ();
                        pref_section.append (_("Preferences"), "app.preferences");
                        var preferences = new SimpleAction ("preferences", null);
                        preferences.activate.connect (() => {
                            Preferences prf = new Preferences();
                            prf.show_all ();
                        });
                        app.add_action (preferences);
                        app.set_accels_for_action ("app.preferences", { "<Primary><Comma>" });
                        app_menu.append_section (_("Settings"), pref_section);

                        // Quit
                        GLib.Menu quit_section = new Menu ();
                        quit_section.append (_("Quit"), "app.quit");
                        var quit = new SimpleAction ("quit", null);
                        quit.activate.connect (() => {
                            unowned var windows = app.get_windows ();
                            foreach (var window in windows) {
                                app.remove_window (window);
                            }
                        });
                        app.add_action (quit);
                        app.set_accels_for_action ("app.quit", { "<Primary>Q" });
                        app_menu.append_section (_("Exit"), quit_section);

                        GLib.Menu menu_bar = new Menu ();

                        // File Menu
                        GLib.Menu file_menu = new Menu ();
                        file_menu.append (_("New File"), "app.new-file");
                        var new_file = new SimpleAction ("new-file", null);
                        new_file.activate.connect (() => {
                            unowned var windows = app.get_windows ();
                            foreach (var window in windows) {
                                if (window is ThiefApp) {
                                    ((ThiefApp)window).toolbar.make_new_sheet ();
                                    break;
                                }
                            }
                        });
                        app.add_action (new_file);
                        app.set_accels_for_action ("app.new-file", { "<Primary>N" });

                        file_menu.append (_("Add to Library"), "app.add-library");
                        var add_library = new SimpleAction ("add-library", null);
                        add_library.activate.connect (() => {
                            add_folder_to_library ();
                        });
                        app.add_action (add_library);
                        menu_bar.append_submenu (_("File"), file_menu);

                        // View Menu
                        GLib.Menu view_menu = new Menu ();
                        // Spell
                        view_menu.append (_("Toggle Spellcheck"), "app.toggle-spell");
                        var toggle_spell = new SimpleAction ("toggle-spell", null);
                        toggle_spell.activate.connect (() => {
                            settings.spellcheck = !settings.spellcheck;
                        });
                        app.add_action (toggle_spell);
                        // Write Good
                        view_menu.append (_("Toggle Write-Good"), "app.toggle-writegood");
                        var toggle_wg = new SimpleAction ("toggle-writegood", null);
                        toggle_wg.activate.connect (() => {
                            settings.writegood = !settings.writegood;
                        });
                        app.add_action (toggle_wg);
                        app.set_accels_for_action ("app.toggle-writegood", { "<Primary><Shift>W" });
                        // Focus
                        view_menu.append (_("Toggle Focus"), "app.toggle-focus");
                        var toggle_focus = new SimpleAction ("toggle-focus", null);
                        toggle_focus.activate.connect (() => {
                            settings.focus_mode = !settings.focus_mode;
                        });
                        app.add_action (toggle_focus);
                        app.set_accels_for_action ("app.toggle-focus", { "<Primary><Shift>R" });
                        // TypeWriter
                        view_menu.append (_("Toggle Typewriter Scrolling"), "app.toggle-type");
                        var toggle_type = new SimpleAction ("toggle-type", null);
                        toggle_type.activate.connect (() => {
                            settings.typewriter_scrolling = !settings.typewriter_scrolling;
                        });
                        app.add_action (toggle_type);
                        app.set_accels_for_action ("app.toggle-type", { "<Primary><Shift>T" });
                        menu_bar.append_submenu (_("View"), view_menu);

                        // Help Menu
                        GLib.Menu help_menu = new Menu ();
                        help_menu.append (_("Markdown Cheatsheet"), "app.markdown");
                        var cheat_sheet = new SimpleAction ("markdown", null);
                        cheat_sheet.activate.connect (() => {
                            MarkdownCheatSheet cs_win = new MarkdownCheatSheet ();
                            cs_win.show_all ();
                        });
                        app.add_action (cheat_sheet);
                        app.set_accels_for_action ("app.markdown", { "<Primary>H" });
                        menu_bar.append_submenu (_("Help"), help_menu);

                        app.set_app_menu (app_menu);
                        app.set_menubar (menu_bar);
                    }
                }
            });
            return app.run (args);
        }
    }
}
