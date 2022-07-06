/*
 * Copyright (C) 2020 kmwallio
 * 
 * Modified August 29, 2020
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
    public class SoloEditor : Hdy.Window {
        private Editor editor;
        private Gtk.Box vbox;
        private Preview preview;
        private Gtk.ScrolledWindow scroller;
        private Hdy.HeaderBar headerbar;
        private File file;
        private TimedMutex preview_mutex;
        public Gtk.Paned preview_display;

        public SoloEditor (File fp) {
            file = fp;
            editor = new Editor (file.get_path ());
            new KeyBindings (this, false);
            build_ui ();
        }

        private void build_ui () {
            var settings = AppSettings.get_default ();
            headerbar = new Hdy.HeaderBar ();

            vbox = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
            scroller = new Gtk.ScrolledWindow (null, null);
            scroller.set_policy (Gtk.PolicyType.EXTERNAL, Gtk.PolicyType.AUTOMATIC);

            string title = "";
            if (!settings.brandless) {
                title = "ThiefMD: ";
            }
            title += file.get_basename ();
            headerbar.set_title (title);
            var header_context = headerbar.get_style_context ();
            header_context.add_class (Gtk.STYLE_CLASS_FLAT);
            header_context.add_class ("thief-toolbar");
            header_context.add_class("thiefmd-toolbar");
            headerbar.show_close_button = true;

            populate_header ();

            preview_display = new Gtk.Paned (Gtk.Orientation.HORIZONTAL);
            preview_display.add2 (preview);
            scroller.vexpand = true;
            scroller.hexpand = true;
            editor.vexpand = true;
            editor.hexpand = true;
            vbox.add (headerbar);
            scroller.add (editor);
            vbox.add (scroller);
            vbox.show_all ();
            add (vbox);
            set_default_size (settings.window_width, settings.window_height);

            editor.buffer.changed.connect (update_preview);

            delete_event.connect (this.on_delete_event);
        }

        private void populate_header () {
            var menu_button = new Gtk.MenuButton ();
            menu_button.has_tooltip = true;
            menu_button.tooltip_text = (_("Settings"));
            menu_button.set_image (new Gtk.Image.from_icon_name ("open-menu-symbolic", Gtk.IconSize.BUTTON));
            menu_button.popover = new QuickPreferences (this);
            headerbar.pack_end (menu_button);
        }

        private void update_preview () {
            if (preview != null && preview_mutex.can_do_action ()) {
                editor.update_preview ();
                preview.update_html_view (true, editor.preview_markdown, has_fountain ());
            }
        }

        public void export () {
            PublisherPreviewWindow ppw = new PublisherPreviewWindow (editor.get_buffer_text (), has_fountain ());
            ppw.show ();
        }

        public void toggle_preview () {
            int w = 0, h = 0;
            this.get_size (out w, out h);
            if (preview_display.get_child1 () == null) {
                // Remove default display
                vbox.remove (scroller);

                // Populate the preview display
                preview_display.add1 (scroller);
                preview = new Preview ();
                preview_mutex = new TimedMutex ();
                preview.update_html_view (true, editor.get_buffer_text (), has_fountain ());
                preview_display.add2 (preview);

                vbox.add (preview_display);
                preview_display.show_all ();
                preview_display.set_position (w / 2);
                vbox.show_all ();
                preview.show_all ();
                update_preview ();
            } else {
                vbox.remove (preview_display);
                preview_display.remove (scroller);
                preview_display.remove (preview);
                preview = null;
                vbox.add (scroller);
                vbox.show_all ();
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
            return false;
        }

        public bool has_fountain () {
            return is_fountain (file.get_basename ());
        }
    }
}
