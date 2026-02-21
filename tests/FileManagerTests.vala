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

        Test.add_func ("/thiefmd/bear2bk_import", () => {
            // Create a tiny bear2bk archive in /tmp for this test
            string archive_path = Path.build_filename (
                Environment.get_tmp_dir (),
                "thiefmd-bear2bk-test.bear2bk"
            );
            string dest = Path.build_filename (
                Environment.get_tmp_dir (),
                "thiefmd-bear2bk-dest"
            );

            // Use python3 to create a valid zip/bear2bk file
            string script =
                "import zipfile\n" +
                "z = zipfile.ZipFile('" + archive_path + "', 'w')\n" +
                "z.writestr('My First Note.textbundle/text.md', '# Hello World\\n\\nTest note.\\n')\n" +
                "z.writestr('My First Note.textbundle/assets/image.png', 'PNG')\n" +
                "z.writestr('Another Note.textbundle/text.md', '# Another Note\\n')\n" +
                "z.close()\n";

            try {
                string[] cmd = { "python3", "-c", script };
                int status;
                Process.spawn_sync (null, cmd, null, SpawnFlags.SEARCH_PATH, null, null, null, out status);
            } catch (SpawnError e) {
                warning ("Could not build bear2bk fixture, skipping: %s", e.message);
                return;
            }

            if (!FileUtils.test (archive_path, FileTest.EXISTS)) {
                warning ("bear2bk fixture not created, skipping test");
                return;
            }

            // Make a clean destination directory
            File dest_dir = File.new_for_path (dest);
            if (dest_dir.query_exists ()) {
                try {
                    Dir dir = Dir.open (dest, 0);
                    string? fname;
                    while ((fname = dir.read_name ()) != null) {
                        File.new_for_path (Path.build_filename (dest, fname)).delete ();
                    }
                } catch (Error e) {}
            } else {
                try {
                    dest_dir.make_directory_with_parents ();
                } catch (Error e) {
                    assert_not_reached ();
                }
            }

            FileManager.import_bear2bk (archive_path, dest);

            // Both notes should land as .md files
            assert (FileUtils.test (Path.build_filename (dest, "My First Note.md"), FileTest.EXISTS));
            assert (FileUtils.test (Path.build_filename (dest, "Another Note.md"), FileTest.EXISTS));

            // The note content should be readable markdown
            string note1 = FileManager.get_file_contents (Path.build_filename (dest, "My First Note.md"));
            assert (note1.contains ("Hello World"));

            // The asset from the first note should be extracted
            assert (FileUtils.test (Path.build_filename (dest, "image.png"), FileTest.EXISTS));
        });
    }
}
