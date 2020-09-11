# This is a Preview File

<div style="float: left; width: 25%;"><img src="data/icons/128/com.github.kmwallio.thiefmd.svg" /></div>

It will be used for sanity checking the style-sheet used.

*Emphasized* text.

**Strong** text.

[Link to page](https://thiefmd.com)

<div style="clear: both;"></div>

## Lists

1. First item
2. Second item
3. Third item

> Block Quote
> - Famous Amos

* First item
* `Second` item
* Third item

---

```vala
    switch (target_type) {
        case Target.STRING:
            selection_data.set (
                selection_data.get_target(),
                BYTE_BITS,
                (uchar [])_sheet_path.to_utf8());
        break;
        default:
            warning ("No known action to take.");
        break;
    }
```

### Markdown Rendered Image

![](docs/images/matt-hoffman-wheat.jpg)

### HTML Rendered Image

<div><img src="docs/images/matt-hoffman-wheat.jpg" /></div>
 
### Tables

| Syntax | Description |
| ----------- | ----------- |
| Header | Title |
| Paragraph | Text | 

Here's a sentence with a footnote. [^1]

I'm basically ~~stealing~~ copying and pasting examples from [https://www.markdownguide.org/cheat-sheet](https://www.markdownguide.org/cheat-sheet).

[^1]: This is the footnote.

### Math (requires libmarkdown 2.2.0 or greater)

$$\int_{a}^{b} x^2 dx$$
