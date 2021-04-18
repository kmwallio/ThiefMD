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

            File new_novel = Dialogs.get_target_save_file_with_extension (
                _("Export PDF"),
                pdf,
                "pdf");

            if (new_novel == null) {
                return true;
            }

            PublishedStatusWindow status = new PublishedStatusWindow (
                publisher_instance,
                _("Working PDF Magic"),
                new Gtk.Label (_("Making sure your hard work looks purrfect...")));

            string? weasyprint_loc = Environment.find_program_in_path ("weasyprint");
            if (weasyprint_loc != null &&
                weasyprint_loc != "" &&
                !publisher_instance.render_fountain &&
                !publisher_instance.preview.html.contains ("<pre class"))
            {
                // string resolved_mkd = Pandoc.resolve_paths (publisher_instance.get_export_markdown ());
                // string temp_file = FileManager.save_temp_file (resolved_mkd);
                string temp_html_file = FileManager.save_temp_file (publisher_instance.preview.html, "html");
                // string css_file_path = "";
                bool res = false;
                if (temp_html_file != "") {
                    try {
                        // Phase 1. Pandoc to Html
                        //  {
                        //      File temp_html = File.new_for_path (temp_html_file);
                        //      temp_html.delete ();
                        //      bool work_bib =  Pandoc.needs_bibtex (publisher_instance.get_original_markdown ());
                        //      string[] command = {
                        //          "pandoc",
                        //          temp_file,
                        //          "-o",
                        //          temp_html_file
                        //      };
                        //      if (work_bib) {
                        //          command +=  Pandoc.has_citeproc () ? "--citeproc" : "--filter=pandoc-citeproc";
                        //      }
                        //      if (settings.print_css != "") {
                        //          File css_file = null;
                        //          if (settings.print_css == "modest-splendor") {
                        //              css_file = File.new_for_path (Path.build_filename(Build.PKGDATADIR, "styles", "preview.css"));
                        //          } else if (settings.print_css != "") {
                        //              css_file = File.new_for_path (Path.build_filename(UserData.css_path, settings.print_css, "print.css"));
                        //          }
                        //          if (css_file != null && css_file.query_exists ()) {
                        //              command += "--css";
                        //              command += css_file.get_path ();
                        //              css_file_path = css_file.get_path ();
                        //          }
                        //      }
                        //      Subprocess pandoc = new Subprocess.newv (command, SubprocessFlags.STDERR_MERGE);
                        //      res = pandoc.wait ();
                        //      File temp = File.new_for_path (temp_file);
                        //      temp.delete ();
                        //  }

                        if (res && new_novel.query_exists ()) {
                            new_novel.delete ();
                        }

                        // Phase 2 weasyprint
                        {
                            string[] command;
                            //  if (css_file_path != null && css_file_path != "") {
                            //      command = {
                            //          "weasyprint",
                            //          "-f",
                            //          "pdf",
                            //          "-s",
                            //          css_file_path,
                            //          temp_html_file,
                            //          new_novel.get_path ()
                            //      };
                            //  } else {
                                command = {
                                    "weasyprint",
                                    "-f",
                                    "pdf",
                                    temp_html_file,
                                    new_novel.get_path ()
                                };
                            //  }

                            var pdf_thread = new Thread<void> ("pdf_thread", () => {
                                // Run PDF conversion
                                Subprocess weasyprint = new Subprocess.newv (command, SubprocessFlags.STDERR_MERGE);
                                res = weasyprint.wait ();
                                status.destroy ();

                                // Clean up intermediate files
                                try {
                                    File temp_html = File.new_for_path (temp_html_file);
                                    temp_html.delete ();
                                } catch (Error e) {
                                    warning ("Could not delete cache file %s, %s", temp_html_file, e.message);
                                }

                                return;
                            });
                            status.run ();
                            pdf_thread.join ();
                        }
                    } catch (Error e) {
                        warning ("Could not generate pdf: %s", e.message);
                    }
                }
            } else {
                var print_operation = new WebKit.PrintOperation (publisher_instance.preview);
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
                print_operation.finished.connect (() => {
                    status.destroy ();
                });
                print_operation.failed.connect (() => {
                    status.destroy ();
                });
                print_operation.print ();
                status.run ();
            }

            if (new_novel.query_exists ()) {
                return true;
            } else {
                return false;
            }
        }
    }
}