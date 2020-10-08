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
    public class Preferences : Dialog {
        private Stack stack;

        public Preferences () {
            set_transient_for (ThiefApp.get_instance ().main_window);
            resizable = false;
            deletable = false;
            modal = true;
            build_ui ();
        }

        private void build_ui () {
            this.set_border_width (20);
            title = _("Preferences");
            window_position = WindowPosition.CENTER;

            stack = new Stack ();
            stack.add_titled (editor_grid (), "Editor Preferences", _("Editor"));
            stack.add_titled (export_grid (), "Export Preferences", _("Export"));
            stack.add_titled (display_grid (), "Display Preferences", _("Display"));

            StackSwitcher switcher = new StackSwitcher ();
            switcher.set_stack (stack);
            switcher.halign = Align.CENTER;

            Box box = new Box (Orientation.VERTICAL, 0);

            box.add (switcher);
            box.add (stack);
            this.get_content_area().add (box);

            add_button (_("Done"), Gtk.ResponseType.CLOSE);
            response.connect (() =>
            {
                destroy ();
            });

            show_all ();
        }

        private Grid display_grid () {
            Grid grid = new Grid ();
            grid.margin = 12;
            grid.row_spacing = 12;
            grid.column_spacing = 12;
            grid.orientation = Orientation.VERTICAL;
            grid.hexpand = true;

            ThemeSelector theme_selector = new ThemeSelector ();
            grid.add (theme_selector);
            grid.show_all ();

            return grid;
        }

        private Grid export_grid () {
            var settings = AppSettings.get_default ();
            Grid grid = new Grid ();
            grid.margin = 12;
            grid.row_spacing = 12;
            grid.column_spacing = 12;
            grid.orientation = Orientation.VERTICAL;
            grid.hexpand = true;

            var epub_metadata_file = new Switch ();
            epub_metadata_file.set_active (settings.export_include_metadata_file);
            epub_metadata_file.notify["active"].connect (() => {
                settings.export_include_metadata_file = epub_metadata_file.get_active ();
            });
            epub_metadata_file.tooltip_text = _("First Markdown File includes Author Metadata");
            var epub_metadata_file_label = new Label(_("First Markdown file includes <a href='https://pandoc.org/MANUAL.html#epub-metadata'>Author metadata</a>"));
            epub_metadata_file_label.xalign = 0;
            epub_metadata_file_label.hexpand = true;
            epub_metadata_file_label.use_markup = true;

            var export_resolve_paths_switch = new Switch ();
            export_resolve_paths_switch.set_active (settings.export_resolve_paths);
            export_resolve_paths_switch.notify["active"].connect (() => {
                settings.export_resolve_paths = export_resolve_paths_switch.get_active ();
            });
            export_resolve_paths_switch.tooltip_text = _("Resolve full paths to resources");
            var export_resolve_paths_label = new Label(_("Resolve full paths to resources on export (ePub, docx required)"));
            export_resolve_paths_label.xalign = 0;
            export_resolve_paths_label.hexpand = true;

            var page_setup_label = new Gtk.Label (_("<b>Page Setup</b>"));
            page_setup_label.hexpand = true;
            page_setup_label.xalign = 0;
            page_setup_label.use_markup = true;

            var side_margin_entry = new Gtk.SpinButton.with_range (0.0, 3.5, 0.05);
            side_margin_entry.set_value (settings.export_side_margins);
            side_margin_entry.value_changed.connect (() => {
                double new_margin = side_margin_entry.get_value ();
                if (new_margin >= 0.0 && new_margin <= 3.5) {
                    settings.export_side_margins = new_margin;
                } else {
                    side_margin_entry.set_value (settings.export_side_margins);
                }
            });
            var side_margin_label = new Label(_("Side margins in PDF in inches"));
            side_margin_label.xalign = 0;
            side_margin_label.hexpand = true;

            var top_bottom_margin_entry = new Gtk.SpinButton.with_range (0.0, 3.5, 0.05);
            top_bottom_margin_entry.set_value (settings.export_top_bottom_margins);
            top_bottom_margin_entry.value_changed.connect (() => {
                double new_margin = top_bottom_margin_entry.get_value ();
                if (new_margin >= 0.0 && new_margin <= 3.5) {
                    settings.export_top_bottom_margins = new_margin;
                } else {
                    top_bottom_margin_entry.set_value (settings.export_top_bottom_margins);
                }
            });
            var top_bottom_margin_label = new Label(_("Top & Bottom margins in PDF in inches"));
            top_bottom_margin_label.xalign = 0;
            top_bottom_margin_label.hexpand = true;

            var pagebreak_folder_switch = new Switch ();
            pagebreak_folder_switch.set_active (settings.export_break_folders);
            pagebreak_folder_switch.notify["active"].connect (() => {
                settings.export_break_folders = pagebreak_folder_switch.get_active ();
            });
            pagebreak_folder_switch.tooltip_text = _("Page Break between Folders");
            var pagebreak_folder_label = new Label(_("Insert a Page Break after each folder"));
            pagebreak_folder_label.xalign = 0;
            pagebreak_folder_label.hexpand = true;

            var pagebreak_sheet_switch = new Switch ();
            pagebreak_sheet_switch.set_active (settings.export_break_sheets);
            pagebreak_sheet_switch.notify["active"].connect (() => {
                settings.export_break_sheets = pagebreak_sheet_switch.get_active ();
            });
            pagebreak_sheet_switch.tooltip_text = _("Page Break between Sheets");
            var pagebreak_sheet_label = new Label(_("Insert a Page Break after each sheet"));
            pagebreak_sheet_label.xalign = 0;
            pagebreak_sheet_label.hexpand = true;

            int cur_w = this.get_allocated_width ();
            var print_css_label = new Gtk.Label (_("<b>PDF Print CSS</b>"));
            print_css_label.hexpand = true;
            print_css_label.xalign = 0;
            print_css_label.use_markup = true;
            var print_css_selector = new CssSelector ("print");
            print_css_selector.set_size_request (cur_w, Constants.CSS_PREVIEW_HEIGHT + 5);

            var css_label = new Gtk.Label (_("<b>Preview and ePub CSS</b>"));
            css_label.hexpand = true;
            css_label.xalign = 0;
            css_label.use_markup = true;
            var css_selector = new CssSelector ("preview");
            css_selector.set_size_request (cur_w, Constants.CSS_PREVIEW_HEIGHT + 5);

            var add_css_button = new Gtk.Button.with_label (_("Add Export Style"));
            add_css_button.hexpand = true;

            add_css_button.clicked.connect (() => {
                File new_css_pkg = Dialogs.display_open_dialog (".*");
                if (new_css_pkg != null && new_css_pkg.query_exists ()) {
                    FileManager.load_css_pkg (new_css_pkg);
                    print_css_selector.refresh ();
                    css_selector.refresh ();
                }
            });

            int g = 1;

            grid.attach (epub_metadata_file, 1, g, 1, 1);
            grid.attach (epub_metadata_file_label, 2, g, 1, 1);
            g++;

            grid.attach (export_resolve_paths_switch, 1, g, 1, 1);
            grid.attach (export_resolve_paths_label, 2, g, 1, 1);
            g++;

            grid.attach (page_setup_label, 1, g, 2, 1);
            g++;
            grid.attach (side_margin_entry, 1, g, 1, 1);
            grid.attach (side_margin_label, 2, g, 1, 1);
            g++;
            grid.attach (top_bottom_margin_entry, 1, g, 1, 1);
            grid.attach (top_bottom_margin_label, 2, g, 1, 1);
            g++;
            grid.attach (pagebreak_folder_switch, 1, g, 1, 1);
            grid.attach (pagebreak_folder_label, 2, g, 2, 1);
            g++;
            grid.attach (pagebreak_sheet_switch, 1, g, 1, 1);
            grid.attach (pagebreak_sheet_label, 2, g, 2, 1);
            g++;

            grid.attach (print_css_label, 1, g, 2, 1);
            g++;
            grid.attach (print_css_selector, 1, g, 2, 2);
            g += 2;

            grid.attach (css_label, 1, g, 2, 1);
            g++;
            grid.attach (css_selector, 1, g, 2, 2);
            g += 2;

            grid.attach (add_css_button, 1, g, 2, 1);
            g++;

            grid.show_all ();

            return grid;
        }

        private Grid editor_grid () {
            var settings = AppSettings.get_default ();
            Grid grid = new Grid ();
            grid.margin = 12;
            grid.row_spacing = 12;
            grid.column_spacing = 12;
            grid.orientation = Orientation.VERTICAL;
            grid.hexpand = true;

            var spellcheck_switch = new Switch ();
            spellcheck_switch.set_active (settings.spellcheck);
            spellcheck_switch.notify["active"].connect (() => {
                settings.spellcheck = spellcheck_switch.get_active ();
            });
            spellcheck_switch.tooltip_text = _("Toggle Spellcheck");
            var spellcheck_label = new Label(_("Check Spelling"));
            spellcheck_label.xalign = 0;

            var writegood_switch = new Switch ();
            writegood_switch.set_active (settings.writegood);
            writegood_switch.notify["active"].connect (() => {
                settings.writegood = writegood_switch.get_active ();
            });
            writegood_switch.tooltip_text = _("Toggle Write-Good");
            var writegood_label = new Label(_("Enable Write-Good checks, passive voice, weasel words, and more"));
            writegood_label.xalign = 0;

            var typewriter_switch = new Switch ();
            typewriter_switch.set_active (settings.typewriter_scrolling);
            typewriter_switch.notify["active"].connect (() => {
                settings.typewriter_scrolling = typewriter_switch.get_active ();
            });
            typewriter_switch.tooltip_text = _("Toggle Spellcheck");
            var typewriter_label = new Label(_("Use TypeWriter Scrolling"));
            typewriter_label.xalign = 0;

            var ui_colorscheme_switch = new Switch ();
            ui_colorscheme_switch.set_active (settings.ui_editor_theme);
            ui_colorscheme_switch.notify["active"].connect (() => {
                settings.ui_editor_theme = ui_colorscheme_switch.get_active ();
                UI.load_css_scheme ();
            });
            ui_colorscheme_switch.tooltip_text = _("Toggle UI Matching");
            var ui_colorscheme_label = new Label(_("Match UI to Editor Theme"));
            ui_colorscheme_label.xalign = 0;

            var brandless_switch = new Switch ();
            brandless_switch.set_active (settings.brandless);
            brandless_switch.notify["active"].connect (() => {
                settings.brandless = brandless_switch.get_active ();
            });
            brandless_switch.tooltip_text = _("Hide meaningless UI Elements");
            var brandless_label = new Label(_("Go Brandless"));
            brandless_label.xalign = 0;

            var perserve_library_switch = new Switch ();
            perserve_library_switch.set_active (settings.save_library_order);
            perserve_library_switch.notify["active"].connect (() => {
                settings.save_library_order = perserve_library_switch.get_active ();
            });
            perserve_library_switch.tooltip_text = _("Toggle Save Library Order");
            var perserve_library_label = new Label(_("Preserve Library Order"));
            perserve_library_label.xalign = 0;

            int g_row = 0;
            grid.attach (spellcheck_switch, 1, g_row, 1, 1);
            grid.attach (spellcheck_label, 2, g_row, 2, 1);
            g_row++;

            grid.attach (writegood_switch, 1, g_row, 1, 1);
            grid.attach (writegood_label, 2, g_row, 2, 1);
            g_row++;

            grid.attach (typewriter_switch, 1, g_row, 1, 1);
            grid.attach (typewriter_label, 2, g_row, 2, 1);
            g_row++;

            grid.attach (ui_colorscheme_switch, 1, g_row, 1, 1);
            grid.attach (ui_colorscheme_label, 2, g_row, 2, 1);
            g_row++;

            grid.attach (brandless_switch, 1, g_row, 1, 1);
            grid.attach (brandless_label, 2, g_row, 2, 1);
            g_row++;

            grid.attach (perserve_library_switch, 1, g_row, 1, 1);
            grid.attach (perserve_library_label, 2, g_row, 2, 1);
            g_row++;

            grid.show_all ();

            return grid;
        }
    }
}