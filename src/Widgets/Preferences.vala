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
using ThiefMD.Connections;

namespace ThiefMD.Widgets {
    public class Preferences : Hdy.PreferencesWindow {
        private Stack stack;
        private Gtk.HeaderBar bar;

        public Preferences () {
            build_ui ();
        }

        private void build_ui () {
            add (editor_grid ());
            add (export_grid ());
            add (display_grid ());
            add (connection_grid ());

            search_enabled = false;
            show_all ();
        }

        private Hdy.PreferencesPage connection_grid () {
            var page = new Hdy.PreferencesPage ();
            var connection_scroller = new ScrolledWindow (null, null);
            connection_scroller.hexpand = true;
            connection_scroller.vexpand = true;
            connection_scroller.set_policy (Gtk.PolicyType.EXTERNAL, Gtk.PolicyType.AUTOMATIC);

            var settings = AppSettings.get_default ();
            Hdy.PreferencesGroup display_options = new Hdy.PreferencesGroup ();
            display_options.title = _("Current Connections");
            display_options.description = _("Click on a connection to remove.");

            Hdy.PreferencesGroup connection_options = new Hdy.PreferencesGroup ();
            connection_options.title = _("Add Connection");
            connection_options.description = _("Choose your blogging software.");

            var writeas_connection = new Gtk.Button.with_label (_("  WriteFreely"));
            writeas_connection.set_image (new Gtk.Image.from_resource ("/com/github/kmwallio/thiefmd/icons/wf.png"));
            writeas_connection.hexpand = true;
            writeas_connection.always_show_image = true;
            writeas_connection.show_all ();
            writeas_connection.clicked.connect (() => {
                ConnectionData? data = WriteFreelyConnection.create_connection ();
                if (data != null) {
                    if (data.endpoint.chug ().chomp () == "") {
                        data.endpoint = "https://write.as/";
                    }
                    warning ("Connecting new writeas account: %s", data.user);
                    WriteFreelyConnection connection = new WriteFreelyConnection (data.user, data.auth, data.endpoint);
                    if (connection.connection_valid ()) {
                        SecretSchemas.get_instance ().add_writefreely_secret (data.endpoint, data.user, data.auth);
                        ThiefApp.get_instance ().connections.add (connection);
                        ThiefApp.get_instance ().exporters.register (connection.export_name, connection.exporter);
                        display_options.add (connection_button (connection, display_options));
                    }
                }
            });
            connection_options.add (writeas_connection);

            var ghost_connection = new Gtk.Button.with_label (_("  ghost"));
            ghost_connection.set_image (new Gtk.Image.from_resource ("/com/github/kmwallio/thiefmd/icons/ghost.png"));
            ghost_connection.hexpand = true;
            ghost_connection.always_show_image = true;
            ghost_connection.show_all ();
            ghost_connection.clicked.connect (() => {
                ConnectionData? data = GhostConnection.create_connection ();
                if (data != null) {
                    if (data.endpoint.chug ().chomp () == "") {
                        data.endpoint = "https://my.ghost.org/";
                    }
                    warning ("Connecting new ghost account: %s", data.user);
                    GhostConnection connection = new GhostConnection (data.user, data.auth, data.endpoint);
                    if (connection.connection_valid ()) {
                        SecretSchemas.get_instance ().add_ghost_secret (data.endpoint, data.user, data.auth);
                        ThiefApp.get_instance ().connections.add (connection);
                        ThiefApp.get_instance ().exporters.register (connection.export_name, connection.exporter);
                        display_options.add (connection_button (connection, display_options));
                    }
                }
            });
            connection_options.add (ghost_connection);

            foreach (var c in ThiefApp.get_instance ().connections) {
                display_options.add (connection_button (c, display_options));
            }

            page.add (display_options);
            page.add (connection_options);
            page.set_icon_name ("preferences-desktop-online-accounts-symbolic");
            page.set_title ("Connections");
            return page;
        }

