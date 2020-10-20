# Name our project
project('com.github.kmwallio.thiefmd', ['vala', 'c'],
    version: '0.1.2'
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

executable(
    meson.project_name(),
    'src/Application.vala',
    'src/Constants/AppSettings.vala',
    'src/Constants/DragAndDrop.vala',
    'src/Constants/ThiefProperties.vala',
    'src/Constants/Helpers.vala',
    'src/Controllers/FileManager.vala',
    'src/Controllers/Dialogs.vala',
    'src/Controllers/SheetManager.vala',
    'src/Controllers/UI.vala',
    'src/Controllers/UserData.vala',
    'src/Controllers/Pandoc.vala',
    'src/Controllers/Exporters.vala',
    'src/Connections/ConnectionBase.vala',
    'src/Connections/WriteasConnection.vala',
    'src/Exporters/ExportBase.vala',
    'src/Exporters/ExportDocx.vala',
    'src/Exporters/ExportEpub.vala',
    'src/Exporters/ExportHtml.vala',
    'src/Exporters/ExportLatex.vala',
    'src/Exporters/ExportMarkdown.vala',
    'src/Exporters/ExportMhtml.vala',
    'src/Exporters/ExportPdf.vala',
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
    'src/Widgets/ProjectStatistics.vala',
    'src/Widgets/QuickPreferences.vala',
    'src/Widgets/ThemeSelector.vala',
    'src/Widgets/DefaultTheme.vala',
    'src/Widgets/SearchBar.vala',
    'src/Widgets/StatisticsBar.vala',
    'src/Widgets/SearchWindow.vala',
    'src/Widgets/ThiefPane.vala',
    'src/Widgets/ThemePreview.vala',
    'src/Widgets/Thinking.vala',
    'src/Widgets/MarkdownCheatSheet.vala',
    'src/ultheme/src/HexColors.vala',
    'src/ultheme/src/Ultheme.vala',
    'src/writegood/src/language.vala',
    'src/writegood/src/writegood.vala',
    'src/writegood/src/en_us.vala',
    'src/writeas/src/Writeas.vala',
    asresources,
    c_args: c_args,
    dependencies: [
        dependency('gobject-2.0'),
        dependency('gtksourceview-4'),
        dependency('gtk+-3.0'),
        dependency('gtkspell3-3.0'),
        dependency('webkit2gtk-4.0'),
        dependency('clutter-1.0'),
        dependency('json-glib-1.0'),
        dependency('gee-0.8'),
        dependency('libarchive'),
        dependency('libxml-2.0'),
        dependency('libsecret-1'),
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
