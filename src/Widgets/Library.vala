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
using GLib;

namespace ThiefMD.Widgets {
    /**
     * Library data object
     */
    private class LibNode : Object {
        public Sheets sheets;
        public string title;
        public string path;
        public GLib.Icon icon;
        public GLib.ListStore children;
        public LibNode? parent = null;
        public bool children_built = false;

        public LibNode (string path, GLib.Icon icon) {
            this.path = path.has_suffix (Path.DIR_SEPARATOR_S) ? path.substring (0, path.char_count () - 1) : path;
            this.title = this.path.substring (this.path.last_index_of (Path.DIR_SEPARATOR_S) + 1);
            this.sheets = new Sheets (this.path);
            this.icon = icon;
            this.children = new GLib.ListStore (typeof (LibNode));
        }
    }

    /**
     * Library or file tree view
     */
    public class Library : Gtk.Box {
        private List<LibNode> _all_sheets;
        private GLib.ListStore _root_store;
        private Gtk.TreeListModel _tree_model;
        private Gtk.SingleSelection _selection;
        private Gtk.ListView _list_view;
        private LibNode? _selected;
        NewFolder folder_popup;
        private Gtk.PopoverMenu? _context_menu;
        private GLib.SimpleActionGroup _context_actions;
        private Gdk.Rectangle _last_menu_rect;
        private bool _has_last_menu_rect = false;

        public Library () {
            Object (orientation: Gtk.Orientation.VERTICAL, spacing: 0);
            debug ("Setting up library");
            _all_sheets = new List<LibNode> ();
            _root_store = new GLib.ListStore (typeof (LibNode));
            _context_actions = new GLib.SimpleActionGroup ();
            insert_action_group ("library", _context_actions);
            setup_context_actions ();
            folder_popup = new NewFolder ();

            build_models ();
            build_view ();
            parse_library ();
        }

        private GLib.ListModel? create_child_model (Object? obj) {
            LibNode? node = obj as LibNode;
            if (node == null) {
                Gtk.TreeListRow? row = obj as Gtk.TreeListRow;
                if (row != null) {
                    node = row.get_item () as LibNode;
                }
            }

            if (node == null) {
                return null;
            }

            if (!node.children_built) {
                rebuild_children (node);
            }

            uint n_children = node.children.get_n_items ();

            if (n_children == 0) {
                return null;
            }

            return node.children;
        }

        private void build_models () {
            _tree_model = new Gtk.TreeListModel (
                _root_store,
                false,
                true,
                create_child_model);

            _selection = new Gtk.SingleSelection (_tree_model);
            _selection.set_can_unselect (false);
            _selection.selection_changed.connect ((position, n_items) => {
                on_selection_changed ();
            });
        }

        private void setup_row_item (Gtk.SignalListItemFactory factory, GLib.Object obj) {
            var item = obj as Gtk.ListItem;
            if (item == null) {
                return;
            }
            var row_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
            row_box.add_css_class ("library-row");

            var icon = new Gtk.Image ();
            icon.set_pixel_size (18);

            var label = new Gtk.Label ("");
            label.set_xalign (0);
            label.set_hexpand (true);

            row_box.append (icon);
            row_box.append (label);

            var expander = new Gtk.TreeExpander ();
            expander.set_child (row_box);

            item.set_child (expander);
        }

