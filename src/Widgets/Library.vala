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
using Gtk;
using Gdk;

namespace ThiefMD.Widgets {
    /**
     * Library data object
     */
    private class LibPair : Object {
        public Sheets _sheets;
        public string _title;
        public string _path;
        public TreeIter _iter; // @TODO: Should be weak?

        public LibPair (string path, TreeIter iter) {
            if (path.has_suffix ("/")) {
                _path = path.substring(0, -1);
            } else {
                _path = path;
            }
            debug ("Got path : %s", _path);
            _title = _path.substring (_path.last_index_of ("/") + 1);
            _sheets = new Sheets(_path);
            _iter = iter;
        }

        public string to_string () {
            return _title;
        }
    }

    /**
     * Library or file tree view
     */
    public class Library : TreeView {
        private List<LibPair> _all_sheets;
        private TreeStore _lib_store;
        private LibPair _selected;
        private TreeIter _selected_node;
        NewFolder folder_popup;

        public Library () {
            debug ("Setting up library");
            _lib_store = new TreeStore (2, typeof (string), typeof (LibPair));
            // GLib.Idle.add (parse_library); // Breaks highlighting files on open
            parse_library ();
            set_model (_lib_store);
            insert_column_with_attributes (-1, "Library", new CellRendererText (), "text", 0, null);
            get_selection ().changed.connect (on_selection);
            folder_popup = new NewFolder ();

            // Drag and Drop Support
            enable_model_drag_dest (target_list, DragAction.MOVE);
            this.drag_motion.connect(this.on_drag_motion);
            this.drag_leave.connect(this.on_drag_leave);
            this.drag_drop.connect(this.on_drag_drop);
            this.drag_data_received.connect(this.on_drag_data_received);
        }

        public void set_active () {
            foreach (var pair in _all_sheets) {
                if (pair._sheets.has_active_sheet ()) {
                    TreePath? tree_path = _lib_store.get_path (pair._iter);
                    set_cursor (tree_path, null, false);
                }
            }
        }

        //
        // Library Functiuons
        //

        public void new_folder (string folder) {
            if ((folder.chomp() == "")) {
                return;
            }

            if (_selected != null && _all_sheets.find (_selected) != null) {
                debug ("Creating %s in %s", folder, _selected._path);
                string new_folder_path = Path.build_filename (_selected._path, folder);
                File newfolder = File.new_for_path (new_folder_path);
                if (newfolder.query_exists ()) {
                    return;
                }
                try {
                    newfolder.make_directory ();
                } catch (Error e) {
                    warning ("Could not make new directory: %s", e.message);
                }
                parse_dir (_selected._path, _selected_node);
            }
        }

        private void remove_children (string str_dir) {
            try {
                Dir dir = Dir.open (str_dir, 0);
                string? file_name = null;
                while ((file_name = dir.read_name()) != null) {
                    if (!file_name.has_prefix(".")) {
                        string path = Path.build_filename (str_dir, file_name);
                        if (FileUtils.test (path, FileTest.IS_DIR)) {
                            LibPair? kid = get_item (path);
                            if (kid != null) {
                                _all_sheets.remove (kid);
                                remove_children (path);
                            }
                        }
                    }
                }
            } catch (Error e) {
                warning ("Could not remove children from %s cleanly: %s", str_dir, e.message);
            }
        }

        private LibPair? get_item (string path) {
            foreach (LibPair pair in _all_sheets) {
                if (pair._sheets.get_sheets_path() == path) {
                    return pair;
                }
            }

            return null;
        }

        public bool has_sheets (string path) {
            foreach (LibPair pair in _all_sheets) {
                if (pair._sheets.get_sheets_path() == path) {
                    return true;
                }
            }

            return false;
        }

        public void refresh_sheets (string path) {
            foreach (LibPair pair in _all_sheets) {
                if (pair._sheets.get_sheets_path () == path) {
                    pair._sheets.load_sheets ();
                }
            }
        }

