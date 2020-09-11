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
    public class ThemeSelector : Gtk.Box {
        public Gtk.FlowBox preview_items;
        private Gtk.Grid app_box;
        private PreviewDrop drop_box;
        public static ThemeSelector instance;

        public ThemeSelector () {
            instance = this;
            build_ui ();
        }

        public void build_ui () {
            var settings = AppSettings.get_default ();
            app_box = new Gtk.Grid ();
            app_box.margin = 12;
            app_box.row_spacing = 12;
            app_box.column_spacing = 12;
            app_box.orientation = Orientation.VERTICAL;
            app_box.hexpand = true;

            var preview_box = new Gtk.ScrolledWindow (null, null);
            preview_box.min_content_height = settings.window_height / 2;
            preview_items = new Gtk.FlowBox ();
            preview_items.margin = 6;
            preview_box.add (preview_items);

            drop_box = new PreviewDrop ();
            drop_box.xalign = 0;

            var border = new Gtk.Frame("Drop Style.ultheme:");
            border.add (drop_box);

            app_box.attach (border, 0, 0, 1, 1);
            app_box.attach (preview_box, 0, 1, 1, 3);
            app_box.hexpand = true;

            preview_items.add (new DefaultTheme ());
            add (app_box);

           GLib.Idle.add (load_themes);

            show_all ();
        }

        public bool load_themes () {
            // Load previous added themes
            try {
                Dir theme_dir = Dir.open (UserData.style_path, 0);
                string? file_name = null;
                while ((file_name = theme_dir.read_name()) != null) {
                    if (!file_name.has_prefix(".")) {
                        if (file_name.down ().has_suffix ("ultheme")) {
                            string style_path = Path.build_filename (UserData.style_path, file_name);
                            File style_file = File.new_for_path (style_path);
                            var new_styles = new Ultheme.Parser (style_file);

                            ThemePreview dark_preview = new ThemePreview (new_styles, true);
                            ThemePreview light_preview = new ThemePreview (new_styles, false);

                            if (ThemeSelector.instance != null) {
                                ThemeSelector.instance.preview_items.add (dark_preview);
                                ThemeSelector.instance.preview_items.add (light_preview);
                            }
                        }
                    }
                }
            } catch (Error e) {
                warning ("Could not load themes: %s", e.message);
            }

            return false;
        }

        private class PreviewDrop : Gtk.Label {
            public PreviewDrop () {
                build_ui ();
            }

            public void build_ui () {
                label = "\n\n\n\n<small>Stored in <a href='file://" + UserData.style_path + "'>" + UserData.style_path + "</a>.</small>";
                use_markup = true;
                set_justify (Justification.LEFT);
                xalign = 0;

                // Drag and Drop Support
                Gtk.drag_dest_set (
                    this,                        // widget will be drag-able
                    DestDefaults.ALL,              // modifier that will start a drag
                    target_list,                   // lists of target to support
                    Gdk.DragAction.COPY            // what to do with data after dropped
                );
                this.drag_motion.connect(this.on_drag_motion);
                this.drag_leave.connect(this.on_drag_leave);
                this.drag_drop.connect(this.on_drag_drop);
                this.drag_data_received.connect(this.on_drag_data_received);
                show_all ();
            }

            private bool on_drag_motion (
                Widget widget,
                DragContext context,
                int x,
                int y,
                uint time)
            {
                // set_shadow_type (Gtk.ShadowType.ETCHED_OUT);
                return false;
            }

            private void on_drag_leave (Widget widget, DragContext context, uint time) {
                // set_shadow_type (Gtk.ShadowType.ETCHED_IN);
            }

            private bool on_drag_drop (
                Widget widget,
                DragContext context,
                int x,
                int y,
                uint time)
            {
                var target_type = (Atom) context.list_targets().nth_data (Target.STRING);

                if (!target_type.name ().ascii_up ().contains ("STRING"))
                {
                    target_type = (Atom) context.list_targets().nth_data (Target.URI);
                }

                // Request the data from the source.
                Gtk.drag_get_data (
                    widget,         // will receive 'drag_data_received' signal
                    context,        // represents the current state of the DnD
                    target_type,    // the target type we want
                    time            // time stamp
                    );
    
                bool is_valid_drop_site = target_type.name ().ascii_up ().contains ("STRING") || target_type.name ().ascii_up ().contains ("URI");
    
                return is_valid_drop_site;
            }
    
            private void on_drag_data_received (
                Widget widget,
                DragContext context,
                int x,
                int y,
                SelectionData selection_data,
                uint target_type,
                uint time)
            {
                string file_to_parse = "";
                File file = dnd_get_file (selection_data, target_type);
                if (!file.query_exists ()) {
                    Gtk.drag_finish (context, false, false, time);
                    return;
                }

                if (!file.get_basename ().down ().has_suffix (".ultheme")) {
                    Gtk.drag_finish (context, false, false, time);
                    return;
                }

                try {
                    File destination = File.new_for_path (Path.build_filename (UserData.style_path, file.get_basename ()));

                    if (destination.query_exists ()) {
                        // Possibly overwrite theme, but don't double draw widget
                        file.copy (destination, FileCopyFlags.OVERWRITE);
                        Gtk.drag_finish (context, true, false, time);
                        return;
                    }

                    file.copy (destination, FileCopyFlags.OVERWRITE);
                    var new_styles = new Ultheme.Parser (destination);

                    ThemePreview dark_preview = new ThemePreview (new_styles, true);
                    ThemePreview light_preview = new ThemePreview (new_styles, false);

                    instance.preview_items.add (dark_preview);
                    instance.preview_items.add (light_preview);
                    instance.show_all ();
                } catch (Error e) {
                    warning ("Failing generating preview: %s\n", e.message);
                }
                Gtk.drag_finish (context, true, false, time);
            }
        }
    }
}