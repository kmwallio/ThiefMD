public class TestMainMarkerNavigation {
    public static int main (string[] args) {
        Test.init (ref args);
        new MarkerNavigationTests ();
        return Test.run ();
    }
}
