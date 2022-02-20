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
                        app.set_accels_for_action ("app.preferences", { "<Primary>comma" });
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

                        // Edit Menu
                        GLib.Menu edit_menu = new Menu ();
                        // Search
                        edit_menu.append (_("Search"), "app.search-file");
                        var toggle_search = new SimpleAction ("search-file", null);
                        toggle_search.activate.connect (() => {
                            ThiefApp.get_instance ().search_bar.toggle_search ();
                        });
                        app.add_action (toggle_search);
                        app.set_accels_for_action ("app.search-file", { "<Primary>F" });
                        // Search All
                        edit_menu.append (_("Search Library"), "app.search-lib");
                        var toggle_lib_search = new SimpleAction ("search-lib", null);
                        toggle_lib_search.activate.connect (() => {
                            SearchWindow search = new SearchWindow ();
                            search.show_all ();
                        });
                        app.add_action (toggle_lib_search);
                        app.set_accels_for_action ("app.search-lib", { "<Primary><Shift>F" });
                        // Text Formatting
                        {
                            GLib.Menu formatting_section = new Menu ();
                            formatting_section.append (_("Bold"), "app.format-bold");
                            var format_bold = new SimpleAction ("format-bold", null);
                            format_bold.activate.connect (() => {
                                SheetManager.bold ();
                            });
                            app.add_action (format_bold);
                            app.set_accels_for_action ("app.format-bold", { "<Primary>B" });

                            formatting_section.append (_("Italic"), "app.format-italic");
                            var format_italic = new SimpleAction ("format-italic", null);
                            format_italic.activate.connect (() => {
                                SheetManager.italic ();
                            });
                            app.add_action (format_italic);
                            app.set_accels_for_action ("app.format-italic", { "<Primary>I" });

                            formatting_section.append (_("Strikethrough"), "app.format-delete");
                            var format_delete = new SimpleAction ("format-delete", null);
                            format_delete.activate.connect (() => {
                                SheetManager.strikethrough ();
                            });
                            app.add_action (format_delete);
                            app.set_accels_for_action ("app.format-delete", { "<Primary>D" });

                            formatting_section.append (_("Link"), "app.format-link");
                            var format_link = new SimpleAction ("format-link", null);
                            format_link.activate.connect (() => {
                                SheetManager.link ();
                            });
                            app.add_action (format_link);
                            app.set_accels_for_action ("app.format-link", { "<Primary>K" });

                            edit_menu.append_section ("Formatting Options", formatting_section);
                        }

                        menu_bar.append_submenu (_("Edit"), edit_menu);

                        // View Menu
                        GLib.Menu view_menu = new Menu ();
                        // Spell
                        view_menu.append (_("Toggle Spellcheck"), "app.toggle-spell");
                        var toggle_spell = new SimpleAction ("toggle-spell", null);
                        toggle_spell.activate.connect (() => {
                            settings.spellcheck = !settings.spellcheck;
                        });
                        app.add_action (toggle_spell);
                        // Spell
                        view_menu.append (_("Toggle Grammar Check"), "app.toggle-grammar");
                        var toggle_grammar = new SimpleAction ("toggle-grammar", null);
                        toggle_grammar.activate.connect (() => {
                            settings.grammar = !settings.grammar ;
                        });
                        app.add_action (toggle_grammar);
                        // Write Good
                        view_menu.append (_("Toggle Write-Good"), "app.toggle-writegood");
                        var toggle_wg = new SimpleAction ("toggle-writegood", null);
                        toggle_wg.activate.connect (() => {
                            settings.writegood = !settings.writegood;
                        });
                        app.add_action (toggle_wg);
                        app.set_accels_for_action ("app.toggle-writegood", { "<Primary><Shift>W" });
                        // Focus
                        {
                            GLib.Menu focus_section = new Menu ();
                            focus_section.append (_("Toggle Focus"), "app.toggle-focus");
                            var toggle_focus = new SimpleAction ("toggle-focus", null);
                            toggle_focus.activate.connect (() => {
                                settings.focus_mode = !settings.focus_mode;
                            });
                            app.add_action (toggle_focus);
                            app.set_accels_for_action ("app.toggle-focus", { "<Primary><Shift>R" });

                            focus_section.append (" - " + _("Word Focus"), "app.toggle-word-focus");
                            var toggle_word_focus = new SimpleAction ("toggle-word-focus", null);
                            toggle_word_focus.activate.connect (() => {
                                settings.focus_type = FocusType.WORD;
                                settings.focus_mode = true;
                            });
                            app.add_action (toggle_word_focus);

                            focus_section.append (" - " + _("Senctence Focus"), "app.toggle-sentence-focus");
                            var toggle_sen_focus = new SimpleAction ("toggle-sentence-focus", null);
                            toggle_sen_focus.activate.connect (() => {
                                settings.focus_type = FocusType.SENTENCE;
                                settings.focus_mode = true;
                            });
                            app.add_action (toggle_sen_focus);

                            focus_section.append (" - " + _("Paragraph Focus"), "app.toggle-paragraph-focus");
                            var toggle_paragraph_focus = new SimpleAction ("toggle-paragraph-focus", null);
                            toggle_paragraph_focus.activate.connect (() => {
                                settings.focus_type = FocusType.PARAGRAPH;
                                settings.focus_mode = true;
                            });
                            app.add_action (toggle_paragraph_focus);

                            view_menu.append_section ("Focus Options", focus_section);
                        }
                        {
                            GLib.Menu type_section = new Menu ();
                            // TypeWriter
                            type_section.append (_("Toggle Typewriter Scrolling"), "app.toggle-type");
                            var toggle_type = new SimpleAction ("toggle-type", null);
                            toggle_type.activate.connect (() => {
                                settings.typewriter_scrolling = !settings.typewriter_scrolling;
                            });
                            app.add_action (toggle_type);
                            app.set_accels_for_action ("app.toggle-type", { "<Primary><Shift>T" });

                            // Enlarge Font
                            type_section.append (_("Increase Font Size"), "app.font-increase");
                            var font_increase = new SimpleAction ("font-increase", null);
                            font_increase.activate.connect (() => {
                                int next_font_size = settings.font_size + 2;
                                if (next_font_size <= 512) {
                                    settings.font_size = next_font_size;
                                    UI.load_font ();
                                }
                            });
                            app.add_action (font_increase);
                            app.set_accels_for_action ("app.font-increase", { "<Primary>plus" });

                            // Shrink Font
                            type_section.append (_("Decrease Font Size"), "app.font-decrease");
                            var font_decrease = new SimpleAction ("font-decrease", null);
                            font_decrease.activate.connect (() => {
                                int next_font_size = settings.font_size - 2;
                                if (next_font_size >= 6) {
                                    settings.font_size = next_font_size;
                                    UI.load_font ();
                                }
                            });
                            app.add_action (font_decrease);
                            app.set_accels_for_action ("app.font-decrease", { "<Primary>minus" });

                            view_menu.append_section ("Scroll Options", type_section);
                        }
                        {
                            GLib.Menu ui_section = new Menu ();
                            // Headerbar
                            ui_section.append (_("Toggle Toolbar"), "app.toggle-header");
                            var toggle_header= new SimpleAction ("toggle-header", null);
                            toggle_header.activate.connect (() => {
                                settings.hide_toolbar = !settings.hide_toolbar;
                                if (settings.hide_toolbar) {
                                    ThiefApp.get_instance ().toolbar.hide_headerbar ();
                                } else {
                                    ThiefApp.get_instance ().toolbar.show_headerbar ();
                                }
                            });
                            app.add_action (toggle_header);
                            app.set_accels_for_action ("app.toggle-header", { "<Primary><Shift>H" });

                            // Editor Only
                            ui_section.append (_("Show Editor Only"), "app.show-editor");
                            var show_editor = new SimpleAction ("show-editor", null);
                            show_editor.activate.connect (() => {
                                settings.view_state = 2;
                                UI.show_view ();
                            });
                            app.add_action (show_editor);
                            app.set_accels_for_action ("app.show-editor", { "<Primary>1" });
                            // Project+Editor
                            ui_section.append (_("Show Project + Editor"), "app.show-project");
                            var show_project = new SimpleAction ("show-project", null);
                            show_project.activate.connect (() => {
                                settings.view_state = 1;
                                UI.show_view ();
                            });
                            app.add_action (show_project);
                            app.set_accels_for_action ("app.show-project", { "<Primary>2" });
                            // Library+Project+Editor
                            ui_section.append (_("Show Library"), "app.show-library");
                            var show_library = new SimpleAction ("show-library", null);
                            show_library.activate.connect (() => {
                                settings.view_state = 0;
                                UI.show_view ();
                            });
                            app.add_action (show_library);
                            app.set_accels_for_action ("app.show-library", { "<Primary>3" });

                            view_menu.append_section ("UI Options", ui_section);
                        }
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
