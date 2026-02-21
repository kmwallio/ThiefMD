/*
 * Copyright (C) 2020 kmwallio
 * 
 * Permission is hereby granted, free of charge, to any person
 * obtaining a copy of this software and associated documentation
 * files (the "Software"), to deal in the Software without restriction,
 * including without limitation the rights to use, copy, modify,
 * merge, publish, distribute, sublicense, and/or sell copies of
 * the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall
 * be included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
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
    // Export a Fountain screenplay as an FDX (Final Draft) file.
    // Only shows up in the publisher preview when editing a Fountain file.
    public class ExportFdx : ExportBase {
        public override string export_name { get; protected set; }
        public override string export_css { get; protected set; }
        private PublisherPreviewWindow publisher_instance;

        public ExportFdx () {
            export_name = "FDX";
            export_css = "print";
            supports_markdown = false;
            supports_fountain = true;
        }

        public override string update_markdown (string markdown) {
            return markdown;
        }

        public override void attach (PublisherPreviewWindow ppw) {
            publisher_instance = ppw;
        }

        public override void detach () {
            publisher_instance = null;
        }

        public override bool export () {
            var fdx_filter = new Gtk.FileFilter ();
            fdx_filter.set_filter_name (_("Final Draft files"));
            fdx_filter.add_mime_type ("application/x-finaldraft");
            fdx_filter.add_pattern ("*.fdx");

            File? new_script = Dialogs.get_target_save_file_with_extension (
                _("Export Final Draft"),
                fdx_filter,
                "fdx");

            if (new_script == null) {
                return true;
            }

            try {
                if (new_script.query_exists ()) {
                    new_script.delete ();
                }

                string fdx_content = FountainFdx.fountain_to_fdx (
                    publisher_instance.get_export_markdown ());

                FileManager.save_file (new_script, fdx_content.data);
            } catch (Error e) {
                warning ("Could not save FDX file: %s", e.message);
            }

            return new_script.query_exists ();
        }
    }
}
