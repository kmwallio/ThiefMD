// Temporary stub for GTK4 build until spellcheck ported
namespace Gspell {
    public class Checker : Object {
        public Checker () {}
        public void attach (Gtk.TextView view) {}
        public void detach () {}
        public void dispose () {}
        public void recheck_all () {}
        public void set_language (string? lang) {}
        public static GLib.SList<string> get_language_list () {
            return new GLib.SList<string> ();
        }
    }
}
