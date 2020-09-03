Name: com.github.kmwallio.thiefmd
Version: 0.0.5
Release: 1%{?dist}
Summary: Markdown Library Manager and Editor built on the efforts of other OSS.
License: GPL-3.0+
Source: meson-dist/%{name}-%{version}.tar.xz

BuildRequires: meson
BuildRequires: vala
BuildRequires: gcc
BuildRequires: pkgconfig(libmarkdown)
BuildRequires: pkgconfig(granite)
BuildRequires: pkgconfig(gobject-2.0)
BuildRequires: pkgconfig(gtksourceview-3.0)
BuildRequires: pkgconfig(gtk+-3.0)
BuildRequires: pkgconfig(gtkspell3-3.0)
BuildRequires: pkgconfig(webkit2gtk-4.0)

%description

%prep
%autosetup

%build
%meson
%meson_build

%install
%meson_install

%check
%meson_test

%files
/usr/share/applications/com.github.kmwallio.thiefmd.desktop
/usr/share/com.github.kmwallio.thiefmd/styles/preview.css
/usr/share/fonts/truetype/thiefmd/iAWriterDuospace-Regular.ttf
/usr/share/glib-2.0/schemas/com.github.kmwallio.thiefmd.gschema.xml
/usr/share/gtksourceview-3.0/styles/thiefmd-dark.xml
/usr/share/gtksourceview-3.0/styles/thiefmd.xml
/usr/share/icons/hicolor/128x128/apps/com.github.kmwallio.thiefmd.svg
/usr/share/icons/hicolor/48x48/apps/com.github.kmwallio.thiefmd.svg
/usr/share/icons/hicolor/64x64/apps/com.github.kmwallio.thiefmd.svg
/usr/share/icons/hicolor/symbolicxsymbolic/apps/com.github.kmwallio.thiefmd.svg
/usr/share/metainfo/com.github.kmwallio.thiefmd.appdata.xml
/usr/bin/com.github.kmwallio.thiefmd
/usr/lib/debug/usr/bin/com.github.kmwallio.thiefmd-%{version}-1.fc32.x86_64.debug
/usr/share/com.github.kmwallio.thiefmd/scripts/auto-render.min.js
/usr/share/com.github.kmwallio.thiefmd/scripts/highlight.js
/usr/share/com.github.kmwallio.thiefmd/scripts/katex.min.js
/usr/share/com.github.kmwallio.thiefmd/styles/fonts/KaTeX_AMS-Regular.ttf
/usr/share/com.github.kmwallio.thiefmd/styles/fonts/KaTeX_AMS-Regular.woff
/usr/share/com.github.kmwallio.thiefmd/styles/fonts/KaTeX_AMS-Regular.woff2
/usr/share/com.github.kmwallio.thiefmd/styles/fonts/KaTeX_Caligraphic-Bold.ttf
/usr/share/com.github.kmwallio.thiefmd/styles/fonts/KaTeX_Caligraphic-Bold.woff
/usr/share/com.github.kmwallio.thiefmd/styles/fonts/KaTeX_Caligraphic-Bold.woff2
/usr/share/com.github.kmwallio.thiefmd/styles/fonts/KaTeX_Caligraphic-Regular.ttf
/usr/share/com.github.kmwallio.thiefmd/styles/fonts/KaTeX_Caligraphic-Regular.woff
/usr/share/com.github.kmwallio.thiefmd/styles/fonts/KaTeX_Caligraphic-Regular.woff2
/usr/share/com.github.kmwallio.thiefmd/styles/fonts/KaTeX_Fraktur-Bold.ttf
/usr/share/com.github.kmwallio.thiefmd/styles/fonts/KaTeX_Fraktur-Bold.woff
/usr/share/com.github.kmwallio.thiefmd/styles/fonts/KaTeX_Fraktur-Bold.woff2
/usr/share/com.github.kmwallio.thiefmd/styles/fonts/KaTeX_Fraktur-Regular.ttf
/usr/share/com.github.kmwallio.thiefmd/styles/fonts/KaTeX_Fraktur-Regular.woff
/usr/share/com.github.kmwallio.thiefmd/styles/fonts/KaTeX_Fraktur-Regular.woff2
/usr/share/com.github.kmwallio.thiefmd/styles/fonts/KaTeX_Main-Bold.ttf
/usr/share/com.github.kmwallio.thiefmd/styles/fonts/KaTeX_Main-Bold.woff
/usr/share/com.github.kmwallio.thiefmd/styles/fonts/KaTeX_Main-Bold.woff2
/usr/share/com.github.kmwallio.thiefmd/styles/fonts/KaTeX_Main-BoldItalic.ttf
/usr/share/com.github.kmwallio.thiefmd/styles/fonts/KaTeX_Main-BoldItalic.woff
/usr/share/com.github.kmwallio.thiefmd/styles/fonts/KaTeX_Main-BoldItalic.woff2
/usr/share/com.github.kmwallio.thiefmd/styles/fonts/KaTeX_Main-Italic.ttf
/usr/share/com.github.kmwallio.thiefmd/styles/fonts/KaTeX_Main-Italic.woff
/usr/share/com.github.kmwallio.thiefmd/styles/fonts/KaTeX_Main-Italic.woff2
/usr/share/com.github.kmwallio.thiefmd/styles/fonts/KaTeX_Main-Regular.ttf
/usr/share/com.github.kmwallio.thiefmd/styles/fonts/KaTeX_Main-Regular.woff
/usr/share/com.github.kmwallio.thiefmd/styles/fonts/KaTeX_Main-Regular.woff2
/usr/share/com.github.kmwallio.thiefmd/styles/fonts/KaTeX_Math-BoldItalic.ttf
/usr/share/com.github.kmwallio.thiefmd/styles/fonts/KaTeX_Math-BoldItalic.woff
/usr/share/com.github.kmwallio.thiefmd/styles/fonts/KaTeX_Math-BoldItalic.woff2
/usr/share/com.github.kmwallio.thiefmd/styles/fonts/KaTeX_Math-Italic.ttf
/usr/share/com.github.kmwallio.thiefmd/styles/fonts/KaTeX_Math-Italic.woff
/usr/share/com.github.kmwallio.thiefmd/styles/fonts/KaTeX_Math-Italic.woff2
/usr/share/com.github.kmwallio.thiefmd/styles/fonts/KaTeX_SansSerif-Bold.ttf
/usr/share/com.github.kmwallio.thiefmd/styles/fonts/KaTeX_SansSerif-Bold.woff
/usr/share/com.github.kmwallio.thiefmd/styles/fonts/KaTeX_SansSerif-Bold.woff2
/usr/share/com.github.kmwallio.thiefmd/styles/fonts/KaTeX_SansSerif-Italic.ttf
/usr/share/com.github.kmwallio.thiefmd/styles/fonts/KaTeX_SansSerif-Italic.woff
/usr/share/com.github.kmwallio.thiefmd/styles/fonts/KaTeX_SansSerif-Italic.woff2
/usr/share/com.github.kmwallio.thiefmd/styles/fonts/KaTeX_SansSerif-Regular.ttf
/usr/share/com.github.kmwallio.thiefmd/styles/fonts/KaTeX_SansSerif-Regular.woff
/usr/share/com.github.kmwallio.thiefmd/styles/fonts/KaTeX_SansSerif-Regular.woff2
/usr/share/com.github.kmwallio.thiefmd/styles/fonts/KaTeX_Script-Regular.ttf
/usr/share/com.github.kmwallio.thiefmd/styles/fonts/KaTeX_Script-Regular.woff
/usr/share/com.github.kmwallio.thiefmd/styles/fonts/KaTeX_Script-Regular.woff2
/usr/share/com.github.kmwallio.thiefmd/styles/fonts/KaTeX_Size1-Regular.ttf
/usr/share/com.github.kmwallio.thiefmd/styles/fonts/KaTeX_Size1-Regular.woff
/usr/share/com.github.kmwallio.thiefmd/styles/fonts/KaTeX_Size1-Regular.woff2
/usr/share/com.github.kmwallio.thiefmd/styles/fonts/KaTeX_Size2-Regular.ttf
/usr/share/com.github.kmwallio.thiefmd/styles/fonts/KaTeX_Size2-Regular.woff
/usr/share/com.github.kmwallio.thiefmd/styles/fonts/KaTeX_Size2-Regular.woff2
/usr/share/com.github.kmwallio.thiefmd/styles/fonts/KaTeX_Size3-Regular.ttf
/usr/share/com.github.kmwallio.thiefmd/styles/fonts/KaTeX_Size3-Regular.woff
/usr/share/com.github.kmwallio.thiefmd/styles/fonts/KaTeX_Size3-Regular.woff2
/usr/share/com.github.kmwallio.thiefmd/styles/fonts/KaTeX_Size4-Regular.ttf
/usr/share/com.github.kmwallio.thiefmd/styles/fonts/KaTeX_Size4-Regular.woff
/usr/share/com.github.kmwallio.thiefmd/styles/fonts/KaTeX_Size4-Regular.woff2
/usr/share/com.github.kmwallio.thiefmd/styles/fonts/KaTeX_Typewriter-Regular.ttf
/usr/share/com.github.kmwallio.thiefmd/styles/fonts/KaTeX_Typewriter-Regular.woff
/usr/share/com.github.kmwallio.thiefmd/styles/fonts/KaTeX_Typewriter-Regular.woff2
/usr/share/com.github.kmwallio.thiefmd/styles/highlight.css
/usr/share/com.github.kmwallio.thiefmd/styles/katex.min.css

%changelog
* Thu Sep 03 2020 kmwallio <kmwallio@gmail.com> - 
- Fix preview issues
