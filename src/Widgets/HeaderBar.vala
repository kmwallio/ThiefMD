using ThiefMD;
using ThiefMD.Controllers;

namespace ThiefMD.Widgets {
    public class Headerbar : Gtk.HeaderBar {
        private static Headerbar? instance = null;

        private Gtk.Button change_view_button;
        private Gtk.Button search_button;
        private Gtk.Button add_library_button;
        private Gtk.MenuButton new_sheet;
        private Gtk.MenuButton menu_button;
        private NewSheet new_sheet_widget;

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
            var settings = AppSettings.get_default ();
            set_title ("ThiefMD");

            new_sheet = new Gtk.MenuButton ();
            new_sheet_widget = new NewSheet ();
            new_sheet.has_tooltip = true;
            new_sheet.tooltip_text = (_("New Sheet"));
            new_sheet.set_image (new Gtk.Image.from_icon_name ("document-new", Gtk.IconSize.LARGE_TOOLBAR));
            new_sheet.popover = new_sheet_widget;

            change_view_button = new Gtk.Button ();
            change_view_button.has_tooltip = true;
            change_view_button.tooltip_text = (_("Change View"));
            change_view_button.set_image (new Gtk.Image.from_icon_name("document-page-setup", Gtk.IconSize.LARGE_TOOLBAR));
            change_view_button.clicked.connect (() => {
                UI.toggle_view();
            });

            add_library_button = new Gtk.Button ();
            add_library_button.has_tooltip = true;
            add_library_button.tooltip_text = (_("Add Folder to Library"));
            add_library_button.set_image (new Gtk.Image.from_icon_name ("folder-new", Gtk.IconSize.LARGE_TOOLBAR));
            add_library_button.clicked.connect (() => {
                string new_lib = Dialogs.select_folder_dialog ();
                if (FileUtils.test(new_lib, FileTest.IS_DIR)) {
                    if (settings.add_to_library (new_lib)) {
                        // Refresh
                        ThiefApp instance = ThiefApp.get_instance ();
                        instance.refresh_library ();
                    }
                }
            });


            //  search_button = new Gtk.Button ();
            //  search_button.has_tooltip = true;
            //  search_button.tooltip_text = (_("Search"));
            //  search_button.set_image (new Gtk.Image.from_icon_name ("edit-find", Gtk.IconSize.LARGE_TOOLBAR));

            menu_button = new Gtk.MenuButton ();
            menu_button.has_tooltip = true;
            menu_button.tooltip_text = (_("Settings"));
            menu_button.set_image (new Gtk.Image.from_icon_name ("open-menu", Gtk.IconSize.LARGE_TOOLBAR));
            menu_button.popover = new QuickPreferences ();

            pack_start (change_view_button);
            pack_start (add_library_button);
            // Need to find a better way to do this
            pack_start (new Gtk.Label("                          "));
            pack_start (new_sheet);

            pack_end (menu_button);

            set_show_close_button (true);
            settings.changed.connect (update_header);
            this.show_all ();
        }

        private void update_header () {
            var settings = AppSettings.get_default ();

            if (settings.show_filename && settings.last_file != "") {
                string file_name = settings.last_file.substring(settings.last_file.last_index_of("/") + 1);
                set_title ("ThiefMD: " + file_name);
            } else {
                set_title ("ThiefMD");
            }
        }
    }
}