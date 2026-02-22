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
using GtkSource;

namespace ThiefMD.Enrichments {
    public class FountainCharacterProposal : Object, GtkSource.CompletionProposal {
        public string character { get; set; }
        public string typed_prefix { get; set; }

        public FountainCharacterProposal (string character, string typed_prefix = "") {
            this.character = character;
            this.typed_prefix = typed_prefix;
        }

        public virtual string? get_typed_text () {
            return typed_prefix;
        }
    }

    public class FountainCharacterCompletionProvider : Object, GtkSource.CompletionProvider {
        private unowned Gtk.TextBuffer buffer;
        private Regex? character_regex;

        public FountainCharacterCompletionProvider (Gtk.TextBuffer buffer) {
            this.buffer = buffer;
            try {
                character_regex = new Regex ("(?<=\\n)([ \\t]*?[^<>\\p{Ll}\\s\\/\\n][^<>\\p{Ll}:!\\?\\n]*[^<>\\p{Ll}\\(!\\?:,\\n\\.][ \\t]?|\\([^\\n]+\\))\\n{1}(?!\\n)(.+?)\\n{1}", RegexCompileFlags.BSR_ANYCRLF | RegexCompileFlags.NEWLINE_ANYCRLF, 0);
            } catch (Error e) {
                warning ("Could not build fountain completion regex: %s", e.message);
            }
        }

        public virtual string? get_title () {
            return _("Characters");
        }

        public virtual int get_priority (GtkSource.CompletionContext context) {
            return 90;
        }

        public virtual bool is_trigger (Gtk.TextIter iter, unichar ch) {
            return true;
        }

        private bool get_prefix_bounds (Gtk.TextIter iter, out Gtk.TextIter prefix_start, out string prefix) {
            prefix_start = iter;
            prefix_start.set_line_offset (0);
            Gtk.TextIter scan = prefix_start;
            while (!scan.ends_line () && (scan.get_char () == ' ' || scan.get_char () == '\t')) {
                if (!scan.forward_char ()) {
                    break;
                }
            }
            prefix_start = scan;
            string text = prefix_start.get_text (iter);
            prefix = text.chomp ().chug ();
            return true;
        }

        private bool get_iter_from_context (GtkSource.CompletionContext context, out Gtk.TextIter iter) {
            Gtk.TextIter begin, end;
            if (context.get_bounds (out begin, out end)) {
                iter = end;
                return true;
            }

            var ctx_buffer = context.get_buffer ();
            if (ctx_buffer != null) {
                var cursor = ctx_buffer.get_insert ();
                ctx_buffer.get_iter_at_mark (out iter, cursor);
                return true;
            }

            iter = Gtk.TextIter ();
            return false;
        }

        private bool is_character_context (Gtk.TextIter iter, out Gtk.TextIter prefix_start, out string prefix, int min_len = 2) {
            prefix = "";
            prefix_start = iter;

            // Check there's no text after cursor on this line.
            // If iter is already at the line end (pointing at \n),
            // forward_to_line_end() would jump to the NEXT line's end,
            // giving us a false non-empty tail.  Skip the check in that case.
            if (!iter.ends_line ()) {
                Gtk.TextIter line_end = iter;
                line_end.forward_to_line_end ();
                string tail = iter.get_text (line_end).chomp ().chug ();
                if (tail != "") {
                    return false;
                }
            }

            if (!get_prefix_bounds (iter, out prefix_start, out prefix)) {
                return false;
            }

            if (prefix.length < min_len) {
                return false;
            }

            if (prefix != prefix.up ()) {
                return false;
            }

            return true;
        }

