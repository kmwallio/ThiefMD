using ThiefMD;
using ThiefMD.Controllers;
using ThiefMD.Widgets;

public class FileManagerTests {
    public FileManagerTests () {
        Test.add_func ("/thiefmd/file_open_tests", () => {
            string readme = Pandoc.find_file ("README.md", Environment.get_current_dir ());
            assert (readme != "");
            assert (readme != "README.md");
            Editor editor;
            FileManager.open_file (readme, out editor);
            assert (editor != null);
            FileManager.open_file ("basdfasdfasdfjawlekrthasjkldhfgajklsdhflkasjd.md", out editor);
            assert (editor == null);

            string readme_contents = FileManager.get_file_contents (readme);
            assert (readme_contents != "");
            string title, date;
            string untouched = FileManager.get_file_lines_yaml (
                readme, // File
                4, // read all lines
                false, // include empty lines
                out title,
                out date);

            assert (untouched != "");
            assert (title != "");
            assert (title.down ().contains ("thief"));
        });
    }
}