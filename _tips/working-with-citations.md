---
layout: page
title: Working With Citations
---

# Working with Citations

ThiefMD utilizes [Pandoc's Citation Support](https://pandoc.org/MANUAL.html#citations).

To get started, you'll need a [BibTeX](http://www.bibtex.org) file, and an update to the [YAML Frontmatter](https://pandoc.org/MANUAL.html#extension-yaml_metadata_block). Your project's [YAML](https://yaml.org) will need a `bibliography` attribute.

```yaml
---
title: My Fancy Research Paper
bibliography: references.bib
---
```

ThiefMD will find and locate the `references.bib` file and offer right-click insertion of Citations Labels.

![Right-Click to Insert Citation](https://user-images.githubusercontent.com/132455/112594422-23499d00-8dc6-11eb-8bd6-b6b6bcc28f7f.gif)
