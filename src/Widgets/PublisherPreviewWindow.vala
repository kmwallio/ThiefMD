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

namespace ThiefMD.Widgets {
    public class PublisherPreviewWindow : Gtk.Window {
        Gtk.HeaderBar headerbar;
        Preview preview;
        private string _markdown;

        public class PublisherPreviewWindow (string markdown) {
            preview = new Preview ();
            preview.exporting = true;
            preview.update_html_view (false, markdown);
            _markdown = markdown;
            build_ui ();
        }

        protected void build_ui () {
            var settings = AppSettings.get_default ();
            int w, h, m, p;

            headerbar = new Gtk.HeaderBar ();
            headerbar.set_title (_("Publishing Preview"));
            var header_context = headerbar.get_style_context ();
            header_context.add_class (Gtk.STYLE_CLASS_FLAT);
            header_context.add_class ("thief-toolbar");

            var preview_type = new Gtk.ComboBoxText ();
            preview_type.append_text (_("HTML/ePUB"));
            preview_type.append_text (_("Print/PDF"));
            preview_type.set_active (0);

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

            preview_css.changed.connect (() => {
                if (preview_css.get_active () >= 0 && preview_css.get_active () < preview_options.size) {
                    string new_css = preview_options.get (preview_css.get_active ());
                    new_css = (new_css == "None") ? "" : new_css;
                    settings.preview_css = new_css;
                    preview.update_html_view (false, _markdown);
                }
            });

            print_css.changed.connect (() => {
                if (print_css.get_active () >= 0 && print_css.get_active () < print_options.size) {
                    string new_css = print_options.get (print_css.get_active ());
                    new_css = (new_css == "None") ? "" : new_css;
                    settings.print_css = new_css;
                    preview.update_html_view (false, _markdown);
                }
            });

            Gtk.Button export_button = new Gtk.Button.with_label (_("Export"));
            export_button.has_tooltip = true;
            export_button.tooltip_text = (_("Export Item"));
            export_button.set_image (new Gtk.Image.from_icon_name("document-export", Gtk.IconSize.LARGE_TOOLBAR));

            preview_type.changed.connect (() => {
                if (preview_type.get_active () == 0) {
                    preview.print_only = false;
                    preview.update_html_view (false, _markdown);
                    headerbar.remove (print_css);
                    headerbar.remove (paper_size);
                    headerbar.pack_start (preview_css);
                } else {
                    preview.print_only = true;
                    preview.update_html_view (false, _markdown);
                    headerbar.remove (preview_css);
                    headerbar.pack_start (print_css);
                    headerbar.pack_end (paper_size);
                }
                headerbar.show_all ();
            });


            export_button.clicked.connect (() => {
                File new_novel = Dialogs.display_save_dialog (preview_type.get_active () == 0);

                if (new_novel == null){
                    return;
                }

                string filename = new_novel.get_basename ().down ();
                try {
                    if (filename.has_suffix (".pdf")) {
                        var print_operation = new WebKit.PrintOperation (preview);
                        var print_settings = new Gtk.PrintSettings ();
                        print_settings.set_printer (_("Print to File"));
                        var page_size = new Gtk.PaperSize(settings.export_paper_size);
                        var page_setup = new Gtk.PageSetup();
                        print_settings[Gtk.PRINT_SETTINGS_OUTPUT_URI] = new_novel.get_uri ();
                        page_setup.set_paper_size_and_default_margins(page_size);
                        page_setup.set_left_margin (settings.export_side_margins, Gtk.Unit.INCH);
                        page_setup.set_right_margin (settings.export_side_margins, Gtk.Unit.INCH);
                        page_setup.set_top_margin (settings.export_top_bottom_margins, Gtk.Unit.INCH);
                        page_setup.set_bottom_margin (settings.export_top_bottom_margins, Gtk.Unit.INCH);
                        print_operation.set_print_settings (print_settings);
                        print_operation.set_page_setup (page_setup);
                        print_operation.print ();
                    } else if (filename.has_suffix (".md") || filename.has_suffix (".markdown")) {
                        if (new_novel.query_exists ()) {
                            new_novel.delete ();
                        }
                        FileManager.save_file (new_novel, _markdown.data);
                    } else if (filename.has_suffix (".html")) {
                        if (new_novel.query_exists ()) {
                            new_novel.delete ();
                        }
                        FileManager.save_file (new_novel, preview.html.data);
                    } else if (filename.has_suffix (".mhtml")) {
                        preview.save_to_file.begin (new_novel, WebKit.SaveMode.MHTML);
                    } else if (filename.has_suffix (".epub")) {
                        Pandoc.make_epub (new_novel.get_path (), _markdown);
                    } else if (filename.has_suffix (".docx")) {
                        Pandoc.make_docx (new_novel.get_path (), _markdown);
                    } else if (filename.has_suffix (".tex")) {
                        Pandoc.make_tex (new_novel.get_path (), _markdown);
                    } else {
                        Gtk.Dialog prompt = new Gtk.Dialog.with_buttons (
                            "Invalid Filename",
                            ThiefApp.get_instance ().main_window,
                            Gtk.DialogFlags.MODAL | Gtk.DialogFlags.DESTROY_WITH_PARENT,
                            _("Close"),
                            Gtk.ResponseType.NO);
                        var contentarea = prompt.get_content_area ();
                        var label = new Gtk.Label (_("Unable to determine type of file to export.\nPlease make sure you included a valid extension"));
                        label.xalign = 0;
                        contentarea.add (label);
                        contentarea.show_all ();

                        prompt.response.connect (() => {
                            prompt.destroy ();
                        });

                        prompt.run ();
                    }
                } catch (Error e) {
                    warning ("Could not save file %s: %s", new_novel.get_basename (), e.message);
                }
            });

            headerbar.pack_start (preview_type);
            headerbar.pack_start (preview_css);

            headerbar.pack_end (export_button);
            headerbar.set_show_close_button (true);
            set_titlebar (headerbar);

            title = _("Publishing Preview");

            ThiefApp.get_instance ().main_window.get_size (out w, out h);
            parent = ThiefApp.get_instance ().main_window;
            destroy_with_parent = true;

            w = w - ThiefApp.get_instance ().pane_position;

            set_default_size(w, h - 150);

            add (preview);
            delete_event.connect (this.on_delete_event);
        }

        public bool on_delete_event () {
            remove (preview);
            show_all ();

            return false;
        }
    }
}