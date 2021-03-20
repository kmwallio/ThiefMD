Name: com.github.kmwallio.thiefmd
Version: 0.1.8
Release: 1%{?dist}
Summary: The markdown editor worth stealing.
License: GPL-3.0+
URL: https://thiefmd.com

Source0: %{name}-%{version}.tar.xz
Source1: data/%{name}.appdata.xml

Requires: pandoc
BuildRequires: meson
BuildRequires: vala
BuildRequires: gcc
BuildRequires: pkgconfig(libmarkdown)
BuildRequires: pkgconfig(libxml-2.0)
BuildRequires: pkgconfig(gio-2.0)
BuildRequires: pkgconfig(gee-0.8)
BuildRequires: pkgconfig(glib-2.0)
BuildRequires: pkgconfig(gobject-2.0)
BuildRequires: pkgconfig(libarchive)
BuildRequires: pkgconfig(libsecret-1)
BuildRequires: pkgconfig(clutter-1.0)
BuildRequires: pkgconfig(gtksourceview-3.0)
BuildRequires: pkgconfig(gtk+-3.0)
BuildRequires: pkgconfig(gtkspell3-3.0)
BuildRequires: pkgconfig(webkit2gtk-4.0)
BuildRequires: pkgconfig(libhandy-1)

%description
Keep your Markdown managed. Write epic tales, keep a journal, or finally write that book report.
ThiefMD is a Markdown Editor providing an easy way to organize your markdown documents.

%package devel
Summary: Development files for %{name}
Requires: %{name}%{?_isa} = %{?epoch:%{epoch}:}{version}-%{release}

%description devel
Development files for %{name}.

%prep
%autosetup

%build
%meson
%meson_build

%install
%meson_install
rm -vf %{buildroot}%{_libdir}/libultheme.a

%check
%meson_test

