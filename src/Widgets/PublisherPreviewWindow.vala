/*
 * Copyright (C) 2020 kmwallio
 * 
 * Modified September 13, 2020
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
using ThiefMD.Exporters;

namespace ThiefMD.Widgets {
    public class PublisherPreviewWindow : Gtk.ApplicationWindow {
        public Adw.HeaderBar headerbar;
        public Preview preview;
        private Gtk.Box advanced_options;
        public Gtk.Paned options_pane;
        private string _markdown;
        private string e_markdown;
        private ExportBase exporter;
        public bool render_fountain;
        // Folder path of the library item being previewed; used by exporters that need file access.
        public string source_path { get; set; default = ""; }

        public PublisherPreviewWindow (string markdown, bool generate_fountain = false) {
            preview = new Preview ();
            preview.exporting = true;
            render_fountain = generate_fountain;
            preview.update_html_view (false, markdown, render_fountain);
            _markdown = markdown;
            new KeyBindings (this, false);
            build_ui ();
        }

        public string get_export_html () {
            return preview.html;
        }

        public string get_original_markdown () {
            return _markdown;
        }

        public string get_export_markdown () {
            return e_markdown;
        }

        protected void build_ui () {
            Gtk.Box vbox = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
            advanced_options = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
            options_pane = new Gtk.Paned (Gtk.Orientation.HORIZONTAL);

            var settings = AppSettings.get_default ();
            int w, h;

            headerbar = new Adw.HeaderBar ();
            var window_title = new Adw.WindowTitle (_("Publishing Preview"), "");
            headerbar.set_title_widget (window_title);
            headerbar.add_css_class ("flat");

            Gee.Set<string> exports = ThiefApp.get_instance ().exporters.get_export_list ();
            Gee.LinkedList<string> exporters = new Gee.LinkedList<string> ();
            foreach (var e in exports) {
                var check_exporter = ThiefApp.get_instance ().exporters.get_exporter (e);
                if (!render_fountain && check_exporter.supports_markdown) {
                    exporters.add (e);
                } else if (render_fountain && check_exporter.supports_fountain) {
                    exporters.add (e);
                }
            }

            var preview_type = new Gtk.ComboBoxText ();

            foreach (var e in exporters) {
                preview_type.append_text (e);
            }

            if (!render_fountain) {
                preview_type.set_active (exporters.index_of (Constants.DEFAULT_EXPORTER));
                exporter = ThiefApp.get_instance ().exporters.get_exporter (Constants.DEFAULT_EXPORTER);
            } else {
                preview_type.set_active (exporters.index_of ("PDF"));
                exporter = ThiefApp.get_instance ().exporters.get_exporter ("PDF");
            }

            exporter.attach (this);
            e_markdown = exporter.update_markdown (_markdown);

            var preview_css = new Gtk.ComboBoxText ();
            var preview_options = CssSelector.list_css ("preview");
            for (int i = 0; i < preview_options.size; i++) {
                preview_css.append_text (preview_options.get (i));

                if (preview_options.get (i) == settings.preview_css) {
                    preview_css.set_active (i);
                }
            }

            if (settings.preview_css == "") {
                preview_css.set_active (0);
            }

            var print_css = new Gtk.ComboBoxText ();
            var print_options = CssSelector.list_css ("print");
            for (int i = 0; i < print_options.size; i++) {
                print_css.append_text (print_options.get (i));

                if (print_options.get (i) == settings.print_css) {
                    print_css.set_active (i);
                }
            }

            if (settings.print_css == "") {
                print_css.set_active (0);
            }

            preview_css.changed.connect (() => {
                if (preview_css.get_active () >= 0 && preview_css.get_active () < preview_options.size) {
                    string new_css = preview_options.get (preview_css.get_active ());
                    new_css = (new_css == "None") ? "" : new_css;
                    settings.preview_css = new_css;
                    if (exporter != null) {
                        e_markdown = exporter.update_markdown (_markdown);
                    } else {
                        e_markdown = _markdown;
                    }
                    preview.update_html_view (false, e_markdown, render_fountain);
                }
            });

            print_css.changed.connect (() => {
                if (print_css.get_active () >= 0 && print_css.get_active () < print_options.size) {
                    string new_css = print_options.get (print_css.get_active ());
                    new_css = (new_css == "None") ? "" : new_css;
                    settings.print_css = new_css;
                    if (exporter != null) {
                        e_markdown = exporter.update_markdown (_markdown);
                    } else {
                        e_markdown = _markdown;
                    }
                    preview.update_html_view (false, e_markdown, render_fountain);
                }
            });

            Gtk.Button export_button = new Gtk.Button.with_label (_("Export"));
            export_button.has_tooltip = true;
            export_button.tooltip_text = (_("Export Item"));
            export_button.set_icon_name ("document-export");

            preview_type.changed.connect (() => {
                int option = preview_type.get_active ();
                if (option >= 0 && option < exporters.size) {
                    if (exporter != null) {
                        exporter.detach ();
                    }
                    exporter = ThiefApp.get_instance ().exporters.get_exporter (exporters.get (option));

                    if (exporter != null) {
                        exporter.attach (this);
                        if (exporter.export_css == "print") {
                            preview.print_only = true;
                            e_markdown = exporter.update_markdown (_markdown);
                            preview.update_html_view (false, e_markdown, render_fountain);
                            headerbar.remove (preview_css);
                            headerbar.pack_start (print_css);
                        } else {
                            preview.print_only = false;
                            e_markdown = exporter.update_markdown (_markdown);
                            preview.update_html_view (false, e_markdown, render_fountain);
                            headerbar.remove (print_css);
                            headerbar.pack_start (preview_css);
                        }
                    }
                }
            });


            export_button.clicked.connect (() => {
                if (exporter != null) {
                    if (!exporter.export ()) {
                        var dialog = new Adw.MessageDialog (this, _("File not Exported"), _("ThiefMD could not export the file, please try again."));
                        dialog.add_response ("close", _("Close"));
                        dialog.set_default_response ("close");
                        dialog.set_close_response ("close");
                        dialog.present ();
                    }
                }
            });

            headerbar.pack_start (preview_type);
            headerbar.pack_start (preview_css);

            headerbar.pack_end (export_button);
            headerbar.set_show_start_title_buttons (true);
            headerbar.set_show_end_title_buttons (true);
            set_titlebar (headerbar);

            title = _("Publishing Preview");

            ThiefApp.get_instance ().get_default_size (out w, out h);

            w = w - ThiefApp.get_instance ().pane_position;

            set_default_size(w, h - 150);

            options_pane.set_start_child (advanced_options);
            options_pane.set_end_child (preview);
            options_pane.set_position (0);
            if (options_pane.get_start_child () != null) {
                options_pane.get_start_child ().hide ();
            }
            if (options_pane.get_end_child () != null) {
                options_pane.get_end_child ().show ();
            }
            vbox.append (options_pane);
            close_request.connect (this.on_delete_event);

            set_child (vbox);
        }

        public void refresh_preview () {
            if (exporter != null) {
                e_markdown = exporter.update_markdown (_markdown);
            } else {
                e_markdown = _markdown;
            }
            preview.update_html_view (false, e_markdown, render_fountain);
        }

        public void show_advanced_options () {
            var start = options_pane.get_start_child ();
            if (start != null) {
                start.show ();
            }
            options_pane.set_position (250);
        }

        public bool on_delete_event () {
            set_child (null);
            if (exporter != null) {
                exporter.detach ();
                exporter = null;
            }

            return false;
        }
    }
}