<p align="center">
  <img src="img/chit-icon.png" alt="chit title"><br>
  Chit: For changing themes.
</p>

<p align="center">
  <img src="img/chit-usage.gif" alt="chit usage" width="80%"><br>
</p>

<p align="center">
  <a href="#introduction">Introduction</a> •
  <a href="#how-to-use">How To Use</a> •
  <a href="#how-it-works">How it Works</a> •
  <a href="#installation">Installation</a> •
  <a href="#adding-themes">Adding Themes</a>
</p>

### Introduction
`chit` makes it easy to change your terminal color themes on the fly.  It works in the background to update everything needed, so color changes are seamless.

`chit` [integrates](#integrations) with other tools, so it's the only tool you need to use.

Changing up your colors should be fun! it should be cheap. it should only cost 1 [chit](https://www.dictionary.com/browse/chit?s=t).

### How To Use
List all themes

```bash
> chit list-themes
```

Change the theme

```bash
> chit set-theme nord
```

View the current theme

```bash
> chit get-current-theme
```

### How it Works
`chit` manages a collection _themes_.  Each theme is defined in a .conf file, stored in `~/.config/chit/theme_definitions`.  On first invocation, `chit` copies some [example themes](example_theme_definitions) to this directory.

#### Theme File Format
The theme .conf files define variables with a `key=value` syntax.  The lines can be in any order.  
The following variables are supported:  

- `CHIT_ITERM_SCHEME`
 - If using the iTerm program, name of the iTerm scheme to use.  See [here](https://github.com/mbadolato/iTerm2-Color-Schemes) for a good list.
- `CHIT_KITTY_THEME_CONF_FILE_PATH`
 - If using the [kitty](https://github.com/kovidgoyal/kitty) program, path of the color .conf file to use.  See [here](https://sw.kovidgoyal.net/kitty/conf.html#color-scheme) for more information.
- `CHIT_VIM_COLORSCHEME`
  - Name of the Vim colorscheme to use.
- `CHIT_VIM_BEFORE`
  - For Vim colorschemes, any command to execute before the scheme is applied.  This is handy for schemes with variants, like [ayu](https://github.com/ayu-theme/ayu-vim#installation).
- `BAT_THEME`
  - Name of the theme for [bat](https://github.com/sharkdp/bat) to use.  If using this option, also make sure to set up [bat integration](#bat).

### Installation
Installation and setup is a three step process:

1. Install `chit` through the homebrew tap:

```bash
> brew install thetomcraig/tap/chit
```

2. Add the initialization line to your shell:
 
- For Zsh:
  - `eval "$(chit shell-init)"`

3. Setup `chit`:
 
```bash
> chit setup
```

This will setup everything you need in the config directory, `~/.config/chit`.  Including the [example themes](example_theme_definitions).

### Integrations

#### Vim
To integrate with Vim, install the [vim-chit](https://github.com/thetomcraig/vim-chit) Vim plugin.

#### Bat
- To integrate with `bat`, you need to alias the `bat` command to use the `chit` theme:
  - For Zsh:
    - ```alias bat="bat --theme \`chit get-theme-variable BAT_THEME\`"```
This will allow `bat` to always use the correct `chit` theme, without needing to reset the environment variables.

### Adding Themes
