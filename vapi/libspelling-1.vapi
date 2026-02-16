/* libspelling-1.vapi - Vala bindings for libspelling */

[CCode (cheader_filename = "libspelling.h", gir_namespace = "Spelling", gir_version = "1")]
namespace Spelling {
    [CCode (cheader_filename = "libspelling.h", type_id = "spelling_checker_get_type ()")]
    public class Checker : GLib.Object {
        [CCode (has_construct_function = false)]
        public Checker (Spelling.Provider? provider, string? language);
        
        public static unowned Spelling.Checker get_default ();
        public unowned Spelling.Provider? get_provider ();
        public unowned string? get_language ();
        public void set_language (string? language);
        public bool check_word (string word, ssize_t word_len = -1);
        public string[] list_corrections (string word);
        public void add_word (string word, ssize_t word_len = -1);
        public GLib.MenuModel get_corrections_menu ();
        
        public string? language { get; set; }
        public Spelling.Provider provider { get; construct; }
    }

    [CCode (cheader_filename = "libspelling.h", type_id = "spelling_language_get_type ()")]
    public class Language : GLib.Object {
        [CCode (has_construct_function = false)]
        protected Language ();
        
        public unowned string? get_code ();
        public unowned string? get_name ();
        public unowned string? get_group ();
        
        public string? code { get; }
        public string? name { get; }
        public string? group { get; }
    }

    [CCode (cheader_filename = "libspelling.h", type_id = "spelling_provider_get_type ()")]
    public class Provider : GLib.Object {
        public static unowned Spelling.Provider get_default ();
        public bool supports_language (string language);
        public unowned GLib.ListModel list_languages ();
    }

    [CCode (cheader_filename = "libspelling.h", type_id = "spelling_text_buffer_adapter_get_type ()")]
    public class TextBufferAdapter : GLib.Object {
        [CCode (has_construct_function = false)]
        public TextBufferAdapter (GtkSource.Buffer buffer, Spelling.Checker? checker);
        
        public unowned GtkSource.Buffer get_buffer ();
        public bool get_enabled ();
        public void set_enabled (bool enabled);
        public unowned Spelling.Checker? get_checker ();
        public void set_checker (Spelling.Checker? checker);
        public unowned string? get_language ();
        public void set_language (string? language);
        public void invalidate_all ();
        public unowned Gtk.TextTag? get_tag ();
        public unowned GLib.MenuModel? get_menu_model ();
        public void update_corrections ();
        
        public GtkSource.Buffer buffer { get; construct; }
        public Spelling.Checker checker { get; set; }
        public bool enabled { get; set; }
        public string? language { get; set; }
    }

    [CCode (cheader_filename = "libspelling.h", cname = "spelling_init")]
    public static void init ();
}