        private Gee.HashSet<string> collect_characters () {
            var characters = new Gee.HashSet<string> ();
            if (character_regex == null || buffer == null) {
                return characters;
            }

            Gtk.TextIter start, end;
            buffer.get_bounds (out start, out end);
            string text = buffer.get_text (start, end, true);

            int logged = 0;
            try {
                MatchInfo match_info;
                if (character_regex.match_full (text, text.length, 0, 0, out match_info)) {
                    do {
                        string character = match_info.fetch (1);
                        if (character == null) {
                            continue;
                        }
                        string cleaned = character.chomp ().chug ();
                        if (cleaned == "" || cleaned.has_prefix ("(")) {
                            continue;
                        }
                        characters.add (cleaned);
                        if (logged < 10) {
                            debug ("Fountain completion: found character '%s'", cleaned);
                            logged++;
                        }
                    } while (match_info.next ());
                }
            } catch (Error e) {
                warning ("Could not collect fountain characters: %s", e.message);
            }

            if (characters.size > 10) {
                debug ("Fountain completion: %u characters collected (showing first 10)", characters.size);
            }

            return characters;
        }

        public async virtual GLib.ListModel populate_async (GtkSource.CompletionContext context, GLib.Cancellable? cancellable) throws GLib.Error {
            var proposals = new GLib.ListStore (typeof (FountainCharacterProposal));

            Gtk.TextIter iter;
            if (!get_iter_from_context (context, out iter)) {
                return proposals;
            }
            Gtk.TextIter prefix_start;
            string prefix;
            var activation = context.get_activation ();
            int min_len = (activation == GtkSource.CompletionActivation.USER_REQUESTED) ? 0 : 2;
            if (!is_character_context (iter, out prefix_start, out prefix, min_len)) {
                return proposals;
            }
            debug ("Fountain completion populate: prefix='%s'", prefix);

            var characters = collect_characters ();
            debug ("Fountain completion populate: activation=%d prefix='%s' chars=%u", (int) activation, prefix, characters.size);

            var matched_characters = new Gee.ArrayList<string> ();
            var fuzzy_priorities = new Gee.HashMap<string, uint> ();
            string prefix_casefold = prefix.casefold ();

            foreach (var character in characters) {
                string character_casefold = character.casefold ();

                if (prefix != "" && character_casefold == prefix_casefold) {
                    continue;
                }

                uint fuzzy_priority = 0;
                bool include = false;

                if (prefix == "") {
                    include = true;
                } else if (GtkSource.Completion.fuzzy_match (character, prefix_casefold, out fuzzy_priority)) {
                    include = true;
                }

                if (!include) {
                    continue;
                }

                matched_characters.add (character);
                fuzzy_priorities.set (character, fuzzy_priority);
            }

            matched_characters.sort ((a, b) => {
                uint a_priority = fuzzy_priorities.has_key (a) ? fuzzy_priorities.get (a) : uint.MAX;
                uint b_priority = fuzzy_priorities.has_key (b) ? fuzzy_priorities.get (b) : uint.MAX;

                if (a_priority < b_priority) {
                    return -1;
                }
                if (a_priority > b_priority) {
                    return 1;
                }

                return a.collate (b);
            });

            int proposal_logged = 0;
            foreach (var character in matched_characters) {
                proposals.append (new FountainCharacterProposal (character, prefix));
                if (proposal_logged < 10) {
                    debug ("Fountain completion: proposal '%s'", character);
                    proposal_logged++;
                }
            }

            if (proposals.get_n_items () > 10) {
                debug ("Fountain completion: %u proposals generated (showing first 10)", proposals.get_n_items ());
            }

            return proposals;
        }

        public virtual void refilter (GtkSource.CompletionContext context, GLib.ListModel model) {
        }

        public virtual void activate (GtkSource.CompletionContext context, GtkSource.CompletionProposal proposal) {
            var character_proposal = proposal as FountainCharacterProposal;
            if (character_proposal == null) {
                return;
            }

            Gtk.TextIter iter;
            if (!get_iter_from_context (context, out iter)) {
                return;
            }
            Gtk.TextIter prefix_start;
            string prefix;
            if (!get_prefix_bounds (iter, out prefix_start, out prefix)) {
                return;
            }

            var text_buffer = iter.get_buffer ();
            if (text_buffer == null) {
                return;
            }

            text_buffer.begin_user_action ();
            text_buffer.delete (ref prefix_start, ref iter);
            text_buffer.insert (ref prefix_start, character_proposal.character, character_proposal.character.length);
            text_buffer.end_user_action ();
        }