        private Gtk.Button connection_button (ConnectionBase connection, Hdy.PreferencesGroup grid) {
            Gtk.Button button = new Gtk.Button.with_label ("  " + connection.export_name);
            string type = "";
            string alias = "";
            string endpoint = "";
            if (connection is WriteFreelyConnection) {
                WriteFreelyConnection wc = (WriteFreelyConnection) connection;
                type = WriteFreelyConnection.CONNECTION_TYPE;
                alias = wc.conf_alias;
                endpoint = wc.conf_endpoint;
                button.set_image (new Gtk.Image.from_resource ("/com/github/kmwallio/thiefmd/icons/wf.png"));
                button.always_show_image = true;
                button.show_all ();
            } else if (connection is GhostConnection) {
                GhostConnection gc = (GhostConnection) connection;
                type = GhostConnection.CONNECTION_TYPE;
                alias = gc.conf_alias;
                endpoint = gc.conf_endpoint;
                button.set_image (new Gtk.Image.from_resource ("/com/github/kmwallio/thiefmd/icons/ghost.png"));
                button.always_show_image = true;
                button.show_all ();
            }

            button.clicked.connect (() => {
                var dialog = new Gtk.Dialog.with_buttons (
                    "Remove " + connection.export_name,
                    this,
                    Gtk.DialogFlags.MODAL,
                    _("_Remove"),
                    Gtk.ResponseType.ACCEPT,
                    _("_Keep"),
                    Gtk.ResponseType.REJECT,
                    null);

                dialog.response.connect ((response_val) => {
                    if (response_val == Gtk.ResponseType.ACCEPT) {
                        grid.remove (button);
                        ThiefApp.get_instance ().connections.remove (connection);
                        ThiefApp.get_instance ().exporters.remove (connection.export_name);
                        SecretSchemas.get_instance ().remove_secret (type, alias, endpoint);
                    }
                    dialog.destroy ();
                });

                if (dialog.run () == Gtk.ResponseType.ACCEPT) {
                    grid.remove (button);
                    ThiefApp.get_instance ().connections.remove (connection);
                    ThiefApp.get_instance ().exporters.remove (connection.export_name);
                    SecretSchemas.get_instance ().remove_secret (type, alias, endpoint);
                }
            });

            return button;
        }

