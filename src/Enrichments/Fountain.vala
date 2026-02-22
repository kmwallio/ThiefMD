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
                character_regex = new Regex ("(?<=\\n)([ \\t]*?[^<>a-z\\s\\/\\n][^<>a-z:!\\?\\n]*[^<>a-z\\(!\\?:,\\n\\.][ \\t]?|\\([^\\n]+\\))\\n{1}(?!\\n)(.+?)\\n{1}", RegexCompileFlags.BSR_ANYCRLF | RegexCompileFlags.NEWLINE_ANYCRLF, 0);
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
            debug ("Fountain completion: is_trigger called");
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

            Gtk.TextIter line_end = iter;
            line_end.forward_to_line_end ();
            string tail = iter.get_text (line_end).chomp ().chug ();
            if (tail != "") {
                return false;
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
                debug ("Fountain completion populate: not in character context");
                return proposals;
            }

            var characters = collect_characters ();
            debug ("Fountain completion populate: activation=%d prefix='%s' chars=%u", (int) activation, prefix, characters.size);

            int proposal_logged = 0;
            foreach (var character in characters) {
                if (prefix == "" || (character.down ().has_prefix (prefix.down ()) && character != prefix)) {
                    proposals.append (new FountainCharacterProposal (character, prefix));
                    if (proposal_logged < 10) {
                        debug ("Fountain completion: proposal '%s'", character);
                        proposal_logged++;
                    }
                }
            }

            if (proposals.get_n_items () > 10) {
                debug ("Fountain completion: %u proposals generated (showing first 10)", proposals.get_n_items ());
            }

            context.set_proposals_for_provider (this, proposals);

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
        private Gtk.TextTag tag_dialogue_continuation;
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
        private Gtk.EventControllerKey? completion_key_controller;
        private TimedMutex completion_limit;
        private Gtk.Popover? completion_popover;
        private Gtk.ListBox? completion_listbox;

        public FountainEnrichment () {
            try {
                scene_heading = new Regex ("\\n(ИНТ|НАТ|инт|нат|INT|EXT|EST|I\\/E|int|ext|est|i\\/e)[\\. \\/].*\\S\\s?\\r?\\n", RegexCompileFlags.BSR_ANYCRLF | RegexCompileFlags.NEWLINE_ANYCRLF | RegexCompileFlags.CASELESS, 0);
                // character_dialogue = new Regex ("(?<=\\n)([ \\t]*[^<>a-z\\s\\/\\n][^<>a-z:!\\?\\n]*[^<>a-z\\(!\\?:,\\n\\.][ \\t]?|[ \\t]*\\(?[^\\n]\\)?[ \\t]*)\\n{1}(?!\\n)(.*?)\\r?\\n{1}", 0, 0);
                // Modified to capture multiline dialogue: matches character name followed by dialogue lines (stops at blank line)
                // Pattern captures one or more non-blank lines after character, stopping before a blank line or EOF
                character_dialogue = new Regex ("(?<=\\n)([ \\t]*?[^<>a-z\\s\\/\\n][^<>a-z:!\\?\\n]*[^<>a-z\\(!\\?:,\\n\\.][ \\t]?|\\([^\\n]+\\))\\n{1}(?!\\n)((?:[^\\n]+\\n(?!\\n))*[^\\n]+)\\n?", RegexCompileFlags.BSR_ANYCRLF | RegexCompileFlags.NEWLINE_ANYCRLF, 0);
                parenthetical_dialogue = new Regex ("(?<=\\n)([ \\t]*?\\([^\\n]+\\))\\n{1}(?!\\n)(.+?)\\n{1}", RegexCompileFlags.BSR_ANYCRLF | RegexCompileFlags.NEWLINE_ANYCRLF, 0);
            } catch (Error e) {
                warning ("Could not build regexes: %s", e.message);
            }
            checking = Mutex ();
            limit_updates = new TimedMutex (250);
            completion_limit = new TimedMutex (150);
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
            buffer.remove_tag (tag_dialogue_continuation, start, end);
            checking_copy = buffer.get_text (start, end, true);

            regex_and_tag (scene_heading, tag_scene_heading);
            tag_characters_and_dialogue ();
            checking_copy = "";
        }

        private void tag_characters_and_dialogue () {
            if (character_dialogue == null || tag_character == null || tag_dialogue == null || tag_dialogue_continuation == null || parenthetical_dialogue == null) {
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
                            buffer.remove_tag (tag_dialogue_continuation, start, end);
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
                            // Split dialogue into lines to handle multiline dialogue
                            string[] dialogue_lines = dialogue.split ("\n");
                            int current_offset = start_pos;
                            bool first_line_tagged = false;

                            for (int i = 0; i < dialogue_lines.length; i++) {
                                string line = dialogue_lines[i];
                                if (line.chomp ().chug () == "") {
                                    // Skip empty lines but account for their length
                                    current_offset += line.length + 1; // +1 for newline
                                    continue;
                                }

                                int line_start = current_offset;
                                int line_end = current_offset + line.length;

                                buffer.get_iter_at_offset (out start, line_start);
                                buffer.get_iter_at_offset (out end, line_end);

                                // First non-empty line gets tag_dialogue, subsequent lines get tag_dialogue_continuation
                                if (!first_line_tagged) {
                                    buffer.apply_tag (tag_dialogue, start, end);
                                    first_line_tagged = true;
                                } else {
                                    buffer.apply_tag (tag_dialogue_continuation, start, end);
                                }

                                current_offset = line_end + 1; // +1 for newline
                            }
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
            // Dialogue continuation (for multiline dialogue)
            tag_dialogue_continuation = buffer.create_tag ("fou_diag_cont");
            tag_dialogue_continuation.accumulative_margin = true;
            tag_dialogue_continuation.left_margin_set = true;
            tag_dialogue_continuation.right_margin_set = true;
            last_cursor = -1;

            calculate_margins ();
            settings_changed ();
            settings.changed.connect (settings_changed);

            completion_key_controller = new Gtk.EventControllerKey ();
            completion_key_controller.key_released.connect ((keyval, _keycode, _state) => {
                // If popup is visible, update it as they type
                if (completion_popover != null && completion_popover.get_visible ()) {
                    uint32 unicode_char = Gdk.keyval_to_unicode (keyval);
                    // Continue updating for uppercase letters, backspace, delete
                    if ((unicode_char >= 'A' && unicode_char <= 'Z') || 
                        keyval == Gdk.Key.BackSpace || keyval == Gdk.Key.Delete) {
                        if (completion_limit.can_do_action ()) {
                            maybe_update_character_completion ();
                        }
                    }
                } else if (completion_limit.can_do_action ()) {
                    // Show popup if not visible
                    maybe_show_character_completion (keyval);
                }
            });
            completion_key_controller.key_pressed.connect ((keyval, _keycode, _state) => {
                // Dismiss popup if user types something that would break character context
                if (completion_popover != null && completion_popover.get_visible ()) {
                    // Check if the keypress would invalidate the character context
                    uint32 unicode_char = Gdk.keyval_to_unicode (keyval);
                    if (unicode_char != 0) {
                        // Lowercase letters break character names (which must be uppercase)
                        if (unicode_char >= 'a' && unicode_char <= 'z') {
                            debug ("Fountain completion: dismissing popup - lowercase typed");
                            completion_popover.popdown ();
                            view.set_data<bool> ("completion-active", false);
                            return false;
                        }
                        // Newline dismisses the popup
                        if (unicode_char == '\n' || unicode_char == '\r') {
                            debug ("Fountain completion: dismissing popup - newline typed");
                            completion_popover.popdown ();
                            view.set_data<bool> ("completion-active", false);
                            return false;
                        }
                    }
                    // Navigation and special keys dismiss
                    if (keyval == Gdk.Key.Escape || keyval == Gdk.Key.Left || 
                        keyval == Gdk.Key.Right || keyval == Gdk.Key.Up || 
                        keyval == Gdk.Key.Down || keyval == Gdk.Key.Home || 
                        keyval == Gdk.Key.End || keyval == Gdk.Key.Page_Up || 
                        keyval == Gdk.Key.Page_Down) {
                        debug ("Fountain completion: dismissing popup - navigation key pressed");
                        completion_popover.popdown ();
                        view.set_data<bool> ("completion-active", false);
                        return keyval == Gdk.Key.Escape;
                    }
                }
                return false;
            });
            view.add_controller (completion_key_controller);

            return true;
        }

        private void maybe_show_character_completion (uint keyval) {
            if (view == null || buffer == null) {
                return;
            }

            update_character_provider ();
            debug_log_character_matches ();

            Gtk.TextIter iter;
            var cursor = buffer.get_insert ();
            buffer.get_iter_at_mark (out iter, cursor);

            Gtk.TextIter prefix_start;
            string prefix;
            if (!is_character_context (iter, out prefix_start, out prefix, 2)) {
                debug ("Fountain completion: not in character context");
                return;
            }

            debug ("Fountain completion: showing popup for prefix '%s'", prefix);
            // Disable typewriter scrolling immediately to prevent scrolling before popup appears
            view.set_data<bool> ("completion-active", true);
            show_custom_completion_popup (prefix, prefix_start);
        }

        private void maybe_update_character_completion () {
            if (view == null || buffer == null) {
                return;
            }

            Gtk.TextIter iter;
            var cursor = buffer.get_insert ();
            buffer.get_iter_at_mark (out iter, cursor);

            Gtk.TextIter prefix_start;
            string prefix;
            if (!is_character_context (iter, out prefix_start, out prefix, 2)) {
                debug ("Fountain completion: no longer in character context, dismissing");
                if (completion_popover != null) {
                    completion_popover.popdown ();
                }
                view.set_data<bool> ("completion-active", false);
                return;
            }

            debug ("Fountain completion: updating popup for prefix '%s'", prefix);
            // Close existing popup and show updated one
            if (completion_popover != null) {
                completion_popover.popdown ();
            }
            show_custom_completion_popup (prefix, prefix_start);
        }

        private void show_custom_completion_popup (string prefix, Gtk.TextIter prefix_start) {
            if (view == null || buffer == null) {
                return;
            }

            var characters = new Gee.ArrayList<string> ();
            Gtk.TextIter start, end;
            buffer.get_bounds (out start, out end);
            string text = buffer.get_text (start, end, true);

            try {
                var regex = new Regex ("(?<=\\n)([ \\t]*?[^<>a-z\\s\\/\\n][^<>a-z:!\\?\\n]*[^<>a-z\\(!\\?:,\\n\\.][ \\t]?|\\([^\\n]+\\))\\n{1}(?!\\n)(.+?)\\n{1}", RegexCompileFlags.BSR_ANYCRLF | RegexCompileFlags.NEWLINE_ANYCRLF, 0);
                MatchInfo match_info;
                if (regex.match_full (text, text.length, 0, 0, out match_info)) {
                    var seen = new Gee.HashSet<string> ();
                    do {
                        string character = match_info.fetch (1);
                        if (character == null) {
                            continue;
                        }
                        string cleaned = character.chomp ().chug ();
                        if (cleaned == "" || cleaned.has_prefix ("(")) {
                            continue;
                        }
                        if (prefix == "" || (cleaned.down ().has_prefix (prefix.down ()) && cleaned != prefix)) {
                            if (!seen.contains (cleaned)) {
                                characters.add (cleaned);
                                seen.add (cleaned);
                            }
                        }
                    } while (match_info.next ());
                }
            } catch (Error e) {
                warning ("Fountain completion popup: regex failed: %s", e.message);
            }

            if (characters.size == 0) {
                debug ("Fountain completion: no matches for prefix '%s'", prefix);
                view.set_data<bool> ("completion-active", false);
                return;
            }

            // Delay popup display to allow typewriter scrolling to complete first
            GLib.Idle.add (() => {
                if (view == null || buffer == null) {
                    return false;
                }

                // Verify we're still in character context after scrolling
                Gtk.TextIter cursor_iter;
                var cursor = buffer.get_insert ();
                buffer.get_iter_at_mark (out cursor_iter, cursor);
                Gtk.TextIter check_prefix_start;
                string check_prefix;
                if (!is_character_context (cursor_iter, out check_prefix_start, out check_prefix, 2)) {
                    view.set_data<bool> ("completion-active", false);
                    return false;
                }

                if (check_prefix != prefix) {
                    debug ("Fountain completion: prefix changed from '%s' to '%s', not showing popup", prefix, check_prefix);
                    view.set_data<bool> ("completion-active", false);
                    return false;
                }

                if (completion_popover != null) {
                    completion_popover.unparent ();
                    completion_popover = null;
                }

                completion_listbox = new Gtk.ListBox ();
                completion_listbox.selection_mode = Gtk.SelectionMode.SINGLE;
                completion_listbox.activate_on_single_click = true;

                foreach (var character in characters) {
                    var label = new Gtk.Label (character);
                    label.xalign = 0;
                    label.margin_start = 8;
                    label.margin_end = 8;
                    label.margin_top = 4;
                    label.margin_bottom = 4;
                    completion_listbox.append (label);
                }

                completion_listbox.row_activated.connect ((row) => {
                    var label = row.get_child () as Gtk.Label;
                    if (label != null) {
                        Gtk.TextIter current_cursor_iter;
                        var current_cursor = buffer.get_insert ();
                        buffer.get_iter_at_mark (out current_cursor_iter, current_cursor);
                        Gtk.TextIter start_iter = check_prefix_start;

                        buffer.begin_user_action ();
                        buffer.delete (ref start_iter, ref current_cursor_iter);
                        buffer.insert (ref start_iter, label.get_text (), label.get_text ().length);
                        buffer.place_cursor (start_iter);
                        buffer.end_user_action ();

                        // Ensure cursor is visible before re-enabling typewriter scrolling
                        view.scroll_to_mark (buffer.get_insert (), 0.0, false, 0.0, 0.0);
                    }
                    
                    // Close popover first, then re-enable typewriter scrolling after a brief delay
                    if (completion_popover != null) {
                        completion_popover.popdown ();
                    }
                    
                    GLib.Idle.add (() => {
                        view.set_data<bool> ("completion-active", false);
                        return false;
                    });
                });

                var scrolled = new Gtk.ScrolledWindow ();
                scrolled.set_policy (Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC);
                scrolled.set_max_content_height (200);
                scrolled.set_child (completion_listbox);

                completion_popover = new Gtk.Popover ();
                completion_popover.set_parent (view);
                completion_popover.set_child (scrolled);
                completion_popover.set_autohide (true);

                // Re-enable typewriter scrolling when popup is closed
                completion_popover.closed.connect (() => {
                    view.set_data<bool> ("completion-active", false);
                    debug ("Fountain completion: popup closed, typewriter scrolling re-enabled");
                });

                Gdk.Rectangle rect;
                view.get_iter_location (check_prefix_start, out rect);
                int window_x, window_y;
                view.buffer_to_window_coords (Gtk.TextWindowType.WIDGET, rect.x, rect.y, out window_x, out window_y);
                rect.x = window_x;
                rect.y = window_y;
                completion_popover.set_pointing_to (rect);

                completion_popover.popup ();
                debug ("Fountain completion: custom popup shown with %u items, typewriter scrolling disabled", characters.size);

                return false;
            }, GLib.Priority.LOW);
        }

        private void debug_log_character_matches () {
            if (buffer == null) {
                return;
            }

            Gtk.TextIter start, end;
            buffer.get_bounds (out start, out end);
            string text = buffer.get_text (start, end, true);

            try {
                var regex = new Regex ("(?<=\\n)([ \\t]*?[^<>a-z\\s\\/\\n][^<>a-z:!\\?\\n]*[^<>a-z\\(!\\?:,\\n\\.][ \\t]?|\\([^\\n]+\\))\\n{1}(?!\\n)(.+?)\\n{1}", RegexCompileFlags.BSR_ANYCRLF | RegexCompileFlags.NEWLINE_ANYCRLF, 0);
                MatchInfo match_info;
                int logged = 0;
                if (regex.match_full (text, text.length, 0, 0, out match_info)) {
                    do {
                        string character = match_info.fetch (1);
                        if (character == null) {
                            continue;
                        }
                        string cleaned = character.chomp ().chug ();
                        if (cleaned == "" || cleaned.has_prefix ("(")) {
                            continue;
                        }
                        if (logged < 10) {
                            debug ("Fountain completion probe: '%s'", cleaned);
                            logged++;
                        }
                    } while (match_info.next ());
                }
                if (logged == 0) {
                    debug ("Fountain completion probe: no characters matched");
                }
            } catch (Error e) {
                warning ("Fountain completion probe failed: %s", e.message);
            }
        }

        private bool is_character_context (Gtk.TextIter iter, out Gtk.TextIter prefix_start, out string prefix, int min_len = 2) {
            prefix = "";
            prefix_start = iter;

            Gtk.TextIter line_end = iter;
            line_end.forward_to_line_end ();
            string tail = iter.get_text (line_end).chomp ().chug ();
            if (tail != "") {
                return false;
            }

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

            if (prefix.length < min_len) {
                return false;
            }

            if (prefix != prefix.up ()) {
                return false;
            }

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

            completion.unblock_interactive ();
            completion.select_on_show = true;
            completion.show_icons = false;

            if (character_provider != null) {
                completion.remove_provider (character_provider);
                character_provider = null;
            }

            character_provider = new FountainCharacterCompletionProvider (buffer);
            completion.add_provider (character_provider);
            debug ("Fountain completion: provider added");
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
                // Dialogue continuation - indented more for visual clarity
                tag_dialogue_continuation.left_margin = (avg_w * 6);
                tag_dialogue_continuation.right_margin = 0;
            } else {
                // Character
                tag_character.left_margin = (avg_w * 14);
                tag_parenthetical.left_margin = (avg_w * 10);
                // Dialogue
                tag_dialogue.left_margin = (avg_w * 6);
                tag_dialogue.right_margin = (avg_w * 6);
                // Dialogue continuation - indented more for visual clarity
                tag_dialogue_continuation.left_margin = (avg_w * 8);
                tag_dialogue_continuation.right_margin = (avg_w * 6);
            }
        }

        public void detach () {
            var settings = AppSettings.get_default ();
            Gtk.TextIter start, end;
            buffer.get_bounds (out start, out end);

            if (character_provider != null && view != null) {
                var completion = view.get_completion ();
                if (completion != null) {
                    completion.remove_provider (character_provider);
                }
                character_provider = null;
            }

            if (completion_key_controller != null && view != null) {
                view.remove_controller (completion_key_controller);
                completion_key_controller = null;
            }

            buffer.remove_tag (tag_scene_heading, start, end);
            buffer.remove_tag (tag_character, start, end);
            buffer.remove_tag (tag_parenthetical, start, end);
            buffer.remove_tag (tag_dialogue, start, end);
            buffer.remove_tag (tag_dialogue_continuation, start, end);
            buffer.tag_table.remove (tag_scene_heading);
            buffer.tag_table.remove (tag_character);
            buffer.tag_table.remove (tag_parenthetical);
            buffer.tag_table.remove (tag_dialogue);
            buffer.tag_table.remove (tag_dialogue_continuation);

            settings.changed.disconnect (settings_changed);

            tag_scene_heading = null;
            tag_character = null;
            tag_parenthetical = null;
            tag_dialogue = null;
            tag_dialogue_continuation = null;

            view = null;
            buffer = null;
            last_cursor = -1;
        }
    }
}