-- tmux-style keybinds, mirroring modules/home/tools/tmux/tmux.conf.
-- Keys are matched unshifted: "%" is shift+5, "H" is shift+h, etc.

local function prefix(key, action, args)
  rex.bind("ctrl+a>" .. key, action, args)
end

-- Press ctrl+a twice to send one to the terminal
prefix("ctrl+a", "pane.send_key", { key = "ctrl+a" })

-- Tabs (tmux windows)
prefix("c", "client.tab.new")
prefix("n", "client.tab.next")
prefix("p", "client.tab.previous")
prefix(",", "client.tab.rename")
prefix("shift+7", "client.tab.close") -- &
for i = 1, 9 do
  prefix(tostring(i), "client.tab.goto", { index = i })
end
rex.bind("shift+left", "client.tab.previous")
rex.bind("shift+right", "client.tab.next")

-- Splits
prefix("shift+5", "pane.split", { direction = "right" }) -- %
prefix("shift+'", "pane.split", { direction = "down" }) -- "
prefix("shift+s", "pane.split", { direction = "down" }) -- S

-- Panes
prefix("z", "pane.zoom")
prefix("x", "pane.close")
prefix("o", "pane.focus_next")
prefix(";", "pane.focus_previous")
prefix("shift+1", "pane.move_to_new_tab") -- !
prefix("space", "pane.balance")

local dirs = { h = "left", j = "down", k = "up", l = "right" }
for key, dir in pairs(dirs) do
  prefix(key, "pane.focus", { direction = dir })
  prefix("shift+" .. key, "pane.resize", { direction = dir, amount = 10 })
  prefix("alt+" .. key, "pane.resize", { direction = dir, amount = 2 })
  rex.bind("alt+" .. key, "pane.focus", { direction = dir })
  rex.bind("alt+" .. dir, "pane.focus", { direction = dir })
end

-- Sessions
prefix("s", "session.switch")
prefix("shift+n", "session.new")
prefix("shift+4", "session.rename") -- $
prefix("shift+9", "session.previous") -- (
prefix("shift+0", "session.next") -- )

-- Misc
prefix("[", "client.find.open")
prefix("shift+;", "client.palette.toggle") -- :
prefix("r", "client.config.reload")
