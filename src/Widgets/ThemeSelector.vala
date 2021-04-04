/*
 * Copyright (C) 2020 kmwallio
 * 
 * Modified September 8, 2020
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

namespace ThiefMD.Widgets {
    public class ThiefFontSelector : Gtk.Box {
        public ThiefFontSelector () {
            build_ui ();
        }

        public bool filter_fonts (Pango.FontFamily fam, Pango.FontFace face) {
            return (!face.get_face_name ().down ().contains ("bold") &&
                    !face.get_face_name ().down ().contains ("italic") &&
                    !face.get_face_name ().down ().contains ("oblique"));
        }

        public void build_ui () {
            var settings = AppSettings.get_default ();
            var grid = new Gtk.Grid ();
            int other = 2;
            int items = 0;
            grid.orientation = Gtk.Orientation.VERTICAL;
            grid.hexpand = true;
            Gee.LinkedList<string> fonts = new Gee.LinkedList<string> ();
            Gee.LinkedList<int> font_sizes = new Gee.LinkedList<int> ();
            Gee.LinkedList<double?> line_spacings = new Gee.LinkedList<double?> ((num1, num2) => {
                return num1 == num2;
            });

            var font_label = new Gtk.Label (_("Font"));
            font_label.xalign = 0;
            font_label.margin = 12;
            font_label.use_markup = true;

            var line_label = new Gtk.Label (_("Spacing"));

            var font_selector = new Gtk.ComboBoxText ();
            font_selector.append_text ("Stolen Victory Duo");
            fonts.add ("Stolen Victory Duo");
            font_selector.append_text ("Stolen Victory Sans");
            fonts.add ("Stolen Victory Sans");
            font_selector.append_text ("iA Writer Duospace");
            fonts.add ("iA Writer Duospace");
            font_selector.append_text ("Courier Prime");
            fonts.add ("Courier Prime");

            var set_font_desc = Pango.FontDescription.from_string (settings.font_family);
            string? set_font_fam = set_font_desc.get_family ();
            if (settings.font_family != null && set_font_fam != null && settings.font_family.chug ().chomp () != "" && !fonts.contains (set_font_fam)) {
                font_selector.append_text (set_font_fam);
                fonts.add (set_font_fam);
                font_selector.set_active (fonts.index_of (set_font_fam));
                other = 3;
                items = 3;
            } else if (set_font_fam != null && fonts.contains (set_font_fam)) {
                font_selector.set_active (fonts.index_of (set_font_fam));
            } else {
                font_selector.set_active (0);
                items = 2;
            }

            var font_size_selector = new Gtk.ComboBoxText ();
            int scale = 2;
            for (int i = 6; i <= 72; i += scale) {
                font_size_selector.append_text (i.to_string ());
                font_sizes.add (i);
                if (i >= 16) {
                    scale = 4;
                }

                if (i >= 24) {
                    scale = 24;
                }
            }

            var line_spacing_selector = new Gtk.ComboBoxText ();
            for (double i = 1.0; i <= 3.5; i += 0.5) {
                line_spacing_selector.append_text (i.to_string ());
                line_spacings.add (i);
            }

            if (!font_sizes.contains (settings.font_size) && settings.font_size > 0 && settings.font_size <= 240) {
                font_sizes.add (settings.font_size);
                font_size_selector.set_active (font_sizes.index_of (settings.font_size));
            } else if (font_sizes.contains (settings.font_size)) {
                font_size_selector.set_active (font_sizes.index_of (settings.font_size));
            } else {
                font_size_selector.set_active (font_sizes.index_of (12));
            }

            if (!line_spacings.contains (settings.line_spacing) && settings.line_spacing >= 1.0 && settings.font_size <= 3.5) {
                line_spacings.add (settings.line_spacing);
                line_spacing_selector.set_active (line_spacings.index_of (settings.line_spacing));
            } else if (line_spacings.contains (settings.line_spacing)) {
                line_spacing_selector.set_active (line_spacings.index_of (settings.line_spacing));
            } else {
                line_spacing_selector.set_active (0);
            }

            font_selector.append_text ("Other");
            fonts.add ("Other");

            font_size_selector.changed.connect (() => {
                int option = font_size_selector.get_active ();
                if (option >= 0 && option < font_sizes.size) {
                    settings.font_size = font_sizes.get (option);
                }
                UI.load_font ();
            });

            line_spacing_selector.changed.connect (() => {
                int option = line_spacing_selector.get_active ();
                if (option >= 0 && option < line_spacings.size) {
                    settings.line_spacing = line_spacings.get (option);
                }
                UI.load_font ();
            });

            font_selector.changed.connect (() => {
                int option = font_selector.get_active ();
                if (option >= 0 && option < fonts.size && fonts.get (option) == "Other") {
                    Gtk.FontChooserDialog font_chooser = new Gtk.FontChooserDialog (_("Font Selector"), ThiefApp.get_instance ());
                    font_chooser.set_filter_func (filter_fonts);
                    Pango.FontDescription fontdesc = new Pango.FontDescription ();
                    if (settings.font_size > 0 && settings.font_size <= 240) {
                        fontdesc.set_size (settings.font_size * Pango.SCALE);
                    } else {
                        fontdesc.set_size (12 * Pango.SCALE);
                    }
                    font_chooser.set_font_desc (fontdesc);

                    int res = font_chooser.run ();
                    if (res != Gtk.ResponseType.CANCEL) {
                        string new_font = font_chooser.get_font_family ().get_name ();
                        string font_desc = font_chooser.get_font_desc ().to_string ();
                        int new_font_size = font_chooser.get_font_size ();
                        if (new_font_size > Pango.SCALE) {
                            new_font_size /= Pango.SCALE;
                        }
                        debug ("Selected font size: %d", new_font_size);
                        debug ("Setting font: %s", new_font);
                        settings.font_family = font_desc;
                        if (!fonts.contains (new_font)) {
                            font_selector.append_text (new_font);
                            fonts.add (new_font);
                        }
                        font_selector.set_active (fonts.index_of (new_font));
                        if (!font_sizes.contains (new_font_size)) {
                            font_size_selector.append_text (new_font_size.to_string ());
                            font_sizes.add (new_font_size);
                        }
                        settings.font_size = new_font_size;
                        font_size_selector.set_active (font_sizes.index_of (new_font_size));
                    } else {
                        if (settings.font_family == null || settings.font_family == "iA Writer Douspace" || settings.font_family.chug ().chomp () == "") {
                            font_selector.set_active (0);
                        } else if (settings.font_family == "Courier Prime") {
                            font_selector.set_active (1);
                        } else {
                            font_selector.set_active (2);
                        }
                    }
                    font_chooser.destroy ();
                } else if (option >= 0 && option < fonts.size && fonts.get (option) != "Other") {
                    settings.font_family = fonts.get (option);
                    debug ("Setting font to: %s", fonts.get (option));
                }

                UI.load_font ();
            });

            grid.attach (font_label, 0, 0, 1, 1);
            grid.attach (font_selector, 1, 0, 2, 1);
            grid.attach (font_size_selector, 3, 0, 1, 1);
            grid.attach (line_label, 0, 1, 1, 1);
            grid.attach (line_spacing_selector, 1, 1, 1, 1);
            grid.show_all ();

            add (grid);
        }
    }
    public class CssSelector : Gtk.Box {
        private string css_type;
        private Gtk.FlowBox app_box;
        private Gee.LinkedList<Gtk.Widget> wids;
        public CssSelector (string what) {
            css_type = what;
            wids = new Gee.LinkedList<Gtk.Widget> ();
            build_ui ();
        }

        public void build_ui () {
            app_box = new Gtk.FlowBox ();
            app_box.orientation = Gtk.Orientation.HORIZONTAL;
            app_box.margin = 6;
            app_box.max_children_per_line = 3;
            app_box.homogeneous = true;
            app_box.expand = false;
            app_box.hexpand = true;

            var none = new CssPreview ("", css_type == "print");
            var modest_splendor = new CssPreview ("modest-splendor", css_type == "print");
            app_box.add (none);
            app_box.add (modest_splendor);

            load_css ();

            add (app_box);
        }

        public void refresh () {
            while (!wids.is_empty) {
                app_box.remove (wids.poll ());
            }

            load_css ();
            show_all ();
        }

        public static Gee.LinkedList<string> list_css (string css_type = "print") {
            Gee.LinkedList<string> styles = new Gee.LinkedList<string> ();
            styles.add ("None");
            styles.add ("modest-splendor");
            try {
                Dir css_dir = Dir.open (UserData.css_path, 0);

                string? theme_pkg = "";
                while ((theme_pkg = css_dir.read_name ()) != null) {
                    string path = Path.build_filename (UserData.css_path, theme_pkg);
                    if (!theme_pkg.has_prefix (".") && FileUtils.test(path, FileTest.IS_DIR)) {
                        File print_css = File.new_for_path (Path.build_filename (UserData.css_path, theme_pkg, "print.css"));
                        File preview_css = File.new_for_path (Path.build_filename (UserData.css_path, theme_pkg, "preview.css"));
                        if (css_type == "print" && print_css.query_exists ()) {
                            styles.add (theme_pkg);
                        } else if (css_type == "preview" && preview_css.query_exists ()) {
                            styles.add (theme_pkg);
                        }
                    }
                }
            } catch (Error e) {
                warning ("Error loading css export packages: %s", e.message);
            }

            return styles;
        }

        public bool load_css () {
            try {
                Dir css_dir = Dir.open (UserData.css_path, 0);

                string? theme_pkg = "";
                while ((theme_pkg = css_dir.read_name ()) != null) {
                    string path = Path.build_filename (UserData.css_path, theme_pkg);
                    if (!theme_pkg.has_prefix (".") && FileUtils.test(path, FileTest.IS_DIR)) {
                        File print_css = File.new_for_path (Path.build_filename (UserData.css_path, theme_pkg, "print.css"));
                        File preview_css = File.new_for_path (Path.build_filename (UserData.css_path, theme_pkg, "preview.css"));
                        if (css_type == "print" && print_css.query_exists ()) {
                            var new_opt = new CssPreview (theme_pkg, true);
                            new_opt.set_size_request (Constants.CSS_PREVIEW_WIDTH, Constants.CSS_PREVIEW_HEIGHT);
                            app_box.add (new_opt);
                            wids.add (new_opt);
                        } else if (css_type == "preview" && preview_css.query_exists ()) {
                            var new_opt = new CssPreview (theme_pkg, false);
                            new_opt.set_size_request (Constants.CSS_PREVIEW_WIDTH, Constants.CSS_PREVIEW_HEIGHT);
                            app_box.add (new_opt);
                            wids.add (new_opt);
                        }
                    }
                }
            } catch (Error e) {
                warning ("Error loading css export packages: %s", e.message);
            }

            return false;
        }
    }

    public class ThemeSelector : Gtk.Box {
        public Gtk.FlowBox preview_items;
        private Gtk.Grid app_box;
        public static ThemeSelector instance;

        public ThemeSelector () {
            instance = this;
            build_ui ();
        }

        public void build_ui () {
            app_box = new Gtk.Grid ();
            app_box.margin = 12;
            app_box.row_spacing = 12;
            app_box.column_spacing = 12;
            app_box.orientation = Orientation.VERTICAL;
            app_box.hexpand = true;

            preview_items = new Gtk.FlowBox ();
            preview_items.margin = 6;
            preview_items.max_children_per_line = 3;
            preview_items.homogeneous = true;
            preview_items.expand = false;
            preview_items.hexpand = true;

            app_box.attach (preview_items, 0, 1, 1, 3);
            app_box.hexpand = true;

            var get_themes = new Gtk.Label (_("Download") + "<a href='https://themes.thiefmd.com/themes/'>" + _("more themes") + "</a>.\n<small>" + _("Stored in") + "<a href='file://" + UserData.style_path + "'>" + UserData.style_path + "</a>.</small>");
            get_themes.use_markup = true;
            get_themes.xalign = 0;

            // preview_items.add (new UserTheme ());
            preview_items.add (new DefaultTheme ());
            app_box.attach (get_themes, 0, 5, 1, 1);
            add (app_box);

            load_themes ();

            show_all ();
        }

        public bool load_themes () {
            // Load previous added themes
            if (UI.user_themes == null) {
                return false;
            }

            foreach (var new_styles in UI.user_themes) {
                ThemePreview dark_preview = new ThemePreview (new_styles, true);
                ThemePreview light_preview = new ThemePreview (new_styles, false);

                ThemeSelector.instance.preview_items.add (dark_preview);
                ThemeSelector.instance.preview_items.add (light_preview);
                ThemeSelector.instance.preview_items.show_all ();
            }

            return false;
        }
    }
}