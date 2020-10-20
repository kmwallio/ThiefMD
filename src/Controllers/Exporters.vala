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
using ThiefMD.Exporters;

namespace ThiefMD.Controllers {
    public class Exporters {
        public Gee.Map<string, ExportBase> exporters;

        public Exporters () {
            exporters = new Gee.HashMap<string, ExportBase> ();
        }

        public bool remove (string name) {
            if (!exporters.has_key (name)) {
                return false;
            }

            ExportBase old = null;
            if (exporters.unset (name, out old)) {
                return true;
            }
            return false;
        }

        public bool register (string name, ExportBase exporter) {
            if (exporters.has_key (name)) {
                return false;
            }

            exporters.set (name, exporter);
            return true;
        }

        public ExportBase? get_exporter (string name) {
            ExportBase? exporter = null;

            if (exporters.has_key (name)) {
                exporter = exporters.get (name);
            }

            return exporter;
        }

        public Gee.Set<string> get_export_list () {
            return exporters.keys;
        }
    }
}