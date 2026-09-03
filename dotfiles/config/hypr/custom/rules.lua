-- Stop chat apps from yanking you to their workspace on every notification.
--
-- misc.focus_on_activate is true in hyprland/general.lua, so when a window
-- asks to be activated Hyprland honours it and switches workspaces. Telegram
-- and Discord ask on every incoming message, which drags you out of whatever
-- you were doing.
--
-- Suppressing only `activatefocus` for these apps keeps the useful half of the
-- behaviour: clicking a link still raises the browser, and notifications still
-- appear normally. Only the unrequested workspace jump is dropped.
local noAutoSwitch = {
    "^(org\\.telegram\\.desktop)$",
    "^(discord)$",
    "^(vesktop)$",
    "^(WebCord)$",
}

for _, cls in ipairs(noAutoSwitch) do
    hl.window_rule({ match = { class = cls }, suppress_event = "activatefocus" })
end