        private void bind_row_item (Gtk.SignalListItemFactory factory, GLib.Object obj) {
            var item = obj as Gtk.ListItem;
            if (item == null) {
                return;
            }
            var row = item.get_item () as Gtk.TreeListRow;
            var node = row != null ? row.get_item () as LibNode : null;
            var expander = item.get_child () as Gtk.TreeExpander;
            if (expander == null || row == null || node == null) {
                return;
            }

            expander.set_list_row (row);

            Gtk.Box? box = expander.get_child () as Gtk.Box;
            if (box == null) {
                return;
            }

            Gtk.Widget? w = box.get_first_child ();
            Gtk.Image? icon = w as Gtk.Image;
            Gtk.Label? label = (w != null) ? w.get_next_sibling () as Gtk.Label : null;

            if (icon != null) {
                icon.set_from_gicon (node.icon);
            }
            if (label != null) {
                label.set_label (node.title);
            }

            // Drag source for moving folders (future feature)
            var drag_source = new Gtk.DragSource ();
            drag_source.actions = Gdk.DragAction.MOVE;
            drag_source.prepare.connect ((x, y) => {
                Value v = Value (typeof (string));
                v.set_string (node.path);
                return new Gdk.ContentProvider.for_value (v);
            });
            box.add_controller (drag_source);

            // Drop target to accept sheets being moved into folders
            var drop_target = new Gtk.DropTarget (typeof (string), Gdk.DragAction.MOVE);
            drop_target.drop.connect ((value, x, y) => {
                string? source_path = (string?) value;
                if (source_path == null) {
                    return false;
                }
                return handle_library_drop (source_path, node);
            });
            box.add_controller (drop_target);

            // Motion controller for hover effects during drag
            var motion = new Gtk.EventControllerMotion ();
            drop_target.enter.connect ((x, y) => {
                box.add_css_class ("library-drop-hover");
                return Gdk.DragAction.MOVE;
            });
            drop_target.leave.connect (() => {
                box.remove_css_class ("library-drop-hover");
            });
            box.add_controller (motion);
        }

        private void unbind_row_item (Gtk.SignalListItemFactory factory, GLib.Object obj) {
            var item = obj as Gtk.ListItem;
            if (item == null) {
                return;
            }
            var expander = item.get_child () as Gtk.TreeExpander;
            if (expander != null) {
                expander.set_list_row (null);

                // Clean up CSS classes
                Gtk.Box? box = expander.get_child () as Gtk.Box;
                if (box != null) {
                    box.remove_css_class ("library-drop-hover");
                }
            }
        }

        private bool handle_library_drop (string source_path, LibNode target_node) {
            var source_file = File.new_for_path (source_path);
            if (!source_file.query_exists ()) {
                return false;
            }

            // Check if source is a regular file (sheet)
            if (!FileUtils.test (source_path, FileTest.IS_REGULAR)) {
                // For now, only support dropping sheets into folders
                // Folder dragging/reordering can be added later
                return false;
            }

            string source_dir = "";
            var parent_dir = source_file.get_parent ();
            if (parent_dir != null) {
                source_dir = parent_dir.get_path ();
            }

            string dest_dir = target_node.path;
            string source_name = source_file.get_basename ();

            // Don't drop into the same folder
            if (source_dir == dest_dir) {
                return false;
            }

            // Move the file
            string dest_path = Path.build_filename (dest_dir, source_name);
            try {
                source_file.move (File.new_for_path (dest_path), FileCopyFlags.OVERWRITE, null, null);
            } catch (Error e) {
                warning ("Could not move %s to %s: %s", source_path, dest_path, e.message);
                return false;
            }

            // Update origin sheets metadata
            var library = ThiefApp.get_instance ().library;
            Sheets? origin_sheets = library.find_sheets_for_path (source_dir);
            if (origin_sheets != null) {
                var origin_sheet = library.find_sheet_for_path (source_path);
                if (origin_sheet != null) {
                    origin_sheets.remove_sheet (origin_sheet);
                    origin_sheets.persist_metadata ();
                } else {
                    origin_sheets.refresh ();
                }
            }

            // Refresh destination
            target_node.sheets.refresh ();
            target_node.sheets.persist_metadata ();

            return true;
        }

        private Gtk.SignalListItemFactory create_row_factory () {
            var factory = new Gtk.SignalListItemFactory ();
            factory.setup.connect (setup_row_item);
            factory.bind.connect (bind_row_item);
            factory.unbind.connect (unbind_row_item);
            return factory;
        }

