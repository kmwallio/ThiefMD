/*
 * Copyright (C) 2021 kmwallio
 * 
 * Modified March 21, 2021
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
using GtkSource;

namespace ThiefMD.Enrichments {
    /**
     * Citation proposal class for GtkSourceView 5 completion.
     * 
     * Represents a single citation from a BibTeX file that can be
     * inserted into the document.
     */
    public class CitationProposal : Object, GtkSource.CompletionProposal {
        public string citation { get; set; }
        public string title { get; set; }
        public string typed_prefix { get; set; }

        public CitationProposal (string citation, string title, string typed_prefix = "") {
            this.citation = citation;
            this.title = title;
            this.typed_prefix = typed_prefix;
        }

        public virtual string? get_typed_text () {
            return typed_prefix;
        }
    }

    /**
     * BibTeX completion provider for GtkSourceView 5.
     * 
     * Provides auto-completion for BibTeX citations when typing '@' followed
     * by citation keys. The provider searches for a .bib file in the current
     * document's directory and offers matching citations.
     * 
     * Usage example:
     * {{{
     *   var completion = source_view.get_completion();
     *   var bibtex_provider = new BibTexCompletionProvider();
     *   completion.add_provider(bibtex_provider);
     * }}}
     * 
     * Compatible with GTK4 and GtkSourceView 5.
     */
    public class BibTexCompletionProvider : Object, GtkSource.CompletionProvider {
        private GLib.ListStore? current_proposals = null;
        private string last_bib_file = "";
        private BibTex.Parser? bib_parser = null;

        public BibTexCompletionProvider () {
        }

        public virtual string? get_title () {
            return _("Citations");
        }

        public virtual int get_priority (GtkSource.CompletionContext context) {
            return 100;
        }

        public virtual bool is_trigger (Gtk.TextIter iter, unichar ch) {
            // Trigger on '@' character
            if (ch == '@') {
                return true;
            }
            // Also trigger on alphanumeric characters after '@'
            if (ch.isalnum () || ch == '_' || ch == '-') {
                Gtk.TextIter check = iter;
                // Look back to see if there's an '@' character
                for (int i = 0; i < 20 && check.backward_char (); i++) {
                    unichar c = check.get_char ();
                    if (c == '@') {
                        return true;
                    }
                    if (c.isspace () || c == '\n' || c == '\r') {
                        break;
                    }
                }
            }
            return false;
        }

        private string get_prefix_at_iter (Gtk.TextIter iter) {
            Gtk.TextIter start = iter;
            // Move backwards to find the start of the word after '@'
            for (int i = 0; i < 100 && start.backward_char (); i++) {
                unichar c = start.get_char ();
                if (c == '@') {
                    start.forward_char (); // Move past '@'
                    break;
                }
                if (c.isspace () || c == '\n' || c == '\r') {
                    return "";
                }
            }
            
            if (start.get_offset () < iter.get_offset ()) {
                return start.get_text (iter);
            }
            return "";
        }

        public async virtual GLib.ListModel populate_async (GtkSource.CompletionContext context, GLib.Cancellable? cancellable) throws GLib.Error {
            var proposals = new GLib.ListStore (typeof (CitationProposal));
            
            Gtk.TextIter begin, end;
            if (!context.get_bounds (out begin, out end)) {
                return proposals;
            }
            
            // Use the end iterator as the current position
            Gtk.TextIter iter = end;

            string prefix = get_prefix_at_iter (iter);
            
            var settings = AppSettings.get_default ();
            string bib_file = find_bibtex_for_sheet (settings.last_file);
            
            if (bib_file == "") {
                return proposals;
            }

            // Parse BibTeX file if needed
            if (bib_file != last_bib_file || bib_parser == null) {
                bib_parser = new BibTex.Parser (bib_file);
                bib_parser.parse_file ();
                last_bib_file = bib_file;
            }

            var cite_labels = bib_parser.get_labels ();
            if (cite_labels.is_empty) {
                return proposals;
            }

            // Add matching citations
            foreach (var citation in cite_labels) {
                if (prefix == "" || citation.down ().has_prefix (prefix.down ())) {
                    string full_title = bib_parser.get_title (citation);
                    string display_title = full_title;
                    if (full_title.length > Constants.CITATION_TITLE_MAX_LEN) {
                        display_title = full_title.substring (0, Constants.CITATION_TITLE_MAX_LEN - 3) + "...";
                    }
                    proposals.append (new CitationProposal (citation, display_title, prefix));
                }
            }

            current_proposals = proposals;
            return proposals;
        }

        public virtual void refilter (GtkSource.CompletionContext context, GLib.ListModel model) {
            // Refiltering is handled by populate_async in this implementation
        }

        public virtual void activate (GtkSource.CompletionContext context, GtkSource.CompletionProposal proposal) {
            var citation_proposal = proposal as CitationProposal;
            if (citation_proposal == null) {
                return;
            }

            Gtk.TextIter begin, end;
            if (!context.get_bounds (out begin, out end)) {
                return;
            }
            
            // Use the end iterator as the current position
            Gtk.TextIter iter = end;

            var buffer = iter.get_buffer ();
            if (buffer == null) {
                return;
            }

            // Find the start of the current word (after '@')
            Gtk.TextIter start = iter;
            for (int i = 0; i < 100 && start.backward_char (); i++) {
                unichar c = start.get_char ();
                if (c == '@') {
                    start.forward_char (); // Position after '@'
                    break;
                }
                if (c.isspace () || c == '\n' || c == '\r') {
                    break;
                }
            }

            // Delete the current prefix and insert the citation
            buffer.begin_user_action ();
            buffer.delete (ref start, ref iter);
            buffer.insert (ref start, citation_proposal.citation, citation_proposal.citation.length);
            buffer.end_user_action ();
        }

        public virtual void display (GtkSource.CompletionContext context, GtkSource.CompletionProposal proposal, GtkSource.CompletionCell cell) {
            var citation_proposal = proposal as CitationProposal;
            if (citation_proposal == null) {
                return;
            }

            var column = cell.get_column ();
            switch (column) {
                case GtkSource.CompletionColumn.TYPED_TEXT:
                    cell.set_text (citation_proposal.citation);
                    break;
                case GtkSource.CompletionColumn.COMMENT:
                    cell.set_text (citation_proposal.title);
                    break;
                case GtkSource.CompletionColumn.DETAILS:
                    // Could show additional details here
                    break;
                default:
                    break;
            }
        }
    }

    public class MarkdownEnrichment : Object {
        private GtkSource.CompletionWords? source_completion;
        private BibTexCompletionProvider? bibtex_provider;
        private unowned GtkSource.View view;
        private unowned Gtk.TextBuffer buffer;
        private Mutex checking;
        private bool markup_inserted_around_selection;
        private Gtk.EventControllerKey? markup_key_controller;
        private ulong markup_cursor_handler_id = 0;
        private ulong image_tooltip_handler_id = 0;
        private int markup_start_offset = -1;
        private int markup_end_offset = -1;
        private bool markup_is_link = false;
        private int link_text_start_offset = -1;
        private int link_text_end_offset = -1;
        private int link_url_start_offset = -1;
        private int link_url_end_offset = -1;
        private bool cursor_at_interesting_location = false;
        public bool active_selection = false;

        private Gtk.TextTag[] heading_text;
        public Gtk.TextTag code_block;
        public Gtk.TextTag markdown_link;
        public Gtk.TextTag markdown_url;

        //
        // Regexes
        // 
        private Regex is_list;
        private Regex is_partial_list;
        private Regex numerical_list;
        private Regex is_url;
        private Regex is_markdown_url;
        private Regex is_image;
        private Regex is_html_image;
        private Regex is_heading;
        private Regex is_codeblock;

        private string checking_copy;
        private TimedMutex limit_updates;

        private int last_cursor;
        private int copy_offset;
        private int hashtag_w;
        private int space_w;
        private int avg_w;

        public MarkdownEnrichment () {
            try {
                is_heading = new Regex ("(?:^|\\n)(#+\\s[^\\n\\r]+?)(?:$|\\r?\\n)", RegexCompileFlags.BSR_ANYCRLF | RegexCompileFlags.NEWLINE_ANYCRLF | RegexCompileFlags.CASELESS, 0);
            } catch (Error e) {
                warning ("Could not initialize heading regex: %s", e.message);
            }
            try {
                is_list = new Regex ("^(\\s*([\\*\\-\\+\\>]|[0-9]+(\\.|\\)))\\s)\\s*(.+)", RegexCompileFlags.CASELESS, 0);
                is_partial_list = new Regex ("^(\\s*([\\*\\-\\+\\>]|[0-9]+\\.))\\s+$", RegexCompileFlags.CASELESS, 0);
                numerical_list = new Regex ("^(\\s*)([0-9]+)((\\.|\\))\\s+)$", RegexCompileFlags.CASELESS, 0);
            } catch (Error e) {
                warning ("Could not initialize list regexes: %s", e.message);
            }
            try {
                is_url = new Regex ("^(http|ftp|ssh|mailto|tor|torrent|vscode|atom|rss|file)?s?(:\\/\\/)?(www\\.)?([a-zA-Z0-9\\.\\-]+)\\.([a-z]+)([^\\s]+)$", RegexCompileFlags.CASELESS, 0);
                is_markdown_url = new Regex ("(?<text_group>\\[(?>[^\\[\\]]+|(?&text_group))+\\])(?:\\((?<url>\\S+?)(?:[ ]\"(?<title>(?:[^\"]|(?<=\\\\)\")*?)\")?\\))", RegexCompileFlags.CASELESS, 0);
                // Matches image tags: ![alt text](url) — used for hover tooltip preview
                is_image = new Regex ("!\\[([^\\]]*)\\]\\(([^)]+)\\)", RegexCompileFlags.CASELESS, 0);
                // Matches HTML image tags like: <img src="path/to/image.png" ...>
                is_html_image = new Regex ("<img\\b[^>]*\\bsrc\\s*=\\s*[\\\"']([^\\\"']+)[\\\"'][^>]*>", RegexCompileFlags.CASELESS, 0);
            } catch (Error e) {
                warning ("Could not initialize URL regexes: %s", e.message);
            }
            try {
                is_codeblock = new Regex ("(```[a-zA-Z]*[\\n\\r]((.*?)[\\n\\r])*?```[\\n\\r])", RegexCompileFlags.MULTILINE | RegexCompileFlags.CASELESS, 0);
            } catch (Error e) {
                warning ("Could not initialize code regex: %s", e.message);
            }
            checking = Mutex ();
            limit_updates = new TimedMutex (250);
            markup_inserted_around_selection = false;
            active_selection = false;
            last_cursor = -1;
        }

        private void tag_code_blocks () {
            Gtk.TextIter start, end;
            buffer.get_bounds (out start, out end);
            buffer.remove_tag (code_block, start, end);
            string code_block_copy = buffer.get_text (start, end, true);
            // Tag code blocks as such (regex hits issues on large text)
            int block_occurrences = code_block_copy.down ().split ("\n```").length - 1;
            if (block_occurrences % 2 == 0) {
                int offset = code_block_copy.index_of ("\n```");
                while (offset > 0) {
                    offset = offset + 1;
                    int next_offset = code_block_copy.index_of ("\n```", offset + 1);
                    if (next_offset > 0) {
                        int start_pos, end_pos;
                        start_pos = code_block_copy.char_count (offset);
                        end_pos = code_block_copy.char_count ((next_offset + 4));
                        buffer.get_iter_at_offset (out start, start_pos);
                        buffer.get_iter_at_offset (out end, end_pos);
                        buffer.apply_tag (code_block, start, end);
                        //
                        // Remove links and headings from codeblock.
                        //
                        for (int h = 0; h < 6; h++) {
                            buffer.remove_tag (heading_text[h], start, end);
                        }
                        buffer.remove_tag (markdown_link, start, end);
                        buffer.remove_tag (markdown_url, start, end);
                        offset = code_block_copy.index_of ("\n```", next_offset + 1);
                    } else {
                        break;
                    }
                }
            }
        }

        private void run_between_start_and_end (Gtk.TextIter start, Gtk.TextIter end) {
            copy_offset = start.get_offset ();
            checking_copy = buffer.get_text (start, end, true);

            update_heading_margins (start, end);
            update_link_text (start, end);

            checking_copy = "";
        }

        public void handle_click (double x, double y, Gdk.ModifierType state) {
            // Only handle clicks with Ctrl held and no selection
            if ((state & Gdk.ModifierType.CONTROL_MASK) != 0 && !buffer.has_selection) {
                warning ("Ctrl+Click detected at coordinates: (%f, %f)", x, y);
                // Convert click coordinates to text position
                Gtk.TextIter click_iter;
                int buffer_x, buffer_y;
                view.window_to_buffer_coords (Gtk.TextWindowType.WIDGET, (int)x, (int)y, out buffer_x, out buffer_y);
                view.get_iter_at_location (out click_iter, buffer_x, buffer_y);
                link_clicked_at_iter (click_iter);
            }
        }

        public void link_clicked_at_iter (Gtk.TextIter cursor_location) {
            warning ("Checking for link at cursor offset: %d", cursor_location.get_offset ());
            if (cursor_location.has_tag (markdown_link) || cursor_location.has_tag (markdown_url)) {
                warning ("Link tag found at click location. Attempting to extract URL...");
                string url = "";
                Gtk.TextIter line_start = cursor_location;
                Gtk.TextIter line_end = cursor_location;
                line_start.set_line_offset (0);
                line_end.forward_to_line_end ();

                string line_text = buffer.get_text (line_start, line_end, true);
                MatchInfo match_info;
                if (is_markdown_url.match_full (line_text, line_text.length, 0,
                        RegexMatchFlags.BSR_ANYCRLF | RegexMatchFlags.NEWLINE_ANYCRLF, out match_info)) {
                    do {
                        int start_full_pos, end_full_pos;
                        int start_url_pos, end_url_pos;
                        bool full_found = match_info.fetch_pos (0, out start_full_pos, out end_full_pos);
                        bool url_found = match_info.fetch_pos (2, out start_url_pos, out end_url_pos);
                        if (!full_found || !url_found) {
                            continue;
                        }

                        int start_full_char = line_text.char_count (start_full_pos);
                        int end_full_char = line_text.char_count (end_full_pos);
                        int line_offset = line_start.get_offset ();
                        int cursor_offset = cursor_location.get_offset ();

                        if (cursor_offset >= line_offset + start_full_char &&
                            cursor_offset <= line_offset + end_full_char) {
                            url = line_text.substring (start_url_pos, end_url_pos - start_url_pos);
                            break;
                        }
                    } while (match_info.next ());
                }

                if (url == "") {
                    warning ("No URL found for click location");
                    return;
                }

                warning ("URL Clicked: %s", url);
                if (url.has_prefix ("https:") || url.has_prefix ("http:") || url.has_prefix ("mailto:") || url.has_prefix ("ftp:") ||
                    url.has_prefix ("sftp:"))
                {
                    try {
                        AppInfo.launch_default_for_uri (url, null);
                    } catch (Error e) {
                        warning ("No app to handle urls: %s", e.message);
                    }
                    return;
                }
                string possible = get_possible_markdown_url (url);
                if (possible != "") {
                    var thief_instance = ThiefApp.get_instance ();
                    if (thief_instance.library.file_in_library (possible)) {
                        var load_sheet = thief_instance.library.find_sheet_for_path (possible);
                        if (load_sheet != null) {
                            load_sheet.clicked ();
                            Timeout.add (250, () => {
                                UI.update_preview ();
                                return false;
                            });
                        } else {
                            try {
                                AppInfo.launch_default_for_uri (possible, null);
                            } catch (Error e) {
                                warning ("No app to handle urls: %s", e.message);
                            }
                        }
                    }
                }
            }
            else
            {
                // log text around click
                var next = cursor_location.copy ();
                next.forward_line ();
                warning ("No link at click location. Text around click: %s", buffer.get_text (cursor_location, next, true));
            }
        }

        public void link_clicked () {
            Gtk.TextIter cursor_location;
            var cursor = buffer.get_insert ();
            buffer.get_iter_at_mark (out cursor_location, cursor);
            link_clicked_at_iter (cursor_location);
        }

        private bool is_common_frontmatter_image_key (string key) {
            switch (key.down ()) {
                case "coverimage":
                case "cover_image":
                case "cover":
                case "featured_image":
                case "feature_image":
                case "image":
                case "thumbnail":
                case "thumb":
                case "banner":
                case "teaser":
                case "hero":
                case "poster":
                    return true;
                default:
                    return false;
            }
        }

        private bool is_iter_in_yaml_frontmatter (Gtk.TextIter iter) {
            if (buffer == null || iter.get_line () <= 0) {
                return false;
            }

            Gtk.TextIter first_start, first_end;
            buffer.get_iter_at_line (out first_start, 0);
            first_end = first_start;
            first_end.forward_to_line_end ();
            if (buffer.get_text (first_start, first_end, false).strip () != "---") {
                return false;
            }

            Gtk.TextIter line_iter;
            buffer.get_iter_at_line (out line_iter, 1);
            for (int line_num = 1; line_num <= iter.get_line (); line_num++) {
                Gtk.TextIter line_end = line_iter;
                line_end.forward_to_line_end ();
                string line_text = buffer.get_text (line_iter, line_end, false).strip ();
                if (line_text == "---" || line_text == "...") {
                    return false;
                }
                if (!line_iter.forward_line ()) {
                    break;
                }
            }

            return true;
        }

        private string get_frontmatter_image_url (string line_text, Gtk.TextIter hover_iter) {
            if (!is_iter_in_yaml_frontmatter (hover_iter)) {
                return "";
            }

            string stripped = line_text.strip ();
            if (stripped == "" || stripped.has_prefix ("#")) {
                return "";
            }

            int colon_index = stripped.index_of (":");
            if (colon_index <= 0 || colon_index + 1 >= stripped.length) {
                return "";
            }

            string key = stripped.substring (0, colon_index).strip ().down ();
            if (!is_common_frontmatter_image_key (key)) {
                return "";
            }

            string value = stripped.substring (colon_index + 1).strip ();
            int comment_index = value.index_of (" #");
            if (comment_index > 0) {
                value = value.substring (0, comment_index).strip ();
            }

            if ((value.has_prefix ("\"") && value.has_suffix ("\"")) ||
                (value.has_prefix ("'") && value.has_suffix ("'")))
            {
                if (value.length >= 2) {
                    value = value.substring (1, value.length - 2);
                }
            }

            if (value == "") {
                return "";
            }

            return value;
        }

        private bool show_image_tooltip_for_path (string img_path, Gtk.Tooltip tooltip) {
            int max_w, max_h;
            get_preview_max_size (out max_w, out max_h);

            Gdk.Texture? texture = load_preview_texture (img_path, max_w, max_h);
            if (texture == null) {
                return false;
            }

            var picture = new Gtk.Picture.for_paintable (texture);
            picture.content_fit = Gtk.ContentFit.SCALE_DOWN;
            picture.can_shrink = true;
            picture.width_request = texture.get_width ();
            picture.height_request = texture.get_height ();

            tooltip.set_custom (picture);
            return true;
        }

        private void get_preview_max_size (out int max_w, out int max_h) {
            max_w = 240;
            max_h = 200;
            int editor_w = view.get_allocated_width ();
            int editor_h = view.get_allocated_height ();
            if (editor_w > 0) {
                max_w = int.max (120, (int) (editor_w * 0.35));
            }
            if (editor_h > 0) {
                max_h = int.max (90, (int) (editor_h * 0.35));
            }
        }

        private string resolve_image_path (string img_url) {
            string img_path = Pandoc.find_file (img_url);
            if (img_path == img_url && img_url.has_prefix ("/") && img_url.length > 1) {
                // Hugo/Jekyll style: `/images/foo.png` should resolve from project root.
                img_path = Pandoc.find_file (img_url.substring (1));
            }

            return img_path;
        }

        private bool handle_image_tooltip (int x, int y, bool keyboard_tooltip, Gtk.Tooltip tooltip) {
            var settings = AppSettings.get_default ();
            if (!settings.experimental || view == null || buffer == null) {
                return false;
            }

            Gtk.TextIter hover_iter;
            if (keyboard_tooltip) {
                var cursor = buffer.get_insert ();
                buffer.get_iter_at_mark (out hover_iter, cursor);
            } else {
                int buffer_x, buffer_y;
                view.window_to_buffer_coords (Gtk.TextWindowType.WIDGET, x, y, out buffer_x, out buffer_y);
                if (!view.get_iter_at_location (out hover_iter, buffer_x, buffer_y)) {
                    return false;
                }
            }

            Gtk.TextIter line_start = hover_iter;
            Gtk.TextIter line_end = hover_iter;
            line_start.set_line_offset (0);
            line_end.forward_to_line_end ();
            // Include invisible text so collapsed markdown image URLs are still matchable.
            string line_text = buffer.get_text (line_start, line_end, true);
            int line_offset = line_start.get_offset ();
            int hover_offset = hover_iter.get_offset ();

            MatchInfo match_info;
            try {
                int url_group = 2; // Markdown image URL capture group
                if (!is_image.match (line_text, 0, out match_info)) {
                    // Fall back to HTML <img ... src="..."> support
                    if (!is_html_image.match (line_text, 0, out match_info)) {
                        string frontmatter_url = get_frontmatter_image_url (line_text, hover_iter);
                        if (frontmatter_url == "") {
                            return false;
                        }

                        string frontmatter_path = resolve_image_path (frontmatter_url);
                        if (frontmatter_path == frontmatter_url &&
                            !GLib.FileUtils.test (frontmatter_path, GLib.FileTest.EXISTS))
                        {
                            return false;
                        }

                        return show_image_tooltip_for_path (frontmatter_path, tooltip);
                    }
                    url_group = 1; // HTML src capture group
                }

                do {
                    int start_pos, end_pos;
                    if (!match_info.fetch_pos (0, out start_pos, out end_pos)) {
                        continue;
                    }

                    int start_char = line_text.char_count (start_pos);
                    int end_char = line_text.char_count (end_pos);
                    bool hover_in_match = !(hover_offset < (line_offset + start_char) || hover_offset > (line_offset + end_char));
                    if (!hover_in_match && url_group == 2 && hover_iter.has_tag (markdown_link)) {
                        int alt_start_pos, alt_end_pos;
                        if (match_info.fetch_pos (1, out alt_start_pos, out alt_end_pos)) {
                            int alt_start_char = line_text.char_count (alt_start_pos);
                            int alt_end_char = line_text.char_count (alt_end_pos);
                            hover_in_match = !(hover_offset < (line_offset + alt_start_char) || hover_offset > (line_offset + alt_end_char));
                        }
                    }
                    if (!hover_in_match) {
                        continue;
                    }

                    string img_url = match_info.fetch (url_group);
                    string img_path = resolve_image_path (img_url);
                    if (img_path == img_url && !GLib.FileUtils.test (img_path, GLib.FileTest.EXISTS)) {
                        continue;
                    }

                    return show_image_tooltip_for_path (img_path, tooltip);
                } while (match_info.next ());
            } catch (Error e) {
                return false;
            }

            return false;
        }

        private void update_link_text (Gtk.TextIter start_region, Gtk.TextIter end_region) {
            var settings = AppSettings.get_default ();
            buffer.remove_tag (markdown_link, start_region, end_region);
            buffer.remove_tag (markdown_url, start_region, end_region);

            try {
                Gtk.TextIter start, end;
                Gtk.TextIter cursor_location;
                var cursor = buffer.get_insert ();
                MatchInfo match_info;
                buffer.get_iter_at_mark (out cursor_location, cursor);
                Gtk.TextIter bound_start, bound_end;
                buffer.get_bounds (out bound_start, out bound_end);
                bool check_selection = buffer.get_has_selection ();
                Gtk.TextIter? select_start = null, select_end = null;
                if (check_selection) {
                    buffer.get_selection_bounds (out select_start, out select_end);
                }
                if (is_markdown_url.match_full (checking_copy, checking_copy.length, 0, RegexMatchFlags.BSR_ANYCRLF | RegexMatchFlags.NEWLINE_ANYCRLF, out match_info)) {
                    do {
                        buffer.get_bounds (out bound_start, out bound_end);
                        int start_link_pos, end_link_pos;
                        int start_url_pos, end_url_pos;
                        int start_full_pos, end_full_pos;
                        //  warning ("Link Found, Text: %s, URL: %s", match_info.fetch (1), match_info.fetch (2));
                        bool linkify = match_info.fetch_pos (1, out start_link_pos, out end_link_pos);
                        bool urlify = match_info.fetch_pos (2, out start_url_pos, out end_url_pos);
                        bool full_found = match_info.fetch_pos (0, out start_full_pos, out end_full_pos);
                        if (linkify && urlify && full_found) {
                            start_full_pos = copy_offset + checking_copy.char_count (start_full_pos);
                            end_full_pos = copy_offset + checking_copy.char_count (end_full_pos);
                            //
                            // Don't hide active link's where the cursor is present
                            //
                            buffer.get_iter_at_offset (out start, start_full_pos);
                            buffer.get_iter_at_offset (out end, end_full_pos);

                            if (cursor_location.in_range (start, end)) {
                                buffer.apply_tag (markdown_link, start, end);
                                continue;
                            }

                            if (check_selection) {
                                if (start.in_range (select_start, select_end) || end.in_range (select_start, select_end)) {
                                    buffer.apply_tag (markdown_link, start, end);
                                    continue;
                                }
                            }

                            // Check if we're in inline code
                            if (start.backward_line ()) {
                                buffer.get_iter_at_offset (out end, start_full_pos);
                                if (start.in_range (bound_start, bound_end) && end.in_range (bound_start, bound_end)) {
                                    string sanity_check = buffer.get_text (start, end, true);
                                    if (sanity_check.index_of_char ('`') >= 0) {
                                        buffer.get_iter_at_offset (out end, end_full_pos);
                                        if (end.forward_line ()) {
                                            buffer.get_iter_at_offset (out start, end_full_pos);
                                            sanity_check = buffer.get_text (start, end, true);
                                            if (sanity_check.index_of_char ('`') >= 0) {
                                                continue;
                                            }
                                        }
                                    }
                                } else {
                                    // Bail, our calculations are now out of range
                                    continue;
                                }
                            }

                            //
                            // Link Text [Text]
                            //
                            start_link_pos = copy_offset + checking_copy.char_count (start_link_pos);
                            end_link_pos = copy_offset + checking_copy.char_count (end_link_pos);
                            buffer.get_iter_at_offset (out start, start_link_pos);
                            buffer.get_iter_at_offset (out end, end_link_pos);
                            if (start.has_tag (code_block) || end.has_tag (code_block)) {
                                continue;
                            }
                            if (start.in_range (bound_start, bound_end) && end.in_range (bound_start, bound_end)) {
                                buffer.apply_tag (markdown_link, start, end);
                            } else  {
                                // Bail, our calculations are now out of range
                                continue;
                            }

                            if (!UI.show_link_brackets () && !settings.focus_mode) {
                                //
                                // Starting [
                                //
                                buffer.get_iter_at_offset (out start, start_link_pos);
                                buffer.get_iter_at_offset (out end, start_link_pos);
                                bool not_at_start = start.backward_chars (1);
                                end.forward_char ();
                                if (start.in_range (bound_start, bound_end) && end.in_range (bound_start, bound_end)) {
                                    if (start.get_char () != '!') {
                                        if (not_at_start) {
                                            start.forward_char ();
                                        }
                                        buffer.apply_tag (markdown_url, start, end);
                                        //
                                        // Closing ]
                                        //
                                        buffer.get_iter_at_offset (out start, end_link_pos);
                                        buffer.get_iter_at_offset (out end, end_link_pos);
                                        start.backward_char ();
                                        buffer.apply_tag (markdown_url, start, end);
                                    }
                                } else {
                                    // Bail, our calculations are now out of range
                                    continue;
                                }
                            }

                            //
                            // Link URL (https://thiefmd.com)
                            //
                            start_url_pos = copy_offset + checking_copy.char_count (start_url_pos);
                            buffer.get_iter_at_offset (out start, start_url_pos);
                            start.backward_char ();
                            buffer.get_iter_at_offset (out end, end_full_pos);
                            if (start.has_tag (code_block) || end.has_tag (code_block)) {
                                continue;
                            }
                            if (start.in_range (bound_start, bound_end) && end.in_range (bound_start, bound_end)) {
                                buffer.apply_tag (markdown_url, start, end);
                            } else  {
                                // Bail, our calculations are now out of range
                                continue;
                            }
                        }
                    } while (match_info.next ());
                }
            } catch (Error e) {
                warning ("Could not apply link formatting: %s", e.message);
            }
        }

        private void update_heading_margins (Gtk.TextIter start_region, Gtk.TextIter end_region) {
            try {
                Gtk.TextIter start, end;
                Gtk.TextIter cursor_location;
                var cursor = buffer.get_insert ();
                MatchInfo match_info;
                buffer.get_iter_at_mark (out cursor_location, cursor);

                for (int h = 0; h < 6; h++) {
                    buffer.remove_tag (heading_text[h], start_region, end_region);
                }

                buffer.tag_table.foreach ((tag) => {
                    if (tag.name != null && tag.name.has_prefix ("list-")) {
                        buffer.remove_tag (tag, start_region, end_region);
                    }
                });

                // Tag headings and make sure they're not in code blocks
                if (is_heading.match_full (checking_copy, checking_copy.length, 0, RegexMatchFlags.BSR_ANYCRLF | RegexMatchFlags.NEWLINE_ANYCRLF, out match_info)) {
                    do {
                        int start_pos, end_pos;
                        string heading = match_info.fetch (1);
                        bool headify = match_info.fetch_pos (1, out start_pos, out end_pos) && (heading.index_of ("\n") < 0);
                        if (headify) {
                            start_pos = copy_offset + checking_copy.char_count (start_pos);
                            end_pos = copy_offset + checking_copy.char_count (end_pos);
                            buffer.get_iter_at_offset (out start, start_pos);
                            buffer.get_iter_at_offset (out end, end_pos);
                            if (start.has_tag (code_block) || end.has_tag (code_block)) {
                                continue;
                            }
                            int heading_depth = heading.index_of_char (' ') - 1;
                            if (heading_depth >= 0 && heading_depth < 6) {
                                buffer.apply_tag (heading_text[heading_depth], start, end);
                            }
                        }
                    } while (match_info.next ());
                }

                // Tag lists and make sure they're not in code blocks
                Gtk.TextIter? line_start = start_region, line_end = null;
                if (!line_start.starts_line ()) {
                    line_start.backward_line ();
                }
                do {
                    while (line_start.get_char () == '\r' || line_start.get_char () == '\n') {
                        if (!line_start.forward_char ()) {
                            break;
                        }
                    }
                    line_end = line_start;
                    if (!line_end.forward_line ()) {
                        break;
                    }
                    string line = line_start.get_text (line_end);
                    if (is_list.match_full (line, line.length, 0, 0, out match_info)) {
                        string list_marker = match_info.fetch (1);
                        if (!line_start.has_tag (code_block) && !line_end.has_tag (code_block)) {
                            list_marker = list_marker.replace ("\t", "    ");
                            int list_depth = list_marker.length;
                            if (list_depth >= 0) {
                                int list_px_index = get_string_px_width (list_marker);
                                Gtk.TextTag? list_indent = buffer.tag_table.lookup ("list-" + list_px_index.to_string ());
                                if (list_indent == null) {
                                    list_indent = buffer.create_tag ("list-" + list_px_index.to_string ());
                                }
                                list_indent.left_margin = view.left_margin;
                                list_indent.left_margin_set = false;
                                list_indent.accumulative_margin = false;
                                list_indent.indent = -list_px_index;
                                list_indent.indent_set = true;
                                buffer.apply_tag (list_indent, line_start, line_end);
                            }
                        }
                    }
                    line_start = line_end;
                } while (true);
            } catch (Error e) {
                warning ("Could not adjust headers: %s", e.message);
            }
        }

        public void reset () {
            last_cursor = -1;
            recheck_all ();
        }

        public void recheck_all () {
            if (view == null || buffer == null) {
                return;
            }

            recalculate_margins ();

            if (!buffer.has_selection) {
                if (!limit_updates.can_do_action ()) {
                    return;
                }
            }

            if (!checking.trylock ()) {
                return;
            }

            var settings = AppSettings.get_default ();
            if (settings.focus_mode) {
                code_block.background_set = false;
                code_block.paragraph_background_set = false;
                code_block.background_full_height_set = false;
            } else {
                double r, g, b;
                UI.get_codeblock_bg_color (out r, out g, out b);
                code_block.background_rgba = Gdk.RGBA () { red = (float) r, green = (float) g, blue = (float) b, alpha = 1.0f };
                code_block.background_set = true;
                code_block.paragraph_background_rgba = Gdk.RGBA () { red = (float) r, green = (float) g, blue = (float) b, alpha = 1.0f };
                code_block.paragraph_background_set = true;
                code_block.background_full_height = true;
                code_block.background_full_height_set = true;
            }

            if (settings.experimental) {
                if (active_selection) {
                    markdown_link.weight = Pango.Weight.NORMAL;
                    markdown_link.weight_set = true;
                    markdown_url.weight = Pango.Weight.NORMAL;
                    markdown_url.weight_set = true;
                } else {
                    markdown_link.weight_set = false;
                    markdown_url.weight_set = false;
                }
            }

            // Remove any previous tags
            Gtk.TextIter start, end, cursor_iter;
            var cursor = buffer.get_insert ();
            buffer.get_iter_at_mark (out cursor_iter, cursor);
            int current_cursor = cursor_iter.get_offset ();

            tag_code_blocks ();
            
            // For large documents, optimize by processing visible area + buffer
            if (last_cursor == -1 || buffer.get_char_count () > 10000) {
                buffer.get_bounds (out start, out end);
                
                // For very large files (>10k chars), just process around cursor
                if (buffer.get_char_count () > 10000 && last_cursor != -1) {
                    buffer.get_iter_at_mark (out start, cursor);
                    buffer.get_iter_at_mark (out end, cursor);
                    
                    // Get a larger chunk around cursor for large files
                    for (int i = 0; i < 50 && start.backward_line (); i++) {}
                    for (int i = 0; i < 50 && end.forward_line (); i++) {}
                }
                
                run_between_start_and_end (start, end);
            } else {
                //
                // Scan where we are
                //
                buffer.get_iter_at_mark (out start, cursor);
                buffer.get_iter_at_mark (out end, cursor);
                get_chunk_of_text_around_cursor (ref start, ref end, true);
                run_between_start_and_end (start, end);

                //
                // Rescan where we were if still in buffer,
                // and not where we just scanned
                //
                if ((current_cursor - last_cursor).abs () > 60) {
                    Gtk.TextIter old_start, old_end, bound_start, bound_end;
                    buffer.get_bounds (out bound_start, out bound_end);
                    buffer.get_iter_at_offset (out old_start, last_cursor);
                    buffer.get_iter_at_offset (out old_end, last_cursor);
                    if (old_start.in_range (bound_start, bound_end)) {
                        get_chunk_of_text_around_cursor (ref old_start, ref old_end, true);
                        if (!old_start.in_range (start, end) || !old_end.in_range (start, end)) {
                            run_between_start_and_end (old_start, old_end);
                        }
                    }
                }
            }

            last_cursor = current_cursor;
            checking.unlock ();
        }

        private void clear_markup_navigation () {
            markup_inserted_around_selection = false;
            markup_is_link = false;
            markup_start_offset = -1;
            markup_end_offset = -1;
            link_text_start_offset = -1;
            link_text_end_offset = -1;
            link_url_start_offset = -1;
            link_url_end_offset = -1;
        }

        private bool handle_markup_navigation_key (uint keyval) {
            if (!markup_inserted_around_selection) {
                return false;
            }

            if (keyval != Gdk.Key.Left && keyval != Gdk.Key.Right) {
                return false;
            }

            Gtk.TextIter cursor_iter;
            var cursor = buffer.get_insert ();
            buffer.get_iter_at_mark (out cursor_iter, cursor);
            int cursor_offset = cursor_iter.get_offset ();

            if (cursor_offset < markup_start_offset || cursor_offset > markup_end_offset) {
                clear_markup_navigation ();
                return false;
            }

            if (markup_is_link && keyval == Gdk.Key.Right) {
                if (cursor_offset >= link_text_start_offset && cursor_offset <= link_text_end_offset) {
                    Gtk.TextIter target;
                    buffer.get_iter_at_offset (out target, link_url_start_offset);
                    buffer.place_cursor (target);
                    return true;
                }
            }

            Gtk.TextIter target;
            if (keyval == Gdk.Key.Left) {
                buffer.get_iter_at_offset (out target, markup_start_offset);
            } else {
                buffer.get_iter_at_offset (out target, markup_end_offset);
            }
            buffer.place_cursor (target);
            clear_markup_navigation ();
            return true;
        }

        private void handle_markup_cursor_position () {
            if (!markup_inserted_around_selection) {
                return;
            }

            Gtk.TextIter cursor_iter;
            var cursor = buffer.get_insert ();
            buffer.get_iter_at_mark (out cursor_iter, cursor);
            int cursor_offset = cursor_iter.get_offset ();
            if (cursor_offset < markup_start_offset || cursor_offset > markup_end_offset) {
                clear_markup_navigation ();
            }
        }

        private void set_generic_markup_range (int start_offset, int end_offset) {
            markup_start_offset = start_offset;
            markup_end_offset = end_offset;
            markup_is_link = false;
            markup_inserted_around_selection = true;
        }

        private void record_link_markup_at_cursor (Gtk.TextIter cursor_iter) {
            Gtk.TextIter scan = cursor_iter;
            bool found_open = false;
            for (int i = 0; i < 256 && scan.backward_char (); i++) {
                unichar c = scan.get_char ();
                if (c == '\n' || c == '\r') {
                    break;
                }
                if (c == '[') {
                    found_open = true;
                    break;
                }
            }
            if (!found_open || scan.get_char () != '[') {
                return;
            }

            int link_open = scan.get_offset ();
            Gtk.TextIter close = scan;
            if (!close.forward_char ()) {
                return;
            }
            while (close.get_char () != ']' && close.forward_char ()) {
                if (close.get_char () == '\n' || close.get_char () == '\r') {
                    return;
                }
            }
            if (close.get_char () != ']') {
                return;
            }
            int link_close = close.get_offset ();

            Gtk.TextIter paren_open = close;
            if (!paren_open.forward_char ()) {
                return;
            }
            if (paren_open.get_char () != '(') {
                return;
            }
            int url_open = paren_open.get_offset ();

            Gtk.TextIter paren_close = paren_open;
            if (!paren_close.forward_char ()) {
                return;
            }
            while (paren_close.get_char () != ')' && paren_close.forward_char ()) {
                if (paren_close.get_char () == '\n' || paren_close.get_char () == '\r') {
                    return;
                }
            }
            if (paren_close.get_char () != ')') {
                return;
            }
            int url_close = paren_close.get_offset ();

            markup_start_offset = link_open;
            markup_end_offset = url_close + 1;
            link_text_start_offset = link_open + 1;
            link_text_end_offset = link_close;
            link_url_start_offset = url_open + 1;
            link_url_end_offset = url_close;
            markup_is_link = true;
            markup_inserted_around_selection = true;
        }

        private void insert_markup_around_cursor (string markup) {
            if (!buffer.get_has_selection ()) {
                Gtk.TextIter iter;
                view.insert_at_cursor (markup + markup);
                buffer.get_iter_at_offset (out iter, buffer.cursor_position - markup.length);
                if (buffer.cursor_position - markup.length > 0) {
                    buffer.place_cursor (iter);
                }
                int cursor_pos = buffer.cursor_position;
                set_generic_markup_range (cursor_pos - markup.length, cursor_pos + markup.length);
            } else {
                Gtk.TextIter iter_start, iter_end;
                if (buffer.get_selection_bounds (out iter_start, out iter_end)) {
                    buffer.insert (ref iter_start, markup, -1);
                    if (buffer.get_selection_bounds (out iter_start, out iter_end)) {
                        buffer.insert (ref iter_end, markup, -1);
                        buffer.get_selection_bounds (out iter_start, out iter_end);
                        iter_end.backward_chars (markup.length);
                        buffer.select_range (iter_start, iter_end);
                        set_generic_markup_range (iter_start.get_offset () - markup.length, iter_end.get_offset () + markup.length);
                    }
                }
            }
        }

        public void bold () {
            insert_markup_around_cursor ("**");
        }

        public void italic () {
            insert_markup_around_cursor ("*");
        }

        public void strikethrough () {
            insert_markup_around_cursor ("~~");
        }

        public void link () {
            if (buffer.has_selection) {
                Gtk.TextIter iter_start, iter_end;
                if (buffer.get_selection_bounds (out iter_start, out iter_end)) {
                    string selected_text = buffer.get_text (iter_start, iter_end, true);
                    MatchInfo match_info;
                    try {
                        if (!is_url.match_full (selected_text, selected_text.length, 0, 0, out match_info)) {
                            buffer.insert (ref iter_start, "[", -1);
                            if (buffer.get_selection_bounds (out iter_start, out iter_end)) {
                                buffer.insert (ref iter_end, "]()", -1);
                                buffer.get_selection_bounds (out iter_start, out iter_end);
                                iter_end.backward_chars (1);
                                buffer.place_cursor (iter_end);
                                record_link_markup_at_cursor (iter_end);
                            }
                        } else {
                            buffer.insert (ref iter_start, "[](", -1);
                            if (buffer.get_selection_bounds (out iter_start, out iter_end)) {
                                buffer.insert (ref iter_end, ")", -1);
                                buffer.get_selection_bounds (out iter_start, out iter_end);
                                iter_start.backward_chars (2);
                                buffer.place_cursor (iter_start);
                                record_link_markup_at_cursor (iter_start);
                            }
                        }
                    } catch (Error e) {
                        warning ("Could not determine URL status, hit exception: %s", e.message);
                    }
                }
            } else {
                view.insert_at_cursor ("[]()");
                var cursor = buffer.get_insert ();
                Gtk.TextIter start;
                buffer.get_iter_at_mark (out start, cursor);
                start.backward_chars (3);
                buffer.place_cursor (start);
                record_link_markup_at_cursor (start);
            }
        }

        private void cursor_update_heading_margins () {
            var settings = AppSettings.get_default ();

            debug ("settings.experimental: %s", settings.experimental ? "true" : "false");

            if (settings.experimental) {
                var cursor = buffer.get_insert ();
                Gtk.TextIter cursor_location;
                buffer.get_iter_at_mark (out cursor_location, cursor);
                if (cursor_location.has_tag (markdown_link) || cursor_location.has_tag (markdown_url) || buffer.has_selection) {
                    recheck_all ();
                    cursor_at_interesting_location = true;
                } else if (cursor_at_interesting_location) {
                    recheck_all ();
                    Gtk.TextIter before, after;
                    Gtk.TextIter bound_start, bound_end;
                    buffer.get_bounds (out bound_start, out bound_end);
                    buffer.get_iter_at_mark (out before, cursor);
                    buffer.get_iter_at_mark (out after, cursor);
                    if (!before.backward_line()) {
                        before = bound_start;
                    }
                    if (!after.forward_line ()) {
                        after = bound_end;
                    }
                    string sample_text = buffer.get_text (before, after, true);
                    // Keep interesting location if we're potentially in something we can remove a link to.
                    if (!is_markdown_url.match (sample_text, RegexMatchFlags.BSR_ANYCRLF | RegexMatchFlags.NEWLINE_ANYCRLF)) {
                        cursor_at_interesting_location = false;
                    }
                }
            }
        }

        public bool attach (GtkSource.View textview) {
            if (textview == null) {
                return false;
            }

            view = textview;
            buffer = textview.get_buffer ();

            if (buffer == null) {
                view = null;
                return false;
            }

            var settings = AppSettings.get_default ();

            view.destroy.connect (detach);

            heading_text = new Gtk.TextTag[6];
            for (int h = 0; h < 6; h++) {
                heading_text[h] = buffer.create_tag ("heading%d-text".printf (h + 1));
            }

            code_block = buffer.create_tag ("code-block");
            markdown_link = buffer.create_tag ("markdown-link");
            markdown_url = buffer.create_tag ("markdown-url");
            markdown_url.invisible = true;
            markdown_url.invisible_set = true;
            markup_inserted_around_selection = false;
            cursor_at_interesting_location = false;
            active_selection = false;

            settings_updated ();
            settings.changed.connect (settings_updated);

            last_cursor = -1;

            // Attach BibTeX completion provider if experimental mode and bibtex file exists
            update_bibtex_provider ();

            markup_key_controller = new Gtk.EventControllerKey ();
            markup_key_controller.key_pressed.connect ((keyval, _keycode, _state) => {
                return handle_markup_navigation_key (keyval);
            });
            view.add_controller (markup_key_controller);
            markup_cursor_handler_id = buffer.notify["cursor-position"].connect (handle_markup_cursor_position);
            view.set_has_tooltip (true);
            image_tooltip_handler_id = view.query_tooltip.connect (handle_image_tooltip);

            return true;
        }

        private void settings_updated () {
            var settings = AppSettings.get_default ();

            if (settings.experimental) {
                buffer.notify["cursor-position"].connect (cursor_update_heading_margins);
                markdown_url.invisible = true;
                markdown_url.invisible_set = true;
            } else {
                buffer.notify["cursor-position"].disconnect (cursor_update_heading_margins);
                markdown_url.invisible = false;
                markdown_url.invisible_set = false;
            }

            // Update BibTeX provider based on experimental mode
            update_bibtex_provider ();

            double r, g, b;
            if (!settings.focus_mode) {
                UI.get_codeblock_bg_color (out r, out g, out b);
                code_block.background_rgba = Gdk.RGBA () { red = (float) r, green = (float) g, blue = (float) b, alpha = 1.0f };
                code_block.background_set = true;
                code_block.paragraph_background_rgba = Gdk.RGBA () { red = (float) r, green = (float) g, blue = (float) b, alpha = 1.0f };
                code_block.paragraph_background_set = true;
                code_block.background_full_height = true;
                code_block.background_full_height_set = true;
            } else {
                code_block.background_set = false;
                code_block.paragraph_background_set = false;
                code_block.background_full_height = false;
                code_block.background_full_height_set = false;
            }

            recalculate_margins ();
        }

        private void update_bibtex_provider () {
            if (view == null) {
                return;
            }

            var settings = AppSettings.get_default ();
            string bib_file = find_bibtex_for_sheet (settings.last_file);
            var completion = view.get_completion ();

            if (completion == null) {
                return;
            }

            // Remove existing provider if present
            if (bibtex_provider != null) {
                completion.remove_provider (bibtex_provider);
                bibtex_provider = null;
            }

            // Add provider if experimental mode is enabled and bibtex file exists
            if (settings.experimental && bib_file != "") {
                bibtex_provider = new BibTexCompletionProvider ();
                completion.add_provider (bibtex_provider);
            }
        }

        private int get_string_px_width (string str) {
            var settings = AppSettings.get_default ();
            int f_w = (int)(settings.get_css_font_size () * ((settings.fullscreen ? 1.4 : 1)));
            if (view.get_realized ()) {
                var font_desc = Pango.FontDescription.from_string (settings.font_family);
                font_desc.set_size ((int)(f_w * Pango.SCALE * (str.has_prefix ("#") ? Pango.Scale.LARGE : 1)));
                var font_context = view.get_pango_context ();
                var font_layout = new Pango.Layout (font_context);
                font_layout.set_font_description (font_desc);
                font_layout.set_text (str, str.length);
                Pango.Rectangle ink, logical;
                font_layout.get_pixel_extents (out ink, out logical);
                font_layout.dispose ();
                debug ("# Ink: %d, Logical: %d", ink.width, logical.width);
                return int.max (ink.width, logical.width);
            }
            return f_w;
        }

        private void recalculate_margins () {
            var settings = AppSettings.get_default ();
            int f_w = (int)(settings.get_css_font_size () * ((settings.fullscreen ? 1.4 : 1)));
            int m = view.left_margin;
            hashtag_w = f_w;
            space_w = f_w;
            avg_w = f_w;

            debug ("Recalculate margins");

            if (view.get_realized ()) {
                var font_desc = Pango.FontDescription.from_string (settings.font_family);
                font_desc.set_size ((int)(f_w * Pango.SCALE * Pango.Scale.LARGE));
                var font_context = view.get_pango_context ();
                var font_layout = new Pango.Layout (font_context);
                font_layout.set_font_description (font_desc);
                font_layout.set_text ("#", 1);
                Pango.Rectangle ink, logical;
                font_layout.get_pixel_extents (out ink, out logical);
                debug ("# Ink: %d, Logical: %d", ink.width, logical.width);
                hashtag_w = int.max (ink.width, logical.width);
                font_layout.set_text (" ", 1);
                font_layout.get_pixel_extents (out ink, out logical);
                font_layout.dispose ();
                debug ("  Ink: %d, Logical: %d", ink.width, logical.width);
                space_w = int.max (ink.width, logical.width);
                if (space_w + hashtag_w <= 0) {
                    hashtag_w = f_w;
                    space_w = f_w;
                }
                if (space_w < (hashtag_w / 2)) {
                    avg_w = (int)((hashtag_w + hashtag_w + space_w) / 3.0);
                } else {
                    avg_w = (int)((hashtag_w + space_w) / 2.0);
                }
                debug ("%s Hashtag: %d, Space: %d, AvgChar: %d", font_desc.get_family (), hashtag_w, space_w, avg_w);
                if (m - ((hashtag_w * 6) + space_w) <= 0) {
                    heading_text[0].left_margin = m;
                    heading_text[1].left_margin = m;
                    heading_text[2].left_margin = m;
                    heading_text[3].left_margin = m;
                    heading_text[4].left_margin = m;
                    heading_text[5].left_margin = m;
                    heading_text[0].left_margin_set = true;
                    heading_text[1].left_margin_set = true;
                    heading_text[2].left_margin_set = true;
                    heading_text[3].left_margin_set = true;
                    heading_text[4].left_margin_set = true;
                    heading_text[5].left_margin_set = true;
                    heading_text[0].indent_set = false;
                    heading_text[1].indent_set = false;
                    heading_text[2].indent_set = false;
                    heading_text[3].indent_set = false;
                    heading_text[4].indent_set = false;
                    heading_text[5].indent_set = false;
                } else {
                    heading_text[0].left_margin = m - ((hashtag_w * 1) + space_w);
                    heading_text[1].left_margin = m - ((hashtag_w * 2) + space_w);
                    heading_text[2].left_margin = m - ((hashtag_w * 3) + space_w);
                    heading_text[3].left_margin = m - ((hashtag_w * 4) + space_w);
                    heading_text[4].left_margin = m - ((hashtag_w * 5) + space_w);
                    heading_text[5].left_margin = m - ((hashtag_w * 6) + space_w);
                    heading_text[0].left_margin_set = true;
                    heading_text[1].left_margin_set = true;
                    heading_text[2].left_margin_set = true;
                    heading_text[3].left_margin_set = true;
                    heading_text[4].left_margin_set = true;
                    heading_text[5].left_margin_set = true;
                    heading_text[0].indent = -((hashtag_w * 1) + space_w);
                    heading_text[1].indent = -((hashtag_w * 2) + space_w);
                    heading_text[2].indent = -((hashtag_w * 3) + space_w);
                    heading_text[3].indent = -((hashtag_w * 4) + space_w);
                    heading_text[4].indent = -((hashtag_w * 5) + space_w);
                    heading_text[5].indent = -((hashtag_w * 6) + space_w);
                    heading_text[0].indent_set = true;
                    heading_text[1].indent_set = true;
                    heading_text[2].indent_set = true;
                    heading_text[3].indent_set = true;
                    heading_text[4].indent_set = true;
                    heading_text[5].indent_set = true;
                    heading_text[0].accumulative_margin = false;
                    heading_text[1].accumulative_margin = false;
                    heading_text[2].accumulative_margin = false;
                    heading_text[3].accumulative_margin = false;
                    heading_text[4].accumulative_margin = false;
                    heading_text[5].accumulative_margin = false;
                }
            }
        }

        /** Load an image from disk, scale it to fit max_w/max_h, and return a texture. Returns null if the image cannot be loaded. */
        private Gdk.Texture? load_preview_texture (string img_path, int max_w, int max_h) {
            try {
                var pixbuf = new Gdk.Pixbuf.from_file_at_scale (img_path, max_w, max_h, true);
                return Gdk.Texture.for_pixbuf (pixbuf);
            } catch (Error e) {
                debug ("Image preview: could not load '%s': %s", img_path, e.message);
                return null;
            }
        }

        public void detach () {
            var settings = AppSettings.get_default ();

            // Remove BibTeX completion provider if present
            if (bibtex_provider != null && view != null) {
                var completion = view.get_completion ();
                if (completion != null) {
                    completion.remove_provider (bibtex_provider);
                }
                bibtex_provider = null;
            }

            Gtk.TextIter start, end;
            buffer.get_bounds (out start, out end);

            buffer.remove_tag (code_block, start, end);
            buffer.remove_tag (markdown_link, start, end);
            buffer.remove_tag (markdown_url, start, end);
            for (int h = 0; h < 6; h++) {
                buffer.remove_tag (heading_text[h], start, end);
                buffer.tag_table.remove (heading_text[h]);
            }
            buffer.tag_table.remove (code_block);
            buffer.tag_table.remove (markdown_link);
            buffer.tag_table.remove (markdown_url);
            code_block = null;
            markdown_link = null;
            markdown_url = null;
            markup_inserted_around_selection = false;
            cursor_at_interesting_location = false;
            active_selection = false;

            settings.changed.disconnect (settings_updated);
            buffer.notify["cursor-position"].disconnect (cursor_update_heading_margins);
            if (markup_cursor_handler_id != 0) {
                SignalHandler.disconnect (buffer, markup_cursor_handler_id);
                markup_cursor_handler_id = 0;
            }
            if (markup_key_controller != null) {
                view.remove_controller (markup_key_controller);
                markup_key_controller = null;
            }
            if (image_tooltip_handler_id != 0) {
                SignalHandler.disconnect (view, image_tooltip_handler_id);
                image_tooltip_handler_id = 0;
            }
            clear_markup_navigation ();
            view = null;
            buffer = null;
            last_cursor = -1;
        }
    }
}