        private Hdy.PreferencesPage display_grid () {
            var settings = AppSettings.get_default ();
            Hdy.PreferencesPage page = new Hdy.PreferencesPage ();
            page.set_title ("Display");
            page.set_icon_name ("preferences-desktop-display-symbolic");

            Hdy.PreferencesGroup display_options = new Hdy.PreferencesGroup ();
            display_options.title = "Display Options";
            display_options.description = "Make ThiefMD feel like home.";

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

            var add_theme_button = new Gtk.Button.with_label (_("Add New Theme"));
            add_theme_button.hexpand = true;
            display_options.add (add_theme_button);

            ThemeSelector theme_selector = new ThemeSelector ();
            display_options.add (theme_selector);

            add_theme_button.clicked.connect (() => {
                File new_theme = Dialogs.display_open_dialog (".ultheme");
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

        private Hdy.PreferencesPage export_grid () {
            Hdy.PreferencesPage page = new Hdy.PreferencesPage ();
            page.set_title ("Export");
            page.set_icon_name ("preferences-system-devices-symbolic");
            var settings = AppSettings.get_default ();

            Hdy.PreferencesGroup editor_options = new Hdy.PreferencesGroup ();
            editor_options.title = "Compiling Options";
            editor_options.description = "Adjust how Markdown files are compiled together.";

            var epub_metadata = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 12);
            var epub_metadata_file = new Switch ();
            epub_metadata_file.set_active (settings.export_include_metadata_file);
            epub_metadata_file.notify["active"].connect (() => {
                settings.export_include_metadata_file = epub_metadata_file.get_active ();
            });
            epub_metadata_file.tooltip_text = _("First Markdown File includes Author Metadata");
            epub_metadata_file.margin = 12;
            var epub_metadata_file_label = new Label(_("First Markdown file includes <a href='https://pandoc.org/MANUAL.html#epub-metadata'>Author metadata</a>"));
            epub_metadata_file_label.xalign = 0;
            epub_metadata_file_label.hexpand = true;
            epub_metadata_file_label.use_markup = true;
            epub_metadata_file_label.margin = 12;
            epub_metadata_file_label.set_line_wrap (true);
            epub_metadata.add (epub_metadata_file);
            epub_metadata.add (epub_metadata_file_label);
            editor_options.add (epub_metadata);

            var export_resolve_paths = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 12);
            var export_resolve_paths_switch = new Switch ();
            export_resolve_paths_switch.set_active (settings.export_resolve_paths);
            export_resolve_paths_switch.notify["active"].connect (() => {
                settings.export_resolve_paths = export_resolve_paths_switch.get_active ();
            });
            export_resolve_paths_switch.tooltip_text = _("Resolve full paths to resources");
            export_resolve_paths_switch.margin = 12;
            var export_resolve_paths_label = new Label(_("Resolve full paths to resources on export"));
            export_resolve_paths_label.xalign = 0;
            export_resolve_paths_label.hexpand = true;
            export_resolve_paths_label.margin = 12;
            export_resolve_paths_label.set_line_wrap (true);
            export_resolve_paths.add (export_resolve_paths_switch);
            export_resolve_paths.add (export_resolve_paths_label);
            editor_options.add (export_resolve_paths);

            var export_include_yaml = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 12);
            var export_include_yaml_title_switch = new Switch ();
            export_include_yaml_title_switch.set_active (settings.export_include_yaml_title);
            export_include_yaml_title_switch.notify["active"].connect (() => {
                settings.export_include_yaml_title = export_include_yaml_title_switch.get_active ();
            });
            export_include_yaml_title_switch.tooltip_text = _("Include YAML title as Heading");
            export_include_yaml_title_switch.margin = 12;
            var export_include_yaml_title_label = new Label(_("Include YAML title as H1 Heading"));
            export_include_yaml_title_label.xalign = 0;
            export_include_yaml_title_label.hexpand = true;
            export_include_yaml_title_label.margin = 12;
            export_include_yaml_title_label.set_line_wrap (true);
            export_include_yaml.add (export_include_yaml_title_switch);
            export_include_yaml.add (export_include_yaml_title_label);
            editor_options.add (export_include_yaml);

            Hdy.PreferencesGroup page_setup = new Hdy.PreferencesGroup ();
            page_setup.title = "Page Setup";
            page_setup.description = "Configure PDF export options.";

            var pagebreak_folder = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 12);
            var pagebreak_folder_switch = new Switch ();
            pagebreak_folder_switch.set_active (settings.export_break_folders);
            pagebreak_folder_switch.notify["active"].connect (() => {
                settings.export_break_folders = pagebreak_folder_switch.get_active ();
            });
            pagebreak_folder_switch.tooltip_text = _("Page Break between Folders");
            pagebreak_folder_switch.margin = 12;
            var pagebreak_folder_label = new Label(_("Insert a Page Break after each folder"));
            pagebreak_folder_label.xalign = 0;
            pagebreak_folder_label.hexpand = true;
            pagebreak_folder_label.margin = 12;
            pagebreak_folder_label.set_line_wrap (true);
            pagebreak_folder.add (pagebreak_folder_switch);
            pagebreak_folder.add (pagebreak_folder_label);
            page_setup.add (pagebreak_folder);

            var pagebreak_sheet = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 12);
            var pagebreak_sheet_switch = new Switch ();
            pagebreak_sheet_switch.set_active (settings.export_break_sheets);
            pagebreak_sheet_switch.notify["active"].connect (() => {
                settings.export_break_sheets = pagebreak_sheet_switch.get_active ();
            });
            pagebreak_sheet_switch.tooltip_text = _("Page Break between Sheets");
            pagebreak_sheet_switch.margin = 12;
            var pagebreak_sheet_label = new Label(_("Insert a Page Break after each sheet"));
            pagebreak_sheet_label.xalign = 0;
            pagebreak_sheet_label.hexpand = true;
            pagebreak_sheet_label.margin = 12;
            pagebreak_sheet_label.set_line_wrap (true);
            pagebreak_sheet.add (pagebreak_sheet_switch);
            pagebreak_sheet.add (pagebreak_sheet_label);
            page_setup.add (pagebreak_sheet);