        public virtual void display (GtkSource.CompletionContext context, GtkSource.CompletionProposal proposal, GtkSource.CompletionCell cell) {
            var character_proposal = proposal as FountainCharacterProposal;
            if (character_proposal == null) {
                return;
            }

            var column = cell.get_column ();
            switch (column) {
                case GtkSource.CompletionColumn.TYPED_TEXT:
                    cell.set_text (character_proposal.character);
                    break;
                case GtkSource.CompletionColumn.COMMENT:
                    cell.set_text (_("Fountain character"));
                    break;
                default:
                    break;
            }
        }
    }

    public class FountainEnrichment : Object {
        private GtkSource.View view;
        private Gtk.TextBuffer buffer;
        private Mutex checking;

        private Gtk.TextTag tag_character;
        private Gtk.TextTag tag_dialogue;
        private Gtk.TextTag tag_scene_heading;
        private Gtk.TextTag tag_parenthetical;

        private Regex scene_heading;
        private Regex character_dialogue;
        private Regex parenthetical_dialogue;
        private string checking_copy;
        private TimedMutex limit_updates;

        private int last_cursor;
        private int copy_offset;

        private FountainCharacterCompletionProvider? character_provider;
        // CompletionWords bootstraps GtkSourceView's internal completion
        // controller.  Without it the interactive trigger loop never starts.
        private GtkSource.CompletionWords? words_provider;
        private Gtk.EventControllerKey? completion_request_key_controller;
        private ulong completion_show_handler_id;
        private ulong completion_hide_handler_id;

        public FountainEnrichment () {
            try {
                scene_heading = new Regex ("\\n(ИНТ|НАТ|инт|нат|INT|EXT|EST|I\\/E|int|ext|est|i\\/e)[\\. \\/].*\\S\\s?\\r?\\n", RegexCompileFlags.BSR_ANYCRLF | RegexCompileFlags.NEWLINE_ANYCRLF | RegexCompileFlags.CASELESS, 0);
                // character_dialogue = new Regex ("(?<=\\n)([ \\t]*[^<>a-z\\s\\/\\n][^<>a-z:!\\?\\n]*[^<>a-z\\(!\\?:,\\n\\.][ \\t]?|[ \\t]*\\(?[^\\n]\\)?[ \\t]*)\\n{1}(?!\\n)(.*?)\\r?\\n{1}", 0, 0);
                character_dialogue = new Regex ("(?<=\\n)([ \\t]*?[^<>\\p{Ll}\\s\\/\\n][^<>\\p{Ll}:!\\?\\n]*[^<>\\p{Ll}\\(!\\?:,\\n\\.][ \\t]?|\\([^\\n]+\\))\\n{1}(?!\\n)(.+?)\\n{1}", RegexCompileFlags.BSR_ANYCRLF | RegexCompileFlags.NEWLINE_ANYCRLF, 0);
                parenthetical_dialogue = new Regex ("(?<=\\n)([ \\t]*?\\([^\\n]+\\))\\n{1}(?!\\n)(.+?)\\n{1}", RegexCompileFlags.BSR_ANYCRLF | RegexCompileFlags.NEWLINE_ANYCRLF, 0);
            } catch (Error e) {
                warning ("Could not build regexes: %s", e.message);
            }
            checking = Mutex ();
            limit_updates = new TimedMutex (250);
            completion_request_key_controller = null;
            completion_show_handler_id = 0;
            completion_hide_handler_id = 0;
            words_provider = null;
            last_cursor = -1;
        }

        public void reset () {
            last_cursor = -1;
            recheck_all ();
        }

