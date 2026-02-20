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
        private static Gtk.Window main_window = null;
        private static List<Gtk.Window> important_windows = new List<Gtk.Window> ();
        public ThiefApplication () {
            Object (
                application_id: "com.github.kmwallio.thiefmd",
                flags: ApplicationFlags.HANDLES_OPEN
            );
        }

        protected override void activate () {
            var settings = AppSettings.get_default ();
            settings.validate_library ();
            var projects = settings.library ();

            if (main_window == null) {
                main_window = this.active_window;
                main_window = new ThiefApp (this);
            }

            if (projects.length > 0) {
                dismiss_welcome_windows ();
                ThiefApp.show_main_instance ();
            } else {
                ThiefApp.hide_main_instance ();
                var welcome_win = new WelcomeWindow ();
                important_windows.append (welcome_win);
                welcome_win.present ();
            }
        }

        private static void dismiss_welcome_windows () {
            var welcome_windows = new List<Gtk.Window> ();
            foreach (var win in important_windows) {
                if (win is WelcomeWindow) {
                    welcome_windows.append (win);
                }
            }

            foreach (var win in welcome_windows) {
                win.close ();
            }
        }

        public static void open_file (File file) {
            foreach (var win in important_windows) {
                if (win is SoloEditor) {
                    var w = (SoloEditor)win;
                    if (w.already_opened (file)) {
                        w.present ();
                        warning ("Already opened");
                        return;
                    }
                }
            }
            var solo_win = new SoloEditor (file);
            important_windows.append (solo_win);
            solo_win.present ();
        }

        public static SoloEditor? get_solo (File file) {
            foreach (var win in important_windows) {
                if (win is SoloEditor) {
                    var w = (SoloEditor)win;
                    if (w.already_opened (file)) {
                        return w;
                    }
                }
            }

            return null;
        }

        public override void open (File[] files, string hint) {
            var settings = AppSettings.get_default ();

            // Start library hidden
            if (main_window == null) {
                main_window = new ThiefApp (this);
                ThiefApp.hide_main_instance ();
            }

            bool library_updated = false;

            foreach (var file in files) {
                if (file.query_exists ()) {
                    if (file.query_file_type (FileQueryInfoFlags.NONE, null) == FileType.DIRECTORY) {
                        string? directory_path = file.get_path ();
                        if (directory_path != null && settings.add_to_library (directory_path)) {
                            library_updated = true;
                        }
                    } else {
                        dismiss_welcome_windows ();
                        open_file (file);
                    }
                }
            }

            if (library_updated) {
                ThiefApp instance = ThiefApp.get_instance ();
                instance.refresh_library ();
                dismiss_welcome_windows ();
                ThiefApp.show_main_instance ();
            }
        }

        public static bool close_window (Gtk.Window win) {
            debug ("Open Files: %u", important_windows.length ());
            if (win is ThiefApp && important_windows.length () > 0) {
                ThiefApp.hide_main_instance ();
                debug ("Hide main window");
                return false;
            } else if (win is ThiefApp && important_windows.length () == 0) {
                debug ("Close main window");
                return true;
            }

            important_windows.remove (win);
            debug ("Closing solo window");
            if (important_windows.length () == 0 && ThiefApp.get_instance () != null && ThiefApp.main_instance_hidden ()) {
                ThiefApp.get_instance ().close ();
            }
            return true;
        }

        public static uint active_window_count () {
            return important_windows.length ();
        }

        public static void exit () {
            debug ("Calling exit");
            foreach (var win in important_windows) {
                win.close ();
            }

            if (main_window != null) {
                main_window.close ();
            }
        }

        public static int main (string[] args) {
            Intl.setlocale (LocaleCategory.ALL, "");
            Intl.bind_textdomain_codeset (Build.GETTEXT_PACKAGE, "UTF-8");
            Intl.textdomain (Build.GETTEXT_PACKAGE);
            Intl.bindtextdomain (Build.GETTEXT_PACKAGE, Build.PACKAGE_LOCALEDIR);
            
            var app = new ThiefApplication ();
            app.startup.connect (() => {
                Adw.init ();
                Spelling.init ();
            });
            return app.run (args);
        }
    }
}
