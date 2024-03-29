if get_option('build_tests')

cc = meson.get_compiler('c')

# Find libMarkdown
libmarkdown = dependency('libmarkdown', version: '>= 2.2.1', required: false)
if libmarkdown.found() == false
    cc = meson.get_compiler('c')
    libmarkdown = cc.find_library('libmarkdown', required: true)
endif

# Find linkgrammar
linkgrammar = dependency('liblink-grammar', version: '>= 5.8.0', required: false)
if linkgrammar.found() == false
    cc = meson.get_compiler('c')
    linkgrammar = cc.find_library('liblink-grammar', required: false)
    # and it just keeps going
    if linkgrammar.found() == false
        cc = meson.get_compiler('c')
        linkgrammar = cc.find_library('link-grammar', required: true)
    endif
endif

testing = executable('tests',
    'ThiefTests.vala',
    'ImageExtractionTests.vala',
    'FileManagerTests.vala',
    'MarkdownTests.vala',
    'TestSettings.vala',
    meson.source_root() + '/src/Controllers/Pandoc.vala',
    meson.source_root() + '/src/Controllers/FileManager.vala',
    meson.source_root() + '/src/Controllers/UserData.vala',
    meson.source_root() + '/src/Constants/ThiefProperties.vala',
    meson.source_root() + '/src/Constants/Helpers.vala',
    meson.source_root() + '/src/Enrichments/Grammar.vala',
    dependencies: [
        dependency('gobject-2.0'),
        dependency('gtksourceview-4'),
        dependency('gtk+-3.0'),
        dependency('gtkspell3-3.0'),
        dependency('webkit2gtk-4.1'),
        dependency('json-glib-1.0'),
        dependency('gee-0.8'),
        dependency('libarchive'),
        dependency('libxml-2.0'),
        dependency('libsecret-1'),
        dependency('libhandy-1'),
        libmarkdown,
        linkgrammar
    ],
    vala_args: [
        meson.source_root() + '/vapi/libmarkdown.vapi',
        meson.source_root() + '/vapi/linkgrammar.vapi'
        ],
    install: false
)

test('ThiefTests', testing)

endif
