# Packaging for Fedora

Update the `com.github.kmwallio.thiefmd.spec`

## Building

1. In the build directory, run `meson dist --include-subprojects`. [^m-dist]
2. Copy the `meson-dist/com.github.kmwallio.thiefmd-version.tar.xz` to `~/rpmbuild/SOURCES/`
3. Copy the `com.github.kmwallio.thiefmd.spec` into the build directory
3. Run the build `rpmbuild -bb com.github.kmwallio.thiefmd.spec` from the build directory.
4. Test installation of RPM `sudo rpm -Uhv com.github.kmwallio.thiefmd-X.Y.Z-1.fc32.x86_64.rpm`
5. Release resulting rpm from `~/rpmbuild/RPMS`.

[^m-dist]:https://mesonbuild.com/Creating-releases.html
