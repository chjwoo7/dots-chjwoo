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
> Like its parent, this fork manages its own configuration folder and does
> **not** overwrite an existing setup. It still requires
> [illogical-impulse](https://github.com/end-4/dots-hyprland) to be installed,
> since it depends on that install being present.

```bash
cd ~/.config/quickshell/
git clone https://github.com/chjwoo7/dots-chjwoo.git
killall qs 2>/dev/null; qs -c dots-chjwoo > /dev/null 2>&1 & disown
```

### 🔧 Set as your default shell

Point Hyprland at this config in `~/.config/hypr/custom/variables.lua` — the
override file that `hyprland/variables.lua` itself recommends, so no stock
file needs editing:

```lua
hl.env("qsConfig", "dots-chjwoo")
```

Everything else (`execs.lua`, `keybinds.lua`, the settings launcher) already
refers to `$qsConfig`, so it follows automatically.

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

- `modules/ii/bar/ChjwooUtils.qml` — a battery conservation-mode toggle for
  Lenovo IdeaPad/Legion hardware, driven by a udev rule.

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
