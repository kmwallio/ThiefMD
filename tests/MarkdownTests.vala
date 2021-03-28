using ThiefMD;

public class MarkdownTests {
    public MarkdownTests () {
        Test.add_func ("/thiefmd/file_extensions", () => {
            assert (is_fountain ("screenplay.fou"));
            assert (is_fountain ("screenplay.fountain"));
            assert (is_fountain ("screenplay.spmd"));
            assert (!is_fountain ("screenplay.markdown"));
            assert (!is_fountain ("screenplay.fountain.markdown"));
            assert (!is_fountain ("screenplay.docx"));
            assert (is_fountain ("screenplay.bib"));
        });

        Test.add_func ("/thiefmd/titles", () => {
            assert (make_title ("this_cool_cat") == "This Cool Cat");
            assert (make_title ("this-cool_cat") == "This Cool Cat");
            assert (make_title ("this_cool-cat") == "This Cool Cat");
            assert (make_title ("this cool-cat") == "This Cool Cat");
            assert (make_title ("this_cool cat") == "This Cool Cat");
        });
    }
}