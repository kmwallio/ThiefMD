using ThiefMD;
using ThiefMD.Controllers;

public class PandocTests {
    public PandocTests () {
        test_find_file ();
        test_needs_bibtex ();
    }

    private void test_find_file () {
        Test.add_func ("/thiefmd/pandoc_find_file", () => {
            // Find README.md in current directory
            string readme = Pandoc.find_file ("README.md", Environment.get_current_dir ());
            assert (readme != "");
            assert (readme != "README.md");
            assert (FileUtils.test (readme, FileTest.EXISTS));
            
            // Non-existent file should return original filename
            string not_found = Pandoc.find_file ("nonexistent_file_12345.xyz", Environment.get_current_dir ());
            assert (not_found == "nonexistent_file_12345.xyz");
        });
    }

    private void test_needs_bibtex () {
        Test.add_func ("/thiefmd/pandoc_needs_bibtex", () => {
            // Text without bibtex reference
            string no_bibtex = "This is a simple document";
            assert (!Pandoc.needs_bibtex (no_bibtex));
            
            // Text with YAML front matter containing bibliography directive
            string with_bibtex = "---\nbibliography: refs.bib\n---\n\nThis cites a source";
            assert (Pandoc.needs_bibtex (with_bibtex));
            
            // Text with YAML front matter with quoted bibliography path
            string with_bibliography = "---\nbibliography: \"sources.bib\"\n---\n\nDocument content";
            assert (Pandoc.needs_bibtex (with_bibliography));
            
            // Text without YAML front matter
            string plain_text = "No YAML here\nJust plain text";
            assert (!Pandoc.needs_bibtex (plain_text));
        });
    }
}
