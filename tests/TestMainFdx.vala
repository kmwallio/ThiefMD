public class TestMainFdx {
    public static int main (string[] args) {
        Test.init (ref args);
        new FdxTests ();
        return Test.run ();
    }
}
