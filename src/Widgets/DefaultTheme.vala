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

namespace ThiefMD.Widgets {
    public class DefaultTheme : Gtk.ToggleButton {
        private GtkSource.View view;
        private GtkSource.Buffer buffer;

        public DefaultTheme () {
            var settings = AppSettings.get_default ();
            margin_top = 0;
            margin_bottom = 0;
            margin_start = 0;
            margin_end = 0;
            view = new GtkSource.View ();
            view.margin_top = 0;
            view.margin_bottom = 0;
            view.margin_start = 0;
            view.margin_end = 0;
            buffer = new GtkSource.Buffer.with_language (UI.get_source_language ());
            buffer.highlight_syntax = true;
            view.editable = false;
            view.set_buffer (buffer);
            view.set_wrap_mode (Gtk.WrapMode.WORD);
            buffer.text = ThiefProperties.PREVIEW_TEXT.printf(ThiefProperties.NAME);
            set_child (view);

            var style_manager = GtkSource.StyleSchemeManager.get_default ();
            var style = style_manager.get_scheme ("thiefmd");
            buffer.set_style_scheme (style);

            clicked.connect (() => {
                var settings2 = AppSettings.get_default ();
                settings2.theme_id = "thiefmd";
                SheetManager.refresh_scheme ();
                UI.load_css_scheme ();
            });

            settings.changed.connect (() => {
                set_preview_state ();
            });

            set_preview_state ();

            set_visible (true);
        }

        private void set_preview_state () {
            var settings = AppSettings.get_default ();
            if (settings.theme_id == "thiefmd") {
                active = true;
            } else {
                active = false;
            }
        }
    }
}