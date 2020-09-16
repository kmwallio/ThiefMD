/*
 * Copyright (C) 2020 kmwallio
 * 
 * Modified September 2, 2020
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
    public class About : AboutDialog {
        private Gtk.Stack stack;

        public About () {
            set_transient_for (ThiefApp.get_instance ().main_window);
            resizable = false;
            deletable = true;
            modal = true;
            build_ui ();
        }

        private void build_ui () {
            window_position = WindowPosition.CENTER;

            program_name = ThiefProperties.NAME;
            comments = ThiefProperties.TAGLINE;
            copyright = ThiefProperties.COPYRIGHT;
            version = ThiefProperties.VERSION;
            website = ThiefProperties.URL;
            license_type = ThiefProperties.LICENSE_TYPE;

            try {
                IconTheme icon_theme = IconTheme.get_default();
                var thief_icon = icon_theme.load_icon("com.github.kmwallio.thiefmd", 128, IconLookupFlags.FORCE_SVG);
                logo = thief_icon;
            } catch (Error e) {
                warning ("Could not load logo: %s", e.message);
            }

            add_credit_section ("Credits", ThiefProperties.GIANTS);

            response.connect ((response_id) => {
                if (response_id == Gtk.ResponseType.CANCEL || response_id == Gtk.ResponseType.DELETE_EVENT) {
                    destroy ();
                }
            });
        }
    }
}