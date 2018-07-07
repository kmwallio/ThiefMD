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

                return true;
            });
        }

        protected bool match_keycode (int keyval, uint code) {
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