        public Sheets get_sheets (string path) {
            foreach (LibPair pair in _all_sheets) {
                debug ("Checking if %s is %s", path, pair._sheets.get_sheets_path());
                if (pair._sheets.get_sheets_path() == path) {
                    debug ("Found %s", path);
                    return pair._sheets;
                }
            }

            debug ("Could not find last opened project in library");
            return new Sheets(path);
        }

        public bool parse_library () {
            var settings = AppSettings.get_default ();
            settings.validate_library ();
            string[] library = settings.library ();

            TreeIter root;

            foreach (string lib in library) {
                if (lib.chomp () == "") {
                    continue;
                }
                if (!has_sheets (lib)) {
                    _lib_store.append (out root, null);
                    debug (lib);
                    LibPair pair = new LibPair(lib, root);
                    _lib_store.set (root, 0, pair._title, 1, pair, -1);
                    _all_sheets.append (pair);
                    parse_dir(lib, root);
                }
            }

            return false;
        }

        private void parse_dir (string str_dir, TreeIter iter) {
            try {
                // Create child iter
                TreeIter child;

                string excludeds = FileManager.get_file_contents (Path.build_filename (str_dir, ".thiefignore"));
                string[] excluded = excludeds.split("\n");

                // Loop through the directory
                Dir dir = Dir.open (str_dir, 0);
                string? file_name = null;
                while ((file_name = dir.read_name()) != null) {
                    if (!file_name.has_prefix(".") && !(file_name in excluded)) {
                        debug ("Found %s ", file_name);
                        string path = Path.build_filename (str_dir, file_name);
                        if (!has_sheets (path) && FileUtils.test(path, FileTest.IS_DIR)) {
                            _lib_store.append (out child, iter);
                            LibPair pair = new LibPair(path, child);
                            _all_sheets.append (pair);
                            // Append dir to list
                            _lib_store.set (child, 0, pair._title, 1, pair, -1);
                            parse_dir (path, child);
                        }
                    }
                }
            } catch (Error e) {
                debug ("Error: %s", e.message);
            }
        }

        public bool file_in_library (string file_path) {
            foreach (LibPair p in _all_sheets)
            {
                if (file_path.has_prefix (p._path))
                {
                    return true;
                }
            }
            return false;
        }

        //
        // Mouse Click Actions
        //

        public override bool button_press_event(Gdk.EventButton event) {
            base.button_press_event (event);

            if (event.type == Gdk.EventType.BUTTON_PRESS && event.button == 3) {
                var settings = AppSettings.get_default ();
                Gtk.Menu menu = new Gtk.Menu ();

                Gtk.MenuItem menu_add_item = new Gtk.MenuItem.with_label (_("Create Sub-Folder"));
                menu_add_item.activate.connect (() => {
                    if (_selected != null && _all_sheets.find (_selected) != null) {
                        TreePath? tree_path = _lib_store.get_path (_selected_node);
                        Rectangle r;
                        this.get_cell_area (tree_path, null, out r);
                        r.x += settings.view_library_width / 2;
                        r.y += 20;
                        folder_popup.set_pointing_to (r);
                        folder_popup.set_relative_to (this);
                        folder_popup.popup ();
                        //ThiefApp.get_instance ().refresh_library ();
                    }
                });
                menu.add (menu_add_item);

                if (_selected != null && !settings.is_in_library (_selected._path)) {
                    Gtk.MenuItem menu_hide_item = new Gtk.MenuItem.with_label (_("Hide from Library"));
                    menu_hide_item.activate.connect (() => {
                        TreeIter hide_node = _selected_node;
                        if (_selected != null && _all_sheets.find (_selected) != null) {
                            debug ("Hiding %s", _selected._path);
                            _all_sheets.remove (_selected);
                            FileManager.add_ignore_folder (_selected._path);
                            _lib_store.remove (ref hide_node);
                            remove_children (_selected._path);
                            //ThiefApp.get_instance ().refresh_library ();
                        }
                    });

                    menu.add (menu_hide_item);
                }

                Gtk.MenuItem menu_reveal_items = new Gtk.MenuItem.with_label (_("Show Hidden Items"));
                menu_reveal_items.activate.connect (() => {
                    if (_selected != null && _all_sheets.find (_selected) != null) {
                        FileManager.move_to_trash (Path.build_filename (_selected._path, ".thiefignore"));
                        parse_dir (_selected._path, _selected_node);
                        // ThiefApp.get_instance ().refresh_library ();
                    }
                });
                menu.add (menu_reveal_items);

                if (_selected != null && settings.is_in_library (_selected._path)) {
                    menu.add (new Gtk.SeparatorMenuItem ());

                    Gtk.MenuItem menu_remove_item = new Gtk.MenuItem.with_label (_("Remove from Library"));
                    menu_remove_item.activate.connect (() => {
                        TreeIter remove_node = _selected_node;
                        if (_selected != null && _all_sheets.find (_selected) != null) {
                            debug ("Removing %s", _selected._path);
                            _all_sheets.remove (_selected);
                            settings.remove_from_library (_selected._path);
                            _lib_store.remove (ref remove_node);
                            remove_children (_selected._path);
                            //ThiefApp.get_instance ().refresh_library ();
                        }
                    });
                    menu.add (menu_remove_item);
                }

                menu.attach_to_widget (this, null);
                menu.show_all ();
                menu.popup_at_pointer (event);
            }
            return true;
        }

