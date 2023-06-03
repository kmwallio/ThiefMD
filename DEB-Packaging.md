# Creating a new ThiefMD Release

## Update Changelog:

`dch -U`

Update list of new features

## Create new Package

For release in PPA:

`debuild -S -sa`

For building locally:

`debuild -us -uc`

Packages will be in parent directory.

## Push package to PPA

`dput ppa:thiefmd/thiefmd ../com.github.kmwallio.thiefmd_0.0.0_source.changes`

## Cleaning

`debuild -T clean`

## Create Tag

`git tag -a v1.4 -m "my version 1.4"`

## Push Tag

`git push origin v0.0.0-label`

## Running Under Debugger

`G_DEBUG=fatal-criticals gdb --args ./com.github.kmwallio.thiefmd`
