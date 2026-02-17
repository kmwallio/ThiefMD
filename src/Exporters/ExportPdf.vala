/*
 * Copyright (C) 2020 kmwallio
 * 
 * Permission is hereby granted, free of charge, to any person
 * obtaining a copy of this software and associated documentation
 * files (the “Software”), to deal in the Software without restriction,
 * including without limitation the rights to use, copy, modify,
 * merge, publish, distribute, sublicense, and/or sell copies of
 * the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall
 * be included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 * OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
 * IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
 * CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
 * TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
 * SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

using ThiefMD;
using ThiefMD.Widgets;
using ThiefMD.Controllers;

namespace ThiefMD.Exporters {
    public class ExportPdf : ExportBase {
        public override string export_name { get; protected set; }
        public override string export_css { get; protected set; }
        private PublisherPreviewWindow publisher_instance;
        private Gtk.ComboBoxText paper_size;

        public ExportPdf () {
            export_name = "PDF";
            export_css = "print";
            supports_fountain = true;
        }

        private void build_ui () {
            var settings = AppSettings.get_default ();

            paper_size = new Gtk.ComboBoxText ();
            paper_size.hexpand = true;
            for (int i = 0; i < ThiefProperties.PAPER_SIZES_FRIENDLY_NAME.size; i++) {
                paper_size.append_text (ThiefProperties.PAPER_SIZES_FRIENDLY_NAME.get (i));

                if (settings.export_paper_size == ThiefProperties.PAPER_SIZES_GTK_NAME[i]) {
                    paper_size.set_active (i);
                }
            }

            paper_size.changed.connect (() => {
                int option = paper_size.get_active ();
                if (option >= 0 && option < ThiefProperties.PAPER_SIZES_GTK_NAME.length) {
                    settings.export_paper_size = ThiefProperties.PAPER_SIZES_GTK_NAME[option];
                }
                publisher_instance.refresh_preview ();
            });
        }

        private void destroy_ui () {
            paper_size = null;
        }

        public override string update_markdown (string markdown) {
            return markdown;
        }

        public override void attach (PublisherPreviewWindow ppw) {
            publisher_instance = ppw;
            build_ui ();
            publisher_instance.headerbar.pack_end (paper_size);
            return;
        }

        public override void detach () {
            publisher_instance.headerbar.remove (paper_size);
            destroy_ui ();
            publisher_instance = null;
            return;
        }

        public override bool export () {
            var settings = AppSettings.get_default ();
            var pdf = new Gtk.FileFilter ();
            pdf.set_filter_name (_("PDF file"));
            pdf.add_mime_type ("application/pdf");
            pdf.add_pattern ("*.pdf");

            File? new_novel = Dialogs.get_target_save_file_with_extension (
                _("Export PDF"),
                pdf,
                "pdf");

            if (new_novel == null) {
                return true;
            }

            bool success = false;

            string? weasyprint_loc = Environment.find_program_in_path ("weasyprint");
            if (weasyprint_loc == null || weasyprint_loc == "")
            {
                if (FileUtils.test("/app/bin/weasyprint", FileTest.EXISTS))
                {
                    weasyprint_loc = "/app/bin/weasyprint";
                }
            }

            string pagedjs_loc = Environment.find_program_in_path ("pagedjs-cli");
            if ((pagedjs_loc != null && pagedjs_loc != "" && !publisher_instance.preview.html.contains ("<img")) ||
                (weasyprint_loc != null && weasyprint_loc != "" && !publisher_instance.render_fountain))
            {
                string temp_html_file = FileManager.save_temp_file (publisher_instance.preview.html, "html");
                if (temp_html_file != "") {
                    try {
                        string[] command;
                        if (pagedjs_loc == null ||
                            pagedjs_loc == "" ||
                            publisher_instance.preview.html.contains ("<img"))
                        {
                            command = {
                                weasyprint_loc,
                                temp_html_file,
                                new_novel.get_path ()
                            };
                            debug ("Using weasyprint");
                        } else {
                            command = {
                                "pagedjs-cli",
                                temp_html_file,
                                "-o",
                                new_novel.get_path ()
                            };
                            debug ("Using pagedjs");
                        }

                        bool res = false;
                        Gee.List<string> pdfSayings = new Gee.LinkedList<string> ();
                        pdfSayings.add(_("Simply Shakespearean."));
                        pdfSayings.add(_("Hmm... that's interesting..."));
                        pdfSayings.add(_("Your writing is insightful."));

                        Thinking worker = new Thinking (_("Working PDF Magic"), () => {
                            try {
                                Subprocess converter = new Subprocess.newv (command, SubprocessFlags.STDERR_MERGE);
                                res = converter.wait ();
                                converter.force_exit ();
                            } catch (Error e) {
                                warning ("Error converting PDF, %s", e.message);
                                res = false;
                            }
                        },
                        pdfSayings,
                        publisher_instance);
                        worker.run ();

                        success = res && new_novel.query_exists ();

                        // Clean up intermediate files
                        try {
                            File temp_html = File.new_for_path (temp_html_file);
                            temp_html.delete ();
                        } catch (Error e) {
                            warning ("Could not delete cache file %s, %s", temp_html_file, e.message);
                        }
                    } catch (Error e) {
                        warning ("Could not generate pdf: %s", e.message);
                        success = false;
                    }
                }
            } else {
                PublishedStatusWindow status = new PublishedStatusWindow (
                    publisher_instance,
                    _("Working PDF Magic"),
                    new Gtk.Label (_("Making sure your hard work looks purrfect...")));

                debug ("Using webkitgtk6 for PDF export");
                var print_operation = new WebKit.PrintOperation (publisher_instance.preview);
                var print_settings = new Gtk.PrintSettings ();
                print_settings.set_printer ("Print to File");
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
                bool printed_success = false;
                var loop = new MainLoop (null, false);
                print_operation.finished.connect (() => {
                    printed_success = true;
                    status.destroy ();
                    loop.quit ();
                });
                print_operation.failed.connect (() => {
                    printed_success = false;
                    status.destroy ();
                    loop.quit ();
                });
                print_operation.print ();
                status.run ();
                loop.run ();
                success = printed_success && new_novel.query_exists ();
            }

            return success;
        }
    }
}