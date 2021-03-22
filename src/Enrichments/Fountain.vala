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
    public class FountainEnrichment {
        private Gtk.TextView view;
        private Gtk.TextBuffer buffer;
        private Mutex checking;

        private Gtk.TextTag tag_character;
        private Gtk.TextTag tag_dialogue;
        private Gtk.TextTag tag_scene_heading;
        private Gtk.TextTag tag_parenthetical;
        private Gtk.TextTag tag_lyrics;
        private Gtk.TextTag tag_transition;
        private Gtk.TextTag tag_very_hard_sentences;

        private Regex scene_heading;
        private Regex character_dialogue;
        private Regex parenthetical_dialogue;
        private string checking_copy;

        public FountainEnrichment () {
            try {
                scene_heading = new Regex ("\\n(ИНТ|НАТ|инт|нат|INT|EXT|EST|I\\/E|int|ext|est|i\\/e)[\\. \\/].*\\S\\s?\\r?\\n", RegexCompileFlags.BSR_ANYCRLF | RegexCompileFlags.NEWLINE_ANYCRLF | RegexCompileFlags.CASELESS, 0);
                // character_dialogue = new Regex ("(?<=\\n)([ \\t]*[^<>a-z\\s\\/\\n][^<>a-z:!\\?\\n]*[^<>a-z\\(!\\?:,\\n\\.][ \\t]?|[ \\t]*\\(?[^\\n]\\)?[ \\t]*)\\n{1}(?!\\n)(.*?)\\r?\\n{1}", 0, 0);
                character_dialogue = new Regex ("(?<=\\n)([ \\t]*?[^<>a-z\\s\\/\\n][^<>a-z:!\\?\\n]*[^<>a-z\\(!\\?:,\\n\\.][ \\t]?|\\([^\\n]+\\))\\n{1}(?!\\n)(.+?)\\n{1}", RegexCompileFlags.BSR_ANYCRLF | RegexCompileFlags.NEWLINE_ANYCRLF, 0);
                parenthetical_dialogue = new Regex ("(?<=\\n)([ \\t]*?\\([^\\n]+\\))\\n{1}(?!\\n)(.+?)\\n{1}", RegexCompileFlags.BSR_ANYCRLF | RegexCompileFlags.NEWLINE_ANYCRLF, 0);
            } catch (Error e) {
                warning ("Could not build regexes: %s", e.message);
            }
            checking = Mutex ();
        }

        public void recheck_all () {
            if (view == null || buffer == null) {
                return;
            }

            if (!checking.trylock ()) {
                return;
            }

            // Remove any previous tags
            Gtk.TextIter start, end;
            buffer.get_bounds (out start, out end);
            buffer.remove_tag (tag_scene_heading, start, end);
            buffer.remove_tag (tag_character, start, end);
            checking_copy = buffer.get_text (start, end, true);

            regex_and_tag (scene_heading, tag_scene_heading);
            tag_characters_and_dialogue ();

            checking_copy = "";
            checking.unlock ();
        }

        private void tag_characters_and_dialogue () {
            if (character_dialogue == null || tag_character == null || tag_dialogue == null || parenthetical_dialogue == null) {
                return;
            }
            tag_char_diag_helper (character_dialogue);
            tag_char_diag_helper (parenthetical_dialogue);
        }

        private void tag_char_diag_helper (Regex regex) {
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
                            start_pos = checking_copy.char_count (start_pos);
                            end_pos = checking_copy.char_count (end_pos);
                            buffer.get_iter_at_offset (out start, start_pos);
                            buffer.get_iter_at_offset (out end, end_pos);
                            buffer.remove_tag (tag_character, start, end);
                            buffer.remove_tag (tag_dialogue, start, end);
                            buffer.remove_tag (tag_parenthetical, start, end);
                        }

                        highlight = match_info.fetch_pos (1, out start_pos, out end_pos);
                        string character = match_info.fetch (1);
                        string dialogue = match_info.fetch (2);
                        if (character == null || dialogue == null || dialogue.chomp ().chug () == "") {
                            continue;
                        }
                        start_pos = checking_copy.char_count (start_pos);
                        end_pos = checking_copy.char_count (end_pos);
        
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
                        start_pos = checking_copy.char_count (start_pos);
                        end_pos = checking_copy.char_count (end_pos);
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
                start_pos = checking_copy.char_count (start_pos);
                end_pos = checking_copy.char_count (end_pos);

                if (word != null && highlight) {
                    debug ("%s: %s", marker.name, word);
                    Gtk.TextIter start, end;
                    buffer.get_iter_at_offset (out start, start_pos);
                    buffer.get_iter_at_offset (out end, end_pos);
                    buffer.apply_tag (marker, start, end);
                }
            } while (match_info.next ());
        }

        public bool attach (Gtk.TextView textview) {
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

            // Margin things
            int f_w = (int)(settings.get_css_font_size () * ((settings.fullscreen ? 1.4 : 1)));

            // Bold Scene Headings
            tag_scene_heading = buffer.create_tag ("scene_heading");
            tag_scene_heading.weight = Pango.Weight.BOLD;
            tag_scene_heading.weight_set = true;

            // Character
            tag_character = buffer.create_tag ("fou_char");
            tag_character.accumulative_margin = true;
            tag_character.left_margin = (f_w * 14);
            tag_character.left_margin_set = true;
            tag_parenthetical = buffer.create_tag ("fou_paren");
            tag_parenthetical.accumulative_margin = true;
            tag_parenthetical.left_margin = (f_w * 12);
            tag_parenthetical.left_margin_set = true;
            // Dialogue
            tag_dialogue = buffer.create_tag ("fou_diag");
            tag_dialogue.accumulative_margin = true;
            tag_dialogue.left_margin = (f_w * 8);
            tag_dialogue.left_margin_set = true;
            tag_dialogue.right_margin = (f_w * 8);
            tag_dialogue.right_margin_set = true;
            

            return true;
        }

        public void detach () {
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
            tag_scene_heading = null;

            view.destroy.disconnect (detach);
            view = null;
            buffer = null;
        }
    }
}