using ThiefMD;
using ThiefMD.Widgets;

namespace ThiefMD.Controllers.UserData {
    public string data_path;
    public string style_path;
    public void create_data_directories () {
        data_path = Path.build_path (
                        Path.DIR_SEPARATOR_S,
                        Environment.get_user_data_dir (),
                        Constants.DATA_BASE);
        
        style_path = Path.build_path (
                        Path.DIR_SEPARATOR_S,
                        data_path,
                        Constants.DATA_STYLES);
        
        try {
            File style_file = File.new_for_path (style_path);
            if (!style_file.query_exists ()) {
                style_file.make_directory_with_parents ();
            }
        } catch (Error e) {
            warning ("Error: %s\n", e.message);
        }
    }
}