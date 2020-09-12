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

namespace ThiefMD.Controllers.UserData {
    public string data_path;
    public string style_path;
    public string scheme_path;
    public string css_path;

    public void create_data_directories () {
        data_path = Path.build_path (
                        Path.DIR_SEPARATOR_S,
                        Environment.get_user_data_dir (),
                        Constants.DATA_BASE);
        
        style_path = Path.build_path (
                        Path.DIR_SEPARATOR_S,
                        data_path,
                        Constants.DATA_STYLES);

        scheme_path = Path.build_path (
                        Path.DIR_SEPARATOR_S,
                        data_path,
                        Constants.DATA_SCHEMES);

        UI.UserSchemes ().append_search_path (scheme_path);

        try {
            File style_file = File.new_for_path (style_path);
            if (!style_file.query_exists ()) {
                style_file.make_directory_with_parents ();
            }
        } catch (Error e) {
            warning ("Error: %s\n", e.message);
        }

        try {
            File scheme_file = File.new_for_path (scheme_path);
            if (!scheme_file.query_exists ()) {
                scheme_file.make_directory_with_parents ();
            }
        } catch (Error e) {
            warning ("Error: %s\n", e.message);
        }
    }

    public string? get_trash_folder () {
        string? home_folder = Environment.get_variable ("XDG_DATA_HOME");
        string? trash_folder = null;
        if (home_folder == null) {
            home_folder = Environment.get_variable ("HOME");
            if (home_folder == null) {
                home_folder = Environment.get_home_dir ();
            }
            trash_folder = Path.build_path (
                                Path.DIR_SEPARATOR_S,
                                home_folder,
                                ".local",
                                "share",
                                "Trash");
        } else {
            trash_folder = Path.build_path (
                Path.DIR_SEPARATOR_S,
                home_folder,
                "Trash");
        }
        warning ("Using %s for trash", trash_folder);
        return trash_folder;
    }
}