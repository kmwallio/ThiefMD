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
    public class SoloEditor : Gtk.ApplicationWindow {
        public Editor editor;
        private Gtk.Box vbox;
        private Preview preview;
        private Gtk.ScrolledWindow scroller;
        private Adw.HeaderBar headerbar;
        private Adw.WindowTitle title_widget;
        private File file;
        private TimedMutex preview_mutex;
        public Gtk.Paned preview_display;

        public SoloEditor (File fp) {
            file = fp;
            editor = new Editor (file.get_path ());
            preview_mutex = new TimedMutex (250);
            new KeyBindings (this, false);
            build_ui ();
        }

        private void build_ui () {
            var settings = AppSettings.get_default ();
            headerbar = new Adw.HeaderBar ();

            vbox = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
            scroller = new Gtk.ScrolledWindow ();
            scroller.set_policy (Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC);

            string title = "";
            if (!settings.brandless) {
                title = "ThiefMD: ";
            }
            title += file.get_basename ();
            title_widget = new Adw.WindowTitle (title, settings.show_filename ? file.get_parent ().get_path () : "");
            headerbar.set_title_widget (title_widget);
            headerbar.add_css_class ("flat");
            headerbar.add_css_class ("thief-toolbar");
            headerbar.add_css_class("thiefmd-toolbar");
            headerbar.set_show_start_title_buttons (true);
            headerbar.set_show_end_title_buttons (true);

            populate_header ();

            preview_display = new Gtk.Paned (Gtk.Orientation.HORIZONTAL);
            scroller.vexpand = true;
            scroller.hexpand = true;
            editor.vexpand = true;
            editor.hexpand = true;
            set_titlebar (headerbar);
            scroller.set_child (editor);
            vbox.append (scroller);
            set_child (vbox);
            set_default_size (settings.window_width, settings.window_height);

            editor.buffer.changed.connect (update_preview);

            close_request.connect (this.on_delete_event);
        }

        private uint solo_resize_timeout_id = 0;
        
        public override void size_allocate (int width, int height, int baseline) {
            base.size_allocate (width, height, baseline);
            
            // Debounce resize events
            if (solo_resize_timeout_id != 0) {
                Source.remove (solo_resize_timeout_id);
            }
            
            solo_resize_timeout_id = Timeout.add (50, () => {
                solo_resize_timeout_id = 0;
                editor.dynamic_margins ();
                return false;
            });
        }

        private void populate_header () {
            var menu_button = new Gtk.MenuButton ();
            menu_button.has_tooltip = true;
            menu_button.tooltip_text = (_("Settings"));
            menu_button.set_icon_name ("open-menu-symbolic");
            menu_button.popover = new QuickPreferences (this);
            headerbar.pack_end (menu_button);
        }

        private void update_preview () {
            if (preview != null && preview_mutex != null && preview_mutex.can_do_action ()) {
                editor.update_preview ();
                preview.update_html_view (true, editor.preview_markdown, has_fountain ());
            }
        }

        public void export () {
            PublisherPreviewWindow ppw = new PublisherPreviewWindow (editor.get_buffer_text (), has_fountain ());
            ppw.show ();
        }

        public void toggle_preview () {
            int w = get_allocated_width ();
            int h = get_allocated_height ();
            if (preview_display.get_start_child () == null) {
                // Remove default display
                vbox.remove (scroller);

                // Populate the preview display
                preview_display.set_start_child (scroller);
                preview = new Preview ();
                preview.base_path = file.get_parent ().get_path ();
                preview_mutex = new TimedMutex ();
                preview.update_html_view (true, editor.get_buffer_text (), has_fountain ());
                preview_display.set_end_child (preview);

                vbox.append (preview_display);
                preview_display.show ();
                preview_display.set_position (w / 2);
                preview.show ();
                update_preview ();
            } else {
                vbox.remove (preview_display);
                preview_display.set_start_child (null);
                preview_display.set_end_child (null);
                preview = null;
                vbox.append (scroller);
            }
        }

        public void get_editor_size (out int w, out int h) {
            w = get_allocated_width ();
            h = get_allocated_height ();
            if (preview_display.get_start_child () != null) {
                w = preview_display.get_position ();
            }
        }

        public bool already_opened (File f) {
            if (file != null) {
                return (f.get_path () == file.get_path ());
            }
            return true;
        }

        public bool on_delete_event () {
            editor.save ();
            ThiefApplication.close_window (this);
            return true;
        }

        public bool has_fountain () {
            return is_fountain (file.get_basename ());
        }
    }
}
