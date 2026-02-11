/* gspell-1 compatibility bindings for GTK4 */

namespace Gspell {
    [CCode (type_cname = "GspellChecker", cprefix = "gspell_checker_")]
    public class Checker {
        public Checker ();
        public static GLib.SList<string> get_language_list ();
        public void set_language (string lang);
        public void attach (Gtk.TextView view);
        public void detach ();
        public void recheck_all ();
        public void dispose ();
    }
}
