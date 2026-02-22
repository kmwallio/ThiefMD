public class TestMainImageExtraction {
    public static int main (string[] args) {
        Test.init (ref args);
        new ImageExtractionTests ();
        return Test.run ();
    }
}
