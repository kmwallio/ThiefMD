# Creating a new ThiefMD Release

## Update Changelog:

`dch -U`

Update list of new features

## Create new Package

`debuild -us -uc`

Packages will be in parent directory.

## Cleaning

`debuild -T clean`

## Create Tag

`git tag -a v1.4 -m "my version 1.4"`

## Push Tag

`git push origin v0.0.0-label`
