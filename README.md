Some of the config files, to simplify the machine migration process.

To make good use of it, clone the repository to a directory of your choice, and create symlinks to the appropriate files. Here is an example below.

```
cd ~
git clone https://github.com/antonk52/dot-files.git
ln -s ~/dot-files/.vimrc
ln -s ~/.zshrc
```

As a result you get a symlink in the home directory, which will be used for vim on load.