        private void build_view () {
            var factory = create_row_factory ();
            _list_view = new Gtk.ListView (_selection, factory);
            _list_view.set_vexpand (true);
            _list_view.set_hexpand (true);

            var scroller = new Gtk.ScrolledWindow ();
            scroller.set_child (_list_view);
            scroller.set_policy (Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC);
            append (scroller);

            var right_click = new Gtk.GestureClick ();
            right_click.set_button (3);
            right_click.released.connect ((n_press, x, y) => {
                // Find and select the row at the click position before showing menu
                var picked = _list_view.pick (x, y, Gtk.PickFlags.DEFAULT);
                if (picked != null) {
                    // Walk up the widget tree to find the ListItem
                    var widget = picked;
                    while (widget != null && !(widget is Gtk.ListItem)) {
                        widget = widget.get_parent ();
                    }
                    
                    if (widget is Gtk.ListItem) {
                        var list_item = (Gtk.ListItem) widget;
                        var row = list_item.get_item () as Gtk.TreeListRow;
                        if (row != null) {
                            var node = row.get_item () as LibNode;
                            if (node != null) {
                                _selected = node;
                                select_node (node);
                            }
                        }
                    }
                }
                show_context_menu (x, y);
            });
            _list_view.add_controller (right_click);

            var activate = new Gtk.GestureClick ();
            activate.set_button (1);
            activate.released.connect ((n_press, x, y) => {
                on_selection_changed ();
            });
            _list_view.add_controller (activate);
        }

        private LibNode? get_selected_node () {
            if (_selection == null) {
                return null;
            }

            var row = _selection.get_selected_item () as Gtk.TreeListRow;
            if (row == null) {
                return null;
            }

            return row.get_item () as LibNode;
        }

        private void on_selection_changed () {
            LibNode? node = get_selected_node ();
            if (node != null) {
                _selected = node;
                debug ("Selected: %s", node.path);
                SheetManager.set_sheets (node.sheets);
            }
        }

        private bool select_node (LibNode node) {
            if (_tree_model == null || _selection == null) {
                return false;
            }

            uint n = _tree_model.get_n_items ();
            for (uint i = 0; i < n; i++) {
                var row = _tree_model.get_item (i) as Gtk.TreeListRow;
                if (row != null && row.get_item () == node) {
                    _selection.select_item (i, true);
                    return true;
                }
            }

            return false;
        }

        public void set_active () {
            foreach (var node in _all_sheets) {
                if (node.sheets.has_active_sheet ()) {
                    select_node (node);
                    break;
                }
            }
        }

        //
        // Library Functions
        //

