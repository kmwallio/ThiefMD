/*
 * Copyright (C) 2020 kmwallio
 * 
 * Modified July 6, 2022
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

namespace ThiefMD {
    public class WelcomeWindow : Gtk.ApplicationWindow {
        public WelcomeWindow () {
            build_ui ();
        }

        private void build_ui () {
            var settings = AppSettings.get_default ();
            var h_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 12);
            var v_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 6);
            v_box.margin_top = 6;
            v_box.margin_bottom = 6;
            v_box.margin_start = 6;
            v_box.margin_end = 6;
            v_box.hexpand = true;
            v_box.vexpand = false;
            v_box.valign = Gtk.Align.CENTER;

            Adw.HeaderBar bar = new Adw.HeaderBar ();
            var title_widget = new Adw.WindowTitle (_("Welcome to ThiefMD"), "");
            bar.set_title_widget (title_widget);
            bar.set_show_start_title_buttons (true);
            bar.set_show_end_title_buttons (true);
            var header_context = bar.get_style_context ();
            header_context.add_class ("thief-toolbar");
            header_context.add_class("thiefmd-toolbar");

            var add_library_button = new Gtk.Button ();
            add_library_button.hexpand = true;
            add_library_button.vexpand = false;
            add_library_button.has_tooltip = true;
            add_library_button.tooltip_text = (_("Add Folder to Library"));
            var add_library_content = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
            var add_library_image = new Gtk.Image.from_icon_name ("folder-new-symbolic");
            add_library_image.pixel_size = 24;
            var add_library_label = new Gtk.Label (_("Add Folder to Library"));
            add_library_label.xalign = 0;
            add_library_label.halign = Gtk.Align.START;
            add_library_content.append (add_library_image);
            add_library_content.append (add_library_label);
            add_library_content.halign = Gtk.Align.START;
            add_library_button.set_child (add_library_content);
            add_library_button.clicked.connect (() => {
                string new_lib = Dialogs.select_folder_dialog ();
                if (FileUtils.test(new_lib, FileTest.IS_DIR)) {
                    if (settings.add_to_library (new_lib)) {
                        // Refresh
                        ThiefApp instance = ThiefApp.get_instance ();
                        instance.refresh_library ();
                        ThiefApp.show_main_instance ();
                        this.close ();
                    }
                }
            });

            v_box.append (add_library_button);

            var open_solo_editor = new Gtk.Button ();
            open_solo_editor.hexpand = true;
            open_solo_editor.vexpand = false;
            open_solo_editor.has_tooltip = true;
            open_solo_editor.tooltip_text = (_("Open File"));
            var open_solo_content = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
            var open_solo_image = new Gtk.Image.from_icon_name ("document-open-symbolic");
            open_solo_image.pixel_size = 24;
            var open_solo_label = new Gtk.Label (_("Open File"));
            open_solo_label.xalign = 0;
            open_solo_label.halign = Gtk.Align.START;
            open_solo_content.append (open_solo_image);
            open_solo_content.append (open_solo_label);
            open_solo_content.halign = Gtk.Align.START;
            open_solo_editor.set_child (open_solo_content);
            open_solo_editor.clicked.connect (() => {
                File? open_file = Dialogs.display_open_dialog (ThiefProperties.SUPPORTED_OPEN_FILES);
                if (open_file != null && open_file.query_exists ()) {
                    ThiefApplication.open_file (open_file);
                    this.close ();
                }
            });

            v_box.append (open_solo_editor);

            // Try to load library image as a responsive hero
            try {
                var library = new Gtk.Picture.for_resource ("/com/github/kmwallio/thiefmd/icons/library.png");
                library.hexpand = true;
                library.vexpand = true;
                library.set_size_request (520, 0); // give it breathing room horizontally
                library.content_fit = Gtk.ContentFit.SCALE_DOWN;
                h_box.append (library);
            } catch (Error e) {
                warning ("Could not load logo: %s", e.message);
            }
            h_box.append (v_box);

            close_request.connect (() => {
                return ThiefApplication.close_window (this);
            });
            set_titlebar (bar);
            set_child (h_box);

            set_sensible_default_size ();
            present ();
        }

        private void set_sensible_default_size () {
            // Aim for a large-but-not-fullscreen window to showcase the hero image
            int target_w = 512;
            int target_h = 430;

            var display = this.get_display ();
            if (display != null) {
                Gdk.Monitor? monitor = null;

                // Prefer the monitor that will contain this surface; fall back to the first monitor
                var surface = this.get_surface ();
                if (surface != null) {
                    monitor = display.get_monitor_at_surface (surface);
                }

                if (monitor == null) {
                    var monitors = display.get_monitors ();
                    if (monitors != null && monitors.get_n_items () > 0) {
                        monitor = monitors.get_item (0) as Gdk.Monitor;
                    }
                }

                if (monitor != null) {
                    Gdk.Rectangle geo = monitor.get_geometry ();
                    // Cap at 90% of the monitor, but allow generous max bounds
                    target_w = (int) Math.fmin ((double) geo.width * 0.90, 512.0);
                    target_h = (int) Math.fmin ((double) geo.height * 0.85, 430.0);
                    // Ensure we are not too small to show the image and controls
                    target_w = int.max (target_w, 512);
                    target_h = int.max (target_h, 430);
                }
            }

            set_default_size (target_w, target_h);
        }
    }
}
