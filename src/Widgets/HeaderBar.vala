namespace ThiefMD.Widgets {
    public class Headerbar : Gtk.HeaderBar {
        private static Headerbar? instance = null;

        private Gtk.Button search_button;
        private Gtk.Button new_sheet;

        public Headerbar () {
            var header_context = this.get_style_context ();
            header_context.add_class (Gtk.STYLE_CLASS_FLAT);
            header_context.add_class ("thief-toolbar");

            build_ui ();
        }

        public static Headerbar get_instance () {
            if (instance == null) {
                instance = new Widgets.Headerbar ();
            }
    
            return instance;
        }

        private void build_ui () {
            set_title ("ThiefMD");

            new_sheet = new Gtk.Button ();
            new_sheet.has_tooltip = true;
            new_sheet.tooltip_text = (_("New Sheet"));
            new_sheet.set_image (new Gtk.Image.from_icon_name ("document-new", Gtk.IconSize.LARGE_TOOLBAR));

            search_button = new Gtk.Button ();
            search_button.has_tooltip = true;
            search_button.tooltip_text = (_("Search"));
            search_button.set_image (new Gtk.Image.from_icon_name ("edit-find", Gtk.IconSize.LARGE_TOOLBAR));

            pack_start(new_sheet);
            pack_start(search_button);

            set_show_close_button (true);
            this.show_all ();
        }
    }
}