        public void new_folder (string folder) {
            if ((folder.chomp() == "")) {
                return;
            }

            if (_selected != null && _all_sheets.find (_selected) != null) {
                debug ("Creating %s in %s", folder, _selected.path);
                string new_folder_path = Path.build_filename (_selected.path, folder);
                File newfolder = File.new_for_path (new_folder_path);
                if (newfolder.query_exists ()) {
                    return;
                }
                try {
                    newfolder.make_directory ();
                } catch (Error e) {
                    warning ("Could not make new directory: %s", e.message);
                }
                rebuild_children (_selected);
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
                                LibNode? kid = get_item (path);
                                if (kid != null) {
                                    kid.sheets.close_active_files ();
                                    if (SheetManager._current_sheets == kid.sheets) {
                                        SheetManager.set_sheets (null);
                                    }
                                    _all_sheets.remove (kid);
                                    remove_node_from_store (kid);
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
                Gee.LinkedList<LibNode> bad_kids = new Gee.LinkedList<LibNode> ();
                foreach (var kid in _all_sheets) {
                    if (kid.path.has_prefix (rem_kids)) {
                        bad_kids.add (kid);
                    }
                }

                foreach (var bad_kid in bad_kids) {
                    bad_kid.sheets.close_active_files ();
                    if (SheetManager._current_sheets == bad_kid.sheets) {
                        SheetManager.set_sheets (null);
                    }
                    _all_sheets.remove (bad_kid);
                    remove_node_from_store (bad_kid);
                }
            }
        }

        private LibNode? get_item (string path) {
            foreach (LibNode node in _all_sheets) {
                if (node.sheets.get_sheets_path() == path) {
                    return node;
                }
            }

            return null;
        }

        public bool has_sheets (string path) {
            foreach (LibNode node in _all_sheets) {
                if (node.sheets.get_sheets_path() == path) {
                    return true;
                }
            }

            return false;
        }

        public void refresh_sheets (string path) {
            foreach (LibNode node in _all_sheets) {
                string lib_path = node.sheets.get_sheets_path ();
                lib_path = lib_path.has_suffix (Path.DIR_SEPARATOR_S) ? lib_path : lib_path + Path.DIR_SEPARATOR_S;
                string comp_path = path.has_suffix (Path.DIR_SEPARATOR_S) ? path : path + Path.DIR_SEPARATOR_S;
                if (lib_path == comp_path) {
                    node.sheets.refresh ();
                }
            }
        }

        public Sheets get_sheets (string path) {
            foreach (LibNode node in _all_sheets) {
                string lib_path = node.sheets.get_sheets_path ();
                lib_path = lib_path.has_suffix (Path.DIR_SEPARATOR_S) ? lib_path : lib_path + Path.DIR_SEPARATOR_S;
                string comp_path = path.has_suffix (Path.DIR_SEPARATOR_S) ? path : path + Path.DIR_SEPARATOR_S;
                if (lib_path == comp_path) {
                    debug ("Found %s", path);
                    return node.sheets;
                }
            }

            debug ("Could not find last opened project in library");
            return new Sheets(path);
        }

        public bool parse_library () {
            var settings = AppSettings.get_default ();
            settings.validate_library ();
            string[] library = settings.library ();

            foreach (string lib in library) {
                if (lib.chomp () == "") {
                    continue;
                }
                if (!has_sheets (lib)) {
                    debug (lib);
                    var icon = get_icon_for_folder (lib);
                    LibNode node = new LibNode (lib, icon);
                    _all_sheets.append (node);
                    _root_store.append (node);
                    rebuild_children (node);
                }
            }

            Timeout.add (150, pick_item);

            return false;
        }

        private bool pick_item () {
            if (_selected == null) {
                foreach (LibNode node in _all_sheets) {
                    select_node (node);
                    break;
                }
            }
            return false;
        }

        public void refresh_dir (Sheets sheet_dir) {
            LibNode? n = get_item (sheet_dir.get_sheets_path ());
            if (n != null) {
                rebuild_children (n);
            }
        }

        public void expand_all () {
            if (_tree_model == null) {
                return;
            }

            uint n = _tree_model.get_n_items ();
            for (uint i = 0; i < n; i++) {
                var row = _tree_model.get_item (i) as Gtk.TreeListRow;
                if (row != null) {
                    row.set_expanded (true);
                }
            }
        }

        public void remove_item (string path) {
            var settings = AppSettings.get_default ();
            LibNode? n = get_item (path);

            if (n != null) {
                remove_children (path);
                _all_sheets.remove (n);
                remove_node_from_store (n);
                settings.writing_changed ();
            }
        }

        private void rebuild_children (LibNode node) {
            var settings = AppSettings.get_default ();
            
            // If already built, only clear if we're forcing a refresh
            if (node.children_built) {
                while (node.children.get_n_items () > 0) {
                    node.children.remove (0);
                }
                // Also clear from _all_sheets
                Gee.LinkedList<LibNode> to_remove = new Gee.LinkedList<LibNode> ();
                foreach (var kid in _all_sheets) {
                    if (kid.parent == node) {
                        to_remove.add (kid);
                    }
                }
                foreach (var kid in to_remove) {
                    _all_sheets.remove (kid);
                }
            }
            
            node.children_built = true;
            var sheet_dir = node.sheets;
            string str_dir = node.path;
            try {
                // Load ordered folders first
                foreach (var file_name in sheet_dir.metadata.folder_order) {
                    if (!file_name.has_prefix(".") && !sheet_dir.metadata.hidden_folders.contains(file_name)) {
                        string path = Path.build_filename (str_dir, file_name);
                        File file = File.new_for_path (path);
                        if (file.query_exists () && !has_sheets (path) && FileUtils.test(path, FileTest.IS_DIR)) {
                            var icon = get_icon_for_folder (path);
                            LibNode child = new LibNode (path, icon);
                            child.parent = node;
                            node.children.append (child);
                            _all_sheets.append (child);
                            // Don't recursively build - let TreeListModel do it lazily
                        } else if (!file.query_exists ()) {
                            remove_children (path);
                            LibNode p = get_item (path);
                            if (p != null) {
                                _all_sheets.remove (p);
                            }
                            settings.writing_changed ();
                        }
                    }
                }

                // Then append any new folders
                Dir dir = Dir.open (str_dir, 0);
                string? file_name = null;
                while ((file_name = dir.read_name()) != null) {
                    if (!file_name.has_prefix(".") && !sheet_dir.metadata.hidden_folders.contains(file_name)) {
                        string path = Path.build_filename (str_dir, file_name);
                        if (!has_sheets (path) && FileUtils.test(path, FileTest.IS_DIR)) {
                            var icon = get_icon_for_folder (path);
                            LibNode child = new LibNode (path, icon);
                            child.parent = node;
                            node.children.append (child);
                            _all_sheets.append (child);
                            sheet_dir.metadata.add_folder (file_name);
                            // Don't recursively build - let TreeListModel do it lazily
                        }
                    }
                }
            } catch (Error e) {
                debug ("Error: %s", e.message);
            }
        }

        public bool file_in_library (string file_path) {
            bool is_dir = FileUtils.test (file_path, FileTest.IS_DIR);
            foreach (LibNode p in _all_sheets)
            {
                if (!is_dir) {
                    if (file_path.down ().has_prefix (p.path.down ()))
                    {
                        return true;
                    }
                } else {
                    string lib_path = p.path.down ();
                    lib_path = lib_path.has_suffix (Path.DIR_SEPARATOR_S) ? lib_path : lib_path + Path.DIR_SEPARATOR_S;
                    string comp_path = file_path.has_suffix (Path.DIR_SEPARATOR_S) ? file_path.down () : file_path.down () + Path.DIR_SEPARATOR_S;
                    if (comp_path.has_prefix (lib_path)) {
                        return true;
                    }
                }
            }
            return false;
        }

        public Sheets? find_sheets_for_path (string file_path) {
            int len = 0;
            Sheets? parent = null;
            foreach (LibNode p in _all_sheets)
            {
                if (file_path.down ().has_prefix (p.path.down ()))
                {
                    if (p.path.length > len) {
                        len = p.path.length;
                        parent = p.sheets;
                    }
                }
            }

            return parent;
        }

        public Sheet? find_sheet_for_path (string file_path) {
            int len = 0;
            Sheets? parent = null;
            foreach (LibNode p in _all_sheets)
            {
                if (file_path.down ().has_prefix (p.path.down ()))
                {
                    if (p.path.length > len) {
                        len = p.path.length;
                        parent = p.sheets;
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
            LibNode? p = get_item (path);
            if (p != null) {
                foreach (var file in p.sheets.get_sheets ()) {
                    wc += file.get_word_count ();
                }

                foreach (var folder in p.sheets.metadata.folder_order) {
                    string next_path = Path.build_filename (p.path, folder);
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
            LibNode? p = get_item (path);
            if (p != null) {
                novel = build_novel (p, settings.export_include_metadata_file);
            }
            return novel;
        }

        private bool render_fountain (LibNode p, bool metadata = false) {
            foreach (var file in p.sheets.metadata.sheet_order) {
                if (!exportable_file (file)) {
                    continue;
                }

                if (is_fountain (file)) {
                    return true;
                }
            }

            foreach (var folder in p.sheets.metadata.folder_order) {
                if (!p.sheets.metadata.hidden_folders.contains (folder)) {
                    string path = Path.build_filename (p.path, folder);
                    if (FileUtils.test (path, FileTest.IS_DIR) && !FileUtils.test (path, FileTest.IS_SYMLINK)) {
                        LibNode? child = get_item (path);
                        return render_fountain (child);
                    }
                }
            }

            return false;
        }

        private string build_novel (LibNode p, bool metadata = false) {
            StringBuilder markdown = new StringBuilder ();
            var settings = AppSettings.get_default ();

            foreach (var file in p.sheets.metadata.sheet_order) {
                if (!exportable_file (file)) {
                    continue;
                }

                string sheet_markdown = FileManager.get_file_contents (Path.build_filename (p.path, file));
                if (settings.export_resolve_paths) {
                    sheet_markdown = Pandoc.resolve_paths (sheet_markdown, p.path);
                }

                if (!metadata) {
                    string title, date;
                    sheet_markdown = FileManager.get_yamlless_markdown(
                        sheet_markdown,
                        0,       // Cap number of lines
                        out title,
                        out date,
                        true,   // Include empty lines
                        settings.export_include_yaml_title, // H1 title:
                        false);

                    markdown.append (sheet_markdown);
                    if (is_fountain (file)) {
                        markdown.append ("\n");
                    }
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

            foreach (var folder in p.sheets.metadata.folder_order) {
                if (!p.sheets.metadata.hidden_folders.contains (folder)) {
                    if (markdown.len != 0) {
                        if (settings.export_break_folders) {
                            markdown.append ("\n<div style='page-break-before: always'></div>\n");
                        } else {
                            markdown.append ("\n\n");
                        }
                    }
                    string path = Path.build_filename (p.path, folder);
                    if (FileUtils.test (path, FileTest.IS_DIR) && !FileUtils.test (path, FileTest.IS_SYMLINK)) {
                        LibNode? child = get_item (path);
                        markdown.append (build_novel (child));
                    }
                }
            }

            return markdown.str;
        }

        public Gee.ArrayList<Sheets> get_all_sheets () {
            Gee.ArrayList<Sheets> all_sheets = new Gee.ArrayList<Sheets> ();
            foreach (var p in _all_sheets) {
                all_sheets.add (p.sheets);
            }
            return all_sheets;
        }

        public Gee.ArrayList<Sheets> get_all_sheets_for_path (string path) {
            Gee.ArrayList<Sheets> all_sheets = new Gee.ArrayList<Sheets> ();
            foreach (var p in _all_sheets) {
                if (p.sheets.get_sheets_path ().has_prefix (path)) {
                    all_sheets.add (p.sheets);
                }
            }
            return all_sheets;
        }

        //
        // Mouse Click Actions
        //

        private LibNode? current_selection () {
            if (_selected != null && _all_sheets.find (_selected) != null) {
                return _selected;
            }

            return null;
        }

        private void show_context_menu (double x, double y) {
            var menu_model = build_context_menu_model ();
            if (menu_model == null) {
                return;
            }

            _last_menu_rect = Gdk.Rectangle ();
            _last_menu_rect.x = (int) x;
            _last_menu_rect.y = (int) y;
            _last_menu_rect.width = 1;
            _last_menu_rect.height = 1;
            _has_last_menu_rect = true;

            if (_context_menu != null) {
                _context_menu.popdown ();
                _context_menu.unparent ();
                _context_menu = null;
            }

            _context_menu = new Gtk.PopoverMenu.from_model (menu_model);
            _context_menu.set_has_arrow (true);
            _context_menu.set_pointing_to (_last_menu_rect);
            _context_menu.set_parent (_list_view);
            _context_menu.set_autohide (true);
            _context_menu.set_flags (Gtk.PopoverMenuFlags.NESTED);
            _context_menu.popup ();
        }

        private void append_icon_item (GLib.Menu icon_menu, string label, string value) {
            var item = new GLib.MenuItem (label, "library.set_icon");
            item.set_attribute_value ("target", new Variant.string (value));
            
            // Add icon preview to menu item
            GLib.Icon? icon = get_icon_for_value (value);
            if (icon != null) {
                item.set_icon (icon);
            }
            
            icon_menu.append_item (item);
        }

        private MenuModel? build_context_menu_model () {
            var settings = AppSettings.get_default ();
            LibNode? selection = current_selection ();
            if (selection == null) {
                return null;
            }

            var root = new GLib.Menu ();

            var export_section = new GLib.Menu ();
            export_section.append (_("Export Preview"), "library.export_preview");
            export_section.append (_("Writing Statistics"), "library.writing_stats");
            root.append_section (null, export_section);

            var search_section = new GLib.Menu ();
            search_section.append (_("Search ") + selection.title, "library.search");
            root.append_section (null, search_section);

            var folder_section = new GLib.Menu ();
            folder_section.append (_("Open in File Manager"), "library.open_folder");
            folder_section.append (_("Create Sub-Folder"), "library.create_folder");
            if (!settings.is_in_library (selection.path)) {
                folder_section.append (_("Hide from Library"), "library.hide");
            }
            folder_section.append (_("Show Hidden Items"), "library.reveal_hidden");
            root.append_section (null, folder_section);

            var icon_menu = new GLib.Menu ();
            append_icon_item (icon_menu, _("None"), "");
            append_icon_item (icon_menu, _("Folder"), "folder");
            append_icon_item (icon_menu, _("Reader"), "ephy-reader-mode-symbolic");
            append_icon_item (icon_menu, _("Love"), "emote-love-symbolic");
            append_icon_item (icon_menu, _("Game"), "applications-games-symbolic");
            append_icon_item (icon_menu, _("Art"), "applications-graphics-symbolic");
            append_icon_item (icon_menu, _("Nature"), "emoji-nature-symbolic");
            append_icon_item (icon_menu, _("Food"), "emoji-food-symbolic");
            append_icon_item (icon_menu, _("Help"), "system-help-symbolic");
            append_icon_item (icon_menu, _("Cool"), "face-cool-symbolic");
            append_icon_item (icon_menu, _("Angel"), "face-angel-symbolic");
            append_icon_item (icon_menu, _("Monkey"), "face-monkey-symbolic");
            append_icon_item (icon_menu, _("WordPress"), "/com/github/kmwallio/thiefmd/icons/wordpress.png");
            append_icon_item (icon_menu, _("Ghost"), "/com/github/kmwallio/thiefmd/icons/ghost.png");
            append_icon_item (icon_menu, _("Write Freely"), "/com/github/kmwallio/thiefmd/icons/wf.png");
            append_icon_item (icon_menu, _("Trash"), "user-trash-symbolic");

            var icon_section = new GLib.Menu ();
            icon_section.append_submenu (_("Set Project Icon"), icon_menu);
            root.append_section (null, icon_section);

            if (settings.is_in_library (selection.path)) {
                var remove_section = new GLib.Menu ();
                remove_section.append (_("Remove from Library"), "library.remove");
                root.append_section (null, remove_section);
            }

            return root;
        }

        private void remove_node_from_store (LibNode node) {
            GLib.ListStore? store = (node.parent != null) ? node.parent.children : _root_store;
            for (uint i = 0; i < store.get_n_items (); i++) {
                if (store.get_item (i) == node) {
                    store.remove (i);
                    break;
                }
            }
        }

        private void setup_context_actions () {
            var export_preview = new GLib.SimpleAction ("export_preview", null);
            export_preview.activate.connect ((parameter) => {
                var settings = AppSettings.get_default ();
                LibNode? selection = current_selection ();
                if (selection == null) {
                    return;
                }
                string preview_markdown = build_novel (selection, settings.export_include_metadata_file);
                PublisherPreviewWindow ppw = new PublisherPreviewWindow (preview_markdown, render_fountain (selection));
                ppw.show ();
            });
            _context_actions.add_action (export_preview);

            var writing_stats = new GLib.SimpleAction ("writing_stats", null);
            writing_stats.activate.connect ((parameter) => {
                LibNode? selection = current_selection ();
                if (selection == null) {
                    return;
                }
                ProjectStatitics project_stat_window = new ProjectStatitics (selection.path);
                project_stat_window.present ();
                project_stat_window.update_wordcount ();
            });
            _context_actions.add_action (writing_stats);

            var search_action = new GLib.SimpleAction ("search", null);
            search_action.activate.connect ((parameter) => {
                LibNode? selection = current_selection ();
                if (selection == null) {
                    return;
                }
                SearchWindow project_search_window = new SearchWindow (selection.path);
                project_search_window.present ();
            });
            _context_actions.add_action (search_action);

            var open_folder = new GLib.SimpleAction ("open_folder", null);
            open_folder.activate.connect ((parameter) => {
                LibNode? selection = current_selection ();
                if (selection == null) {
                    return;
                }
                try {
                    AppInfo.launch_default_for_uri ("file://%s".printf (selection.path), null);
                } catch (Error e) {
                    warning ("Could not open folder: %s", e.message);
                }
            });
            _context_actions.add_action (open_folder);

            var create_folder = new GLib.SimpleAction ("create_folder", null);
            create_folder.activate.connect ((parameter) => {
                if (current_selection () == null) {
                    return;
                }
                show_new_folder_popover ();
            });
            _context_actions.add_action (create_folder);

            var hide_folder = new GLib.SimpleAction ("hide", null);
            hide_folder.activate.connect ((parameter) => {
                var settings = AppSettings.get_default ();
                LibNode? selection = current_selection ();
                if (selection == null) {
                    return;
                }
                selection.sheets.close_active_files ();
                if (SheetManager._current_sheets == selection.sheets) {
                    SheetManager.set_sheets (null);
                }
                LibNode? parent = selection.parent;
                if (parent != null) {
                    parent.sheets.add_hidden_item (selection.path);
                }
                remove_children (selection.path);
                _all_sheets.remove (selection);
                remove_node_from_store (selection);
                settings.writing_changed ();
            });
            _context_actions.add_action (hide_folder);

            var reveal_hidden = new GLib.SimpleAction ("reveal_hidden", null);
            reveal_hidden.activate.connect ((parameter) => {
                var settings = AppSettings.get_default ();
                LibNode? selection = current_selection ();
                if (selection == null) {
                    return;
                }
                selection.sheets.remove_hidden_items ();
                rebuild_children (selection);
                settings.writing_changed ();
            });
            _context_actions.add_action (reveal_hidden);

            var set_icon_action = new GLib.SimpleAction ("set_icon", VariantType.STRING);
            set_icon_action.activate.connect ((parameter) => {
                if (parameter == null) {
                    return;
                }
                set_selected_icon (parameter.get_string ());
            });
            _context_actions.add_action (set_icon_action);

            var remove_action = new GLib.SimpleAction ("remove", null);
            remove_action.activate.connect ((parameter) => {
                var settings = AppSettings.get_default ();
                LibNode? selection = current_selection ();
                if (selection == null) {
                    return;
                }
                selection.sheets.close_active_files ();
                if (SheetManager._current_sheets == selection.sheets) {
                    SheetManager.set_sheets (null);
                }
                remove_children (selection.path);
                _all_sheets.remove (selection);
                settings.remove_from_library (selection.path);
                remove_node_from_store (selection);
                settings.writing_changed ();
            });
            _context_actions.add_action (remove_action);
        }

        private void set_selected_icon (string icon_value) {
            LibNode? selection = current_selection ();
            if (selection == null) {
                return;
            }

            selection.sheets.metadata.icon = icon_value;
            selection.sheets.persist_metadata ();
            selection.icon = get_icon_for_value (icon_value);
            var settings = AppSettings.get_default ();
            settings.writing_changed ();
            
            // Force ListView to rebind the item by notifying the model
            // Find the position of the changed item
            GLib.ListStore? store = (selection.parent != null) ? selection.parent.children : _root_store;
            for (uint i = 0; i < store.get_n_items (); i++) {
                if (store.get_item (i) == selection) {
                    store.items_changed (i, 1, 1);
                    break;
                }
            }
        }

        private void show_new_folder_popover () {
            Gdk.Rectangle rect = _last_menu_rect;
            if (!_has_last_menu_rect) {
                rect = Gdk.Rectangle ();
                rect.x = 0;
                rect.y = 0;
                rect.width = 1;
                rect.height = 1;
            }
            folder_popup.set_pointing_to (rect);
            folder_popup.set_parent (_list_view);
            folder_popup.popup ();
        }
    }
}
