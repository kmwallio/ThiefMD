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
        private PreventDelayedDrop _droppable;
        NewFolder folder_popup;

        public Library () {
            debug ("Setting up library");
            _lib_store = new TreeStore (2, typeof (string), typeof (LibPair));
            parse_library ();
            set_model (_lib_store);
            insert_column_with_attributes (-1, "Library", new CellRendererText (), "text", 0, null);
            get_selection ().changed.connect (on_selection);
            folder_popup = new NewFolder ();
            _droppable = new PreventDelayedDrop ();

            // Drop Support
            enable_model_drag_dest (target_list, DragAction.MOVE);
            this.drag_motion.connect(this.on_drag_motion);
            this.drag_leave.connect(this.on_drag_leave);
            this.drag_drop.connect(this.on_drag_drop);
            this.drag_data_received.connect(this.on_drag_data_received);
            
            // Drap support
            enable_model_drag_source (ModifierType.BUTTON1_MASK, target_list, DragAction.MOVE);
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
                parse_dir (_selected._sheets, _selected._path, _selected_node);
            }
        }

        private void remove_children (string str_dir) {
            File temp = File.new_for_path (str_dir);
            if (temp.query_exists ()) {
                try {
                    Dir dir = Dir.open (str_dir, 0);
                    string? file_name = null;
                    while ((file_name = dir.read_name()) != null) {
                        if (!file_name.has_prefix(".")) {
                            string path = Path.build_filename (str_dir, file_name);
                            if (FileUtils.test (path, FileTest.IS_DIR)) {
                                LibPair? kid = get_item (path);
                                if (kid != null) {
                                    kid._sheets.close_active_files ();
                                    if (SheetManager._current_sheets == kid._sheets) {
                                        SheetManager.set_sheets (null);
                                    }
                                    _all_sheets.remove (kid);
                                    remove_children (path);
                                }
                            }
                        }
                    }
                } catch (Error e) {
                    warning ("Could not remove children from %s cleanly: %s", str_dir, e.message);
                }
            } else {
                string rem_kids = str_dir.has_suffix (Path.DIR_SEPARATOR_S) ? str_dir : str_dir + Path.DIR_SEPARATOR_S;
                Gee.LinkedList<LibPair> bad_kids = new Gee.LinkedList<LibPair> ();
                foreach (var kid in _all_sheets) {
                    if (kid._path.has_prefix (rem_kids)) {
                        bad_kids.add (kid);
                    }
                }

                foreach (var bad_kid in bad_kids) {
                    bad_kid._sheets.close_active_files ();
                    if (SheetManager._current_sheets == bad_kid._sheets) {
                        SheetManager.set_sheets (null);
                    }
                    _all_sheets.remove (bad_kid);
                }
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
                    pair._sheets.refresh ();
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

                    parse_dir(pair._sheets, lib, root);
                }
            }

            Timeout.add (150, pick_item);

            return false;
        }

        private bool pick_item () {
            if (_selected == null) {
                foreach (LibPair pair in _all_sheets) {
                    TreePath? tree_path = _lib_store.get_path (pair._iter);
                    if (tree_path != null) {
                        set_cursor (tree_path, null, false);
                        break;
                    }
                }
            }
            return false;
        }

        public void refresh_dir (Sheets sheet_dir) {
            LibPair? p = get_item (sheet_dir.get_sheets_path ());
            if (p != null) {
                parse_dir (sheet_dir, sheet_dir.get_sheets_path (), p._iter);
            }
        }

        public void remove_item (string path) {
            var settings = AppSettings.get_default ();
            LibPair? p = get_item (path);

            if (p != null) {
                remove_children (path);
                if (p != null) {
                    _all_sheets.remove (p);
                    _lib_store.remove (ref p._iter);
                }
                settings.writing_changed ();
            }
        }

        private void parse_dir (Sheets sheet_dir, string str_dir, TreeIter iter) {
            var settings = AppSettings.get_default ();
            try {
                // Create child iter
                TreeIter child;

                // Load ordered folders
                foreach (var file_name in sheet_dir.metadata.folder_order) {
                    if (!file_name.has_prefix(".") && !sheet_dir.metadata.hidden_folders.contains(file_name)) {
                        string path = Path.build_filename (str_dir, file_name);
                        File file = File.new_for_path (path);
                        if (file.query_exists () && !has_sheets (path) && FileUtils.test(path, FileTest.IS_DIR)) {
                            _lib_store.append (out child, iter);
                            LibPair pair = new LibPair(path, child);
                            _all_sheets.append (pair);
                            // Append dir to list
                            _lib_store.set (child, 0, pair._title, 1, pair, -1);

                            parse_dir (pair._sheets, path, child);
                        } else if (!file.query_exists ()) {
                            remove_children (path);
                            LibPair p = get_item (path);
                            if (p != null) {
                                _all_sheets.remove (p);
                                _lib_store.remove (ref p._iter);
                            }
                            settings.writing_changed ();
                        }
                    }
                }

                // Loop through the directory
                Dir dir = Dir.open (str_dir, 0);
                string? file_name = null;
                while ((file_name = dir.read_name()) != null) {
                    if (!file_name.has_prefix(".") && !sheet_dir.metadata.hidden_folders.contains(file_name)) {
                        string path = Path.build_filename (str_dir, file_name);
                        if (!has_sheets (path) && FileUtils.test(path, FileTest.IS_DIR)) {
                            _lib_store.append (out child, iter);
                            LibPair pair = new LibPair(path, child);
                            _all_sheets.append (pair);
                            // Append dir to list
                            _lib_store.set (child, 0, pair._title, 1, pair, -1);
                            sheet_dir.metadata.add_folder (file_name);

                            parse_dir (pair._sheets, path, child);
                        }
                    }
                }
            } catch (Error e) {
                debug ("Error: %s", e.message);
            }
        }

        public bool file_in_library (string file_path) {
            bool is_dir = FileUtils.test (file_path, FileTest.IS_DIR);
            foreach (LibPair p in _all_sheets)
            {
                if (!is_dir) {
                    if (file_path.down ().has_prefix (p._path.down ()))
                    {
                        return true;
                    }
                } else {
                    string lib_path = p._path.down ();
                    lib_path = lib_path.has_suffix (Path.DIR_SEPARATOR_S) ? lib_path : lib_path + Path.DIR_SEPARATOR_S;
                    string comp_path = file_path.has_suffix (Path.DIR_SEPARATOR_S) ? file_path.down () : file_path.down () + Path.DIR_SEPARATOR_S;
                    if (comp_path.has_prefix (lib_path)) {
                        return true;
                    }
                }
            }
            return false;
        }

        public Sheet? find_sheet_for_path (string file_path) {
            int len = 0;
            Sheets? parent = null;
            foreach (LibPair p in _all_sheets)
            {
                if (file_path.down ().has_prefix (p._path.down ()))
                {
                    if (p._path.length > len) {
                        len = p._path.length;
                        parent = p._sheets;
                    }
                }
            }
            
            if (parent != null) {
                foreach (var potential in parent.get_sheets ()) {
                    if (potential.file_path () == file_path) {
                        return potential;
                    }
                }
            }

            return null;
        }

        public int get_word_count_for_path (string path) {
            int wc = 0;
            LibPair? p = get_item (path);
            if (p != null) {
                foreach (var file in p._sheets.get_sheets ()) {
                    wc += file.get_word_count ();
                }

                foreach (var folder in p._sheets.metadata.folder_order) {
                    string next_path = Path.build_filename (p._path, folder);
                    if (FileUtils.test (next_path, FileTest.IS_DIR) && !FileUtils.test (next_path, FileTest.IS_SYMLINK)) {
                        wc += get_word_count_for_path (next_path);
                    }
                }
            }

            return wc;
        }

        public string get_novel (string path) {
            var settings = AppSettings.get_default ();
            string novel = "";
            LibPair? p = get_item (path);
            if (p != null) {
                novel = build_novel (p, settings.export_include_metadata_file);
            }
            return novel;
        }

        private string build_novel (LibPair p, bool metadata = false) {
            StringBuilder markdown = new StringBuilder ();
            var settings = AppSettings.get_default ();

            foreach (var file in p._sheets.metadata.sheet_order) {
                string sheet_markdown = FileManager.get_file_contents (Path.build_filename (p._path, file));
                if (settings.export_resolve_paths) {
                    sheet_markdown = Pandoc.resolve_paths (sheet_markdown, p._path);
                }

                if (!metadata) {
                    sheet_markdown = FileManager.get_yamlless_markdown(
                        sheet_markdown,
                        0,       // Cap number of lines
                        true,   // Include empty lines
                        settings.export_include_yaml_title, // H1 title:
                        false);

                    markdown.append (sheet_markdown);
                    if (settings.export_break_sheets) {
                        markdown.append ("\n<div style='page-break-before: always'></div>\n");
                    } else {
                        markdown.append ("\n\n");
                    }
                } else {
                    metadata = false;
                    markdown.append (sheet_markdown);
                    markdown.append ("\n");
                }
            }

            foreach (var folder in p._sheets.metadata.folder_order) {
                if (!p._sheets.metadata.hidden_folders.contains (folder)) {
                    if (markdown.len != 0) {
                        if (settings.export_break_folders) {
                            markdown.append ("\n<div style='page-break-before: always'></div>\n");
                        } else {
                            markdown.append ("\n\n");
                        }
                    }
                    string path = Path.build_filename (p._path, folder);
                    if (FileUtils.test (path, FileTest.IS_DIR) && !FileUtils.test (path, FileTest.IS_SYMLINK)) {
                        LibPair? child = get_item (path);
                        markdown.append (build_novel (child));
                    }
                }
            }

            return markdown.str;
        }

        public Gee.ArrayList<Sheets> get_all_sheets () {
            Gee.ArrayList<Sheets> all_sheets = new Gee.ArrayList<Sheets> ();
            foreach (var p in _all_sheets) {
                all_sheets.add (p._sheets);
            }
            return all_sheets;
        }

        public Gee.ArrayList<Sheets> get_all_sheets_for_path (string path) {
            Gee.ArrayList<Sheets> all_sheets = new Gee.ArrayList<Sheets> ();
            foreach (var p in _all_sheets) {
                if (p._sheets.get_sheets_path ().has_prefix (path)) {
                    all_sheets.add (p._sheets);
                }
            }
            return all_sheets;
        }

        //
        // Mouse Click Actions
        //

        public override bool button_press_event(Gdk.EventButton event) {
            base.button_press_event (event);

            if (event.type == Gdk.EventType.BUTTON_PRESS && event.button == 3) {
                var settings = AppSettings.get_default ();
                Gtk.Menu menu = new Gtk.Menu ();

                Gtk.MenuItem menu_preview_item = new Gtk.MenuItem.with_label (_("Export Preview"));
                menu_preview_item.activate.connect (() => {
                    if (_selected != null && _all_sheets.find (_selected) != null) {
                        string preview_markdown = build_novel (_selected, settings.export_include_metadata_file);
                        PublisherPreviewWindow ppw = new PublisherPreviewWindow (preview_markdown);
                        ppw.show_all ();
                    }
                });
                menu.add (menu_preview_item);

                Gtk.MenuItem menu_writing_stats = new Gtk.MenuItem.with_label (_("Writing Statistics"));
                menu_writing_stats.activate.connect (() => {
                    if (_selected != null && _all_sheets.find (_selected) != null) {
                        ProjectStatitics project_stat_window = new ProjectStatitics (_selected._path);
                        project_stat_window.show_all ();
                        project_stat_window.update_wordcount ();
                    }
                });
                menu.add (menu_writing_stats);

                menu.add (new Gtk.SeparatorMenuItem ());

                if (_selected != null && _all_sheets.find (_selected) != null) {
                    Gtk.MenuItem menu_search = new Gtk.MenuItem.with_label (_("Search ") + _selected._title);
                    menu_search.activate.connect (() => {
                        if (_selected != null && _all_sheets.find (_selected) != null) {
                            SearchWindow project_search_window = new SearchWindow (_selected._path);
                            project_search_window.show_all ();
                        }
                    });
                    menu.add (menu_search);

                    menu.add (new Gtk.SeparatorMenuItem ());
                }

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
                            _selected._sheets.close_active_files ();
                            if (SheetManager._current_sheets == _selected._sheets) {
                                SheetManager.set_sheets (null);
                            }
                            LibPair? parent = get_item (_selected._sheets.get_parent_sheets_path ());
                            if (parent != null) {
                                parent._sheets.add_hidden_item (_selected._path);
                            }
                            // Always touch lib store last as it changes selection
                            remove_children (_selected._path);
                            _all_sheets.remove (_selected);
                            _lib_store.remove (ref hide_node);
                            settings.writing_changed ();
                        }
                    });

                    menu.add (menu_hide_item);
                }

                Gtk.MenuItem menu_reveal_items = new Gtk.MenuItem.with_label (_("Show Hidden Items"));
                menu_reveal_items.activate.connect (() => {
                    if (_selected != null && _all_sheets.find (_selected) != null) {
                        _selected._sheets.remove_hidden_items ();
                        parse_dir (_selected._sheets, _selected._path, _selected_node);
                    }
                    settings.writing_changed ();
                });
                menu.add (menu_reveal_items);

                if (_selected != null && settings.is_in_library (_selected._path)) {
                    menu.add (new Gtk.SeparatorMenuItem ());

                    Gtk.MenuItem menu_remove_item = new Gtk.MenuItem.with_label (_("Remove from Library"));
                    menu_remove_item.activate.connect (() => {
                        TreeIter remove_node = _selected_node;
                        if (_selected != null && _all_sheets.find (_selected) != null) {
                            debug ("Removing %s", _selected._path);
                            _selected._sheets.close_active_files ();
                            if (SheetManager._current_sheets == _selected._sheets) {
                                SheetManager.set_sheets (null);
                            }
                            // Always touch lib store last as it changes selection
                            remove_children (_selected._path);
                            _all_sheets.remove (_selected);
                            settings.remove_from_library (_selected._path);
                            _lib_store.remove (ref remove_node);
                            settings.writing_changed ();
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

        private void move_folder (
            ref TreeIter source_iter,
            ref TreeIter dest_iter,
            LibPair source,
            LibPair dest,
            TreeViewDropPosition pos)
        {
            if (source == null || dest == null) {
                warning ("Could not determine drag source or destination");
                return;
            }

            File p1 = File.new_for_path (source._path);
            File p2 = File.new_for_path (dest._path);

            if (p1.get_parent ().get_path () != p2.get_parent ().get_path ()) {
                warning ("Can only reorder library items for items at the same level");
                return;
            }

            LibPair parent = get_item (p1.get_parent ().get_path ());
            if (parent == null) {
                warning ("Could not find parent metadata file");
                return;
            }

            if (pos == TreeViewDropPosition.AFTER || pos == TreeViewDropPosition.INTO_OR_AFTER) {
                debug ("Moving %s after %s", source._path, dest._path);
                parent._sheets.move_folder_after (p2.get_basename (), p1.get_basename ());
                _lib_store.move_after (ref source_iter, dest_iter);
            } else {
                debug ("Moving %s before %s", source._path, dest._path);
                parent._sheets.move_folder_before (p2.get_basename (), p1.get_basename ());
                _lib_store.move_before (ref source_iter, dest_iter);
            }
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
            if (!_droppable.can_get_drop ()) {
                Gtk.drag_finish (context, false, false, time);
                return;
            }

            bool dnd_success = false;
            bool delete_selection_data = false;
            bool item_in_library = false;
            string file_to_move = "";
            File? file = null;
            TreePath? path;
            TreeViewDropPosition pos;
            TreeIter dest_iter;
            LibPair? p = null;

            if (get_dest_row_at_pos (x, y, out path, out pos)){
                string title;
                _lib_store.get_iter (out dest_iter, path);
                _lib_store.get (dest_iter, 0, out title, 1, out p);
                debug ("Got location %s", p._path);
                if (selection_data == null || selection_data.get_length () < 0) {
                    move_folder (ref _selected_node, ref dest_iter, _selected, p, pos);
                    Gtk.drag_finish (context, false, false, time);
                    return;
                }
            }

            // Deal with what we are given from source
            if ((selection_data != null) && (selection_data.get_length() >= 0)) 
            {
                if (context.get_suggested_action() == DragAction.MOVE)
                {
                    delete_selection_data = true;
                }

                file = dnd_get_file (selection_data, target_type);
                debug ("Got drag data: %s", file.get_path ());
                file_to_move = file.get_path ();
                item_in_library = file_in_library (file_to_move);

                debug ("Item in library: %s", item_in_library ? "yes" : "no");

                if (item_in_library && delete_selection_data && !FileUtils.test(file_to_move, FileTest.IS_DIR))
                {
                    dnd_success = true;
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
                        // Requires path to drag to
                        if (p == null) {
                            Gtk.drag_finish (context, false, false, time);
                            return;
                        }

                        if (file_to_move.has_suffix (".md") || file_to_move.has_suffix (".markdown")) {
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
                        } else {
                            warning ("Importing file");
                            FileManager.import_file (file.get_path (), p._sheets);
                            parse_dir (_selected._sheets, _selected._path, _selected_node);
                        }
                    }
                }
                else
                {
                    warning ("Item not found");
                }
            }

            // Default behavior
            if (dnd_success)
            {
                // Requires path to drag to
                if (p == null) {
                    Gtk.drag_finish (context, false, false, time);
                    return;
                }

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
