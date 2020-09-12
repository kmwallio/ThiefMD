# Testing [flatpak]()

1. To build and install flatpak version, change working director to `ThiefMD\flatpak`.
2. Run `flatpak-builder --user --install build-dir com.github.kmwallio.thiefmd`
3. Run `flatpak run com.github.kmwallio.thiefmd`

A .desktop file should be created and added to the proper path. If this is a the first user installed flatpak, the current session may have to be restarted to pickup the new location.