<div align="center">

# 💠 dots-chjwoo

**A personal fork of [end4-pC](https://github.com/pctrade/end4-pC) by [@pctrade](https://github.com/pctrade),**
**which is itself a fork of [illogical-impulse](https://github.com/end-4/dots-hyprland) by [@end-4](https://github.com/end-4)**

Maintained by **chjwoo** for personal use

</div>

---

## About

This is not an original rice. Practically everything you see — the bar,
sidebars, overview, lock screen, Material You theming, the whole visual
language — was designed and written by the people credited below. This fork
exists so I have somewhere to keep my own tweaks without having to work
around someone else's repository.

Lineage:

```
illogical-impulse  (end-4)
  └─ end4-pC       (pctrade)
       └─ dots-chjwoo  (this fork)
```

If you like how this looks, star [dots-hyprland](https://github.com/end-4/dots-hyprland)
and [end4-pC](https://github.com/pctrade/end4-pC) — that is where the work is.

## 📸 Screenshots

> The screenshots below are inherited from end4-pC and show the shared shell,
> not changes specific to this fork.

<div align="center">

| 🎵 Lyrics | 🖼️ Online Wallpapers |
|:---:|:---:|
| ![Screenshot 1](screenshots/1.png) | ![Screenshot 2](screenshots/2.png) |
| 🪟 Desktop Widgets | 🔧 Hyprland Configs |
| ![Screenshot 5](screenshots/5.png) | ![Screenshot 6](screenshots/6.png) |
| ⚙️ Configurable Bar | ✨ And More |
| ![Screenshot 3](screenshots/3.png) | ![Screenshot 4](screenshots/4.png) |

</div>

---

## ⚡ Installation

> [!NOTE]
> This fork replaces the **Quickshell config only**. It does not install
> Hyprland, the fonts, matugen or any of the other machinery the shell talks
> to, so a working [illogical-impulse](https://github.com/end-4/dots-hyprland)
> install has to be in place first. Like its parent it lives in its own
> configuration folder and never overwrites an existing one.

### Requirements

- **illogical-impulse installed and working** — i.e. `qs -c ii` (or `end4-pC`,
  or whatever you run today) already gives you a bar.
- **`satty`** — the only extra package this fork needs, for the annotate half
  of the screenshot button. `grim`, `slurp` and `wl-clipboard` already come in
  with illogical-impulse.
- **A Lenovo IdeaPad/Legion laptop** — only for the conservation-mode button.
  On hardware without a `conservation_mode` attribute the button hides itself
  and the rest of the shell is unaffected.

### 1. Clone the shell

```bash
cd ~/.config/quickshell/
git clone https://github.com/chjwoo7/dots-chjwoo.git
```

### 2. Point Hyprland at it

Put this in `~/.config/hypr/custom/variables.lua` — the override file that
`hyprland/variables.lua` itself recommends, so no stock file needs editing:

```lua
hl.env("qsConfig", "dots-chjwoo")
```

Everything else (`execs.lua`, `keybinds.lua`, the settings launcher) already
refers to `$qsConfig`, so it follows automatically.

`hl.env` is read when Hyprland starts, so that line takes effect at your next
login. To switch the running session over right away:

```bash
killall qs 2>/dev/null; qs -c dots-chjwoo > /dev/null 2>&1 & disown
```

### 3. Put the ChjwooUtils widget in the bar

The bar layout lives in `~/.config/illogical-impulse/config.json`, which is
outside this repository, and the stock layout has never heard of this fork's
widget. Cloning alone is therefore not enough to see it: add `"chjwooUtils"`
to `bar.layouts.rightLayout`.

```json
"rightLayout": ["sysTray", "utilButtons", "chjwooUtils", "batteryIndicator", "systemIcons", "powerButton"]
```

Or from the shell — safe to run twice, it will not add a second copy:

```bash
cfg=~/.config/illogical-impulse/config.json
jq '.bar.layouts.rightLayout = ((.bar.layouts.rightLayout // ["sysTray","utilButtons","systemIcons","powerButton"])
      | if index("chjwooUtils") then . else
          reduce .[] as $w ([]; . + [$w] + (if $w == "utilButtons" then ["chjwooUtils"] else [] end))
        end)' "$cfg" > "$cfg.new" && mv "$cfg.new" "$cfg"
```

Reload the shell afterwards with `CTRL + SUPER + R`.

### 4. Battery conservation mode (IdeaPad/Legion only)

The toggle writes to a sysfs attribute that is root-owned by default. A udev
rule hands it to the `wheel` group so the unprivileged shell can flip it.

First check the machine actually has it, and that you are in `wheel`:

```bash
ls /sys/bus/platform/drivers/ideapad_acpi/*/conservation_mode
groups | tr ' ' '\n' | grep -x wheel
```

Then install the rule and apply it without rebooting:

```bash
cd ~/.config/quickshell/dots-chjwoo
sudo install -m 644 dotfiles/system/60-ideapad-conservation.rules /etc/udev/rules.d/
sudo udevadm control --reload
sudo udevadm trigger -c bind -s platform
```

Verify — the group must be `wheel` and the mode `664`:

```bash
$ ls -l /sys/bus/platform/drivers/ideapad_acpi/VPC2004:00/conservation_mode
-rw-rw-r-- 1 root wheel 4096 ... conservation_mode
```

If it still says `root root`, the button renders as a padlock instead of a
toggle — that is the deliberate signal that the rule did not land. Both the
rule and `ChjwooUtils.qml` hardcode the device name `VPC2004:00`; if your
machine enumerates it differently, the `ls` above tells you the real name and
both files need that name instead.

---

## 🗂️ The `dotfiles/` folder

The shell is only half of a rice. Steps 2 and 3 above set up the two pieces
that live outside this repository by hand; `dotfiles/` is the rest of the
configuration, kept here so the whole setup can be rebuilt rather than
reassembled from memory.

```
dotfiles/
├── config/     mirrors ~/.config  (hypr, illogical-impulse, kitty, fish,
│               fuzzel, wlogout, cava, matugen, Kvantum, GTK themes, ...)
├── home/       ~/.bashrc, ~/.zshrc, ~/.bash_profile, ~/.gtkrc-2.0
└── system/     udev rule for Legion/IdeaPad battery conservation mode
```

Two files in there matter more than the rest:

- `config/hypr/custom/variables.lua` — sets `qsConfig` to this config. Without
  it Hyprland keeps loading whatever it loaded before.
- `config/illogical-impulse/config.json` — shell settings, including the bar
  layout that places the `ChjwooUtils` widget. The QML file alone is not
  enough for the widget to appear.

### Installing it

This step is optional — the shell runs without it, once steps 1-3 above are
done. It is here for rebuilding this exact rice on a fresh machine, and it
**overwrites** live configuration, so read what you are about to replace.

```bash
cd ~/.config/quickshell/dots-chjwoo
cp -r dotfiles/config/. ~/.config/
cp -r dotfiles/home/.   ~/       # .bashrc, .zshrc, .bash_profile, .gtkrc-2.0
sudo install -m 644 dotfiles/system/60-ideapad-conservation.rules /etc/udev/rules.d/
sudo udevadm control --reload
sudo udevadm trigger -c bind -s platform
```

A few of the copied files are personal rather than portable, and are worth
fixing up afterwards on someone else's machine:

- `config/illogical-impulse/config.json` — `wallpaperPath`, the lock-screen
  background and the screen-recording `savePath` are absolute paths under
  `/home/chjwoo`.
- `config/spicetify/config-xpui.ini` — same, absolute paths.
- `config/hypr/hyprland/variables.lua` — ships with `qsConfig` set to
  `end4-pC`; the `custom/variables.lua` override from step 2 is what actually
  selects this fork.

### Keeping it up to date

`dotfiles/` holds copies, not the live files. After changing anything under
`~/.config`, re-sync before committing:

```bash
./sync-dotfiles.sh
git add dotfiles && git commit -m "sync dotfiles"
```

The script skips `*.bak*` files and the illogical-impulse installer manifest.
It never touches application data such as browser or Discord profiles.

---

## ✨ Changes in this fork

### Cheatsheet, restored

end4-pC removed the cheatsheet module in commit `4c80a65` ("remove waffles
thing"), which left `SUPER + /` dispatching the global
`quickshell:cheatsheetToggle` with nothing listening for it. It is back here,
using the upstream illogical-impulse look.

Three things were needed, and each one hid the next:

- `modules/ii/cheatsheet/` — the module itself, from upstream illogical-impulse.
- `services/CheatsheetBinds.qml` — a service reading `hyprctl binds -j`. It is
  added **alongside** `HyprlandKeybinds` rather than replacing it: the
  illogical-impulse cheatsheet wants a flat array, while `LauncherSearch.qml`
  in this fork still depends on the older tree-shaped service. Swapping it
  would quietly break launcher search.
- `modules/common/Config.qml` — the `cheatsheet` options block, restored.
  Without it `Config.options.cheatsheet.fontSize.key` is undefined, and the
  keycaps render blank while the labels still show.

### Custom bar widget

`modules/ii/bar/ChjwooUtils.qml` is a new file rather than an edit to
`UtilButtons.qml`, so pulling from upstream can never conflict with it. It
holds two buttons:

- **Battery conservation mode** — toggles the IdeaPad/Legion charge cap
  (~60%) through `ideapad_laptop`'s sysfs attribute, which the udev rule in
  `dotfiles/system/` makes group-writable. Hovering it opens a popup with the
  current On/Off state, using the same `StyledPopup` component as the battery
  indicator. The icon becomes a padlock when the attribute is not writable.
- **Snip and annotate** — `grim` into `satty`, mirroring the `CTRL + Print`
  keybind. The command lives in two places that have to stay in sync: this
  file and `hypr/custom/keybinds.lua`.

It only appears once `"chjwooUtils"` is in the bar layout — see step 3 of the
installation.

---

## ❓ FAQ

### How do I see my keybinds?

Press `SUPER + /` for the cheatsheet, or open the launcher (`SUPER`) and type
`<` for the same list in search form.

### Why doesn't Settings have a search bar?

It doesn't need one — the launcher already does that job. Open the launcher
(`SUPER`) and type what you're looking for (e.g. `wallpaper`, `bar`, `blur`);
it matches page names and section keywords and jumps straight to the right
Settings page.

---

## 🙏 Credits

This fork exists because of other people's work:

- **[@end-4](https://github.com/end-4)** — for creating the original [dots-hyprland](https://github.com/end-4/dots-hyprland) / illogical-impulse shell. An absolute masterpiece of a dotfiles project 🫡
- **[@pctrade](https://github.com/pctrade)** — for [end4-pC](https://github.com/pctrade/end4-pC), the fork this one is built on, and for maintaining it 🙌

Carried over from end4-pC's own credits, for contributions still present in
this code:

- **[@gh0stzk](https://github.com/gh0stzk)** — for the weather API integration behind the weather widget 🙌
- **[@StarS2112](https://github.com/StarS2112)** — for showcasing that fork 🙌
- **[@simeulinuxkaliaiwr](https://github.com/simeulinuxkaliaiwr)** — for some shader transitions 🎨

Please respect the licenses of the upstream projects when reusing anything here.

---

<div align="center">

Made with ❤️ — feel free to fork and make it your own

</div>
