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
        private bool writecheck_scheduled = false;
        private void write_good_recheck () {
            if (writegood_limit.can_do_action () && writecheck_active) {
                writegood.recheck_all ();
            } else if (writecheck_active) {
                if (!writecheck_scheduled) {
                    writecheck_scheduled = true;
                    Timeout.add (1500, () => {
                        if (writecheck_active) {
                            writegood.recheck_all ();
                        }
                        writecheck_scheduled = false;
                        return false;
                    });
                }
            }
        }
```

### Markdown Rendered Image

![](/images/matt-hoffman-wheat.jpg)

### HTML Rendered Image

<div><img src="/images/matt-hoffman-wheat.jpg" /></div>

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

$$f(x)=a_0+a_2x^2$$

$$x_{1,2}=\frac{-b\pm\sqrt{b^2-4ac}}{2a}$$

### GitHub Style Lists

- [ ] foo
- [x] bar
