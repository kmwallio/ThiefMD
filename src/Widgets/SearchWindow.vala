/*
 * Copyright (C) 2020 kmwallio
 * 
 * Modified October 9, 2020
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
    public class SearchResult : Object {
        public string search_term;
        public string file_path;
        public Sheet file_sheet;
        public string text_highlight;
        public string mini_mark;
        public int occurrences;
    }

    public class SearchDisplay : Gtk.Button {
        public string search_term;
        public string file_path;
        public string mini_mark;
        public Sheet file_sheet;
        public int occurrences;

        public void double_check () {
            string contents = FileManager.get_file_contents (file_path);
            int index = contents.down ().index_of (search_term.down ());
            if (index != -1) {
                string title, date;
                mini_mark = SheetManager.mini_mark (FileManager.get_file_lines_yaml (file_path, Constants.SEARCH_PREVIEW_LINES, true, out title, out date));
                int index2 = contents.down ().index_of (search_term.down (), mini_mark.length + 6 + ((title != "") ? title.length + 7 : 0) + ((date != "") ? date.length + 6 : 0));
                if (index2 != -1) {
                    index = index2;
                }
                int start = (index - 10) >= 0 ? (index - 10) : 0;
                int end = (index + 50) < contents.length ? 50 : -1;
                occurrences = contents.down ().split (search_term.down ()).length - 1;
                string text_highlight = contents.substring (start, end);
                text_highlight = text_highlight.replace ("\n", " ");
                text_highlight = text_highlight.replace ("&", "&amp;");
                text_highlight = text_highlight.replace ("<", "&lt;").replace (">", "&gt;");
                text_highlight = mini_mark + "\n..." + text_highlight + "...";
                text_highlight = text_highlight.down ().replace (search_term.down (), "<b>" + search_term + "</b>");
                string lib_path = get_base_library_path (file_path);
                if (lib_path == "") {
                    lib_path = file_path;
                }
                var label = new Gtk.Label ("<b>" + lib_path + " (" + occurrences.to_string () + " matches)</b>\n" + text_highlight);
                label.xalign = 0;
                label.set_ellipsize (Pango.EllipsizeMode.END);
                label.use_markup = true;
                set_child (label);
            }
        }
    }

    public class SearchThread : Object {
        string search_term;
        Sheets to_check;
        SearchBase to_update;
        public SearchThread (string term, Sheets path, SearchBase parent) {
            search_term = term;
            to_check = path;
            to_update = parent;
        }

        public void search () {
            debug ("Thread entered");
            GLib.List<Sheet> files = to_check.get_sheets ();
            int res_count = 0;
            for (int i = 0; i < files.length () && to_update.searching; i++) {
                string contents = FileManager.get_file_contents (files.nth_data (i).file_path ());
                int index = contents.down ().index_of (search_term.down ());
                if (index != -1) {
                    SearchResult res = new SearchResult ();
                    string title, date;
                    res.mini_mark = SheetManager.mini_mark (FileManager.get_file_lines_yaml (files.nth_data (i).file_path (), Constants.SEARCH_PREVIEW_LINES, true, out title, out date));
                    int index2 = contents.down ().index_of (search_term.down (), res.mini_mark.length + 6 + ((title != "") ? title.length + 7 : 0) + ((date != "") ? date.length + 6 : 0));
                    if (index2 != -1) {
                        index = index2;
                    }
                    int start = (index - 10) >= 0 ? (index - 10) : 0;
                    int end = (index + 50) < contents.length ? 50 : -1;
                    res.occurrences = contents.down ().split (search_term.down ()).length - 1;
                    res.file_path = files.nth_data (i).file_path ();
                    res.search_term = search_term;
                    res.text_highlight = contents.substring (start, end);
                    res.text_highlight = res.text_highlight.replace ("\n", " ");
                    res.text_highlight = res.text_highlight.replace ("&", "&amp;");
                    res.text_highlight = res.text_highlight.replace ("<", "&lt;").replace (">", "&gt;");
                    res.text_highlight = res.mini_mark + "\n..." + res.text_highlight + "...";
                    res.text_highlight = res.text_highlight.down ().replace (search_term.down (), "<b>" + search_term + "</b>");
                    res.file_sheet = files.nth_data (i);
                    to_update.results.add (res);
                    res_count++;
                    debug ("Found: %s", res.file_path + " (" + res.occurrences.to_string () + " matches)");
                }
            }
            debug ("Thread done, %d found", res_count);
            to_update.remove_thread ();
            return;
        }
    }

    public class SearchBase : Object {
        public Gtk.ScrolledWindow scrolled_results;
        public Gee.ConcurrentList<SearchResult> results;
        Gee.ConcurrentList<SearchDisplay> displayed;
        public Gtk.Entry search;
        string active_search_term;
        Mutex start_search;
        Mutex ui_update;
        Mutex ui_remove;
        Mutex thread_update;
        public int running_threads;
        public bool searching = false;
        Gtk.FlowBox search_results;
        Gee.ArrayList<Sheets> searchable;
        TimedMutex one_click;
        private string scoped_folder;

        public SearchBase (string local_result = "") {
            ui_update = Mutex ();
            ui_remove = Mutex ();
            thread_update = Mutex ();
            start_search = Mutex ();
            scoped_folder = local_result;
            results = new Gee.ConcurrentList<SearchResult> ();
            displayed = new Gee.ConcurrentList<SearchDisplay> ();
            one_click = new TimedMutex (750);

            search = new Gtk.Entry ();
            search.placeholder_text = "Enter search";

            search.activate.connect (update_terms);

            scrolled_results = new Gtk.ScrolledWindow ();
            scrolled_results.hexpand = true;
            scrolled_results.vexpand = true;
            scrolled_results.set_policy (Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC);
            var header_context = scrolled_results.get_style_context ();
            header_context.add_class ("flat");
            header_context.add_class ("thief-sheets");

            search_results = new Gtk.FlowBox ();
            search_results.orientation = Gtk.Orientation.HORIZONTAL;
            search_results.max_children_per_line = 1;
            search_results.column_spacing = 0;
            search_results.margin_top = 0;
            search_results.margin_bottom = 0;
            search_results.margin_start = 0;
            search_results.margin_end = 0;
            search_results.row_spacing = 0;
            search_results.homogeneous = true;
            search_results.hexpand = true;
            search_results.set_sort_func (search_order);

            header_context = search_results.get_style_context ();
            header_context.add_class ("thief-search-results");

            search_results.hexpand = true;
            scrolled_results.set_child (search_results);
        }

        public void create_searchers () {
            debug ("spawning seachers");
            if (scoped_folder == null || scoped_folder.chomp ().chug () == "") {
                searchable = ThiefApp.get_instance ().library.get_all_sheets ();
            } else {
                searchable = ThiefApp.get_instance ().library.get_all_sheets_for_path (scoped_folder);
                if (searchable.size == 0) {
                    return;
                }
            }

            if (!Thread.supported ()) {
                debug ("Thread support not available...");
                foreach (var search in searchable) {
                    if (!searching) {
                        break;
                    }
                    SearchThread not_a_thread = new SearchThread (active_search_term, search, this);
                    not_a_thread.search ();
                }
            } else {
                foreach (var search in searchable) {
                    SearchThread thread = new SearchThread (active_search_term, search, this);
                    add_thread ();
                    new Thread<void> ("search_thread" + search.get_sheets_path (), thread.search);
                }
            }
        }

        public bool remove_search () {
            if (ui_remove.trylock ()) {
                for (int i = 0; i < displayed.size; i++) {
                    if (i < 0 || i > displayed.size) {
                        break;
                    }
                    SearchDisplay dis = displayed.get (i);
                    if (dis.search_term != active_search_term) {
                        displayed.remove (dis);
                        search_results.remove (dis);
                        i--;
                    }
                }
                ui_remove.unlock ();
            }

            return searching;
        }

        public void remove_thread () {
            thread_update.lock ();
            running_threads--;
            thread_update.unlock ();
        }

        public void add_thread () {
            thread_update.lock ();
            running_threads++;
            thread_update.unlock ();
        }

        private int search_order (Gtk.FlowBoxChild c1, Gtk.FlowBoxChild c2) {
            SearchDisplay sd1 = (SearchDisplay)c1.get_child ();
            SearchDisplay sd2 = (SearchDisplay)c2.get_child ();
            return (sd2.occurrences - sd1.occurrences);
        }

        public bool update_search () {
            if (ui_update.trylock ()) {
                while (!results.is_empty) {
                    SearchResult res = results.remove_at (0);
                    if (res.search_term == active_search_term) {
                        SearchDisplay dis = new SearchDisplay ();
                        dis.margin_top = 0;
                        dis.margin_bottom = 0;
                        dis.margin_start = 0;
                        dis.margin_end = 0;
                        dis.file_path = res.file_path;
                        dis.search_term = res.search_term;
                        dis.mini_mark = res.mini_mark;
                        var header_context = dis.get_style_context ();
                        header_context.add_class ("flat");
                        header_context.add_class ("thief-list-sheet");

                        string lib_path = get_base_library_path (res.file_path);
                        if (lib_path == "") {
                            lib_path = res.file_path;
                        }
                        var label = new Gtk.Label ("<b>" + lib_path + " (" + res.occurrences.to_string () + " matches)</b>\n" + res.text_highlight);
                        label.xalign = 0;
                        label.set_ellipsize (Pango.EllipsizeMode.END);
                        label.use_markup = true;
                        dis.set_child (label);
                        dis.occurrences = res.occurrences;
                        dis.hexpand = true;
                        dis.file_sheet = res.file_sheet;
                        dis.clicked.connect (() => {
                            if (one_click.can_do_action ()) {
                                debug ("Opening %s", dis.file_path);
                                // any other method I try crashes everying...
                                dis.file_sheet.clicked ();
                                ThiefApp.get_instance ().search_bar.activate_search ();
                                ThiefApp.get_instance ().search_bar.search_for (dis.search_term);
                            }
                        });

                        int row = 0;
                        bool add = true;
                        foreach (var already in displayed) {
                            if (res.occurrences <= already.occurrences) {
                                row++;
                            }

                            if (already.file_path == res.file_path) {
                                add = false;
                            }
                        }

                        if (add) {
                            search_results.insert (dis, row);
                            displayed.add (dis);
                            debug ("added result");
                        }
                    }
                }
                ui_update.unlock ();
            }

            if (thread_update.trylock ()) {
                if (running_threads == 0) {
                    searching = false;
                }
                thread_update.unlock ();
            }

            return searching;
        }

        public void update_terms () {
            debug ("Updating search term");
            active_search_term = search.text;

            start_search.lock ();
            // stop all current threads
            if (searching) {
                searching = false;
            }

            while (running_threads > 0) {
                searching = false;
            }
            start_search.unlock ();

            live_reload ();
        }

        public void live_reload () {
            if (active_search_term != search.text) {
                active_search_term = search.text;
            }

            if (active_search_term == null || active_search_term.chomp ().chug () == "") {
                return;
            }

            if (!start_search.trylock ()) {
                return;
            }

            if (!searching) {
                if (ui_remove.trylock ()) {
                    if (ui_update.trylock ()) {
                        foreach (var had_it in displayed) {
                            had_it.double_check ();
                        }
                        for (int r = 0; r < displayed.size; r++) {
                            var had_it = displayed.get (r);
                            if (had_it.occurrences == 0 || had_it.search_term != active_search_term) {
                                displayed.remove (had_it);
                                search_results.remove (had_it);
                            }
                        }
                        search_results.invalidate_sort ();
                        ui_update.unlock ();
                        searching = true;
                        create_searchers ();
                        GLib.Idle.add (update_search);
                        GLib.Idle.add (remove_search);
                    }
                    ui_remove.unlock ();
                }
            }
            start_search.unlock ();
        }
    }

    public class SearchWidget : Gtk.Box {
        Gtk.SearchBar headerbar;
        public SearchBase searcher;
        string scoped_folder;

        public SearchWidget (string local_result = "") {
            searcher = new SearchBase (local_result);
            this.orientation = Gtk.Orientation.VERTICAL;
            scoped_folder = local_result;
            build_ui ();
        }

        private void build_ui () {
            headerbar = new Gtk.SearchBar ();
            headerbar.set_key_capture_widget (searcher.search);
            headerbar.search_mode_enabled = true;
            headerbar.set_child (searcher.search);

            append (headerbar);
            append (searcher.scrolled_results);
        }
    }

    public class SearchWindow : Gtk.ApplicationWindow {
        Adw.HeaderBar headerbar;
        Adw.WindowTitle title_widget;
        SearchBase searcher;
        string scoped_folder;

        public SearchWindow (string local_result = "") {
            searcher = new SearchBase (local_result);
            scoped_folder = local_result;
            build_ui ();
        }

        private void build_ui () {
            var settings = AppSettings.get_default ();
            headerbar = new Adw.HeaderBar ();
            title_widget = new Adw.WindowTitle ("", "");
            if (scoped_folder == null || scoped_folder.chomp ().chug () == "") {
                title_widget.set_title (_("Library Search"));
            } else {
                title_widget.set_title (get_base_library_path (scoped_folder).replace (Path.DIR_SEPARATOR_S, " " + Path.DIR_SEPARATOR_S + " ") + " " + _("Search"));
            }
            headerbar.set_title_widget (title_widget);
            var header_context = headerbar.get_style_context ();
            header_context.add_class ("flat");
            header_context.add_class ("thiefmd-toolbar");
            set_titlebar (headerbar);

            Gtk.Box vbox = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
            vbox.append (searcher.scrolled_results);
            set_child(vbox);

            headerbar.pack_start (searcher.search);
            headerbar.set_show_start_title_buttons (true);
            headerbar.set_show_end_title_buttons (true);
            transient_for = ThiefApp.get_instance ();

            int w, h;
            ThiefApp.get_instance ().get_default_size (out w, out h);

            set_default_size(w / 3, h - 50);

            var live_reload_switch = new Gtk.Switch ();
            live_reload_switch.set_active (false);
            live_reload_switch.tooltip_text = _("Monitor for Library changes");
            headerbar.pack_end (live_reload_switch);
            live_reload_switch.notify["active"].connect (() => {
                if (live_reload_switch.active) {
                    settings.writing_changed.connect (searcher.live_reload);
                } else {
                    settings.writing_changed.disconnect (searcher.live_reload);
                }
            });

            
            close_request.connect (() => {
                searcher.searching = false;
                if (live_reload_switch.active) {
                    settings.writing_changed.disconnect (searcher.live_reload);
                }
                return false;
            });
        }
    }
}