        private void on_selection (TreeSelection selected) {
            TreeModel model;
            TreeIter iter;
            if (selected.get_selected (out model, out iter)) {
                LibPair p = convert_selection (model, iter);
                _selected = p;
                _selected_node = iter;
                debug ("Selected: %s", p._path);
                SheetManager.set_sheets(p._sheets);
                return;
            }
        }

        private LibPair convert_selection (TreeModel model, TreeIter iter) {
            LibPair p;
            string title = "";
            model.get (iter, 0, out title, 1, out p);
            return p;
        }

        //
        // Drag and Drop Support
        //

        // Highlight current tree item sheet is over
        private bool on_drag_motion (
            Widget widget,
            DragContext context,
            int x,
            int y,
            uint time)
        {
            /*TreePath? path;
            TreeViewDropPosition pos;
            if (get_dest_row_at_pos (x, y, out path, out pos)){
                TreeIter iter;
                string title;
                LibPair p;
                set_drag_dest_row (path, pos);
                create_row_drag_icon (path);
                _lib_store.get_iter (out iter, path);
                _lib_store.get (iter, 0, out title, 1, out p);
                debug ("Got location %s", p._path);
            }*/
            return false;
        }


        private void on_drag_leave (Widget widget, DragContext context, uint time) {
            debug ("%s: on_drag_leave", widget.name);
        }

