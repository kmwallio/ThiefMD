if get_option('build_tests')

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

test_common_sources = [
    'TestSettings.vala',
    meson.source_root() + '/src/Controllers/MarkdownCompat.c',
    meson.source_root() + '/src/Controllers/Pandoc.vala',
    meson.source_root() + '/src/Controllers/FileManager.vala',
    meson.source_root() + '/src/Controllers/UserData.vala',
    meson.source_root() + '/src/Constants/ThiefProperties.vala',
    meson.source_root() + '/src/Constants/Helpers.vala',
    meson.source_root() + '/src/Enrichments/Grammar.vala',
]

test_common_dependencies = [
    dependency('gobject-2.0'),
    dependency('gtksourceview-5'),
    dependency('gtk4'),
    dependency('webkitgtk-6.0'),
    dependency('json-glib-1.0'),
    dependency('gee-0.8'),
    dependency('libarchive'),
    dependency('libxml-2.0'),
    dependency('libsecret-1'),
    dependency('libadwaita-1'),
    libmarkdown,
    linkgrammar
]

test_common_vala_args = [
    meson.source_root() + '/vapi/libmarkdown.vapi',
    meson.source_root() + '/vapi/linkgrammar.vapi'
]

testing_all = executable('tests-all',
    [
        'ThiefTests.vala',
        'ImageExtractionTests.vala',
        'FileManagerTests.vala',
        'MarkdownTests.vala',
        'MarkerNavigationTests.vala',
        'HelpersTests.vala',
        'PandocTests.vala',
    ] + test_common_sources,
    dependencies: test_common_dependencies,
    vala_args: test_common_vala_args,
    install: false
)

testing_image = executable('tests-image-extraction',
    [
        'TestMainImageExtraction.vala',
        'ImageExtractionTests.vala',
    ] + test_common_sources,
    dependencies: test_common_dependencies,
    vala_args: test_common_vala_args,
    install: false
)

testing_markdown = executable('tests-markdown',
    [
        'TestMainMarkdown.vala',
        'MarkdownTests.vala',
    ] + test_common_sources,
    dependencies: test_common_dependencies,
    vala_args: test_common_vala_args,
    install: false
)

testing_marker_navigation = executable('tests-marker-navigation',
    [
        'TestMainMarkerNavigation.vala',
        'MarkerNavigationTests.vala',
    ] + test_common_sources,
    dependencies: test_common_dependencies,
    vala_args: test_common_vala_args,
    install: false
)

testing_file_manager = executable('tests-file-manager',
    [
        'TestMainFileManager.vala',
        'FileManagerTests.vala',
    ] + test_common_sources,
    dependencies: test_common_dependencies,
    vala_args: test_common_vala_args,
    install: false
)

testing_helpers = executable('tests-helpers',
    [
        'TestMainHelpers.vala',
        'HelpersTests.vala',
    ] + test_common_sources,
    dependencies: test_common_dependencies,
    vala_args: test_common_vala_args,
    install: false
)

testing_pandoc = executable('tests-pandoc',
    [
        'TestMainPandoc.vala',
        'PandocTests.vala',
    ] + test_common_sources,
    dependencies: test_common_dependencies,
    vala_args: test_common_vala_args,
    install: false
)

test('ThiefTests-All', testing_all, is_parallel: false)
test('ThiefTests-ImageExtraction', testing_image, is_parallel: false)
test('ThiefTests-Markdown', testing_markdown)
test('ThiefTests-MarkerNavigation', testing_marker_navigation)
test('ThiefTests-FileManager', testing_file_manager)
test('ThiefTests-Helpers', testing_helpers)
test('ThiefTests-Pandoc', testing_pandoc)

endif
