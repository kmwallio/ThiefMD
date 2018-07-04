using ThiefMD;
using ThiefMD.Widgets;

namespace ThiefMD.Controllers.SheetManager {
    private Sheet _currentSheet;

    public static bool load_sheet (Sheet sheet) {
        var settings = AppSettings.get_default ();
        bool loaded_file = false;

        if (sheet == null) {
            return false;
        }

        if (settings.last_file != "") {
            FileManager.save_work_file ();
        }

        if (_currentSheet != null) {
            _currentSheet.redraw ();
            _currentSheet.active = false;
        }

        loaded_file = FileManager.open_file (sheet.file_path());
        _currentSheet = sheet;
        _currentSheet.active = false;

        debug ("Tried to load %s (%s)\n", sheet.file_path (), (loaded_file) ? "success" : "failed");

        return loaded_file;
    }

    public string mini_mark (string contents) {
        string result = contents;
        try {
            Regex headers = new Regex ("^(#+)\\s(.+)", RegexCompileFlags.MULTILINE | RegexCompileFlags.CASELESS, 0);
            result = headers.replace (contents, -1, 0, "<b>\\1 \\2</b>");
        } catch (Error e) {
            warning ("Error: %s", e.message);
        }
        return result;
    }
}