        private bool on_drag_drop (
            Widget widget,
            DragContext context,
            int x,
            int y,
            uint time)
        {
            debug ("%s: on_drag_drop", widget.name);

            TreePath? path;
            TreeViewDropPosition pos;
            bool is_valid_drop_site = false;

            if ((context.list_targets() != null) &&
                 get_dest_row_at_pos (x, y, out path, out pos)) 
            {
                var target_type = (Atom) context.list_targets().nth_data (Target.STRING);

                debug ("Requested STRING, got: %s", target_type.name());

                if (!target_type.name ().ascii_up ().contains ("STRING"))
                {
                    target_type = (Atom) context.list_targets().nth_data (Target.URI);
                    debug ("Requested URI, got: %s", target_type.name());
                }

                // Request the data from the source.
                Gtk.drag_get_data (
                    widget,         // will receive 'drag_data_received' signal
                    context,        // represents the current state of the DnD
                    target_type,    // the target type we want
                    time            // time stamp
                    );

                is_valid_drop_site = true;
            }

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
            debug ("%s: on_drag_data_received", widget.name);

            bool dnd_success = false;
            bool delete_selection_data = false;
            bool item_in_library = false;
            string file_to_move = "";
            File? file = null;
            TreePath? path;
            TreeViewDropPosition pos;
            LibPair? p = null;

            if (get_dest_row_at_pos (x, y, out path, out pos)){
                TreeIter iter;
                string title;
                _lib_store.get_iter (out iter, path);
                _lib_store.get (iter, 0, out title, 1, out p);
                debug ("Got location %s", p._path);
            }

            // Deal with what we are given from source
            if ((selection_data != null) && (selection_data.get_length() >= 0)) 
            {
                if (context.get_suggested_action() == DragAction.MOVE)
                {
                    delete_selection_data = true;
                }

                // Check that we got the format we can use
                switch (target_type)
                {
                    case Target.URI:
                        file_to_move = (string) selection_data.get_data();
                    break;
                    case Target.STRING:
                        file_to_move = (string) selection_data.get_data();
                    break;
                    default:
                        dnd_success = false;
                        warning ("Invalid data type");
                    break;
                }

                debug ("Got %s", file_to_move);

                if (file_to_move != "")
                {
                    if (file_to_move.has_prefix ("file"))
                    {
                        debug ("Removing file prefix for %s", file_to_move.chomp ());
                        file = File.new_for_uri (file_to_move.chomp ());
                        string? check_path = file.get_path ();
                        if ((check_path == null) || (check_path.chomp () == ""))
                        {
                            debug ("No local path");
                            item_in_library = true;
                            delete_selection_data = false;
                        }
                        else
                        {
                            file_to_move = check_path.chomp ();
                            debug ("Result path: %s", file_to_move);
                        }
                    }

                    file = File.new_for_path (file_to_move);
                    item_in_library = file_in_library (file_to_move);

                    if (item_in_library && delete_selection_data && !FileUtils.test(file_to_move, FileTest.IS_DIR))
                    {
                        dnd_success = true;
                    }
                }
            }

            // This isn't in our library, check if it's a folder or file
            if (!item_in_library)
            {
                debug ("Item not in library");
                delete_selection_data = false;
                dnd_success = false;
                if (file.query_exists ())
                {
                    debug ("Item found");
                    if (FileUtils.test(file_to_move, FileTest.IS_DIR))
                    {
                        var settings = AppSettings.get_default ();
                        // Just add to library, no prompt 😅
                        if (settings.add_to_library (file_to_move))
                        {
                            ThiefApp instance = ThiefApp.get_instance ();
                            instance.refresh_library ();
                        }
                    }
                    else
                    {
                        debug ("Prompting for action");
                        Dialog prompt = new Dialog.with_buttons (
                            "Move into Library",
                            ThiefApp.get_instance ().main_window,
                            DialogFlags.MODAL | Gtk.DialogFlags.DESTROY_WITH_PARENT,
                            _("Copy"),
                            Gtk.ResponseType.NO,
                            _("Move"),
                            Gtk.ResponseType.YES);

                        prompt.response.connect((response_id) =>
                        {
                            prompt.close();
                            if (response_id == Gtk.ResponseType.NO)
                            {
                                try
                                {
                                    debug ("Copying %s to %s", file_to_move, p._path);
                                    FileManager.copy_item (file_to_move, p._path);
                                }
                                catch (Error e)
                                {
                                    warning ("Hit failure trying to move item in library: %s", e.message);
                                }
                            }
                            else if (response_id == Gtk.ResponseType.YES)
                            {
                                try
                                {
                                    debug ("Moving %s to %s", file_to_move, p._path);
                                    FileManager.move_item (file_to_move, p._path);
                                }
                                catch (Error e)
                                {
                                    warning ("Hit failure trying to move item in library: %s", e.message);
                                }
                            }
                            refresh_sheets (p._path);
                        });

                        prompt.show_all ();
                    }
                }
                else
                {
                    debug ("Item not found");
                }
            }

            // Default behavior
            if (dnd_success)
            {
                try
                {
                    debug ("Moving %s to %s", file_to_move, p._path);
                    FileManager.move_item (file_to_move, p._path);
                    refresh_sheets (p._path);
                    File? parent = file.get_parent ();
                    if (parent != null)
                    {
                        refresh_sheets (parent.get_path ());
                    }
                    UI.set_sheets (SheetManager.get_sheets ());
                }
                catch (Error e)
                {
                    warning ("Hit failure trying to move item in library: %s", e.message);
                    delete_selection_data = false;
                    dnd_success = false;
                }
            }
            else
            {
                delete_selection_data = false;
            }

            Gtk.drag_finish (context, dnd_success, delete_selection_data, time);
        }
    }
}
