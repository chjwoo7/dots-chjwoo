-- Stop chat apps from yanking you to their workspace on every notification.
--
-- misc.focus_on_activate is true in hyprland/general.lua, so when a window
-- asks to be activated Hyprland honours it and switches workspaces. Telegram
-- and Discord ask on every incoming message, which drags you out of whatever
-- you were doing.
--
-- `activatefocus` alone only stops the focus grab; the workspace still follows
-- the activate request itself, so both have to be suppressed. Notifications
-- still appear normally, and clicking a link still raises the browser, because
-- this is scoped to these apps rather than turning focus_on_activate off.
--
-- Window rules attach when a window is mapped, so an app already running when
-- this changed has to be restarted before the rule applies to it.
local noAutoSwitch = {
    "^(org\\.telegram\\.desktop)$",
    "^(discord)$",
    "^(vesktop)$",
    "^(WebCord)$",
}

for _, cls in ipairs(noAutoSwitch) do
    hl.window_rule({ match = { class = cls }, suppress_event = "activate activatefocus" })
end
