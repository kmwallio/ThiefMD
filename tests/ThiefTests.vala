public class ThiefTests {
    public static int main (string[] args) {
        Test.init (ref args);
        new ImageExtractionTests ();
        new MarkdownTests ();
        new FileManagerTests ();
        return Test.run ();
    }
}