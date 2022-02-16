/*
 * Copyright (C) 2020 kmwallio
 * 
 * Modified September 2, 2020
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
using Gtk;
using Gdk;


namespace ThiefMD.Widgets {
    public class Preferences : Hdy.PreferencesWindow {
        public Preferences () {
            build_ui ();
        }

        private void build_ui () {
            add (editor_grid ());
            add (display_grid ());

            search_enabled = false;
            show_all ();
        }

        private Hdy.PreferencesPage display_grid () {
            var settings = AppSettings.get_default ();
            Hdy.PreferencesPage page = new Hdy.PreferencesPage ();
            page.set_title (_("Display"));
            page.set_icon_name ("preferences-desktop-display-symbolic");

            Hdy.PreferencesGroup display_options = new Hdy.PreferencesGroup ();
            display_options.title = _("Display Options");
            display_options.description = _("Make ThiefMD feel like home.");

            ThiefFontSelector font_selector = new ThiefFontSelector ();
            display_options.add (font_selector);

            var focus = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 12);
            var focus_label = new Gtk.Label (_("Focus"));
            focus_label.use_markup = true;
            focus_label.xalign = 0;
            focus_label.margin = 12;
            var focus_selector = new Gtk.ComboBoxText ();
            focus_selector.append_text (_("None"));
            focus_selector.append_text (_("Paragraph"));
            focus_selector.append_text (_("Sentence"));
            focus_selector.append_text (_("Word"));
            focus.add (focus_label);
            focus.add (focus_selector);

            display_options.add (focus);

            if (settings.focus_mode) {
                focus_selector.set_active (settings.focus_type + 1);
            } else {
                focus_selector.set_active (0);
            }

            focus_selector.changed.connect (() => {
                int option = focus_selector.get_active ();
                if (option <= 0) {
                    settings.focus_mode = false;
                } else if (option == 1) {
                    settings.focus_type = FocusType.PARAGRAPH;
                    settings.focus_mode = true;
                } else if (option == 2) {
                    settings.focus_type = FocusType.SENTENCE;
                    settings.focus_mode = true;
                } else if (option == 3) {
                    settings.focus_type = FocusType.WORD;
                    settings.focus_mode = true;
                }
            });

            var num_preview_lines = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 12);
            var num_preview_lines_entry = new Gtk.SpinButton.with_range (0, 15, 1);
            num_preview_lines_entry.set_value (settings.num_preview_lines);
            num_preview_lines_entry.value_changed.connect (() => {
                int new_margin = (int)num_preview_lines_entry.get_value ();
                if (new_margin >= 0 && new_margin < 15) {
                    settings.num_preview_lines = new_margin;
                } else {
                    num_preview_lines_entry.set_value (settings.num_preview_lines);
                }
            });
            var num_preview_lines_label = new Label(_("Number of Lines to Preview in Sheets View"));
            num_preview_lines_label.xalign = 0;
            num_preview_lines_label.hexpand = true;
            num_preview_lines_label.margin = 12;
            num_preview_lines_label.set_line_wrap (true);
            num_preview_lines.add (num_preview_lines_entry);
            num_preview_lines.add (num_preview_lines_label);
            display_options.add (num_preview_lines);

            var add_theme_button = new Gtk.Button.with_label (_("Add New Theme"));
            add_theme_button.hexpand = true;
            display_options.add (add_theme_button);

            ThemeSelector theme_selector = new ThemeSelector ();
            display_options.add (theme_selector);

            add_theme_button.clicked.connect (() => {
                File new_theme = Dialogs.display_open_dialog ("*.ultheme");
                if (new_theme != null && new_theme.query_exists ()) {
                    try {
                        File destination = File.new_for_path (Path.build_filename (UserData.style_path, new_theme.get_basename ()));

                        if (destination.query_exists ()) {
                            // Possibly overwrite theme, but don't double draw widget
                            new_theme.copy (destination, FileCopyFlags.OVERWRITE);
                        }

                        new_theme.copy (destination, FileCopyFlags.OVERWRITE);
                        var new_styles = new Ultheme.Parser (destination);
                        UI.add_user_theme (new_styles);

                        ThemePreview dark_preview = new ThemePreview (new_styles, true);
                        ThemePreview light_preview = new ThemePreview (new_styles, false);

                        theme_selector.preview_items.add (dark_preview);
                        theme_selector.preview_items.add (light_preview);
                        theme_selector.preview_items.show_all ();
                        theme_selector.show_all ();
                    } catch (Error e) {
                        warning ("Failing generating preview: %s\n", e.message);
                    }
                }
            });

            page.add (display_options);

            return page;
        }

        private Hdy.PreferencesPage editor_grid () {
            var settings = AppSettings.get_default ();
            Hdy.PreferencesPage page = new Hdy.PreferencesPage ();
            page.set_title (_("Editor"));
            page.set_icon_name ("thiefmd-symbolic");

            Hdy.PreferencesGroup editor_options = new Hdy.PreferencesGroup ();
            editor_options.title = _("Editor Settings");
            editor_options.description = _("Modify the ThiefMD environment.");

            Gtk.Box spellcheck = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 12);
            var spellcheck_switch = new Switch ();
            spellcheck_switch.set_active (settings.spellcheck);
            spellcheck_switch.notify["active"].connect (() => {
                settings.spellcheck = spellcheck_switch.get_active ();
            });
            spellcheck_switch.tooltip_text = _("Enable spellcheck");
            spellcheck_switch.margin = 12;
            var spellcheck_label = new Label(_("Check document spelling"));
            spellcheck_label.xalign = 0;
            spellcheck_label.margin = 12;
            spellcheck_label.set_line_wrap (true);
            spellcheck.add (spellcheck_switch);
            spellcheck.add (spellcheck_label);
            editor_options.add (spellcheck);

            Gtk.Box writegood = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 12);
            var writegood_switch = new Switch ();
            writegood_switch.set_active (settings.writegood);
            writegood_switch.notify["active"].connect (() => {
                settings.writegood = writegood_switch.get_active ();
            });
            writegood_switch.tooltip_text = _("Enable Write-Good");
            writegood_switch.hexpand = false;
            writegood_switch.vexpand = false;
            writegood_switch.margin = 12;
            var writegood_label = new Label(_("Enable Write-Good: recommendations for sentence structure"));
            writegood_label.xalign = 0;
            writegood_label.margin = 12;
            writegood_label.set_line_wrap (true);
            writegood.add (writegood_switch);
            writegood.add (writegood_label);
            editor_options.add (writegood);

            var typewriter = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 12);
            var typewriter_switch = new Switch ();
            typewriter_switch.set_active (settings.typewriter_scrolling);
            typewriter_switch.notify["active"].connect (() => {
                settings.typewriter_scrolling = typewriter_switch.get_active ();
            });
            typewriter_switch.margin = 12;
            typewriter_switch.tooltip_text = _("Toggle typewriter scrolling");
            var typewriter_label = new Label(_("Enable typewriter focus mode"));
            typewriter_label.xalign = 0;
            typewriter_label.margin = 12;
            typewriter_label.set_line_wrap (true);
            typewriter.add (typewriter_switch);
            typewriter.add (typewriter_label);
            editor_options.add (typewriter);

            var ui_writing_statistics = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 12);
            var ui_writing_statistics_switch = new Switch ();
            ui_writing_statistics_switch.set_active (settings.show_writing_statistics);
            ui_writing_statistics_switch.notify["active"].connect (() => {
                settings.show_writing_statistics = ui_writing_statistics_switch.get_active ();
                if (settings.show_writing_statistics) {
                    ThiefApp.get_instance ().stats_bar.show_statistics ();
                } else {
                    ThiefApp.get_instance ().stats_bar.hide_statistics ();
                }
            });
            ui_writing_statistics_switch.margin = 12;
            ui_writing_statistics_switch.tooltip_text = _("Toggle writing statistics");
            var ui_writing_statistics_label = new Label(_("Show writing statistics"));
            ui_writing_statistics_label.xalign = 0;
            ui_writing_statistics_label.margin = 12;
            ui_writing_statistics_label.set_line_wrap (true);
            ui_writing_statistics.add (ui_writing_statistics_switch);
            ui_writing_statistics.add (ui_writing_statistics_label);
            editor_options.add (ui_writing_statistics);

            var ui_dont_show_tips = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 12);
            var ui_dont_show_tips_switch = new Switch ();
            ui_dont_show_tips_switch.set_active (settings.dont_show_tips);
            ui_dont_show_tips_switch.notify["active"].connect (() => {
                settings.dont_show_tips = ui_dont_show_tips_switch.get_active ();
            });
            ui_dont_show_tips_switch.margin = 12;
            ui_dont_show_tips_switch.tooltip_text = _("Disable application tips");
            var ui_dont_show_tips_label = new Label(_("Start with new empty sheet on launch"));
            ui_dont_show_tips_label.xalign = 0;
            ui_dont_show_tips_label.margin = 12;
            ui_dont_show_tips_label.set_line_wrap (true);
            ui_dont_show_tips.add (ui_dont_show_tips_switch);
            ui_dont_show_tips.add (ui_dont_show_tips_label);
            editor_options.add (ui_dont_show_tips);

            //
            // More UI-ish options
            //

            Hdy.PreferencesGroup thiefmd_options = new Hdy.PreferencesGroup ();
            thiefmd_options.title = _("ThiefMD Settings");
            thiefmd_options.description = _("Modify the ThiefMD appearance.");

            var ui_colorscheme = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 12);
            var ui_colorscheme_switch = new Switch ();
            ui_colorscheme_switch.set_active (settings.ui_editor_theme);
            ui_colorscheme_switch.notify["active"].connect (() => {
                settings.ui_editor_theme = ui_colorscheme_switch.get_active ();
                UI.load_css_scheme ();
            });
            ui_colorscheme_switch.margin = 12;
            ui_colorscheme_switch.tooltip_text = _("Toggle interface theming");
            var ui_colorscheme_label = new Label(_("Apply theme to interface"));
            ui_colorscheme_label.xalign = 0;
            ui_colorscheme_label.margin = 12;
            ui_colorscheme_label.set_line_wrap (true);
            ui_colorscheme.add (ui_colorscheme_switch);
            ui_colorscheme.add (ui_colorscheme_label);
            thiefmd_options.add (ui_colorscheme);

            var headerbar_opt = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 12);
            var headerbar_switch = new Switch ();
            headerbar_switch.set_active (settings.hide_toolbar);
            headerbar_switch.notify["active"].connect (() => {
                settings.hide_toolbar = headerbar_switch.get_active ();
                if (settings.hide_toolbar) {
                    ThiefApp.get_instance ().toolbar.hide_headerbar ();
                } else {
                    ThiefApp.get_instance ().toolbar.show_headerbar ();
                }
            });
            headerbar_switch.tooltip_text = _("Toggle auto-hide headerbar");
            headerbar_switch.margin = 12;
            var headerbar_label = new Label(_("Automatically hide headerbar"));
            headerbar_label.xalign = 0;
            headerbar_label.margin = 12;
            headerbar_label.set_line_wrap (true);
            headerbar_opt.add (headerbar_switch);
            headerbar_opt.add (headerbar_label);
            thiefmd_options.add (headerbar_opt);

            var brandless = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 12);
            var brandless_switch = new Switch ();
            brandless_switch.set_active (settings.brandless);
            brandless_switch.notify["active"].connect (() => {
                settings.brandless = brandless_switch.get_active ();
            });
            brandless_switch.tooltip_text = _("Hide title");
            brandless_switch.margin = 12;
            var brandless_label = new Label(_("Remove ThiefMD branding"));
            brandless_label.xalign = 0;
            brandless_label.margin = 12;
            brandless_label.set_line_wrap (true);
            brandless.add (brandless_switch);
            brandless.add (brandless_label);
            thiefmd_options.add (brandless);

            var preserve_library = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 12);
            var perserve_library_switch = new Switch ();
            perserve_library_switch.set_active (settings.save_library_order);
            perserve_library_switch.notify["active"].connect (() => {
                settings.save_library_order = perserve_library_switch.get_active ();
            });
            perserve_library_switch.tooltip_text = _("Toggle library order");
            perserve_library_switch.margin = 12;
            var perserve_library_label = new Label(_("Keep library order"));
            perserve_library_label.xalign = 0;
            perserve_library_label.margin = 12;
            perserve_library_label.set_line_wrap (true);
            preserve_library.add (perserve_library_switch);
            preserve_library.add (perserve_library_label);
            thiefmd_options.add (preserve_library);

            var experimental_mode = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 12);
            var experimental_mode_switch = new Switch ();
            experimental_mode_switch.set_active (settings.experimental);
            experimental_mode_switch.notify["active"].connect (() => {
                settings.experimental = experimental_mode_switch.get_active ();
            });
            experimental_mode_switch.tooltip_text = _("Toggle experimental features");
            experimental_mode_switch.margin = 12;
            var experimental_mode_label = new Label(_("Enable experimental features"));
            experimental_mode_label.xalign = 0;
            experimental_mode_label.margin = 12;
            experimental_mode_label.set_line_wrap (true);
            experimental_mode.add (experimental_mode_switch);
            experimental_mode.add (experimental_mode_label);
            thiefmd_options.add (experimental_mode);

            page.add (editor_options);
            page.add (thiefmd_options);
            return page;
        }
    }
}
