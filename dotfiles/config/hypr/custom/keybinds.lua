hl.bind("CTRL+SUPER+ALT+Slash", hl.dsp.exec_cmd("xdg-open ~/.config/hypr/custom/keybinds.lua"), {description = "Edit user keybinds"} )

--# Screenshot + anotasi pakai satty (CTRL + Print)
hl.bind("CTRL + Print", hl.dsp.exec_cmd(
    "grim -g \"$(slurp)\" - | satty -f - --early-exit --actions-on-enter save-to-clipboard --initial-tool rectangle"),
    { description = "Utilities: Screen snip >> anotasi (satty)" })
