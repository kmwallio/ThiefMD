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

        Test.add_func ("/thiefmd/textpack_export", () => {
            // Set up a temp folder with some markdown files
            string temp_dir = DirUtils.make_tmp ("thiefmd_textpack_XXXXXX");
            string md1 = Path.build_filename (temp_dir, "chapter1.md");
            string md2 = Path.build_filename (temp_dir, "chapter2.md");
            string textpack_path = Path.build_filename (temp_dir, "output.textpack");

            try {
                FileUtils.set_contents (md1, "# Chapter 1\n\nOnce upon a time...\n");
                FileUtils.set_contents (md2, "# Chapter 2\n\nAnd they all lived happily ever after.\n");

                // Export the folder as a textpack
                bool success = FileManager.export_textpack (temp_dir, textpack_path);
                assert (success);
                assert (File.new_for_path (textpack_path).query_exists ());

                // Verify the textpack contains the right files
                var archive = new Archive.Read ();
                archive.support_filter_all ();
                archive.support_format_all ();
                archive.open_filename (textpack_path, 10240);

                bool found_info = false;
                bool found_text = false;
                unowned Archive.Entry entry;
                while (archive.next_header (out entry) == Archive.Result.OK) {
                    if (entry.pathname () == "info.json") {
                        found_info = true;
                    }
                    if (entry.pathname () == "text.md") {
                        found_text = true;
                    }
                    archive.read_data_skip ();
                }
                archive.close ();

                assert (found_info);
                assert (found_text);
            } catch (Error e) {
                warning ("textpack_export test failed: %s", e.message);
                assert_not_reached ();
            }

            // Clean up temp folder
            try {
                Dir cleanup_dir = Dir.open (temp_dir, 0);
                string? cleanup_name = null;
                while ((cleanup_name = cleanup_dir.read_name ()) != null) {
                    string cleanup_path = Path.build_filename (temp_dir, cleanup_name);
                    if (FileUtils.test (cleanup_path, FileTest.IS_DIR)) {
                        DirUtils.remove (cleanup_path);
                    } else {
                        FileUtils.unlink (cleanup_path);
                    }
                }
                DirUtils.remove (temp_dir);
            } catch (Error e) {
                warning ("Could not clean up temp folder: %s", e.message);
            }
        });
    }
}