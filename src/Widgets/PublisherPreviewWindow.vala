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

            Gtk.Button export_button = new Gtk.Button ();
            export_button.has_tooltip = true;
            export_button.tooltip_text = (_("Export Item"));
            export_button.set_image (new Gtk.Image.from_icon_name("document-export", Gtk.IconSize.LARGE_TOOLBAR));
            export_button.clicked.connect (() => {
                File new_novel = Dialogs.display_save_dialog ();

                if (new_novel == null){
                    return;
                }

                string filename = new_novel.get_basename ().down ();
                try {
                    if (filename.has_suffix (".pdf")) {
                        var print_operation = new WebKit.PrintOperation (preview);
                        var print_settings = new Gtk.PrintSettings ();
                        print_settings.set_printer (_("Print to File"));
                        var page_size = new Gtk.PaperSize(Gtk.PAPER_NAME_LETTER);
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
                    }
                } catch (Error e) {
                    warning ("Could not save file %s: %s", new_novel.get_basename (), e.message);
                }
            });

            headerbar.pack_end (export_button);
            headerbar.set_show_close_button (true);
            set_titlebar (headerbar);

            title = _("Publishing Preview");

            ThiefApp.get_instance ().main_window.get_size (out w, out h);
            transient_for = ThiefApp.get_instance ().main_window;
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