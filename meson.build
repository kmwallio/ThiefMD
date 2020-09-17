# Name our project
project('com.github.kmwallio.thiefmd', ['vala', 'c'],
    version: '0.0.8'
)

# Application ID
thief_app_id = 'com.github.kmwallio.thiefmd'

# Import main lib files
gnome = import('gnome')
i18n = import('i18n')

# Compile the GResources for this project
asresources = gnome.compile_resources(
    'as-resources', 'data/app.gresource.xml',
    source_dir: 'data',
    c_name: 'as'
)

# Set this for convenience
conf = configuration_data()

# Get the package data directory under Meson
pkgdatadir = join_paths([ get_option('prefix'),
                          get_option('datadir'),
                          'com.github.kmwallio.thiefmd' ])

conf.set_quoted('PKGDATADIR', pkgdatadir)
# Generate config.h
conf.set_quoted('GETTEXT_PACKAGE', meson.project_name())
conf.set_quoted('RELEASE_NAME', thief_app_id)
conf.set_quoted('VERSION', meson.project_version())
add_global_arguments('-DDATADIR="' + get_option('datadir') + '"', language: 'c')
configure_file(output: 'config.h', configuration: conf)
config_h_dir = include_directories('.')

# Arguments for C
c_args = [
  '-include', 'config.h',
  '-w'
]

cc = meson.get_compiler('c')

# Find libMarkdown
libmarkdown = dependency('libmarkdown', version: '>= 2.2.1', required: false)
if libmarkdown.found() == false
    cc = meson.get_compiler('c')
    libmarkdown = cc.find_library('libmarkdown', required: true)
endif

# Let's define our executable
add_project_arguments(['--vapidir', join_paths(meson.current_source_dir(), 'vapi')], language: 'vala')
gxml_dep = dependency('gxml-0.18', fallback : [ 'gxml', 'libgxml_dep' ])
ultheme_dep = dependency('ultheme-0.1', fallback : [ 'ultheme', 'libultheme_dep' ])

executable(
    meson.project_name(),
    'src/Application.vala',
    'src/Constants/AppSettings.vala',
    'src/Constants/DragAndDrop.vala',
    'src/Constants/ThiefProperties.vala',
    'src/Constants/Helpers.vala',
    'src/Widgets/About.vala',
    'src/Widgets/HeaderBar.vala',
    'src/Widgets/Sheets.vala',
    'src/Widgets/Sheet.vala',
    'src/Widgets/Editor.vala',
    'src/Widgets/Library.vala',
    'src/Widgets/NewFolder.vala',
    'src/Widgets/NewSheet.vala',
    'src/Widgets/Preferences.vala',
    'src/Widgets/Preview.vala',
    'src/Widgets/PreviewWindow.vala',
    'src/Widgets/PublisherPreviewWindow.vala',
    'src/Widgets/KeyBindings.vala',
    'src/Widgets/QuickPreferences.vala',
    'src/Widgets/ThemeSelector.vala',
    'src/Widgets/DefaultTheme.vala',
    'src/Widgets/ThemePreview.vala',
    'src/Controllers/FileManager.vala',
    'src/Controllers/Dialogs.vala',
    'src/Controllers/SheetManager.vala',
    'src/Controllers/UI.vala',
    'src/Controllers/UserData.vala',
    'src/Controllers/Pandoc.vala',
    asresources,
    c_args: c_args,
    dependencies: [
        dependency('granite'),
        dependency('gobject-2.0'),
        dependency('gtksourceview-3.0'),
        dependency('gtk+-3.0'),
        dependency('gtkspell3-3.0'),
        dependency('webkit2gtk-4.0'),
        dependency('clutter-1.0'),
        dependency('json-glib-1.0'),
        gxml_dep,
        ultheme_dep,
        libmarkdown
    ],
    vala_args: [
        meson.source_root() + '/vapi/config.vapi',
        meson.source_root() + '/vapi/libmarkdown.vapi'
    ],
    install : true
)

# Add in a post install script
meson.add_install_script('meson/post_install.py')

# Add subfolders for Meson to look
subdir('data')
