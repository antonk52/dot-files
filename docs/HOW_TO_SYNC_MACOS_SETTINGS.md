# How to sync macos settings

Ie instead of toggling them in UI have it auto set up using a script.

```sh
$ defaults read >> before.txt

# Change something in System Preferences

$ defaults read >> after.txt

$ git diff --no-index before.txt after.txt
```

Now you can see the diff and what has changed specifically. If this is a wanted change you can add a section to the [`prepare-macos.sh`](../scripts/prepare-macos.sh) script. To apply the changes a [`defaults`](https://github.com/kevinSuttle/macOS-Defaults/blob/master/REFERENCE.md) tool should be used.
