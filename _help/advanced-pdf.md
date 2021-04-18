---
layout: page
title: Advanced Pdf Generation
---
# Advanced PDF Generation

ThiefMD tries to use the best HTML to PDF generator possible based on your content.

ThiefMD uses:

- [WeasyPrint](https://weasyprint.org)
- [WebKitGTK with Gtk2Pdf](https://webkitgtk.org)
- [Paged.js](https://www.pagedjs.org) (*if installed under /home/user*)

When WeasyPrint or Paged.js generates the PDF, the [@page CSS property](https://developer.mozilla.org/en-US/docs/Web/CSS/@page) can be used[^super-logic].

[^super-logic]: WeasyPrint does not run JavaScript. Paged.js can run JavaScript, but may not calculate image height properly. WebKitGTK with Gtk2Pdf cannot maintain links in the final PDF. ThiefMD prioritizes WeasyPrint, Paged.js, then WebKitGTK with Gtk2Pdf after scanning content. Math or Syntax Highlighting will prevent ThiefMD from using WeasyPrint. Images will prevent Paged.js.

## @page CSS

When using a @page CSS compatible PDF generator, ThiefMD will insert:

```css
@page {
  margin: 1in 1in 1in 1in;
  size: Letter;
}
```

The paper size and margins come from the values set in the Preferences.

This comes before the Export CSS, so the values can be overwritten by the Export CSS. This can create [beautiful PDF's for screen](https://themes.thiefmd.com/2021/04/17/highlighted-headings.html) instead of print.

**Please note**: The @page size should never be overwritten by the Export CSS package.

### A Sample Resume or Newsletter Style

An online resume for download might have backgrounds running to the page edge.

#### Changing Margins

We can overwrite the margins with:

```css
@page {
  margin: 0;
}
```

This allows us to control the padding and margins in the rest of our stylesheet.

#### Styling Headings

#### Two-Column Lists

#### Results

## Installing Paged.js

With [flatpak](), ThiefMD only has access to the user's /home/ directory.

To pickup [Paged.js](https://www.pagedjs.org/documentation/02-getting-started-with-paged-js/#command-line-version), configure [npm to install to the user's home directory](https://github.com/sindresorhus/guides/blob/main/npm-global-without-sudo.md).

Once npm is configure, install Paged.js with:

```bash
npm install -g pagedjs-cli pagedjs
```

---