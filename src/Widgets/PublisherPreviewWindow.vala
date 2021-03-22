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
    public class PublisherPreviewWindow : Hdy.Window {
        public Hdy.HeaderBar headerbar;
        public Preview preview;
        private Gtk.Box advanced_options;
        public Gtk.Paned options_pane;
        private string _markdown;
        private string e_markdown;
        private ExportBase exporter;
        private bool render_fountain;

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

            headerbar = new Hdy.HeaderBar ();
            headerbar.set_title (_("Publishing Preview"));
            var header_context = headerbar.get_style_context ();
            header_context.add_class (Gtk.STYLE_CLASS_FLAT);

            Gee.Set<string> exports = ThiefApp.get_instance ().exporters.get_export_list ();
            Gee.LinkedList<string> exporters = new Gee.LinkedList<string> ();
            foreach (var e in exports) {
                if (!render_fountain) {
                    exporters.add (e);
                } else {
                    if (e == "HTML" || e == "PDF") {
                        exporters.add (e);
                    }
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
            export_button.set_image (new Gtk.Image.from_icon_name("document-export", Gtk.IconSize.LARGE_TOOLBAR));

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
                headerbar.show_all ();
            });


            export_button.clicked.connect (() => {
                if (exporter != null) {
                    if (!exporter.export ()) {
                        PublishedStatusWindow status = new PublishedStatusWindow (
                            this,
                            _("File not Exported"),
                            new Gtk.Label (_("ThiefMD could not export the file, please try again.")));

                        status.run ();
                    }
                }
            });

            headerbar.pack_start (preview_type);
            headerbar.pack_start (preview_css);

            headerbar.pack_end (export_button);
            headerbar.set_show_close_button (true);
            vbox.add (headerbar);

            title = _("Publishing Preview");

            ThiefApp.get_instance ().get_size (out w, out h);
            parent = ThiefApp.get_instance ();
            destroy_with_parent = true;

            w = w - ThiefApp.get_instance ().pane_position;

            set_default_size(w, h - 150);

            options_pane.add1 (advanced_options);
            options_pane.add2 (preview);
            options_pane.set_position (0);
            options_pane.get_child1 ().hide ();
            options_pane.get_child2 ().show ();
            options_pane.show ();
            vbox.add (options_pane);
            delete_event.connect (this.on_delete_event);

            add (vbox);
            preview.show_all ();
            headerbar.show_all ();
            vbox.show ();
        }

        public void show_advanced_options () {
            options_pane.get_child1 ().show ();
            options_pane.set_position (250);
        }

        public bool on_delete_event () {
            remove (preview);
            show_all ();

            return false;
        }
    }

    public class PublishedStatusWindow : Gtk.Dialog {
        private Gtk.Label message;

        public PublishedStatusWindow (PublisherPreviewWindow win, string set_title, Gtk.Label body) {
            set_transient_for (win);
            modal = true;
            title = set_title;
            message = body;
            build_ui ();
        }

        private void build_ui () {
            window_position = Gtk.WindowPosition.CENTER;
            this.get_content_area().add (build_message_ui ());
            show_all ();
        }

        private Gtk.Grid build_message_ui () {
            Gtk.Grid grid = new Gtk.Grid ();
            grid.margin = 12;
            grid.row_spacing = 12;
            grid.column_spacing = 12;
            grid.orientation = Gtk.Orientation.VERTICAL;
            grid.hexpand = true;
            grid.vexpand = true;

            try {
                Gtk.IconTheme icon_theme = Gtk.IconTheme.get_default();
                var thief_icon = icon_theme.load_icon("com.github.kmwallio.thiefmd", 128, Gtk.IconLookupFlags.FORCE_SVG);
                var icon = new Gtk.Image.from_pixbuf (thief_icon);
                grid.attach (icon, 1, 1);
            } catch (Error e) {
                warning ("Could not load logo: %s", e.message);
            }

            grid.attach (message, 1, 2);

            Gtk.Button close = new Gtk.Button.with_label (_("Close"));
            grid.attach (close, 1, 3);

            close.clicked.connect (() => {
                this.destroy ();
            });

            response.connect (() => {
                this.destroy ();
            });

            grid.show_all ();
            return grid;
        }
    }
}