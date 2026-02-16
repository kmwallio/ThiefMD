/* gspell-1 bindings for GTK4 */

namespace Gspell {
    [CCode (cheader_filename = "gspell/gspell.h", type_id = "gspell_checker_get_type ()")]
    public class Checker : GLib.Object {
        [CCode (has_construct_function = false)]
        public Checker (Gspell.Language? language);
        public void add_word_to_personal (string word, ssize_t word_length);
        public void add_word_to_session (string word, ssize_t word_length);
        public bool check_word (string word, ssize_t word_length) throws GLib.Error;
        public unowned Gspell.Language? get_language ();
        public GLib.SList<string> get_suggestions (string word, ssize_t word_length);
        public void set_language (Gspell.Language? language);
        [NoWrapper]
        public virtual signal void language_changed ();
        [NoWrapper]
        public virtual signal void session_cleared ();
        [NoWrapper]
        public virtual signal void word_added_to_personal (string word);
        [NoWrapper]
        public virtual signal void word_added_to_session (string word);
        public Gspell.Language language { get; set; }
    }

    [CCode (cheader_filename = "gspell/gspell.h", type_id = "gspell_language_get_type ()")]
    [Compact]
    [GIR (fullname = "Gspell.Language")]
    public class Language {
        [CCode (has_construct_function = false)]
        protected Language ();
        public int compare (Gspell.Language language_b);
        public unowned string get_code ();
        public unowned string get_name ();
        public static unowned Gspell.Language? get_default ();
        public static unowned GLib.List<unowned Gspell.Language> get_available ();
        public static unowned Gspell.Language? lookup (string language_code);
    }

    [CCode (cheader_filename = "gspell/gspell.h", type_id = "gspell_text_view_get_type ()")]
    public class TextView : GLib.Object {
        [CCode (has_construct_function = false)]
        protected TextView ();
        public static void basic_setup (Gspell.TextView gspell_view);
        public bool get_enable_language_menu ();
        public bool get_inline_spell_checking ();
        public unowned Gtk.TextView get_view ();
        public void set_enable_language_menu (bool enable_language_menu);
        public void set_inline_spell_checking (bool enable);
        [CCode (cname = "gspell_text_view_get_from_gtk_text_view")]
        public static unowned Gspell.TextView? from_gtk_text_view (Gtk.TextView gtk_view);
        public bool enable_language_menu { get; set; }
        public bool inline_spell_checking { get; set; }
        public Gtk.TextView view { get; construct; }
    }

    [CCode (cheader_filename = "gspell/gspell.h", type_id = "gspell_text_buffer_get_type ()")]
    public class TextBuffer : GLib.Object {
        [CCode (has_construct_function = false)]
        protected TextBuffer ();
        public unowned Gspell.Checker get_spell_checker ();
        public void set_spell_checker (Gspell.Checker? spell_checker);
        [CCode (cname = "gspell_text_buffer_get_from_gtk_text_buffer")]
        public static unowned Gspell.TextBuffer? from_gtk_text_buffer (Gtk.TextBuffer gtk_buffer);
        public Gspell.Checker spell_checker { get; set; }
        public Gtk.TextBuffer buffer { get; construct; }
    }
}
