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
        private Gtk.Window window;
        private bool is_main;
        private GLib.SimpleActionGroup action_group;
        private Gtk.ShortcutController shortcut_controller;

        public KeyBindings (Gtk.Window window, bool is_main = true) {
            this.window = window;
            this.is_main = is_main;
            this.action_group = new GLib.SimpleActionGroup ();
            this.shortcut_controller = new Gtk.ShortcutController ();
            
            setup_actions ();
            setup_shortcuts ();
            
            ((Gtk.Widget) window).insert_action_group ("keybindings", action_group);
            ((Gtk.Widget) window).add_controller (shortcut_controller);
        }

        private void setup_actions () {
            // Quit
            add_simple_action ("quit", () => {
                window.destroy ();
            });

            // Search
            add_simple_action ("search", () => {
                if (is_main) {
                    ThiefApp.get_instance ().search_bar.toggle_search ();
                }
            });

            // Experimental Mode
            add_simple_action ("experimental", () => {
                var settings = AppSettings.get_default ();
                if (window is ThiefApp || window is SoloEditor) {
                    settings.experimental = !settings.experimental;
                }
            });

            // Headerbar
            add_simple_action ("toggle-headerbar", () => {
                var settings = AppSettings.get_default ();
                if (is_main) {
                    settings.hide_toolbar = !settings.hide_toolbar;
                    if (settings.hide_toolbar) {
                        ThiefApp.get_instance ().toolbar.hide_headerbar ();
                    } else {
                        ThiefApp.get_instance ().toolbar.show_headerbar ();
                    }
                }
            });

            // Global search
            add_simple_action ("global-search", () => {
                if (is_main) {
                    SearchWindow search = new SearchWindow ();
                    search.present ();
                }
            });

            // Cheat Sheet
            add_simple_action ("cheat-sheet", () => {
                MarkdownCheatSheet cheat_sheet = new MarkdownCheatSheet ();
                cheat_sheet.present ();
            });

            // Preview
            add_simple_action ("preview", () => {
                if (window is ThiefApp || window is SoloEditor) {
                    if (window is ThiefApp) {
                        PreviewWindow pvw = PreviewWindow.get_instance ();
                        pvw.present ();
                    } else {
                        ((SoloEditor)window).toggle_preview ();
                    }
                }
            });

            // Focus mode
            add_simple_action ("focus-mode", () => {
                var settings = AppSettings.get_default ();
                if (window is ThiefApp || window is SoloEditor) {
                    settings.focus_mode = !settings.focus_mode;
                }
            });

            // Type-writer scrolling
            add_simple_action ("typewriter-scrolling", () => {
                var settings = AppSettings.get_default ();
                settings.typewriter_scrolling = !settings.typewriter_scrolling;
            });

            // Write-Good Suggestions
            add_simple_action ("writegood", () => {
                var settings = AppSettings.get_default ();
                if (window is ThiefApp || window is SoloEditor) {
                    settings.writegood = !settings.writegood;
                }
            });

            // New Sheet
            add_simple_action ("new-sheet", () => {
                if (is_main && window is ThiefApp) {
                    SheetManager.get_sheets ().make_new_sheet ();
                }
            });

            // Bold
            add_simple_action ("bold", () => {
                if (window is ThiefApp || window is SoloEditor) {
                    if (window is ThiefApp) {
                        SheetManager.bold ();
                    } else {
                        ((SoloEditor)window).editor.bold ();
                    }
                }
            });

            // Italic
            add_simple_action ("italic", () => {
                if (window is ThiefApp || window is SoloEditor) {
                    if (window is ThiefApp) {
                        SheetManager.italic ();
                    } else {
                        ((SoloEditor)window).editor.italic ();
                    }
                }
            });

            // Strikethrough
            add_simple_action ("strikethrough", () => {
                if (window is ThiefApp || window is SoloEditor) {
                    if (window is ThiefApp) {
                        SheetManager.strikethrough ();
                    } else {
                        ((SoloEditor)window).editor.strikethrough ();
                    }
                }
            });

            // Link
            add_simple_action ("link", () => {
                if (window is ThiefApp || window is SoloEditor) {
                    if (window is ThiefApp) {
                        SheetManager.link ();
                    } else {
                        ((SoloEditor)window).editor.link ();
                    }
                }
            });

            // Shrink font
            add_simple_action ("shrink-font", () => {
                var settings = AppSettings.get_default ();
                if (window is ThiefApp || window is SoloEditor) {
                    int next_font_size = settings.font_size - 2;
                    if (next_font_size >= 6) {
                        settings.font_size = next_font_size;
                        UI.load_font ();
                    }
                }
            });

            // Enlarge font
            add_simple_action ("enlarge-font", () => {
                var settings = AppSettings.get_default ();
                if (window is ThiefApp || window is SoloEditor) {
                    int next_font_size = settings.font_size + 2;
                    if (next_font_size <= 512) {
                        settings.font_size = next_font_size;
                        UI.load_font ();
                    }
                }
            });

            // Save
            add_simple_action ("save", () => {
                SheetManager.save_active ();
                if (window is SoloEditor) {
                    ((SoloEditor)window).editor.save ();
                }
            });

            // Toggle statistics bar
            add_simple_action ("toggle-statistics", () => {
                if (window is ThiefApp) {
                    ((ThiefApp)window).stats_bar.toggle_statistics ();
                }
            });

            // Toggle Dark/Light theme
            add_simple_action ("toggle-theme", () => {
                var settings = AppSettings.get_default ();
                if (window is ThiefApp || window is SoloEditor) {
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
            });

            // Preferences
            add_simple_action ("preferences", () => {
                Preferences prf = new Preferences();
                prf.present ();
            });

            // Undo
            add_simple_action ("undo", () => {
                if (window is ThiefApp || window is SoloEditor) {
                    if (window is ThiefApp) {
                        SheetManager.undo ();
                    } else {
                        ((SoloEditor)window).editor.undo ();
                    }
                }
            });

            // Redo
            add_simple_action ("redo", () => {
                if (window is ThiefApp || window is SoloEditor) {
                    if (window is ThiefApp) {
                        SheetManager.redo ();
                    } else {
                        ((SoloEditor)window).editor.redo ();
                    }
                }
            });

            // Editor Mode
            add_simple_action ("editor-mode", () => {
                var settings = AppSettings.get_default ();
                if (is_main && window is ThiefApp) {
                    settings.view_state = 2;
                    UI.show_view ();
                }
            });

            // Sheets + Editor Mode
            add_simple_action ("sheets-editor-mode", () => {
                var settings = AppSettings.get_default ();
                if (is_main && window is ThiefApp) {
                    settings.view_state = 1;
                    UI.show_view ();
                }
            });

            // Library + Sheets + Editor Mode
            add_simple_action ("library-mode", () => {
                var settings = AppSettings.get_default ();
                if (is_main && window is ThiefApp) {
                    settings.view_state = 0;
                    UI.show_view ();
                }
            });

            // Fullscreen
            add_simple_action ("fullscreen", () => {
                if (is_main) {
                    var settings = AppSettings.get_default ();
                    settings.fullscreen = !settings.fullscreen;
                } else {
                    if (!is_fullscreen) {
                        window.fullscreen ();
                        is_fullscreen = true;
                    } else {
                        window.unfullscreen ();
                        is_fullscreen = false;
                    }
                }
            });

            // Escape
            add_simple_action ("escape", () => {
                if (is_main) {
                    if (window is ThiefApp) {
                        var settings = AppSettings.get_default ();
                        if (((ThiefApp)window).search_bar.should_escape_search ()) {
                            ((ThiefApp)window).search_bar.deactivate_search ();
                        } else if (settings.fullscreen) {
                            settings.fullscreen = false;
                        }
                    }
                } else {
                    window.unfullscreen ();
                    is_fullscreen = false;
                }
            });

            // Next Marker (Heading/Scene)
            add_simple_action ("next-marker", () => {
                if (window is ThiefApp || window is SoloEditor) {
                    if (window is ThiefApp) {
                        SheetManager.next_marker ();
                    } else {
                        ((SoloEditor)window).editor.next_marker ();
                    }
                }
            });

            // Previous Marker (Heading/Scene)
            add_simple_action ("prev-marker", () => {
                if (window is ThiefApp || window is SoloEditor) {
                    if (window is ThiefApp) {
                        SheetManager.prev_marker ();
                    } else {
                        ((SoloEditor)window).editor.prev_marker ();
                    }
                }
            });
        }

        private void setup_shortcuts () {
            // Ctrl+Q - Quit
            add_shortcut ("<Primary>q", "keybindings.quit");
            
            // Ctrl+F - Search
            add_shortcut ("<Primary>f", "keybindings.search");
            
            // Ctrl+Shift+M - Experimental Mode
            add_shortcut ("<Primary><Shift>m", "keybindings.experimental");
            
            // Ctrl+Shift+H - Toggle Headerbar
            add_shortcut ("<Primary><Shift>h", "keybindings.toggle-headerbar");
            
            // Ctrl+Shift+F - Global search
            add_shortcut ("<Primary><Shift>f", "keybindings.global-search");
            
            // Ctrl+H - Cheat Sheet
            add_shortcut ("<Primary>h", "keybindings.cheat-sheet");
            
            // Ctrl+Shift+? - Cheat Sheet (alternate)
            add_shortcut ("<Primary><Shift>question", "keybindings.cheat-sheet");
            
            // Ctrl+Shift+P - Preview
            add_shortcut ("<Primary><Shift>p", "keybindings.preview");
            
            // Ctrl+Shift+R - Focus Mode
            add_shortcut ("<Primary><Shift>r", "keybindings.focus-mode");
            
            // Ctrl+Shift+T - Typewriter Scrolling
            add_shortcut ("<Primary><Shift>t", "keybindings.typewriter-scrolling");
            
            // Ctrl+Shift+W - Write Good
            add_shortcut ("<Primary><Shift>w", "keybindings.writegood");
            
            // Ctrl+N - New Sheet
            add_shortcut ("<Primary>n", "keybindings.new-sheet");
            
            // Ctrl+B - Bold
            add_shortcut ("<Primary>b", "keybindings.bold");
            
            // Ctrl+I - Italic
            add_shortcut ("<Primary>i", "keybindings.italic");
            
            // Ctrl+D - Strikethrough
            add_shortcut ("<Primary>d", "keybindings.strikethrough");
            
            // Ctrl+K - Link
            add_shortcut ("<Primary>k", "keybindings.link");
            
            // Ctrl+- - Shrink Font
            add_shortcut ("<Primary>minus", "keybindings.shrink-font");
            
            // Ctrl++ - Enlarge Font
            add_shortcut ("<Primary>plus", "keybindings.enlarge-font");
            add_shortcut ("<Primary>equal", "keybindings.enlarge-font");
            
            // Ctrl+S - Save
            add_shortcut ("<Primary>s", "keybindings.save");
            
            // Ctrl+Shift+S - Toggle Statistics
            add_shortcut ("<Primary><Shift>s", "keybindings.toggle-statistics");
            
            // Ctrl+Shift+L - Toggle Theme
            add_shortcut ("<Primary><Shift>l", "keybindings.toggle-theme");
            
            // Ctrl+, - Preferences
            add_shortcut ("<Primary>comma", "keybindings.preferences");
            
            // Ctrl+Z - Undo
            add_shortcut ("<Primary>z", "keybindings.undo");
            
            // Ctrl+Shift+Z - Redo
            add_shortcut ("<Primary><Shift>z", "keybindings.redo");
            
            // Ctrl+1 - Editor Mode
            add_shortcut ("<Primary>1", "keybindings.editor-mode");
            
            // Ctrl+2 - Sheets + Editor Mode
            add_shortcut ("<Primary>2", "keybindings.sheets-editor-mode");
            
            // Ctrl+3 - Library Mode
            add_shortcut ("<Primary>3", "keybindings.library-mode");
            
            // F11 - Fullscreen
            add_shortcut ("F11", "keybindings.fullscreen");

            // Escape
            add_shortcut ("Escape", "keybindings.escape");

            // Ctrl+[ - Previous Marker (Heading/Scene)
            add_shortcut ("<Primary>bracketleft", "keybindings.prev-marker");

            // Ctrl+] - Next Marker (Heading/Scene)
            add_shortcut ("<Primary>bracketright", "keybindings.next-marker");
        }

        private void add_simple_action (string name, owned SimpleActionFunc func) {
            var action = new GLib.SimpleAction (name, null);
            action.activate.connect ((parameter) => {
                func ();
            });
            action_group.add_action (action);
        }

        private void add_shortcut (string shortcut_string, string action_name) {
            var trigger = Gtk.ShortcutTrigger.parse_string (shortcut_string);
            if (trigger == null) {
                warning ("Could not parse shortcut: %s", shortcut_string);
                return;
            }
            
            var action = new Gtk.NamedAction (action_name);
            var shortcut = new Gtk.Shortcut (trigger, action);
            shortcut_controller.add_shortcut (shortcut);
        }
    }

    public delegate void SimpleActionFunc ();
}