%files
%{_bindir}/com.github.kmwallio.thiefmd
/usr/share/applications/com.github.kmwallio.thiefmd.desktop
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
/usr/share/com.github.kmwallio.thiefmd/styles/preview.css
/usr/share/fonts/truetype/thiefmd/iAWriterDuospace-Regular.ttf
/usr/share/glib-2.0/schemas/com.github.kmwallio.thiefmd.gschema.xml
/usr/share/gtksourceview-4/styles/thiefmd.xml
/usr/share/icons/hicolor/128x128/apps/com.github.kmwallio.thiefmd.svg
/usr/share/icons/hicolor/48x48/apps/com.github.kmwallio.thiefmd.svg
/usr/share/icons/hicolor/64x64/apps/com.github.kmwallio.thiefmd.svg
/usr/share/icons/hicolor/symbolicxsymbolic/apps/com.github.kmwallio.thiefmd.svg
/usr/share/metainfo/com.github.kmwallio.thiefmd.appdata.xml
/usr/share/com.github.kmwallio.thiefmd/gtksourceview-4/language-specs/css.lang
/usr/share/com.github.kmwallio.thiefmd/gtksourceview-4/language-specs/def.lang
/usr/share/com.github.kmwallio.thiefmd/gtksourceview-4/language-specs/dtd.lang
/usr/share/com.github.kmwallio.thiefmd/gtksourceview-4/language-specs/dtl.lang
/usr/share/com.github.kmwallio.thiefmd/gtksourceview-4/language-specs/html.lang
/usr/share/com.github.kmwallio.thiefmd/gtksourceview-4/language-specs/javascript-expressions.lang
/usr/share/com.github.kmwallio.thiefmd/gtksourceview-4/language-specs/javascript-functions-classes.lang
/usr/share/com.github.kmwallio.thiefmd/gtksourceview-4/language-specs/javascript-literals.lang
/usr/share/com.github.kmwallio.thiefmd/gtksourceview-4/language-specs/javascript-modules.lang
/usr/share/com.github.kmwallio.thiefmd/gtksourceview-4/language-specs/javascript-statements.lang
/usr/share/com.github.kmwallio.thiefmd/gtksourceview-4/language-specs/javascript-values.lang
/usr/share/com.github.kmwallio.thiefmd/gtksourceview-4/language-specs/javascript.lang
/usr/share/com.github.kmwallio.thiefmd/gtksourceview-4/language-specs/jsdoc.lang
/usr/share/com.github.kmwallio.thiefmd/gtksourceview-4/language-specs/json.lang
/usr/share/com.github.kmwallio.thiefmd/gtksourceview-4/language-specs/language-specs.its
/usr/share/com.github.kmwallio.thiefmd/gtksourceview-4/language-specs/language-specs.pot
/usr/share/com.github.kmwallio.thiefmd/gtksourceview-4/language-specs/language.dtd
/usr/share/com.github.kmwallio.thiefmd/gtksourceview-4/language-specs/language.rng
/usr/share/com.github.kmwallio.thiefmd/gtksourceview-4/language-specs/language2.rng
/usr/share/com.github.kmwallio.thiefmd/gtksourceview-4/language-specs/latex.lang
/usr/share/com.github.kmwallio.thiefmd/gtksourceview-4/language-specs/markdown.lang
/usr/share/com.github.kmwallio.thiefmd/gtksourceview-4/language-specs/rst.lang
/usr/share/com.github.kmwallio.thiefmd/gtksourceview-4/language-specs/xml.lang
/usr/share/com.github.kmwallio.thiefmd/gtksourceview-4/language-specs/xslt.lang
/usr/share/com.github.kmwallio.thiefmd/gtksourceview-4/language-specs/yaml.lang
/usr/share/icons/hicolor/32x32/apps/com.github.kmwallio.thiefmd.svg
/usr/share/com.github.kmwallio.thiefmd/gtksourceview-4/language-specs/R.lang
/usr/share/com.github.kmwallio.thiefmd/gtksourceview-4/language-specs/abnf.lang
/usr/share/com.github.kmwallio.thiefmd/gtksourceview-4/language-specs/actionscript.lang
/usr/share/com.github.kmwallio.thiefmd/gtksourceview-4/language-specs/ada.lang
/usr/share/com.github.kmwallio.thiefmd/gtksourceview-4/language-specs/ansforth94.lang
/usr/share/com.github.kmwallio.thiefmd/gtksourceview-4/language-specs/asciidoc.lang
/usr/share/com.github.kmwallio.thiefmd/gtksourceview-4/language-specs/asp.lang
/usr/share/com.github.kmwallio.thiefmd/gtksourceview-4/language-specs/automake.lang
/usr/share/com.github.kmwallio.thiefmd/gtksourceview-4/language-specs/awk.lang
/usr/share/com.github.kmwallio.thiefmd/gtksourceview-4/language-specs/bennugd.lang
/usr/share/com.github.kmwallio.thiefmd/gtksourceview-4/language-specs/bibtex.lang
/usr/share/com.github.kmwallio.thiefmd/gtksourceview-4/language-specs/bluespec.lang
/usr/share/com.github.kmwallio.thiefmd/gtksourceview-4/language-specs/boo.lang
/usr/share/com.github.kmwallio.thiefmd/gtksourceview-4/language-specs/c.lang
/usr/share/com.github.kmwallio.thiefmd/gtksourceview-4/language-specs/cg.lang
/usr/share/com.github.kmwallio.thiefmd/gtksourceview-4/language-specs/changelog.lang
/usr/share/com.github.kmwallio.thiefmd/gtksourceview-4/language-specs/chdr.lang
/usr/share/com.github.kmwallio.thiefmd/gtksourceview-4/language-specs/check-language.sh
/usr/share/com.github.kmwallio.thiefmd/gtksourceview-4/language-specs/cmake.lang
/usr/share/com.github.kmwallio.thiefmd/gtksourceview-4/language-specs/cobol.lang
/usr/share/com.github.kmwallio.thiefmd/gtksourceview-4/language-specs/commonlisp.lang
/usr/share/com.github.kmwallio.thiefmd/gtksourceview-4/language-specs/cpp.lang
/usr/share/com.github.kmwallio.thiefmd/gtksourceview-4/language-specs/cpphdr.lang
/usr/share/com.github.kmwallio.thiefmd/gtksourceview-4/language-specs/csharp.lang
/usr/share/com.github.kmwallio.thiefmd/gtksourceview-4/language-specs/csv.lang
/usr/share/com.github.kmwallio.thiefmd/gtksourceview-4/language-specs/cuda.lang
/usr/share/com.github.kmwallio.thiefmd/gtksourceview-4/language-specs/d.lang
/usr/share/com.github.kmwallio.thiefmd/gtksourceview-4/language-specs/dart.lang
/usr/share/com.github.kmwallio.thiefmd/gtksourceview-4/language-specs/desktop.lang
/usr/share/com.github.kmwallio.thiefmd/gtksourceview-4/language-specs/diff.lang
/usr/share/com.github.kmwallio.thiefmd/gtksourceview-4/language-specs/docbook.lang
/usr/share/com.github.kmwallio.thiefmd/gtksourceview-4/language-specs/docker.lang
/usr/share/com.github.kmwallio.thiefmd/gtksourceview-4/language-specs/dosbatch.lang
/usr/share/com.github.kmwallio.thiefmd/gtksourceview-4/language-specs/dot.lang
/usr/share/com.github.kmwallio.thiefmd/gtksourceview-4/language-specs/dpatch.lang
/usr/share/com.github.kmwallio.thiefmd/gtksourceview-4/language-specs/eiffel.lang
/usr/share/com.github.kmwallio.thiefmd/gtksourceview-4/language-specs/erb-html.lang
/usr/share/com.github.kmwallio.thiefmd/gtksourceview-4/language-specs/erb-js.lang
/usr/share/com.github.kmwallio.thiefmd/gtksourceview-4/language-specs/erb.lang
/usr/share/com.github.kmwallio.thiefmd/gtksourceview-4/language-specs/erlang.lang
/usr/share/com.github.kmwallio.thiefmd/gtksourceview-4/language-specs/fcl.lang
/usr/share/com.github.kmwallio.thiefmd/gtksourceview-4/language-specs/fish.lang
/usr/share/com.github.kmwallio.thiefmd/gtksourceview-4/language-specs/forth.lang
/usr/share/com.github.kmwallio.thiefmd/gtksourceview-4/language-specs/fortran.lang
/usr/share/com.github.kmwallio.thiefmd/gtksourceview-4/language-specs/fsharp.lang
/usr/share/com.github.kmwallio.thiefmd/gtksourceview-4/language-specs/ftl.lang
/usr/share/com.github.kmwallio.thiefmd/gtksourceview-4/language-specs/gap.lang
/usr/share/com.github.kmwallio.thiefmd/gtksourceview-4/language-specs/gdb-log.lang
/usr/share/com.github.kmwallio.thiefmd/gtksourceview-4/language-specs/gdscript.lang
/usr/share/com.github.kmwallio.thiefmd/gtksourceview-4/language-specs/genie.lang
/usr/share/com.github.kmwallio.thiefmd/gtksourceview-4/language-specs/glsl.lang
/usr/share/com.github.kmwallio.thiefmd/gtksourceview-4/language-specs/go.lang
/usr/share/com.github.kmwallio.thiefmd/gtksourceview-4/language-specs/gradle.lang
/usr/share/com.github.kmwallio.thiefmd/gtksourceview-4/language-specs/groovy.lang
/usr/share/com.github.kmwallio.thiefmd/gtksourceview-4/language-specs/gtk-doc.lang
/usr/share/com.github.kmwallio.thiefmd/gtksourceview-4/language-specs/gtkrc.lang
/usr/share/com.github.kmwallio.thiefmd/gtksourceview-4/language-specs/haddock.lang
/usr/share/com.github.kmwallio.thiefmd/gtksourceview-4/language-specs/haskell-literate.lang
/usr/share/com.github.kmwallio.thiefmd/gtksourceview-4/language-specs/haskell.lang
/usr/share/com.github.kmwallio.thiefmd/gtksourceview-4/language-specs/haxe.lang
/usr/share/com.github.kmwallio.thiefmd/gtksourceview-4/language-specs/idl-exelis.lang
/usr/share/com.github.kmwallio.thiefmd/gtksourceview-4/language-specs/idl.lang
/usr/share/com.github.kmwallio.thiefmd/gtksourceview-4/language-specs/imagej.lang
/usr/share/com.github.kmwallio.thiefmd/gtksourceview-4/language-specs/ini.lang
/usr/share/com.github.kmwallio.thiefmd/gtksourceview-4/language-specs/j.lang
/usr/share/com.github.kmwallio.thiefmd/gtksourceview-4/language-specs/jade.lang
/usr/share/com.github.kmwallio.thiefmd/gtksourceview-4/language-specs/java.lang
/usr/share/com.github.kmwallio.thiefmd/gtksourceview-4/language-specs/jsx.lang
/usr/share/com.github.kmwallio.thiefmd/gtksourceview-4/language-specs/julia.lang
/usr/share/com.github.kmwallio.thiefmd/gtksourceview-4/language-specs/kotlin.lang
/usr/share/com.github.kmwallio.thiefmd/gtksourceview-4/language-specs/lang_v1_to_v2.xslt
/usr/share/com.github.kmwallio.thiefmd/gtksourceview-4/language-specs/less.lang
/usr/share/com.github.kmwallio.thiefmd/gtksourceview-4/language-specs/lex.lang
/usr/share/com.github.kmwallio.thiefmd/gtksourceview-4/language-specs/libtool.lang
/usr/share/com.github.kmwallio.thiefmd/gtksourceview-4/language-specs/llvm.lang
/usr/share/com.github.kmwallio.thiefmd/gtksourceview-4/language-specs/logcat.lang
/usr/share/com.github.kmwallio.thiefmd/gtksourceview-4/language-specs/logtalk.lang
/usr/share/com.github.kmwallio.thiefmd/gtksourceview-4/language-specs/lua.lang
/usr/share/com.github.kmwallio.thiefmd/gtksourceview-4/language-specs/m4.lang
/usr/share/com.github.kmwallio.thiefmd/gtksourceview-4/language-specs/makefile.lang
/usr/share/com.github.kmwallio.thiefmd/gtksourceview-4/language-specs/mallard.lang
/usr/share/com.github.kmwallio.thiefmd/gtksourceview-4/language-specs/matlab.lang
/usr/share/com.github.kmwallio.thiefmd/gtksourceview-4/language-specs/maxima.lang
/usr/share/com.github.kmwallio.thiefmd/gtksourceview-4/language-specs/mdb.lang
/usr/share/com.github.kmwallio.thiefmd/gtksourceview-4/language-specs/mediawiki.lang
/usr/share/com.github.kmwallio.thiefmd/gtksourceview-4/language-specs/meson.lang
/usr/share/com.github.kmwallio.thiefmd/gtksourceview-4/language-specs/modelica.lang
/usr/share/com.github.kmwallio.thiefmd/gtksourceview-4/language-specs/mxml.lang
/usr/share/com.github.kmwallio.thiefmd/gtksourceview-4/language-specs/nemerle.lang
/usr/share/com.github.kmwallio.thiefmd/gtksourceview-4/language-specs/netrexx.lang
/usr/share/com.github.kmwallio.thiefmd/gtksourceview-4/language-specs/nsis.lang
/usr/share/com.github.kmwallio.thiefmd/gtksourceview-4/language-specs/objc.lang
/usr/share/com.github.kmwallio.thiefmd/gtksourceview-4/language-specs/objj.lang
/usr/share/com.github.kmwallio.thiefmd/gtksourceview-4/language-specs/ocaml.lang
/usr/share/com.github.kmwallio.thiefmd/gtksourceview-4/language-specs/ocl.lang
/usr/share/com.github.kmwallio.thiefmd/gtksourceview-4/language-specs/octave.lang
/usr/share/com.github.kmwallio.thiefmd/gtksourceview-4/language-specs/ooc.lang
/usr/share/com.github.kmwallio.thiefmd/gtksourceview-4/language-specs/opal.lang
/usr/share/com.github.kmwallio.thiefmd/gtksourceview-4/language-specs/opencl.lang
/usr/share/com.github.kmwallio.thiefmd/gtksourceview-4/language-specs/pascal.lang
/usr/share/com.github.kmwallio.thiefmd/gtksourceview-4/language-specs/perl.lang
/usr/share/com.github.kmwallio.thiefmd/gtksourceview-4/language-specs/php.lang
/usr/share/com.github.kmwallio.thiefmd/gtksourceview-4/language-specs/pig.lang
/usr/share/com.github.kmwallio.thiefmd/gtksourceview-4/language-specs/pkgconfig.lang
/usr/share/com.github.kmwallio.thiefmd/gtksourceview-4/language-specs/po.lang
/usr/share/com.github.kmwallio.thiefmd/gtksourceview-4/language-specs/powershell.lang
/usr/share/com.github.kmwallio.thiefmd/gtksourceview-4/language-specs/prolog.lang
/usr/share/com.github.kmwallio.thiefmd/gtksourceview-4/language-specs/protobuf.lang
/usr/share/com.github.kmwallio.thiefmd/gtksourceview-4/language-specs/puppet.lang
/usr/share/com.github.kmwallio.thiefmd/gtksourceview-4/language-specs/python.lang
/usr/share/com.github.kmwallio.thiefmd/gtksourceview-4/language-specs/python3.lang
/usr/share/com.github.kmwallio.thiefmd/gtksourceview-4/language-specs/rpmspec.lang
/usr/share/com.github.kmwallio.thiefmd/gtksourceview-4/language-specs/ruby.lang
/usr/share/com.github.kmwallio.thiefmd/gtksourceview-4/language-specs/rust.lang
/usr/share/com.github.kmwallio.thiefmd/gtksourceview-4/language-specs/scala.lang
/usr/share/com.github.kmwallio.thiefmd/gtksourceview-4/language-specs/scheme.lang
/usr/share/com.github.kmwallio.thiefmd/gtksourceview-4/language-specs/scilab.lang
/usr/share/com.github.kmwallio.thiefmd/gtksourceview-4/language-specs/scss.lang
/usr/share/com.github.kmwallio.thiefmd/gtksourceview-4/language-specs/sh.lang
/usr/share/com.github.kmwallio.thiefmd/gtksourceview-4/language-specs/sml.lang
/usr/share/com.github.kmwallio.thiefmd/gtksourceview-4/language-specs/solidity.lang
/usr/share/com.github.kmwallio.thiefmd/gtksourceview-4/language-specs/sparql.lang
/usr/share/com.github.kmwallio.thiefmd/gtksourceview-4/language-specs/sql.lang
/usr/share/com.github.kmwallio.thiefmd/gtksourceview-4/language-specs/sweave.lang
/usr/share/com.github.kmwallio.thiefmd/gtksourceview-4/language-specs/swift.lang
/usr/share/com.github.kmwallio.thiefmd/gtksourceview-4/language-specs/systemverilog.lang
/usr/share/com.github.kmwallio.thiefmd/gtksourceview-4/language-specs/t2t.lang
/usr/share/com.github.kmwallio.thiefmd/gtksourceview-4/language-specs/tcl.lang
/usr/share/com.github.kmwallio.thiefmd/gtksourceview-4/language-specs/tera.lang
/usr/share/com.github.kmwallio.thiefmd/gtksourceview-4/language-specs/testv1.lang
/usr/share/com.github.kmwallio.thiefmd/gtksourceview-4/language-specs/texinfo.lang
/usr/share/com.github.kmwallio.thiefmd/gtksourceview-4/language-specs/thrift.lang
/usr/share/com.github.kmwallio.thiefmd/gtksourceview-4/language-specs/toml.lang
/usr/share/com.github.kmwallio.thiefmd/gtksourceview-4/language-specs/typescript-js-expressions.lang
/usr/share/com.github.kmwallio.thiefmd/gtksourceview-4/language-specs/typescript-js-functions-classes.lang
/usr/share/com.github.kmwallio.thiefmd/gtksourceview-4/language-specs/typescript-js-literals.lang
/usr/share/com.github.kmwallio.thiefmd/gtksourceview-4/language-specs/typescript-js-modules.lang
/usr/share/com.github.kmwallio.thiefmd/gtksourceview-4/language-specs/typescript-js-statements.lang
/usr/share/com.github.kmwallio.thiefmd/gtksourceview-4/language-specs/typescript-jsx.lang
/usr/share/com.github.kmwallio.thiefmd/gtksourceview-4/language-specs/typescript-type-expressions.lang
/usr/share/com.github.kmwallio.thiefmd/gtksourceview-4/language-specs/typescript-type-generics.lang
/usr/share/com.github.kmwallio.thiefmd/gtksourceview-4/language-specs/typescript-type-literals.lang
/usr/share/com.github.kmwallio.thiefmd/gtksourceview-4/language-specs/typescript.lang
/usr/share/com.github.kmwallio.thiefmd/gtksourceview-4/language-specs/ue2gsv.pl
/usr/share/com.github.kmwallio.thiefmd/gtksourceview-4/language-specs/update-pot.sh
/usr/share/com.github.kmwallio.thiefmd/gtksourceview-4/language-specs/vala.lang
/usr/share/com.github.kmwallio.thiefmd/gtksourceview-4/language-specs/vbnet.lang
/usr/share/com.github.kmwallio.thiefmd/gtksourceview-4/language-specs/verilog.lang
/usr/share/com.github.kmwallio.thiefmd/gtksourceview-4/language-specs/vhdl.lang
/usr/share/com.github.kmwallio.thiefmd/gtksourceview-4/language-specs/yacc.lang
/usr/share/com.github.kmwallio.thiefmd/gtksourceview-4/language-specs/yara.lang
"/usr/share/fonts/truetype/thiefmd/Courier Prime-Bold.ttf"
"/usr/share/fonts/truetype/thiefmd/Courier Prime-BoldItalic.ttf"
"/usr/share/fonts/truetype/thiefmd/Courier Prime-Italic.ttf"
"/usr/share/fonts/truetype/thiefmd/Courier Prime-Regular.ttf"
/usr/share/fonts/truetype/thiefmd/iAWriterDuospace-Bold.ttf
/usr/share/fonts/truetype/thiefmd/iAWriterDuospace-BoldItalic.ttf
/usr/share/fonts/truetype/thiefmd/iAWriterDuospace-Italic.ttf
/usr/share/com.github.kmwallio.thiefmd/gtksourceview-4/language-specs/README.md
/usr/share/locale/en_GB/LC_MESSAGES/com.github.kmwallio.thiefmd.mo
/usr/share/locale/es/LC_MESSAGES/com.github.kmwallio.thiefmd.mo
/usr/share/locale/fr/LC_MESSAGES/com.github.kmwallio.thiefmd.mo
/usr/share/locale/sk/LC_MESSAGES/com.github.kmwallio.thiefmd.mo
/usr/share/locale/sv/LC_MESSAGES/com.github.kmwallio.thiefmd.mo

