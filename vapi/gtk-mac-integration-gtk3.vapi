[CCode(cheader_filename="gtkosxapplication.h")]
namespace Gtk {
    [Flags]
    [CCode (cname = "GtkosxApplicationAttentionType", cprefix = "GTKOSX_APPLICATION_ATTENTION_TYPE_")]
    public enum OSXApplicationAttentionType {
        CRITICAL_REQUEST,
        INFO_REQUEST
    }

    [CCode (cname = "GtkosxApplication", cprefix = "gtkosx_application_", free_function = "")]
    [Compact]
    public class OSXApplication {
        [CCode(cname="GTKOSX_TYPE_APPLICATION")]
        public static GLib.Type GTKOSX_TYPE_APPLICATION;

        public static Gtk.OSXApplication get_instance() {
            return (Gtk.OSXApplication) GLib.Object.new(GTKOSX_TYPE_APPLICATION);
        }

        [CCode(cname = "gtkosx_application_ready")]
        public void ready();

        /*Accelerator functions*/
        [CCode(cname = "gtkosx_application_set_use_quartz_accelerators")]
        public void set_use_quartz_accelerators(bool use_quartz_accelerators);

        [CCode(cname = "gtkosx_application_use_quartz_accelerators")]
        public bool use_quartz_accelerators();

        /*Menu functions*/
        [CCode(cname = "gtkosx_application_set_menu_bar")]
        public void set_menu_bar(Gtk.MenuShell menu_shell);

        [CCode(cname = "gtkosx_application_sync_menubar")]
        public void sync_menubar();
        [CCode(cname = "gtkosx_application_sync_menubar")]
        public void sync_menu_bar();

        [CCode(cname = "gtkosx_application_insert_app_menu_item")]
        public void insert_app_menu_item(Gtk.Widget menu_item, int index);

        [CCode(cname = "gtkosx_application_set_about_item")]
        public void set_about_item(Gtk.Widget item);

        [CCode(cname = "gtkosx_application_set_window_menu")]
        public void set_window_menu(Gtk.MenuItem menu_item);

        [CCode(cname = "gtkosx_application_set_help_menu")]
        public void set_help_menu(Gtk.MenuItem menu_item);

        /* Dock Functions */
        [CCode(cname = "gtkosx_application_set_dock_menu")]
        public void set_dock_menu(Gtk.MenuShell menu_shell);

        [CCode(cname = "gtkosx_application_set_dock_icon_pixbuf")]
        public void set_dock_icon_pixbuf(Gdk.Pixbuf icon_pixbuf);

        [CCode(cname = "gtkosx_application_set_dock_icon_resource")]
        public void set_dock_icon_resource(string name, string type, string subdir);

        [CCode(cname = "gtkosx_application_attention_request")]
        public int attention_request(OSXApplicationAttentionType type);

        [CCode(cname = "gtkosx_application_cancel_attention_request")]
        public void cancel_attention_request(int id);
    }
}
