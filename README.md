# ThiefMD

<div style="float: left; width: 64px"><img src="docs/images/thiefmd_64.png" width="48" /></div>

ThiefMD is a [Markdown](https://en.wikipedia.org/wiki/Markdown) editor that helps with organization and management.  It is heavily inspired by [Ulysses](https://ulysses.app).  Initial code was based on work from [Quilter](https://github.com/lainsce/quilter).

## Font

The included for is [iA Writer Duospace](https://github.com/iaolo/iA-Fonts).  It is licensed under the [SIL Open Font License](data/font/LICENSE.md).

## Screenshots

![](docs/images/thief_styles.png)

[Ulysses Themes](https://styles.ulysses.app/themes) support. Showing [Tomorrow Dark](https://styles.ulysses.app/themes/tomorrow-qyp), Default ThiefMD Theme, [Dracula](https://styles.ulysses.app/themes/dracula-ZwJ), and [WWDC16](https://styles.ulysses.app/themes/wwdc16-04B).

![](docs/images/work_in_progress.png)

Still a work in progress, but this shows the sheets and editor view.  Sheets render a preview of the first few lines of a file, or shows the file name.

![](docs/images/panel_animation.gif)

Switching editor view modes.

![](docs/images/library_remove.gif)

Basic library management.

![](docs/images/drag_n_drop_sheets.gif)

Drag and Drop organizing of the library.

![](docs/images/preview.png)

Live Preview

## Dependencies

**Ubuntu**
```
meson
ninja-build
valac
cmake
libgranite-dev
libgtkspell3-3-dev
libwebkit2gtk-4.0-dev
libmarkdown2-dev
libxml2-dev
libclutter-1.0-dev
libarchive-dev
libgtk-3-dev
libgtksourceview-3.0-dev
```

**Fedora**
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
granite-devel
gtkspell3-devel
libarchive-devel
```

## Building

```bash
$ meson build && cd build
$ meson configure -Dprefix=/usr
$ ninja
$ sudo ninja install
```

## Features

 * Basic library at the moment
 * Switch between documents
 * Hide Library and Document Switcher
 * Live Preview
 * Sheet Management
 * Shortcut key bindings

## Planning

 * Better library organization
 * Export
 * Theming

## Acknowledgments

* Code <s>stolen</s> *forked* from [Quilter](https://github.com/lainsce/quilter)
* Font is [iA Writer Duospace](https://github.com/iaolo/iA-Fonts)
* Inspired by [Ulysses](https://ulysses.app)
* Preview CSS is [Splendor](http://markdowncss.github.io/splendor)
* Preview Scroll stolen from [this Stackoverflow](https://stackoverflow.com/questions/8922107/javascript-scrollintoview-middle-alignment) by [Rohan Orton](https://stackoverflow.com/users/2800005/rohan-orton)
* Syntax Highlighting by [highlight.js](https://highlightjs.org)
* Math Rendering by [Katex](https://katex.org)
