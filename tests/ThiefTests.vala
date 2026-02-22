public class ThiefTests {
    public static int main (string[] args) {
        Test.init (ref args);
        new ImageExtractionTests ();
        new MarkdownTests ();
        new MarkerNavigationTests ();
        new FileManagerTests ();
        new HelpersTests ();
        new PandocTests ();
        new FdxTests ();
        return Test.run ();
    }
}