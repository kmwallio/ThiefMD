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
    public class KeyBindings : Object { 
        private bool is_fullscreen = false;
        public KeyBindings (Gtk.Window window, bool is_main = true) {
            window.key_press_event.connect ((e) => {
                uint keycode = e.hardware_keycode;
                var settings = AppSettings.get_default ();

                // Quit
                if ((e.state & Gdk.ModifierType.CONTROL_MASK) != 0 && (e.state & Gdk.ModifierType.SHIFT_MASK) == 0) {
                    if (match_keycode (Gdk.Key.q, keycode)) {
                        window.destroy ();
                    }
                }

                // Search
                if ((e.state & Gdk.ModifierType.CONTROL_MASK) != 0 && (e.state & Gdk.ModifierType.SHIFT_MASK) == 0 && is_main) {
                    if (match_keycode (Gdk.Key.f, keycode)) {
                        ThiefApp.get_instance ().search_bar.toggle_search ();
                    }
                }

                // Experimental Mode
                if ((e.state & Gdk.ModifierType.CONTROL_MASK) != 0 && (e.state & Gdk.ModifierType.SHIFT_MASK) != 0 && (window is ThiefApp || window is SoloEditor)) {
                    if (match_keycode (Gdk.Key.m, keycode)) {
                        settings.experimental = !settings.experimental;
                    }
                }

                // Headerbar
                if ((e.state & Gdk.ModifierType.CONTROL_MASK) != 0 && (e.state & Gdk.ModifierType.SHIFT_MASK) != 0 && is_main) {
                    if (match_keycode (Gdk.Key.h, keycode)) {
                        settings.hide_toolbar = !settings.hide_toolbar;
                        if (settings.hide_toolbar) {
                            ThiefApp.get_instance ().toolbar.hide_headerbar ();
                        } else {
                            ThiefApp.get_instance ().toolbar.show_headerbar ();
                        }
                    }
                }

                // Global search
                if ((e.state & Gdk.ModifierType.CONTROL_MASK) != 0 && (e.state & Gdk.ModifierType.SHIFT_MASK) != 0) {
                    if (match_keycode (Gdk.Key.f, keycode)) {
                        SearchWindow search = new SearchWindow ();
                        search.show_all ();
                    }
                }

                // Cheat Sheet
                if ((e.state & Gdk.ModifierType.CONTROL_MASK) != 0 && (e.state & Gdk.ModifierType.SHIFT_MASK) == 0) {
                    if (match_keycode (Gdk.Key.h, keycode)) {
                        MarkdownCheatSheet cheat_sheet = new MarkdownCheatSheet ();
                        cheat_sheet.show_all ();
                    }
                }
                if ((e.state & Gdk.ModifierType.CONTROL_MASK) != 0 && (e.state & Gdk.ModifierType.SHIFT_MASK) != 0) {
                    if (match_keycode (Gdk.Key.question, keycode)) {
                        MarkdownCheatSheet cheat_sheet = new MarkdownCheatSheet ();
                        cheat_sheet.show_all ();
                    }
                }

                // Preview
                if ((e.state & Gdk.ModifierType.CONTROL_MASK) != 0 && (e.state & Gdk.ModifierType.SHIFT_MASK) != 0 && (window is ThiefApp || window is SoloEditor)) {
                    if (match_keycode (Gdk.Key.p, keycode)) {
                        if (window is ThiefApp) {
                            PreviewWindow pvw = PreviewWindow.get_instance ();
                            pvw.show_all ();
                        } else {
                            ((SoloEditor)window).toggle_preview ();
                        }
                    }
                }

                // Focus
                if ((e.state & Gdk.ModifierType.CONTROL_MASK) != 0 && (e.state & Gdk.ModifierType.SHIFT_MASK) != 0 && (window is ThiefApp || window is SoloEditor)) {
                    if (match_keycode (Gdk.Key.r, keycode)) {
                        settings.focus_mode = !settings.focus_mode;
                    }
                }

                // Type-writer scrolling
                if ((e.state & Gdk.ModifierType.CONTROL_MASK) != 0 && (e.state & Gdk.ModifierType.SHIFT_MASK) != 0) {
                    if (match_keycode (Gdk.Key.t, keycode)) {
                        settings.typewriter_scrolling = !settings.typewriter_scrolling;
                    }
                }

                // Write-Good Suggestions
                if ((e.state & Gdk.ModifierType.CONTROL_MASK) != 0 && (e.state & Gdk.ModifierType.SHIFT_MASK) != 0 && (window is ThiefApp || window is SoloEditor)) {
                    if (match_keycode (Gdk.Key.w, keycode)) {
                        settings.writegood = !settings.writegood;
                    }
                }

                // New Sheet
                if ((e.state & Gdk.ModifierType.CONTROL_MASK) != 0 && (e.state & Gdk.ModifierType.SHIFT_MASK) == 0 && is_main) {
                    if (match_keycode (Gdk.Key.n, keycode)) {
                        if (window is ThiefApp) {
                            ((ThiefApp)window).toolbar.make_new_sheet ();
                        }
                    }
                }

                // Bold
                if ((e.state & Gdk.ModifierType.CONTROL_MASK) != 0 && (e.state & Gdk.ModifierType.SHIFT_MASK) == 0 && (window is ThiefApp || window is SoloEditor)) {
                    if (match_keycode (Gdk.Key.b, keycode)) {
                        if (window is ThiefApp) {
                            SheetManager.bold ();
                        } else {
                            ((SoloEditor)window).editor.bold ();
                        }
                        return true;
                    }
                }

                // Italic
                if ((e.state & Gdk.ModifierType.CONTROL_MASK) != 0 && (e.state & Gdk.ModifierType.SHIFT_MASK) == 0 && (window is ThiefApp || window is SoloEditor)) {
                    if (match_keycode (Gdk.Key.i, keycode)) {
                        if (window is ThiefApp) {
                            SheetManager.italic ();
                        } else {
                            ((SoloEditor)window).editor.italic ();
                        }
                        return true;
                    }
                }

                // Strikethrough
                if ((e.state & Gdk.ModifierType.CONTROL_MASK) != 0 && (e.state & Gdk.ModifierType.SHIFT_MASK) == 0 && (window is ThiefApp || window is SoloEditor)) {
                    if (match_keycode (Gdk.Key.d, keycode)) {
                        if (window is ThiefApp) {
                            SheetManager.strikethrough ();
                        } else {
                            ((SoloEditor)window).editor.strikethrough ();
                        }
                        return true;
                    }
                }

                // Link
                if ((e.state & Gdk.ModifierType.CONTROL_MASK) != 0 && (e.state & Gdk.ModifierType.SHIFT_MASK) == 0 && (window is ThiefApp || window is SoloEditor)) {
                    if (match_keycode (Gdk.Key.k, keycode)) {
                        if (window is ThiefApp) {
                            SheetManager.link ();
                        } else {
                            ((SoloEditor)window).editor.link ();
                        }
                        return true;
                    }
                }

                // Shrink font
                if ((e.state & Gdk.ModifierType.CONTROL_MASK) != 0 && (e.state & Gdk.ModifierType.SHIFT_MASK) == 0 && (window is ThiefApp || window is SoloEditor)) {
                    if (match_keycode (Gdk.Key.minus, keycode)) {
                        int next_font_size = settings.font_size - 2;
                        if (next_font_size >= 6) {
                            settings.font_size = next_font_size;
                            UI.load_font ();
                        }
                    }
                }

                // Enlarge font
                if ((e.state & Gdk.ModifierType.CONTROL_MASK) != 0 && (window is ThiefApp || window is SoloEditor)) {
                    if (match_keycode (Gdk.Key.plus, keycode)) {
                        int next_font_size = settings.font_size + 2;
                        if (next_font_size <= 512) {
                            settings.font_size = next_font_size;
                            UI.load_font ();
                        }
                    }
                }

                // Save
                if ((e.state & Gdk.ModifierType.CONTROL_MASK) != 0 && (e.state & Gdk.ModifierType.SHIFT_MASK) == 0) {
                    if (match_keycode (Gdk.Key.s, keycode)) {
                        SheetManager.save_active ();
                        if (window is SoloEditor) {
                            ((SoloEditor)window).editor.save ();
                        }
                    }
                }

                // Toggle statistics bar
                if ((e.state & Gdk.ModifierType.CONTROL_MASK) != 0 && (e.state & Gdk.ModifierType.SHIFT_MASK) != 0 && (window is ThiefApp || window is SoloEditor)) {
                    if (match_keycode (Gdk.Key.s, keycode)) {
                        if (window is ThiefApp) {
                            ((ThiefApp)window).stats_bar.toggle_statistics ();
                        }
                    }
                }

                // Toggle Dark/Light theme
                if ((e.state & Gdk.ModifierType.CONTROL_MASK) != 0 && (e.state & Gdk.ModifierType.SHIFT_MASK) != 0 && (window is ThiefApp || window is SoloEditor)) {
                    if (match_keycode (Gdk.Key.l, keycode)) {
                        if (settings.theme_id != "thiefmd") {
                            settings.dark_mode = !settings.dark_mode;
                            settings.theme_id = settings.theme_id.substring (0, settings.theme_id.last_index_of_char ('-')) +  ((settings.dark_mode) ? "-dark" : "-light");
                            UI.load_css_scheme ();
                            SheetManager.refresh_scheme ();
                            if (window is SoloEditor) {
                                ((SoloEditor)window).editor.set_scheme (settings.theme_id);
                            }
                        }
                    }
                }

                // Preferences
                if ((e.state & Gdk.ModifierType.CONTROL_MASK) != 0 && (e.state & Gdk.ModifierType.SHIFT_MASK) == 0) {
                    if (match_keycode (Gdk.Key.comma, keycode)) {
                        Preferences prf = new Preferences();
                        prf.show_all ();
                    }
                }

                // Undo
                if ((e.state & Gdk.ModifierType.CONTROL_MASK) != 0 && (e.state & Gdk.ModifierType.SHIFT_MASK) == 0 && (window is ThiefApp || window is SoloEditor)) {
                    if (match_keycode (Gdk.Key.z, keycode)) {
                        if (window is ThiefApp) {
                            SheetManager.undo ();
                        } else {
                            ((SoloEditor)window).editor.undo ();
                        }
                        return true;
                    }
                }

                // Redo
                if ((e.state & Gdk.ModifierType.CONTROL_MASK & Gdk.ModifierType.SHIFT_MASK) != 0 && (window is ThiefApp || window is SoloEditor)) {
                    if (match_keycode (Gdk.Key.z, keycode)) {
                        if (window is ThiefApp) {
                            SheetManager.redo ();
                        } else {
                            ((SoloEditor)window).editor.redo ();
                        }
                        return true;
                    }
                }

                // Editor Mode
                if ((e.state & Gdk.ModifierType.CONTROL_MASK) != 0 && (e.state & Gdk.ModifierType.SHIFT_MASK) == 0 && is_main) {
                    if (match_keycode (Gdk.Key.@1, keycode)) {
                        if (window is ThiefApp) {
                            settings.view_state = 2;
                            UI.show_view ();
                        }
                    }
                }

                // Sheets + Editor Mode
                if ((e.state & Gdk.ModifierType.CONTROL_MASK) != 0 && (e.state & Gdk.ModifierType.SHIFT_MASK) == 0 && is_main) {
                    if (match_keycode (Gdk.Key.@2, keycode)) {
                        if (window is ThiefApp) {
                            settings.view_state = 1;
                            UI.show_view ();
                        }
                    }
                }

                // Library + Sheets + Editor Mode
                if ((e.state & Gdk.ModifierType.CONTROL_MASK) != 0 && (e.state & Gdk.ModifierType.SHIFT_MASK) == 0 && is_main) {
                    if (match_keycode (Gdk.Key.@3, keycode)) {
                        if (window is ThiefApp) {
                            settings.view_state = 0;
                            UI.show_view ();
                        }
                    }
                }

                // Fullscreen
                if (match_keycode (Gdk.Key.F11, keycode)) {
                    if (is_main) {
                        settings.fullscreen = !settings.fullscreen;
                    } else {
                        if (!is_fullscreen) {
                            window.fullscreen ();
                            is_fullscreen = true;
                            return true;
                        } else {
                            window.unfullscreen ();
                            is_fullscreen = false;
                            return true;
                        }
                    }
                }

                if (match_keycode (Gdk.Key.Escape, keycode)) {
                    if (is_main) {
                        if (window is ThiefApp) {
                            if (((ThiefApp)window).search_bar.should_escape_search ()) {
                                ((ThiefApp)window).search_bar.deactivate_search ();
                            } else if (settings.fullscreen) {
                                settings.fullscreen = false;
                            }
                        }
                    } else {
                        window.unfullscreen ();
                        is_fullscreen = false;
                        return true;
                    }
                }

                return false;
            });
        }
    }
}