        public void recheck_all () {
            if (view == null || buffer == null) {
                return;
            }

            if (!limit_updates.can_do_action ()) {
                return;
            }

            if (!checking.trylock ()) {
                return;
            }

            calculate_margins ();

            // Get current cursor location
            Gtk.TextIter start, end, cursor_iter;
            var cursor = buffer.get_insert ();
            buffer.get_iter_at_mark (out cursor_iter, cursor);
            int current_cursor = cursor_iter.get_offset ();

            if (last_cursor == -1) {
                buffer.get_bounds (out start, out end);
                run_between_start_and_end (start, end);
            } else {
                //
                // Scan where we are
                //
                buffer.get_iter_at_mark (out start, cursor);
                buffer.get_iter_at_mark (out end, cursor);
                get_chunk_of_text_around_cursor (ref start, ref end);
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
                        get_chunk_of_text_around_cursor (ref old_start, ref old_end);
                        if (!old_start.in_range (start, end) || !old_end.in_range (start, end)) {
                            run_between_start_and_end (old_start, old_end);
                        }
                    }
                }
            }

            last_cursor = current_cursor;
            checking.unlock ();
        }

        private void run_between_start_and_end (Gtk.TextIter start, Gtk.TextIter end) {
            copy_offset = start.get_offset ();

            buffer.remove_tag (tag_scene_heading, start, end);
            buffer.remove_tag (tag_character, start, end);
            buffer.remove_tag (tag_parenthetical, start, end);
            buffer.remove_tag (tag_dialogue, start, end);
            checking_copy = buffer.get_text (start, end, true);

            regex_and_tag (scene_heading, tag_scene_heading);
            tag_characters_and_dialogue ();
            checking_copy = "";
        }

        private void tag_characters_and_dialogue () {
            if (character_dialogue == null || tag_character == null || tag_dialogue == null || parenthetical_dialogue == null) {
                return;
            }
            tag_char_diag_helper (character_dialogue);
            tag_char_diag_helper (parenthetical_dialogue);
        }

        private void tag_char_diag_helper (Regex regex) {
            Gtk.TextIter cursor_iter;
            var cursor = buffer.get_insert ();
            buffer.get_iter_at_mark (out cursor_iter, cursor);
            try {
                MatchInfo match_info;
                if (regex.match_full (checking_copy, checking_copy.length, 0, 0, out match_info)) {
                    do {
                        int start_pos, end_pos;
                        bool highlight = false;
                        Gtk.TextIter start, end;

                        // Clear tags from all
                        highlight = match_info.fetch_pos (0, out start_pos, out end_pos);
                        if (highlight) {
                            start_pos = copy_offset + checking_copy.char_count (start_pos);
                            end_pos = copy_offset + checking_copy.char_count (end_pos);
                            buffer.get_iter_at_offset (out start, start_pos);
                            buffer.get_iter_at_offset (out end, end_pos);
                            buffer.remove_tag (tag_character, start, end);
                            buffer.remove_tag (tag_dialogue, start, end);
                            buffer.remove_tag (tag_parenthetical, start, end);
                        }

                        highlight = match_info.fetch_pos (1, out start_pos, out end_pos);
                        string character = match_info.fetch (1);
                        string dialogue = match_info.fetch (2);
                        if (character == null || dialogue == null || dialogue.chomp ().chug () == "" || dialogue.has_prefix ("\t") || dialogue.has_prefix ("    ")) {
                            continue;
                        }
                        start_pos = copy_offset + checking_copy.char_count (start_pos);
                        end_pos = copy_offset + checking_copy.char_count (end_pos);
        
                        if (highlight) {
                            buffer.get_iter_at_offset (out start, start_pos);
                            buffer.get_iter_at_offset (out end, end_pos);
                            if (character.chomp ().chug ().has_prefix ("(")) {
                                buffer.apply_tag (tag_parenthetical, start, end);
                            } else {
                                buffer.apply_tag (tag_character, start, end);
                            }
                        }

                        highlight = match_info.fetch_pos (2, out start_pos, out end_pos);
                        start_pos = copy_offset + checking_copy.char_count (start_pos);
                        end_pos = copy_offset + checking_copy.char_count (end_pos);
                        if (highlight) {
                            buffer.get_iter_at_offset (out start, start_pos);
                            buffer.get_iter_at_offset (out end, end_pos);
                            buffer.apply_tag (tag_dialogue, start, end);
                        }
                    } while (match_info.next ());
                }
            } catch (Error e) {
                warning ("Could not tag characters and dialogues: %s", e.message);
            }
        }

        private void regex_and_tag (Regex regex, Gtk.TextTag tag) {
            if (regex == null || tag == null) {
                return;
            }
            try {
                MatchInfo match_info;
                if (regex.match_full (checking_copy, checking_copy.length, 0, 0, out match_info)) {
                    highlight_results (match_info, tag);
                }
            } catch (Error e) {
                warning ("Could not apply tags: %s", e.message);
            }
        }

        private void highlight_results (MatchInfo match_info, Gtk.TextTag marker) throws Error {
            do {
                int start_pos, end_pos;
                bool highlight = false;
                highlight = match_info.fetch_pos (0, out start_pos, out end_pos);
                string word = match_info.fetch (0);
                start_pos = copy_offset + checking_copy.char_count (start_pos);
                end_pos = copy_offset + checking_copy.char_count (end_pos);

                if (word != null && highlight) {
                    // debug ("%s: %s", marker.name, word);
                    Gtk.TextIter start, end;
                    buffer.get_iter_at_offset (out start, start_pos);
                    buffer.get_iter_at_offset (out end, end_pos);
                    buffer.apply_tag (marker, start, end);
                }
            } while (match_info.next ());
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

            // Bold Scene Headings
            tag_scene_heading = buffer.create_tag ("scene_heading");
            tag_scene_heading.weight = Pango.Weight.BOLD;
            tag_scene_heading.weight_set = true;

            // Character
            tag_character = buffer.create_tag ("fou_char");
            tag_character.accumulative_margin = true;
            tag_character.left_margin_set = true;
            tag_parenthetical = buffer.create_tag ("fou_paren");
            tag_parenthetical.accumulative_margin = true;
            tag_parenthetical.left_margin_set = true;
            // Dialogue
            tag_dialogue = buffer.create_tag ("fou_diag");
            tag_dialogue.accumulative_margin = true;
            tag_dialogue.left_margin_set = true;
            tag_dialogue.right_margin_set = true;
            last_cursor = -1;

            calculate_margins ();
            settings_changed ();
            settings.changed.connect (settings_changed);

            completion_request_key_controller = new Gtk.EventControllerKey ();
            completion_request_key_controller.key_pressed.connect ((keyval, _keycode, state) => {
                if ((state & Gdk.ModifierType.CONTROL_MASK) == 0) {
                    return false;
                }

                if (keyval != Gdk.Key.space) {
                    return false;
                }

                var completion = view.get_completion ();
                if (completion == null) {
                    return false;
                }

                completion.show ();
                return true;
            });
            view.add_controller (completion_request_key_controller);

            return true;
        }

        private void settings_changed () {
            update_character_provider ();
        }

        private void update_character_provider () {
            if (view == null || buffer == null) {
                return;
            }

            debug ("Fountain completion: updating provider");

            var completion = view.get_completion ();
            if (completion == null) {
                debug ("Fountain completion: view.get_completion() returned null");
                return;
            }

            completion.select_on_show = true;
            completion.show_icons = false;

            if (completion_show_handler_id == 0) {
                completion_show_handler_id = completion.show.connect (() => {
                    if (view != null) {
                        view.set_data<bool> ("completion-active", true);
                    }
                });
            }

            if (completion_hide_handler_id == 0) {
                completion_hide_handler_id = completion.hide.connect (() => {
                    if (view != null) {
                        view.set_data<bool> ("completion-active", false);
                    }
                });
            }

            if (character_provider != null) {
                completion.remove_provider (character_provider);
                character_provider = null;
            }

            // CompletionWords tells GtkSourceView to monitor buffer changes
            // so the interactive completion loop actually kicks off.
            if (words_provider == null) {
                words_provider = new GtkSource.CompletionWords ("Words");
                words_provider.register (buffer);
                completion.add_provider (words_provider);
            }

            character_provider = new FountainCharacterCompletionProvider (buffer);
            completion.add_provider (character_provider);
            debug ("Fountain completion: providers registered");
        }

        private void calculate_margins () {
            var settings = AppSettings.get_default ();
            int f_w = (int)(settings.get_css_font_size () * ((settings.fullscreen ? 1.4 : 1)));

            int hashtag_w = f_w;
            int space_w = f_w;
            int avg_w = f_w;

            if (view.get_realized ()) {
                var font_desc = Pango.FontDescription.from_string (settings.font_family);
                font_desc.set_size ((int)(f_w * Pango.SCALE * Pango.Scale.LARGE));
                var font_context = view.get_pango_context ();
                var font_layout = new Pango.Layout (font_context);
                font_layout.set_font_description (font_desc);
                font_layout.set_text ("#", 1);
                Pango.Rectangle ink, logical;
                font_layout.get_pixel_extents (out ink, out logical);
                // debug ("# Ink: %d, Logical: %d", ink.width, logical.width);
                hashtag_w = int.max (ink.width, logical.width);
                font_layout.set_text (" ", 1);
                font_layout.get_pixel_extents (out ink, out logical);
                font_layout.dispose ();
                // debug ("  Ink: %d, Logical: %d", ink.width, logical.width);
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
                // debug ("%s Hashtag: %d, Space: %d, AvgChar: %d", font_desc.get_family (), hashtag_w, space_w, avg_w);
            }

            if (ThiefApp.get_instance ().show_touch_friendly) {
                // Character
                tag_character.left_margin = (avg_w * 8);
                tag_parenthetical.left_margin = (avg_w * 6);
                // Dialogue
                tag_dialogue.left_margin = (avg_w * 4);
                tag_dialogue.right_margin = 0;
            } else {
                // Character
                tag_character.left_margin = (avg_w * 14);
                tag_parenthetical.left_margin = (avg_w * 10);
                // Dialogue
                tag_dialogue.left_margin = (avg_w * 6);
                tag_dialogue.right_margin = (avg_w * 6);
            }
        }

        public void detach () {
            var settings = AppSettings.get_default ();
            Gtk.TextIter start, end;
            buffer.get_bounds (out start, out end);

            if (view != null) {
                view.set_data<bool> ("completion-active", false);
            }

            if (view != null) {
                var completion = view.get_completion ();
                if (completion != null) {
                    if (completion_show_handler_id != 0) {
                        completion.disconnect (completion_show_handler_id);
                        completion_show_handler_id = 0;
                    }
                    if (completion_hide_handler_id != 0) {
                        completion.disconnect (completion_hide_handler_id);
                        completion_hide_handler_id = 0;
                    }
                    if (character_provider != null) {
                        completion.remove_provider (character_provider);
                    }
                    if (words_provider != null) {
                        words_provider.unregister (buffer);
                        completion.remove_provider (words_provider);
                    }
                }
                character_provider = null;
                words_provider = null;
            }

            buffer.remove_tag (tag_scene_heading, start, end);
            buffer.remove_tag (tag_character, start, end);
            buffer.remove_tag (tag_parenthetical, start, end);
            buffer.remove_tag (tag_dialogue, start, end);
            buffer.tag_table.remove (tag_scene_heading);
            buffer.tag_table.remove (tag_character);
            buffer.tag_table.remove (tag_parenthetical);
            buffer.tag_table.remove (tag_dialogue);

            settings.changed.disconnect (settings_changed);

            if (completion_request_key_controller != null && view != null) {
                view.remove_controller (completion_request_key_controller);
                completion_request_key_controller = null;
            }

            tag_scene_heading = null;
            tag_character = null;
            tag_parenthetical = null;
            tag_dialogue = null;

            view = null;
            buffer = null;
            last_cursor = -1;
        }
    }
}