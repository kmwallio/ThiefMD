# Testing [flatpak](https://flatpak.org/)

## Prerequisites

You will need runtime `org.gnome.Platform` version `3.38` and sdk `org.gnome.Sdk` version `3.38` installed in flatpak.

These can be installed in either the user directory or system wide.

## Local Building and Running

1. To build and install flatpak version, change working director to `ThiefMD\flatpak`.
2. Run `flatpak-builder --force-clean --user --install build-dir com.github.kmwallio.thiefmd.json`
3. Run `flatpak run com.github.kmwallio.thiefmd`

A .desktop file should be created and added to the proper path. If this is a the first user installed flatpak, the current session may have to be restarted to pickup the new location.

## Submitting a Release

1. Determine the release file hash using `sha256sum com.github.kmwallio.thiefmd-X.Y.Z.tar.xz`
2. Make sure the tar.xz is uploaded as part of the GitHub release
3. Clone https://github.com/flathub/com.github.kmwallio.thiefmd
4. Checkout the `beta` branch. Update the json file for the new source package.
5. Publish the beta branch (or send a pull request). Once in beta branch, monitor build at [flathub.org/builds](https://flathub.org/builds)
6. Make sure you have the beta-repo installed:
   - `flatpak remote-add --user flathub-beta https://flathub.org/beta-repo/flathub-beta.flatpakrepo`
7. Install the beta build:
   - `flatpak install --user flathub-beta com.github.kmwallio.thiefmd`
8. Test the build. and submit a pull request to `master` if satisfied.
9. ???
10. Profit

## Installing non-flatpak'd themes

ThiefMD currently requests home directory permissions, so themes installed in the user's home directory will work.

The theme in the screenshots is [Vimix Gtk](https://github.com/vinceliuice/vimix-gtk-themes).

1. Clone the repo
  `git clone https://github.com/vinceliuice/vimix-gtk-themes.git`
2. `cd vimix-gtk-themes`
3. If using the system install of the gnome runtime
  `sudo ./install.sh -a -d /var/lib/flatpak/runtime/org.gnome.Platform/x86_64/3.36/active/files/share/themes`
