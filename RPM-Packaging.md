# Packaging for Fedora

Update `meson.build` to include:

```
rpm = import('rpm')
rpm.generate_spec_template()
```

Update the `com.github.kmwallio.thiefmd.spec`

## Building

1. In the build directory, run `meson dist`. [^m-dist]
2. Copy the `meson-dist/com.github.kmwallio.thiefmd-version.tar.xz` to `~/rpmbuild/SOURCES/`
3. Run the build `rpmbuild -bb com.github.kmwallio.thiefmd.spec` from the build directory.
4. Release resulting rpm from `~/rpmbuild/RPMS`.

[^m-dist]:https://mesonbuild.com/Creating-releases.html

## Sample com.github.kmwallio.thiefmd.spec

```
Name: com.github.kmwallio.thiefmd
Version: 0.0.4
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
/usr/lib/debug/usr/bin/com.github.kmwallio.thiefmd-0.0.4-1.fc32.x86_64.debug

%changelog
```