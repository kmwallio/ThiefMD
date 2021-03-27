# Contributing

Thanks for considering a contribution to ThiefMD!

Most of this documentation is about Code Changes. If you want to help improve are website or documentation, jump down to [Contributing Documentation](#contributing-documentation)

It's recommended to first [search for or create an issue](https://github.com/kmwallio/ThiefMD/issues). I'll try to categorize issues into [Projects](https://github.com/kmwallio/ThiefMD/projects) for tracking state.

This is mostly for communication and deduplicating work. There may be a branch where the feature is already in progress, or it may be a feature in the beta branch awaiting release.

If you search an issue or feature you'd like to work on, check the **Assignees** and the **Projects** section of the issue. If no one is assigned, feel free to comment and ask for the issue. We'll assign the issue to you and put the state into *In progress*.

Please link to your fork and/or branch in the comment once you start work.

## Bug Reporting and Feature Requests

Contributions don't have to be through code or documentation. Just letting us know a feature is broken or there's something you'd like to see in ThiefMD helps us improve it.

### Bugs

For bugs, please let us know if there are consistent repro steps. Ideally something like:

```
Title: ThiefMD crashes when attempting to _____
Comment:
    ThiefMD crashes when I do ________.
    Using: Flatpak/DEB/RPM/etc.
    Desktop Environment: GNOME/KDE/Xfce/etc.
    OS: Ubuntu 20.10/Fedora 33/Arch/Pop OS 20.04/etc.
    I am using/not using Wayland.

    Steps:
    1. Open ThiefMD
    2. Do this in the UI
    3. See ThiefMD crash
```

This will let us test for and isolate the issue. There are some known issues on older versions of the Gtk. Some distributions with Wayland are also known to have issues when not using the flatpak release.

### Feature Requests

Feel free to [create an issue](https://github.com/kmwallio/ThiefMD/issues). If it aligns with ThiefMD's vision, we'll categorize it and put it in a project. We cannot guarantee if or when a feature request will be implemented.

Priority of features is based on usefulness and practicality, how life feels knowing we don't have the feature, ease of implementation, and translating the feature into the User Interface. Some features may be hidden behind keyboard shortcuts until an appropriate UI Interaction can be found.

## Main Branches

It is recommended to fork and work from the beta branch as this branch always contains the next release.

* [beta](https://github.com/kmwallio/ThiefMD/tree/beta): The beta branch is where most feature work is branched from or winds up. This branch should remain mostly stable.
* [master](https://github.com/kmwallio/ThiefMD): This is the branch we release off of. This branch must remain usable.

Please make sure your code changes build and run when [packaged as a flatpak](/flatpak-packaging.md).

## Feature Screenshots

Try to take screenshots using the default GNOME Adwaita Theme and Icons.

## CSS Packages & Color Themes

Please see [/ThiefMD/themes](https://github.com/ThiefMD/themes).

If you would like to work with us on improving the Themes site, please submit an issue or [send me an e-mail](mailto:mwallio@gmail.com). I can generate screenshots or you can run `thiefshot` in the `themes` root directory. [thiefshot repo](https://github.com/TwiRp/thief-screenshot). If running the tool yourself, please make sure to set your GTK Theme to Adwaita.

# Contributing Documentation

Thanks again for helping to make ThiefMD useful to everyone. Insights shared from our users help us to improve features, and also help us learn new ways to use ThiefMD ourselves.

## Adding Tips

Use ThiefMD in a way that's not documented or have some special trick for making life better? [Tips & Tricks](https://thiefmd.com/tips/) are a great way to share them.

In source, these are in [ThiefMD/docs/tips](https://github.com/kmwallio/ThiefMD/tree/master/docs/tips). The file name should be meaningful and all-age appropriate.

Images can be placed in `ThiefMD/docs/images/tip-file-name/`.

When using linking to an image or another page, always start with a `/`. The path should start from after `ThiefMD/docs`. For instance, an image pointing to [/ThiefMD/blob/master/docs/images/thief_library.png](https://github.com/kmwallio/ThiefMD/blob/master/docs/images/thief_library.png), would show up as:

```markdown
![](/images/thief_library.png)
```

If you want to align the image to the left or right responsively, you can use HTML as well:

```html
    <div class="responsive-left">
    <img src="/images/thief_library.png" />
    </div>
```

Alignment classes are:
 - responsive-right
 - responsive-left
 - responsive-right-short
 - responsive-left-short

If the PNG is transparent and you want to add a background, you can add one of the following classes:
 - [marcel](https://github.com/kmwallio/ThiefMD/blob/master/docs/images/gaelle-marcel-wheat.jpg)
 - [jonas](https://github.com/kmwallio/ThiefMD/blob/master/docs/images/jonas-zurcher-wheat.jpg)
 - [hoffman](https://github.com/kmwallio/ThiefMD/blob/master/docs/images/matt-hoffman-wheat.jpg)

```html
    <div class="responsive-left jonas">
    <img src="/images/thief_library.png" />
    </div>
```

## Fixing Typos or Incorrect Documentation

If you have a copy of the ThiefMD repo, feel free to send a pull request with the fix. Alternatively, create an [issue](https://github.com/kmwallio/ThiefMD/issues) with a link to the page, a copy of the Incorrect Documentation and what the correct Documentation should be.

# Other Contributions

Thanks again for reading this documentation. If you have a question about something not covered here, feel free to ask [through issues](https://github.com/kmwallio/ThiefMD/issues).