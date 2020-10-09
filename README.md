# ThiefMD

<img src="docs/images/thiefmd_64.png" width="48" style="float: left; width: 48px" />

ThiefMD is a [Markdown](https://en.wikipedia.org/wiki/Markdown) editor that helps with `organization and management`. It is heavily inspired by [Ulysses](https://ulysses.app). Initial code was based on work from [Quilter](https://github.com/lainsce/quilter).

## Installation from Flatpak

[ThiefMD](https://flathub.org/apps/details/com.github.kmwallio.thiefmd) is now available on Flathub. Make sure you've added [flathub](https://flatpak.org/setup) to your system.

```bash
flatpak install flathub com.github.kmwallio.thiefmd
```

## Debian Based Distro Installation

```bash
sudo add-apt-repository ppa:thiefmd/thiefmd
sudo apt-get update
sudo apt-get install com.github.kmwallio.thiefmd
```

## Features

 * Basic library at the moment
 * Switch between documents
 * Hide Library and Document Switcher
 * Live Preview
 * Sheet Management
 * Shortcut key bindings
 * Themes
 * Export (DocX, ePUB, PDF, HTML, Markdown, and more...)
 * Import (DocX, ePUB, HTML, rst, textile, and more...)

## Planning

 * Better library organization
 * Writing Statistics
 * Dedicated Markdown Editor

## Screenshots

![](docs/images/theme_preferences.png)

Download themes from [https://themes.thiefmd.com](https://themes.thiefmd.com) or [make your own](https://themes.thiefmd.com/howto). [Ulysses Themes](https://styles.ulysses.app/themes) can also be imported through the preferences `Ctrl+,`.

![](docs/images/drag_n_drop_sheets.gif)

Drag and Drop organizing of the library.

![](docs/images/epub-export.png)

Live Preview & Export Preview

![](docs/images/typewriter_scrolling.gif)

Typewriter Scrolling.

![](docs/images/write-good.png)

[Write-Good](https://github.com/ThiefMD/libwritegood-vala) recommendations and highlighting.

## Dependencies

As part of the build, [libwritegood-vala](https://github.com/ThiefMD/libwritegood-vala) and the [Ulysses Theme Parser](https://github.com/TwiRp/ultheme-vala) will be cloned and built.

### Ubuntu

```
meson
ninja-build
valac
cmake
libgtkspell3-3-dev
libwebkit2gtk-4.0-dev
libmarkdown2-dev
libxml2-dev
libclutter-1.0-dev
libarchive-dev
libgtk-3-dev
libgee-0.8-dev
libgtksourceview-3.0-dev
```

### Fedora

```
vala
meson
ninja-build
cmake
libmarkdown-devel
clutter-gtk-devel
webkit2gtk3-devel
gtk3-devel
gtksourceview3-devel
gtkspell3-devel
libarchive-devel
libxml2-devel
libgee-devel
```

## Building

```bash
$ meson build && cd build
$ meson configure -Dprefix=/usr
$ ninja
$ sudo ninja install
```

[Prebuilt packages](https://github.com/kmwallio/ThiefMD/releases) are available.

## Acknowledgments

* Code ~~stolen~~ *forked* from [Quilter](https://github.com/lainsce/quilter)
* Font is [iA Writer Duospace](https://github.com/iaolo/iA-Fonts)
* Inspired by [Ulysses](https://ulysses.app)
* Preview CSS is [Splendor](http://markdowncss.github.io/splendor) + [Modest](http://markdowncss.github.io/modest)
* Preview Scroll stolen from [this Stackoverflow](https://stackoverflow.com/questions/8922107/javascript-scrollintoview-middle-alignment) by [Rohan Orton](https://stackoverflow.com/users/2800005/rohan-orton)
* Preview Syntax Highlighting by [highlight.js](https://highlightjs.org)
* Math Rendering by [Katex](https://katex.org)
* Multi-format Export by [Pandoc](https://pandoc.org)
* Write-Good based on [btford/write-good](https://github.com/btford/write-good)
