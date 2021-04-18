---
layout: page
title: Export Styles
---

# ThiefMD Export Styles

Want more control over the live preview and export options? Then creating an export style package is the way to go.

It sounds complicated, but it's just a [ZIP](https://en.wikipedia.org/wiki/Zip_(file_format)) file with at least 1 [CSS file](https://en.wikipedia.org/wiki/CSS) in it. You can find some samples at [https://themes.thiefmd.com/export-css](https://themes.thiefmd.com/export-css).

## Export Package Contents

The zip file can contain:

* print.css
* preview.css

### Print.css

Will be used for PDF export. There's no need to use `@media print`, ThiefMD will insert and format the CSS for you. This will also allow ThiefMD to render a preview as accurately as it can.

When [WeasyPrint](https://weasyprint.org) generates the PDF, the [@page CSS](https://developer.mozilla.org/en-US/docs/Web/CSS/@page) can be used. See [advanced PDF CSS](/help/advanced-pdf).

### Preview.css

Preview.css specifies the CSS to use for [ePUB](https://en.wikipedia.org/wiki/EPUB) export and the Live Preview.

### Minimum CSS

This is an example of styling all the possible [standard Markdown](https://daringfireball.net/projects/markdown/syntax) elements.

You can use the same CSS for both the `print.css` and `preview.css`.

```css
html {
  font-size: 16px;
}

body {
  color: #000;
  font-family: serif;
  margin: 0;
  max-width: 100%;
}

h1 {
  font-size: 4rem;
}

h2 {
  font-size: 3rem;
}

h3 {
  font-size: 2rem;
}

h4 {
  font-size: 1.5rem;
}

h5 {
  font-size: 1.2rem;
}

h6 {
  font-size: 1rem;
}

small {
  font-size: .75em;
}

p {
  font-size: 1rem;
}

blockquote p {
  font-style: italic;
  margin: 1rem auto 1rem;
}

pre,
code {
  font-family: monospace;
}

pre {
  line-height: 1.25;
}

img {
  max-width: 100%;
}
```

### Adding Page breaks

By default, ThiefMD allows users to configure page breaks in the Preferences (`Ctrl+,`). This allows for the user to control some formatting without modifying CSS, but doesn't provide much power. If `# Heading 1` means a new Chapter on a new Page for you, you could add to your CSS:

```css
h1 {
  page-break-before: always;
}
```

This will result in `# Heading 1` to always start a new page.

If you always want code to be on it's own sample page, you could similarly do:

```css
code {
  page-break-before: always;
  page-break-after: always;
}
```
