# ![](data/images/icon.png) ThiefMD

Ulysses inspired markdown editor.

## Font

### [Courier Prime Sans](https://github.com/quoteunquoteapps/CourierPrimeSans)

[Courier Prime Sans](https://quoteunquoteapps.com/courierprime/) from [Quote-Unquote Apps](https://quoteunquoteapps.com).

## Dependencies

```
valac
libgranite-dev
libgtkspell3-3-dev
libwebkit2gtk-4.0-dev
libmarkdown2-dev
libgtkspell3-3-dev
libsqlite3-dev
gtk+-3.0
gtksourceview-3.0
meson
```

## Building

```bash
$ meson build && cd build
$ meson configure -Dprefix=/usr
$ sudo ninja install
```

## Acknowledgements

* Code <s>stolen</s> *forked* from [Quilter](https://github.com/lainsce/quilter)
* Inspired by [Ulysses](https://ulyssesapp.com/)
