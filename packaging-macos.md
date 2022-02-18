# Packaging for Mac

1. Install build dependencies with [homebrew](https://brew.sh). `brew install vala meson ninja clutter-gtk cmake gettext gtkspell3 link-grammar libgee libsecret gtksourceview4 gtk+3 adwaita-icon-theme libsoup discount libarchive libhandy`
2. Make sure pkgconfig can find packages. `export PKG_CONFIG_PATH="/opt/homebrew/opt/libarchive/lib/pkgconfig:/opt/homebrew/opt/link-grammar/lib/pkgconfig:/opt/homebrew/Cellar/libsoup/3.0.4/lib/pkgconfig:/opt/homebrew/Cellar/icu4c/69.1/lib/pkgconfig:$PKG_CONFIG_PATH"`
3. Setup to build to app package. `meson --prefix=/Applications/ThiefMD.app --bindir=Contents/MacOS --datadir=Contents/share --localedir=Contents/share/locale build`
4. `cd build`
5. `ninja`
6. `ninja install`
