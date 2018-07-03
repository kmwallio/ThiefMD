using ThiefMD;
using ThiefMD.Widgets;

namespace ThiefMD.Controllers.SheetManager {
    public static bool load_sheet (Sheet sheet) {
        var settings = AppSettings.get_default ();
        bool loaded_file = false;

        if (settings.last_file != "") {
            FileManager.save_work_file ();
        }

        loaded_file = FileManager.open_file (sheet.file_path());

        stdout.printf ("Tried to load %s (%s)\n", sheet.file_path (), (loaded_file) ? "success" : "failed");

        return loaded_file;
    }

    
}