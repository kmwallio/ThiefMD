# Testing [flatpak](https://flatpak.org/)

## Prerequisites

You will need runtime `org.gnome.Platform` version `3.36` and sdk `org.gnome.Sdk` version `3.36` installed in flatpack.

These can be installed in either the user directory or system wide.

## Building and Running

1. To build and install flatpak version, change working director to `ThiefMD\flatpak`.
2. Run `flatpak-builder --force-clean --user --install build-dir com.github.kmwallio.thiefmd.json`
3. Run `flatpak run com.github.kmwallio.thiefmd`

A .desktop file should be created and added to the proper path. If this is a the first user installed flatpak, the current session may have to be restarted to pickup the new location.

## Installing non-flatpak'd themes

The theme in the screenshots is [Vimix Gtk](https://github.com/vinceliuice/vimix-gtk-themes).

1. Clone the repo
  `git clone https://github.com/vinceliuice/vimix-gtk-themes.git`
2. `cd vimix-gtk-themes`
3. If using the system install of the gnome runtime
  `sudo ./install.sh -a -d /var/lib/flatpak/runtime/org.gnome.Platform/x86_64/3.36/active/files/share/themes`
