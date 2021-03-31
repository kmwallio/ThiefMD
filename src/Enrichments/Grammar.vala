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
    public class GrammarChecker {
        private Gtk.TextView view;
        private Gtk.TextBuffer buffer;
        private Mutex checking;
        private TimedMutex limit_updates;
        private GrammarThinking checker;
        public Gtk.TextTag grammar_line;
        public Gtk.TextTag grammar_word;

        private int last_cursor;
        private int copy_offset;

        public GrammarChecker () {
            checking = Mutex ();
            limit_updates = new TimedMutex (3000);
            grammar_line = null;
            grammar_word = null;
            last_cursor = -1;
            checker = new GrammarThinking ();
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

            // Remove any previous tags
            Gtk.TextIter start, end, cursor_iter;
            var cursor = buffer.get_insert ();
            buffer.get_iter_at_mark (out cursor_iter, cursor);
            int current_cursor = cursor_iter.get_offset ();

            if (last_cursor == -1) {
                Thinking worker = new Thinking (_("Checking Grammar"), () => {
                    Gtk.TextIter t_start, t_end;
                    buffer.get_bounds (out t_start, out t_end);
                    run_between_start_and_end (t_start, t_end);
                });
                worker.run ();
            } else {
                //
                // Scan where we are
                //
                buffer.get_iter_at_mark (out start, cursor);
                buffer.get_iter_at_mark (out end, cursor);
                get_chunk_of_text_around_cursor (ref start, ref end, false);
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
                        get_chunk_of_text_around_cursor (ref old_start, ref old_end, false);
                        if (!old_start.in_range (start, end) || !old_end.in_range (start, end)) {
                            run_between_start_and_end (old_start, old_end);
                        }
                    }
                }
            }

            last_cursor = current_cursor;
            checking.unlock ();
        }

        private void grab_sentence (ref Gtk.TextIter start, ref Gtk.TextIter end) {
            var link_tag = buffer.tag_table.lookup ("markdown-link");
            var url_tag = buffer.tag_table.lookup ("markdown-url");
            if (!end.ends_sentence () || ((link_tag != null && end.has_tag (link_tag)) || (url_tag != null && end.has_tag (url_tag)))) {
                do {
                    Gtk.TextIter next_line = end.copy (), next_sentence = end.copy ();
                    if (next_line.forward_to_line_end () && next_sentence.forward_sentence_end () && next_line.get_offset () < next_sentence.get_offset ()) {
                        end.forward_to_line_end ();
                        break;
                    }
                    if (!end.forward_sentence_end ()) {
                        break;
                    }
                } while ((end.has_tag (url_tag) || end.has_tag (link_tag)));
            }

            while (!end.get_char ().isspace ()) {
                if (!end.forward_char ()) {
                    break;
                }
            }
        }

        private void run_between_start_and_end (Gtk.TextIter start, Gtk.TextIter end) {
            if (grammar_word == null || grammar_line == null) {
                return;
            }

            copy_offset = start.get_offset ();
            if (!start.starts_sentence ()) {
                start.backward_sentence_start ();
            }
            if (!end.ends_sentence ()) {
                end.backward_sentence_start ();
            }
            if (end.get_offset () == start.get_offset ()) {
                return;
            }

            buffer.remove_tag (grammar_line, start, end);
            buffer.remove_tag (grammar_word, start, end);
            Gtk.TextIter check_end = start;
            grab_sentence (ref start, ref check_end);
            Gtk.TextIter check_start = start;

            var code_block = buffer.tag_table.lookup ("code-block");

            while (check_start.in_range (start, end) &&
                    check_end.in_range (start, end) &&
                    (check_end.get_offset () != check_start.get_offset ())) 
            {
                Gtk.TextIter cursor_iter;
                var cursor = buffer.get_insert ();
                buffer.get_iter_at_mark (out cursor_iter, cursor);

                if ((!cursor_iter.in_range (check_start, check_end)) &&
                    (!(code_block != null && (check_start.has_tag (code_block) || check_end.has_tag (code_block)))))
                {
                    string sentence = buffer.get_text (check_start, check_end, false).chug ().chomp ();
                    Gee.List<string> problem_words = new Gee.LinkedList<string> ();
                    if (sentence != "" && !checker.sentence_check (sentence, problem_words)) {
                        while (check_start.get_char () == ' ' && check_start.forward_char ()) {
                            if (check_start.get_char () != ' ') {
                                break;
                            }
                        }
                        buffer.apply_tag (grammar_line, check_start, check_end);
                        Gtk.TextIter word_start = check_start.copy ();
                        Gtk.TextIter word_end = check_start.copy ();
                        if (!problem_words.is_empty) {
                            while (word_end.forward_word_end () && word_end.get_offset () <= check_end.get_offset ()) {
                                string check_word = strip_markdown (word_start.get_text (word_end)).chug ().chomp ();
                                check_word = check_word.replace ("\"", "");
                                if (problem_words.contains (check_word) || problem_words.contains (check_word.down ())) {
                                    while (word_start.get_char () == ' ' && word_start.forward_char ()) {
                                        if (word_start.get_char () != ' ') {
                                            break;
                                        }
                                    }
                                    buffer.apply_tag (grammar_word, word_start, word_end);
                                }
                                word_start = word_end;
                            }
                        }
                    }
                }
                check_start = check_end;
                check_start.forward_char ();
                if (!check_end.forward_sentence_end ()) {
                    break;
                }
                grab_sentence (ref check_start, ref check_end);
            }
        }

        public bool handle_tooltip (int x, int y, bool keyboard_tooltip, Gtk.Tooltip tooltip) {
            Gtk.TextIter? iter;
            if (keyboard_tooltip) {
                int offset = buffer.cursor_position;
                buffer.get_iter_at_offset (out iter, offset);
            } else {
                int m_x, m_y, trailing;
                view.window_to_buffer_coords (Gtk.TextWindowType.TEXT, x, y, out m_x, out m_y);
                view.get_iter_at_position (out iter, out trailing, m_x, m_y);
            }

            if (iter != null) {
                if (iter.has_tag (grammar_line)) {
                    Gtk.TextIter start = iter.copy (), end = iter.copy ();
                    bool no_foward = false;
                    while (start.has_tag (grammar_line)) {
                        if (!start.backward_char ()) {
                            no_foward = true;
                            break;
                        }
                    }
                    if (!no_foward) {
                        start.forward_char ();
                    }
                    no_foward = false;
                    while (end.has_tag (grammar_line)) {
                        if (!end.forward_char ()) {
                            no_foward = true;
                            break;
                        }
                    }
                    if (!no_foward) {
                        end.backward_char ();
                    }
                    string suggestion = "";
                    if (!checker.sentence_check_suggestion (strip_markdown (buffer.get_text (start, end, false)), out suggestion) && suggestion != "") {
                        tooltip.set_markup (suggestion);
                        return true;
                    }
                }
            } else {
                return false;
            }

            return false;
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

            grammar_line = buffer.create_tag ("grammar_check", "underline", Pango.Underline.ERROR, null);
            grammar_line.underline_rgba = Gdk.RGBA () { red = 0.0, green = 0.40, blue = 0.133, alpha = 1.0 };

            grammar_word = buffer.create_tag ("grammar_word", "underline", Pango.Underline.ERROR, null);
            grammar_word.underline_rgba = Gdk.RGBA () { red = 0.0, green = 0.40, blue = 0.133, alpha = 1.0 };
            grammar_word.background_rgba = Gdk.RGBA () { red = 0.0, green = 0.40, blue = 0.133, alpha = 1.0 };
            grammar_word.foreground_rgba = Gdk.RGBA () { red = 0.9, green = 0.9, blue = 0.9, alpha = 1.0 };
            grammar_word.background_set = true;
            grammar_word.foreground_set = true;
            checker.check_language_settings ();

            view.set_has_tooltip (true);
            view.query_tooltip.connect (handle_tooltip);

            last_cursor = -1;

            return true;
        }

        public void detach () {
            Gtk.TextIter start, end;
            buffer.get_bounds (out start, out end);

            buffer.remove_tag (grammar_line, start, end);
            buffer.remove_tag (grammar_word, start, end);
            buffer.tag_table.remove (grammar_line);
            buffer.tag_table.remove (grammar_word);

            view.query_tooltip.disconnect (handle_tooltip);

            grammar_line = null;
            grammar_word = null;

            view = null;
            buffer = null;
            last_cursor = -1;
        }
    }

    public class GrammarThinking : GLib.Object {
        private int wait_time;
        private Cancellable cancellable;
        private bool done;
        private Gee.LinkedList<string> valid_cache;
        private Gee.LinkedList<string> invalid_cache;
        private Gee.LinkedList<string> invalid_suggestion;
        private int cache_size;
        private string language;
        public GrammarThinking (int cache_items = Constants.GRAMMAR_SENTENCE_CACHE_SIZE, int timeout_millseconds = Constants.GRAMMAR_SENTENCE_CHECK_TIMEOUT) {
            wait_time = timeout_millseconds;
            cache_size = cache_items;
            valid_cache = new Gee.LinkedList<string> ();
            invalid_cache = new Gee.LinkedList<string> ();
            invalid_suggestion = new Gee.LinkedList<string> ();
            check_language_settings ();
        }

        public void check_language_settings () {
            language = "en";
            var settings = AppSettings.get_default ();
            // @TODO could check file path and if this changes sometime
            if (settings.spellcheck_language.length > 2) {
                language = settings.spellcheck_language.substring (0, 2);
                if (!language_check (language)) {
                    language = "";
                }
            }
        }

        public bool language_detected () {
            return language != "";
        }

        private void resize_cache () {
            while (valid_cache.size > cache_size) {
                valid_cache.poll ();
            }
            while (invalid_cache.size > (cache_size / 2)) {
                invalid_cache.poll ();
                invalid_suggestion.poll ();
            }
        }

        public void clear_cache () {
            while (!valid_cache.is_empty) {
                valid_cache.poll ();
            }
            while (!invalid_cache.is_empty) {
                invalid_cache.poll ();
                invalid_suggestion.poll ();
            }
        }

        public bool language_check (string lang) {
            bool have_language = false;
            bool res = false;
            done = false;

            Subprocess grammar;
            InputStream? output_stream = null;
            try {
                cancellable = new Cancellable ();
                string[] command = {
                    "link-parser",
                    lang,
                    "-batch"
                };
                grammar = new Subprocess.newv (command,
                    SubprocessFlags.STDOUT_PIPE |
                    SubprocessFlags.STDIN_PIPE |
                    SubprocessFlags.STDERR_MERGE);

                var input_stream = grammar.get_stdin_pipe ();
                if (input_stream != null) {
                    DataOutputStream flush_buffer = new DataOutputStream (input_stream);
                    if (!flush_buffer.put_string ("thief were here")) {
                        warning ("Could not set buffer");
                    }
                    flush_buffer.flush ();
                    flush_buffer.close ();
                }
                output_stream = grammar.get_stdout_pipe ();

                // Before we wait, setup watchdogs
                Thread<void> watchdog = null;
                if (Thread.supported ()) {
                    watchdog = new Thread<void> ("grammar_watchdog", this.watch_dog);
                } else {
                    int now = 0;
                    Timeout.add (5, () => {
                        now += 5;
                        if (now > wait_time && !done) {
                            cancellable.cancel ();
                        }
                        return done;
                    });
                }

                res = grammar.wait (cancellable);
                done = true;
                if (watchdog != null) {
                    watchdog.join ();
                }
            } catch (Error e) {
                warning ("Failed to run grammar: %s", e.message);
            }

            try {
                if (output_stream != null) {
                    var proc_input = new DataInputStream (output_stream);
                    string line = "";
                    while ((line = proc_input.read_line (null)) != null) {
                        line = line.down ();
                        have_language = have_language || line.contains ("dictionary found");
                    }
                }
            } catch (Error e) {
                warning ("Could not process output: %s", e.message);
            }

            return have_language;
        }

        public bool sentence_check_suggestion (string sentence, out string suggestion) {
            return sentence_check_ex (sentence, out suggestion);
        }

        public bool sentence_check (string sentence, Gee.List<string>? problem_words = null) {
            string suggestion;
            return sentence_check_ex (sentence, out suggestion, problem_words);
        }

        private void parse_suggestion (string raw_suggestion, out string suggestion, Gee.List<string>? problem_words = null) {
            suggestion = "";
            string[] parts = raw_suggestion.replace ("LEFT-WALL", "").replace ("RIGHT-WALL", "").replace ("  ", " ").chug ().chomp ().split (" ");
            string last_word = "";
            foreach (var word in parts) {
                if (problem_words != null && word.has_prefix ("[")) {
                    string problem_word = word.substring (1, word.index_of_char (']') - 1);
                    if (problem_word.has_prefix ("'") || problem_word.has_prefix (",") || problem_word.has_prefix (".") ||
                        problem_word.has_prefix ("?") || problem_word.has_prefix ("?"))
                    {
                        problem_word = last_word + problem_word;
                    }
                    if (problem_word != "") {
                        problem_words.add (problem_word);
                    }
                }

                if (word.index_of_char ('.') != -1) {
                    word = word.substring (0, word.index_of_char ('.'));
                }
                last_word = word;
                suggestion += word + " ";
            }
        }

        private bool grab_invalid_suggestion (string sentence, out string suggestion, Gee.List<string>? problem_words = null) {
            int index = invalid_cache.index_of (sentence);
            if (index != -1) {
                parse_suggestion (invalid_suggestion.get (index), out suggestion, problem_words);
            } else {
                suggestion = "";
            }
            return false;
        }

        public bool sentence_check_ex (string sentence, out string suggestion, Gee.List<string>? problem_words = null) {
            suggestion = "";
            if (valid_cache.contains (sentence)) {
                return true;
            }

            if (invalid_cache.contains (sentence)) {
                return grab_invalid_suggestion (sentence, out suggestion, problem_words);
            }

            if (language == "") {
                return true;
            }

            bool error_free = false;
            bool res = false;
            done = false;
            string raw_suggestion = "";
            string check_sentence = strip_markdown (sentence).chug ().chomp ();
            // If it looks like we'd be noisy for HTML or random syntax
            if (check_sentence.contains ("[") || check_sentence.contains ("]") ||
                sentence.contains ("<") || sentence.contains (">") || sentence.has_prefix ("!") ||
                sentence.replace ("-", "").chug ().chomp () == "" || sentence.replace ("*", "").chug ().chomp () == "")
            {
                return true;
            }

            InputStream? output_stream = null;

            try {
                cancellable = new Cancellable ();
                string[] command = {
                    "link-parser",
                    language
                };
                Subprocess grammar = new Subprocess.newv (command,
                    SubprocessFlags.STDOUT_PIPE |
                    SubprocessFlags.STDIN_PIPE |
                    SubprocessFlags.STDERR_MERGE);

                var input_stream = grammar.get_stdin_pipe ();
                if (input_stream != null) {
                    DataOutputStream flush_buffer = new DataOutputStream (input_stream);
                    if (!flush_buffer.put_string (check_sentence)) {
                        warning ("Could not set buffer");
                    }
                    flush_buffer.flush ();
                    flush_buffer.close ();
                }
                output_stream = grammar.get_stdout_pipe ();

                // Before we wait, setup watchdogs
                Thread<void> watchdog = null;
                if (Thread.supported ()) {
                    watchdog = new Thread<void> ("grammar_watchdog", this.watch_dog);
                } else {
                    int now = 0;
                    Timeout.add (5, () => {
                        now += 5;
                        if (now > wait_time && !done) {
                            cancellable.cancel ();
                        }
                        return done;
                    });
                }

                res = grammar.wait (cancellable);
                done = true;
                if (watchdog != null) {
                    watchdog.join ();
                }
            } catch (Error e) {
                warning ("Failed to run grammar: %s", e.message);
                error_free = true;
            }

            try {
                if (output_stream != null) {
                    var proc_input = new DataInputStream (output_stream);
                    string line = "";
                    while ((line = proc_input.read_line (null)) != null) {
                        line = line.chomp ().chug ();
                        error_free = error_free || line.down ().contains ("unused=0");
                        if (line.has_prefix ("LEFT-WALL")) {
                            raw_suggestion = line;
                            parse_suggestion (raw_suggestion, out suggestion, problem_words);
                        }
                    }
                } else {
                    warning ("Got nothing");
                }

                if (!res || output_stream == null) {
                    error_free = true;
                }
            } catch (Error e) {
                warning ("Could not process output: %s", e.message);
            }

            if (error_free) {
                valid_cache.add (sentence);
                resize_cache ();
            }
            if (!error_free && raw_suggestion != "") {
                invalid_cache.add (sentence);
                invalid_suggestion.add (raw_suggestion);
                resize_cache ();
            }

            return error_free;
        }

        private void watch_dog () {
            int now = 0;
            while (now < wait_time && !done) {
                Thread.usleep (5000);
                now += 5;
            }

            if (!done) {
                cancellable.cancel ();
                warning ("Had to terminate grammar");
            }

            Thread.exit (0);
            return;
        }
    }
}