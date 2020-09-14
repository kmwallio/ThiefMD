/*
* Copyright (c) 2017 Lains
*
* Modified July 6, 2018 for use in ThiefMD
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public
* License as published by the Free Software Foundation; either
* version 2 of the License, or (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
* General Public License for more details.
*
* You should have received a copy of the GNU General Public
* License along with this program; if not, write to the
* Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
* Boston, MA 02110-1301 USA
*/

using ThiefMD;
using ThiefMD.Controllers;

namespace ThiefMD.Widgets {
    public class KeyBindings { 
        public KeyBindings (Gtk.Window window) {
            window.key_press_event.connect ((e) => {
                uint keycode = e.hardware_keycode;
                var settings = AppSettings.get_default ();
                var instance = ThiefApp.get_instance ();

                // Quit
                if ((e.state & Gdk.ModifierType.CONTROL_MASK) != 0) {
                    if (match_keycode (Gdk.Key.q, keycode)) {
                        window.destroy ();
                    }
                }

                // New Sheet
                if ((e.state & Gdk.ModifierType.CONTROL_MASK) != 0) {
                    if (match_keycode (Gdk.Key.n, keycode)) {
                        Widgets.Headerbar.get_instance ().make_new_sheet ();
                    }
                }

                // Save
                if ((e.state & Gdk.ModifierType.CONTROL_MASK) != 0) {
                    if (match_keycode (Gdk.Key.s, keycode)) {
                        try {
                            FileManager.save_work_file ();
                        } catch (Error e) {
                            warning ("Unexpected error during open: " + e.message);
                        }
                    }
                }

                // Preview
                if ((e.state & Gdk.ModifierType.CONTROL_MASK) != 0) {
                    if (match_keycode (Gdk.Key.p, keycode)) {
                        PreviewWindow pvw = PreviewWindow.get_instance ();
                        pvw.show_all ();
                    }
                }

                // Preferences
                if ((e.state & Gdk.ModifierType.CONTROL_MASK) != 0) {
                    if (match_keycode (Gdk.Key.comma, keycode)) {
                        Preferences prf = new Preferences();
                        prf.run();
                    }
                }

                // Undo
                if ((e.state & Gdk.ModifierType.CONTROL_MASK) != 0) {
                    if (match_keycode (Gdk.Key.z, keycode)) {
                        Widgets.Editor.buffer.undo ();
                    }
                }

                // Redo
                if ((e.state & Gdk.ModifierType.CONTROL_MASK + Gdk.ModifierType.SHIFT_MASK) != 0) {
                    if (match_keycode (Gdk.Key.z, keycode)) {
                        Widgets.Editor.buffer.redo ();
                    }
                }

                // Editor Mode
                if ((e.state & Gdk.ModifierType.CONTROL_MASK) != 0) {
                    if (match_keycode (Gdk.Key.@1, keycode)) {
                        settings.view_state = 2;
                        UI.show_view ();
                    }
                }

                // Sheets + Editor Mode
                if ((e.state & Gdk.ModifierType.CONTROL_MASK) != 0) {
                    if (match_keycode (Gdk.Key.@2, keycode)) {
                        settings.view_state = 1;
                        UI.show_view ();
                    }
                }

                // Library + Sheets + Editor Mode
                if ((e.state & Gdk.ModifierType.CONTROL_MASK) != 0) {
                    if (match_keycode (Gdk.Key.@3, keycode)) {
                        settings.view_state = 0;
                        UI.show_view ();
                    }
                }

                // Fullscreen
                if (match_keycode (Gdk.Key.F11, keycode)) {
                    settings.fullscreen = !settings.fullscreen;
                }

                if (match_keycode (Gdk.Key.Escape, keycode)) {
                    if (settings.fullscreen) {
                        settings.fullscreen = false;
                    }
                }

                return false;
            });
        }

        protected bool match_keycode (uint keyval, uint code) {
            Gdk.KeymapKey [] keys;
            Gdk.Keymap keymap = Gdk.Keymap.get_for_display (Gdk.Display.get_default ());
            if (keymap.get_entries_for_keyval (keyval, out keys)) {
                foreach (var key in keys) {
                    if (code == key.keycode)
                        return true;
                    }
                }

            return false;
        }
    }
}