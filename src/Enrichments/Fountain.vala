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

namespace ThiefMD.Enrichments {
    public class FountainCharacterSuggestor : Gtk.SourceCompletionProvider, Object {
        public Gee.HashSet<string> characters;

        public FountainCharacterSuggestor () {
            characters = new Gee.HashSet<string> ();
        }

        public override string get_name () {
            return _("Characters");
        }

        public override bool match (Gtk.SourceCompletionContext context) {
            Gtk.TextIter? start = null, iter = null;
            if (context.get_iter (out iter)) {
                if (iter.ends_line () && context.get_iter (out start)) {
                    start.backward_word_start ();
                    if ((iter.get_offset () - start.get_offset ()) >= 2) {
                        string check = start.get_text (iter);
                        return check == check.up ();
                    }
                }
            }

            return false;
        }

        public override void populate (Gtk.SourceCompletionContext context) {
            List<Gtk.SourceCompletionItem> completions = new List<Gtk.SourceCompletionItem> ();
            Gtk.TextIter? start = null, iter = null;
            if (context.get_iter (out iter)) {
                if (iter.ends_line () && context.get_iter (out start)) {
                    start.backward_word_start ();
                    if ((iter.get_offset () - start.get_offset ()) >= 2) {
                        string check = start.get_text (iter);
                        foreach (var character in characters) {
                            if (character.has_prefix (check) && character != check) {
                                var com_item = new Gtk.SourceCompletionItem ();
                                com_item.text = character;
                                com_item.label = character;
                                com_item.markup = character;
                                completions.append (com_item);
                            }
                        }
                    }
                }
            }
            context.add_proposals (this, completions, true);
        }

        public override bool activate_proposal (Gtk.SourceCompletionProposal proposal, Gtk.TextIter iter) {
            return false;
        }
    }

    public class FountainEnrichment : Object {
        private FountainCharacterSuggestor character_suggester;
        private Gtk.SourceCompletionWords source_completion;
        private Gtk.SourceView view;
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

        public FountainEnrichment () {
            try {
                scene_heading = new Regex ("\\n(ИНТ|НАТ|инт|нат|INT|EXT|EST|I\\/E|int|ext|est|i\\/e)[\\. \\/].*\\S\\s?\\r?\\n", RegexCompileFlags.BSR_ANYCRLF | RegexCompileFlags.NEWLINE_ANYCRLF | RegexCompileFlags.CASELESS, 0);
                // character_dialogue = new Regex ("(?<=\\n)([ \\t]*[^<>a-z\\s\\/\\n][^<>a-z:!\\?\\n]*[^<>a-z\\(!\\?:,\\n\\.][ \\t]?|[ \\t]*\\(?[^\\n]\\)?[ \\t]*)\\n{1}(?!\\n)(.*?)\\r?\\n{1}", 0, 0);
                character_dialogue = new Regex ("(?<=\\n)([ \\t]*?[^<>a-z\\s\\/\\n][^<>a-z:!\\?\\n]*[^<>a-z\\(!\\?:,\\n\\.][ \\t]?|\\([^\\n]+\\))\\n{1}(?!\\n)(.+?)\\n{1}", RegexCompileFlags.BSR_ANYCRLF | RegexCompileFlags.NEWLINE_ANYCRLF, 0);
                parenthetical_dialogue = new Regex ("(?<=\\n)([ \\t]*?\\([^\\n]+\\))\\n{1}(?!\\n)(.+?)\\n{1}", RegexCompileFlags.BSR_ANYCRLF | RegexCompileFlags.NEWLINE_ANYCRLF, 0);
            } catch (Error e) {
                warning ("Could not build regexes: %s", e.message);
            }
            character_suggester = new FountainCharacterSuggestor ();
            checking = Mutex ();
            limit_updates = new TimedMutex (250);
            last_cursor = -1;
            source_completion = null;
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
                                start.backward_word_start ();
                                end.forward_word_end ();
                                if (!character_suggester.characters.contains (character) && !cursor_iter.in_range (start, end)) {
                                    bool partial_character_name = false;
                                    if (character.has_suffix ("^")) {
                                        character = character.substring (0, character.length - 1);
                                    }
                                    foreach (var person in character_suggester.characters) {
                                        if (person.contains (character)) {
                                            partial_character_name = true;
                                        }
                                    }
                                    if (!partial_character_name) {
                                        character_suggester.characters.add (character);
                                    }
                                }
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
                    debug ("%s: %s", marker.name, word);
                    Gtk.TextIter start, end;
                    buffer.get_iter_at_offset (out start, start_pos);
                    buffer.get_iter_at_offset (out end, end_pos);
                    buffer.apply_tag (marker, start, end);
                }
            } while (match_info.next ());
        }

        public bool attach (Gtk.SourceView textview) {
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

            return true;
        }

        private void settings_changed () {
            var settings = AppSettings.get_default ();
            if (settings.experimental && source_completion == null) {
                try {
                    var completion = view.get_completion ();
                    completion.add_provider (character_suggester);
                    source_completion = new Gtk.SourceCompletionWords ("Character Suggestor", null);
                    source_completion.register (buffer);
                } catch (Error e) {
                    warning ("Cannot add autocompletion: %s", e.message);
                }
            } else if (!settings.experimental && source_completion != null) {
                try {
                    var completion = view.get_completion ();
                    source_completion.unregister (buffer);
                    completion.remove_provider (character_suggester);
                } catch (Error e) {
                    warning ("Could not add autocompletion: %s", e.message);
                }
            }
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
            }

            if (ThiefApp.get_instance ().main_content.folded) {
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

            buffer.remove_tag (tag_scene_heading, start, end);
            buffer.remove_tag (tag_character, start, end);
            buffer.remove_tag (tag_parenthetical, start, end);
            buffer.remove_tag (tag_dialogue, start, end);
            buffer.tag_table.remove (tag_scene_heading);
            buffer.tag_table.remove (tag_character);
            buffer.tag_table.remove (tag_parenthetical);
            buffer.tag_table.remove (tag_dialogue);

            if (source_completion != null) {
                source_completion.unregister (buffer);
            }

            settings.changed.disconnect (settings_changed);

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