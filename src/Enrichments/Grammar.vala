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

        private int last_cursor;
        private int copy_offset;

        public GrammarChecker () {
            checking = Mutex ();
            limit_updates = new TimedMutex (3000);
            grammar_line = null;
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
                buffer.get_bounds (out start, out end);
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

        private void run_between_start_and_end (Gtk.TextIter start, Gtk.TextIter end) {
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
            Gtk.TextIter check_start = start;
            Gtk.TextIter check_end = start;
            check_end.forward_sentence_end ();

            while (check_start.in_range (start, end) &&
                    check_end.in_range (start, end) &&
                    (check_end.get_offset () != check_start.get_offset ())) 
            {
                Gtk.TextIter cursor_iter;
                var cursor = buffer.get_insert ();
                buffer.get_iter_at_mark (out cursor_iter, cursor);
                if (!cursor_iter.in_range (check_start, check_end))
                {
                    string sentence = buffer.get_text (check_start, check_end, false).chug ().chomp ();
                    if (sentence != "" && !checker.sentence_check (sentence)) {
                        buffer.apply_tag (grammar_line, check_start, check_end);
                    }
                }
                check_start = check_end;
                if (!check_end.forward_sentence_end ()) {
                    break;
                }
            }
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
            grammar_line.underline_rgba = Gdk.RGBA () { red = 0.51, green = 0.61, blue = 0.41, alpha = 1.0 };

            last_cursor = -1;

            return true;
        }

        public void detach () {
            Gtk.TextIter start, end;
            buffer.get_bounds (out start, out end);

            buffer.remove_tag (grammar_line, start, end);
            buffer.tag_table.remove (grammar_line);

            grammar_line = null;

            view = null;
            buffer = null;
            last_cursor = -1;
        }
    }

    public class GrammarThinking : GLib.Object {
        private int wait_time;
        private Cancellable cancellable;
        private bool done;
        public GrammarThinking (int timeout_millseconds = 500) {
            wait_time = timeout_millseconds;
        }

        public bool sentence_check (string sentence) {
            bool error_free = false;
            bool res = false;
            done = false;

            string check_sentence = strip_markdown (sentence).chug ().chomp ();
            if (check_sentence.contains ("[") || check_sentence.contains ("]") ||
                sentence.contains ("<") || sentence.contains (">"))
            {
                return true;
            }

            try {
                cancellable = new Cancellable ();
                string[] command = {
                    "link-parser",
                    "-batch"
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
                var output_stream = grammar.get_stdout_pipe ();

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

                if (output_stream != null) {
                    var proc_input = new DataInputStream (output_stream);
                    string line = "";
                    while ((line = proc_input.read_line (null)) != null) {
                        error_free = error_free || line.down ().contains ("0 errors");
                    }
                }

                if (!res || output_stream == null) {
                    error_free = true;
                }
            } catch (Error e) {
                warning ("Failed to run grammar: %s", e.message);
                error_free = true;
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