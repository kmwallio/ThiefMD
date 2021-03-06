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
    public class ExportFountain : ExportBase {
        public override string export_name { get; protected set; }
        public override string export_css { get; protected set; }
        private PublisherPreviewWindow publisher_instance;

        public ExportFountain () {
            export_name = "Fountain";
            export_css = "print";
            supports_markdown = false;
            supports_fountain = true;
        }

        public override string update_markdown (string markdown) {
            return markdown;
        }

        public override void attach (PublisherPreviewWindow ppw) {
            publisher_instance = ppw;
            return;
        }

        public override void detach () {
            publisher_instance = null;
            return;
        }

        public override bool export () {
            var fountain_filter = new Gtk.FileFilter ();
            fountain_filter.set_filter_name (_("Fountain files"));
            fountain_filter.add_mime_type ("text/fountain");
            fountain_filter.add_pattern ("*.fountain");
            fountain_filter.add_pattern ("*.spmd");

            File new_script = Dialogs.get_target_save_file_with_extension (
                _("Export Fountain"),
                fountain_filter,
                "fountain");

            if (new_script == null) {
                return true;
            }

            try {
                if (new_script.query_exists ()) {
                    new_script.delete ();
                }

                FileManager.save_file (
                    new_script,
                    publisher_instance.get_export_markdown ().data);

            } catch (Error e) {
                warning ("Could not save fountain file: %s", e.message);
            }

            if (new_script.query_exists ()) {
                return true;
            } else {
                return false;
            }
        }
    }
}