            var paper = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 12);
            var paper_size = new Gtk.ComboBoxText ();
            paper_size.hexpand = true;
            for (int i = 0; i < ThiefProperties.PAPER_SIZES_FRIENDLY_NAME.length; i++) {
                paper_size.append_text (ThiefProperties.PAPER_SIZES_FRIENDLY_NAME[i]);

                if (settings.export_paper_size == ThiefProperties.PAPER_SIZES_GTK_NAME[i]) {
                    paper_size.set_active (i);
                }
            }

            paper_size.changed.connect (() => {
                int option = paper_size.get_active ();
                if (option >= 0 && option < ThiefProperties.PAPER_SIZES_GTK_NAME.length) {
                    settings.export_paper_size = ThiefProperties.PAPER_SIZES_GTK_NAME[option];
                }
            });
            paper.add (paper_size);
            page_setup.add (paper);

            var side_margin = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 12);
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
            side_margin_label.margin = 12;
            side_margin_label.set_line_wrap (true);
            side_margin.add (side_margin_entry);
            side_margin.add (side_margin_label);
            page_setup.add (side_margin);

            var top_bottom_margin = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 12);
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
            top_bottom_margin_label.margin = 12;
            top_bottom_margin_label.set_line_wrap (true);
            top_bottom_margin.add (top_bottom_margin_entry);
            top_bottom_margin.add (top_bottom_margin_label);
            page_setup.add (top_bottom_margin);

            Hdy.PreferencesGroup pdf_options = new Hdy.PreferencesGroup ();
            pdf_options.title = "PDF CSS";
            pdf_options.description = "Choose CSS Style for PDF Export.";
            int cur_w = this.get_allocated_width ();

            var print_css_selector = new CssSelector ("print");
            print_css_selector.set_size_request (cur_w, (int)(1.2 * Constants.CSS_PREVIEW_HEIGHT + 5));
            pdf_options.add (print_css_selector);

            Hdy.PreferencesGroup epub_setup = new Hdy.PreferencesGroup ();
            epub_setup.title = "ePub & HTML CSS";
            epub_setup.description = "Choose CSS Style to use for ePub and HTML Export.";

            var css_selector = new CssSelector ("preview");
            css_selector.set_size_request (cur_w, (int)(1.2 * Constants.CSS_PREVIEW_HEIGHT + 5));
            epub_setup.add (css_selector);

            var add_css_button = new Gtk.Button.with_label (_("Add Export Style"));
            add_css_button.hexpand = true;
            epub_setup.add (add_css_button);

            add_css_button.clicked.connect (() => {
                File new_css_pkg = Dialogs.display_open_dialog (".*");
                if (new_css_pkg != null && new_css_pkg.query_exists ()) {
                    FileManager.load_css_pkg (new_css_pkg);
                    print_css_selector.refresh ();
                    css_selector.refresh ();
                }
            });

            page.add (editor_options);
            page.add (page_setup);
            page.add (pdf_options);
            page.add (epub_setup);
            return page;
        }

        private Hdy.PreferencesPage editor_grid () {
            var settings = AppSettings.get_default ();
            Hdy.PreferencesPage page = new Hdy.PreferencesPage ();
            page.set_title ("Editor");
            page.set_icon_name ("thiefmd-symbolic");

            Hdy.PreferencesGroup editor_options = new Hdy.PreferencesGroup ();
            editor_options.title = "Editor Settings";
            editor_options.description = "Modify the ThiefMD environment.";

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

            //
            // More UI-ish options
            //

            Hdy.PreferencesGroup thiefmd_options = new Hdy.PreferencesGroup ();
            thiefmd_options.title = "ThiefMD Settings";
            thiefmd_options.description = "Modify the ThiefMD appearance.";

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

            page.add (editor_options);
            page.add (thiefmd_options);
            return page;
        }
    }
}
