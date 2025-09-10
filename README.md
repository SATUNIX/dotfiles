# SATUNIX Aurora Fork (Hyprland Setup)

This repository is a **personal fork of [flicko’s Aurora](https://github.com/flicko/aurora)** with a streamlined installation and a few key modifications:

* **Display Manager / Session**: Hyprland-based environment, no swaylock-effects.
* **Wallpaper**: Using **Hyprpaper** (instead of `swww`).
* **Lockscreen**: Using **Gtklock** + `gtklock-powerbar-module` (instead of `swaylock-effects`).
* **Screenshots**: Using **Hyprshot** (from official repos, no longer from AUR).
* **Fonts**: Includes **JetBrains Mono** and extended JetBrains font families in configs.
* **Configs**: All configs live under `./config` in this repo and are deployed directly to `~/.config`.

---

## Installation (Automated)

You can bootstrap the entire environment with a **single script**. This script installs all dependencies (pacman + paru), clones this repo, backs up your configs, and applies the fork’s configuration.

> ⚠️ **Arch Linux required.** Do not run as root; use a normal user with `sudo` privileges.

```bash
curl -fsSL https://raw.githubusercontent.com/SATUNIX/dotfiles/refs/heads/aurora/install.sh | bash
```

### What it does

1. Ensures `paru` is installed (AUR helper).
2. Installs all required packages from **pacman** and **paru**.
3. Clones this repository (`aurora` branch).
4. Backs up your current `~/.config` → `~/.<timestamp>.config.bak`.
5. Deploys this repo’s `./config` → `~/.config`.
6. Creates Hyprland state files (`~/.config/hypr/store/...`).
7. Marks scripts in `~/.config/hypr/scripts/` executable.
8. Shows a summary of packages installed/removed in the last 24 hours.

---

## Package Differences from Upstream Aurora

* **Removed**:

  * `swww-git` (wallpaper daemon)
  * `swaylock-effects-git` (lockscreen)

* **Added / Replaced**:

  * `hyprpaper` (wallpaper)
  * `gtklock`, `gtklock-powerbar-module` (lockscreen)
  * `hyprshot` (screenshots, now in official repos)
  * `ttf-jetbrains-mono` (font)

* **Unchanged core**:

  * `hyprland`, `foot`, `grim`, `slurp`, `waybar`, `fish`, `light`, `sddm`, `xdg-desktop-portal-hyprland`, etc.

---

## Repository Layout

```
dotfiles/
├── config/             # configs to be deployed directly into ~/.config
│   ├── hypr/           # Hyprland configs, scripts, store files
│   ├── waybar/         # Waybar configuration
│   ├── gtklock/        # Gtklock config + style
│   └── ...
├── install.sh          # automated installation script
└── (Aurora’s original README.md follows)
```

---

## Notes

* This fork is tailored for **Hyprland + Hyprpaper + Gtklock + Hyprshot** workflow.
* Original Aurora README is preserved below for reference.
* If you want to update configs after installation, just re-clone and re-run the installer; your old `~/.config` will always be timestamped and preserved.


Refer to the below for the previous readme file. For reference. 

---


<div align="justify">

<div align="center">

```ocaml
 ❄️ hyprland / aurora / catppuccin ❄️
```


# gallery
![pipes](./assets/pipes.png)
![fetch](./assets/fetch.png)
 

https://user-images.githubusercontent.com/77581181/204240865-8a272152-7c31-45f9-a46b-47099b071060.mp4

 
</div>
</div>




<div align="justify">

<div align="center">

# installation
 
<hr>
 
</div>
</div>

## Arch
dependencies
```
hyprland-git waybar-hyprland-git cava waybar-mpris-git python rustup kitty fish wofi xdg-desktop-portal-hyprland-git tty-clock-git swaylockd grim slurp pokemon-colorscripts-git starship jq dunst wl-clipboard swaylock-effects-git swww-git
```
using `paru`
```
paru -S hyprland-git waybar-hyprland-git cava waybar-mpris-git python rustup kitty fish wofi xdg-desktop-portal-hyprland-git tty-clock-git swaylockd grim slurp pokemon-colorscripts-git starship jq dunst wl-clipboard swaylock-effects-git swww-git
```

## moving config files

```bash
git clone -b aurora https://github.com/flick0/dotfiles
cd dotfiles
cp -r ./config/* ~/.config
```

## additional setup

```bash
mkdir ~/.config/hypr/store
touch ~/.config/hypr/store/dynamic_out.txt
touch ~/.config/hypr/store/prev.txt
touch ~/.config/hypr/store/latest_notif

chmod +x ~/.config/hypr/scripts/tools/*
chmod +x ~/.config/hypr/scripts/*
chmod +x ~/.config/hypr/*
```

## building the tools used in this rice

`rgb-borders` | rgb borders for grouped windows
```bash
git clone https://github.com/flick0/rgb-rs
cd rgb-rs
cargo build --release
cp ./target/release/rgb ~/.config/hypr/scripts/
```


# extras

## vscode custom css

you will need the `custom css and js loader` extension, you can get it from [here](https://marketplace.visualstudio.com/items?itemName=be5invis.vscode-custom-css)

make a new css file anywhere that fits you
then copy the following css to the file

```css
.tab.active {
    border: 4px solid #f5c2e7 !important;
    color: #f5c2e7 !important;
}
.tab{
    font-weight: 700 !important;
    border-radius: 12px !important;
    margin: 5px !important;
    padding-bottom: 2px !important;
    height: 45px !important;
    border:3px solid #313244 !important;
    background-color: #1e1e2e !important;
}
.tabs-container{
    height: auto !important;
    padding: 5px !important;
}
```

allow modifications to vscode by running the following command pointing to your vscode installation
```bash
sudo chown -R {your username} /opt/visual-studio-code-insiders/
```
> replace visual-studio-code-insiders with your vscode installation,
> you can find your installation dir by doing `whereis code` on your terminal


then open the vscode `settings.json` file (you shud be able to open it from `ctrl` + `shift` + `p` and searching for `Open User Settings(JSON)`)
then add the following to the file

```json
"vscode_custom_css.imports": [
    "file:///{path_to_file}"
],
```

then finally to apply the changes, open the command pallette(`ctrl`+`shift`+`p`) and search for `Enable Custom CSS and JS`


<hr>

<p align="center">
	<a href="https://www.reddit.com/r/unixporn/comments/z6s20y/hyprland_aurora_modified_my_previous_rice_to_fit/">
		<img alt="Reddit" src="https://img.shields.io/badge/Reddit-%23eba0ac.svg?style=for-the-badge&logo=Reddit&logoColor=1e1e2e">
  </a>
	<a href="https://www.youtube.com/watch?v=zi2Nm5-0PYY">
		<img alt="Youtube" src="https://img.shields.io/badge/YouTube-%23f38ba8.svg?style=for-the-badge&logo=YouTube&logoColor=white">
  </a>
   ॱ
 	<a href="https://discord.com/channels/@me/482139697796349953">
		<img alt="Youtube" src="https://dcbadge.vercel.app/api/shield/482139697796349953">
  </a>
</p>

*lmk if anything is broken on the repo*