%post -p /sbin/ldconfig
%postun -p /sbin/ldconfig

%changelog
* Sun Mar 13 2021 kmwallio <mwallio@gmail.com> - 0.1.7
- Snap.as image upload support
- WordPress featured image support
- Performance improvements for experimental mode
* Fri Mar 05 2021 kmwallio <mwallio@gmail.com> - 0.1.6
- Wordpress Export is now available, just add a Connection
- Recessed headers
- Small tweaks and improvements have been made to speed up the UI
- Experimental mode to hide markdown links in the editor
* Sun Feb 28 2021 kmwallio <mwallio@gmail.com> - 0.1.5
- Added a shortcut for inserting in a link
- Editor enhancements for continuing lists
- Tab will skip over select Markdown formatting so you can tab back into focus
* Sun Feb 07 2021 kmwallio <mwallio@gmail.com> - 0.1.4
- Added French Translation from David Bosman
- Added Slovak Translation from Marek L'ach
- Added ability to increase line spacing in editor
- Hope your 2021 is going well so far!
* Sun Dec 06 2020 kmwallio <mwallio@gmail.com> - 0.1.3
- Initial steps towards supporting mobile
- Fixes some graphical issues when hiding toolbar
- Toolbar now available in fullscreen, hide with `Ctrl+Shift+H`
- Adding click actions to support mobile devices
* Fri Oct 23 2020 kmwallio <mwallio@gmail.com> - 0.1.2
- Export to a WriteFreely instance
- Export to a Ghost blog
- Font sizes are consistent with your other apps
- Revised preferences to prevent strechted out elements
- Write-Good now shows as tool tips
* Fri Oct 16 2020 kmwallio <mwallio@gmail.com> - 0.1.1
- Improved search interface
- Support for dragging certain files onto the editor (including CSV to Markdown table)
- Ability to cusomize font
- Ability to hide Headerbar
- Focus Mode
- Misc Improvements
* Sat Oct 10 2020 kmwallio <mwallio@gmail.com> - 0.1.0
- Import DocX, ePUB, HTML, and more, just drag the file onto a library folder
- New Export Tool, change CSS, Page Size, and more
- Library Search and Editor Search
- Writing Statistics
* Mon Oct 05 2020 kmwallio <mwallio@gmail.com> - 0.0.12
- Update Dynamic CSS to include buttons and button hover
- Determine light/dark based on luminance of editor theme
- Add option to hide titles/go brandless
- Add link to new themes site with original ThiefMD themes
- Fix typos
* Thu Oct 01 2020 kmwallio <mwallio@gmail.com> - 0.0.11
- Write-Good support for writing suggestions
* Tue Sep 29 2020 kmwallio <mwallio@gmail.com> - 0.0.10
- Default to User's GTK Theme
- Certain well-known hidden folders persist between restarts
- Image path resolution for cover-image in ePub YAML front-matter
* Fri Sep 18 2020 kmwallio <mwallio@gmail.com> - 0.0.9
- This release is a bug fix release
- Fix bug when trying to export with no file selected
- Select first folder added to Library
- Show error when unable to export file
* Thu Sep 17 2020 kmwallio <mwallio@gmail.com> - 0.0.8
- Pandoc Export
- More PDF Export options
- Shortcut keys
- Better undo management
* Sun Sep 13 2020 kmwallio <mwallio@gmail.com> - 0.0.7
- Library Reordering
- Sheets Reordering
- Library Export
* Wed Sep 09 2020 kmwallio <mwallio@gmail.com> - 0.0.6
- Adding theme support
- Improve UI for About and Preferences
- Fix a bug in Editor only view
* Thu Sep 03 2020 kmwallio <mwallio@gmail.com> - 0.0.5
- Fix bug with () rendering
- Add Syntax Highlighting and KaTeX
* Wed Sep 02 2020 kmwallio <mwallio@gmail.com> - 0.0.4
- Drag and Drop Support for moving sheets in library
- Blogging centric features