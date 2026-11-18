-- Sessions
rex.bind("cmd+shift+s", "session.switch")
rex.bind("cmd+shift+n", "session.new")
rex.bind("cmd+shift+r", "session.rename")
rex.bind("cmd+shift+x", "session.close")
rex.bind("cmd+shift+[", "session.previous")
rex.bind("cmd+shift+]", "session.next")

-- Quick switcher views: s sessions (above), b blocks, a activity
rex.bind("cmd+shift+b", "pane.go_to")
rex.bind("cmd+shift+a", "pane.view_activity")

-- Tabs
rex.bind("cmd+n", "client.tab.new")
rex.unbind("cmd+t")
rex.unbind("cmd+w")
rex.bind("cmd+r", "client.tab.rename")
rex.bind("cmd+[", "client.tab.previous")
rex.bind("cmd+]", "client.tab.next")

-- cmd+1..8 go to that tab of the current session, and cmd+9 to its last tab.
-- The client's own client.tab.goto counts tabs across every session.
rex.action({
  name = "session_tab",
  title = "Go to Tab in Session",
  args = { index = "integer" },
  run = function(ctx, args)
    local view, err = rex.session.view({})
    if err ~= nil then error(err, 0) end
    local i = args.index < 0 and #view.windows + 1 + args.index or args.index
    local window = view.windows[i]
    if window then
      rex.client.queue("session.select", { session_id = ctx.session_id, window_id = window.window_id })
    end
  end,
})
for i = 1, 8 do
  rex.bind("cmd+" .. i, "session_tab", { index = i })
end
rex.bind("cmd+9", "session_tab", { index = -1 })

-- Close the focused pane, or the whole tab when it is the only pane in it.
-- A focused floating pane always closes on its own.
rex.action({
  name = "close",
  title = "Close Pane or Tab",
  run = function()
    local ok, view = pcall(rex.session.view)
    if ok and view then
      for _, window in ipairs(view.windows) do
        if window.window_id == view.active_window_id then
          local panes = 0
          for _, layer in ipairs(window.layers) do
            if layer.kind == "tiled" then
              panes = panes + #layer.blocks
            else
              for _, block in ipairs(layer.blocks) do
                if block.block_id == window.focused_block_id then
                  rex.client.queue("pane.close")
                  return
                end
              end
            end
          end
          if panes <= 1 then
            rex.client.queue("client.tab.close")
            return
          end
        end
      end
    end
    rex.client.queue("pane.close")
  end,
})
rex.bind("cmd+x", "close")

-- Panes
-- The focused pane's working directory, or nil if it hasn't reported one.
local function focused_cwd(ctx)
  local ok, result = pcall(rex.call, "block.method", {
    session_id = ctx.session_id,
    block_id = ctx.block_id,
    method = "pwd",
  })
  if ok and result and result.pwd then
    -- pwd is a file://host/path URL
    return (result.pwd:gsub("^file://[^/]*", ""):gsub("%%(%x%x)", function(hex)
      return string.char(tonumber(hex, 16))
    end))
  end
end

-- Open a floating pane over the current tab, in cwd or else the focused pane's
-- directory. With a command, the pane runs it and closes when it exits.
local function open_float(ctx, label, command, cwd)
  rex.session.new_layer({
    bounds = { 0.067, 0.067, 0.866, 0.866 },
    focus = true,
    layout = {
      block = {
        flavor = "com.superlogical.terminal.shell",
        label = label,
        options = { cwd = cwd or focused_cwd(ctx), command = command },
      },
    },
  })
end

-- cmd+f opens a floating shell; cmd+x closes it.
rex.action({
  name = "float",
  title = "New Floating Pane",
  run = function(ctx)
    open_float(ctx, "float")
  end,
})
rex.bind("cmd+f", "float")
-- cmd+g opens lazygit in a floating pane; quitting lazygit (q) closes it.
-- This replaces Rex's default cmd+g (Find Next).
rex.action({
  name = "lazygit",
  title = "Lazygit",
  run = function(ctx)
    open_float(ctx, "lazygit", { "env", "XDG_CONFIG_HOME=" .. os.getenv("HOME") .. "/.config", "lazygit" })
  end,
})
rex.bind("cmd+g", "lazygit")
-- cmd+e opens a scratchpad: Neovim on ~/.config/scratch, in a floating pane.
-- Pressing it again hides the scratchpad (it keeps running), and again shows it.
-- Also in the command palette as "Scratchpad".
local home = os.getenv("HOME")
rex.action({
  name = "scratch",
  title = "Scratchpad",
  keywords = "scratch notes jot nvim",
  run = function(ctx)
    local view = rex.session.view({})
    for _, window in ipairs(view.windows) do
      if window.window_id == view.active_window_id then
        for _, layer in ipairs(window.layers) do
          for _, block in ipairs(layer.blocks) do
            if layer.kind ~= "tiled" and block.label == "scratch" then
              local shown = layer.state ~= "minimized" and block.block_id == window.focused_block_id
              rex.session.set_layer_state({
                session_id = ctx.session_id,
                layer_id = layer.layer_id,
                state = shown and "minimized" or "normal",
                focus = not shown,
              })
              return
            end
          end
        end
      end
    end
    -- The pane starts in $HOME so it can create the directory before entering it.
    open_float(ctx, "scratch", { "sh", "-c", 'mkdir -p "$1" && cd "$1" && exec nvim .', "sh", home .. "/.config/scratch" }, home)
  end,
})
rex.bind("cmd+e", "scratch")
-- cmd+m hides the focused floating pane (it keeps running) and shows it again.
rex.bind("cmd+m", "pane.minimize_floating")
-- cmd+ctrl+m does the same for every floating pane in the tab.
rex.bind("cmd+ctrl+m", "pane.minimize_all_floating")
-- cmd+d and cmd+shift+d are the client's default splits, so they stay bound.
-- Drop the other default splits.
for _, d in ipairs({ "left", "right", "up", "down" }) do
  rex.unbind("cmd+shift+" .. d)
end
rex.bind("cmd+left", "pane.focus.left")
rex.bind("cmd+right", "pane.focus.right")
rex.bind("cmd+up", "pane.focus.up")
rex.bind("cmd+down", "pane.focus.down")
-- Home-row pane focus, vim style. Free in every app here: Aerospace owns
-- alt+hjkl, and tmux/Neovim/the shell use ctrl+hjkl.
rex.bind("cmd+h", "pane.focus.left")
rex.bind("cmd+j", "pane.focus.down")
rex.bind("cmd+k", "pane.focus.up")
rex.bind("cmd+l", "pane.focus.right")
rex.bind("cmd+z", "pane.zoom")

-- Pane mode: cmd+p, then
--   arrows resize, shift+arrows resize by more, alt+arrows move the pane,
--   = balance, enter/esc leave
rex.mode("pane", { exclusive = true })
rex.bind("cmd+p", "client.mode.enter", { name = "pane" })
for _, d in ipairs({ "left", "right", "up", "down" }) do
  rex.bind("pane/" .. d, "pane.resize", { direction = d })
  rex.bind("pane/shift+" .. d, "pane.resize", { direction = d, amount = 15 })
  rex.bind("pane/alt+" .. d, "pane.move." .. d)
end
rex.bind("pane/=", "pane.balance")
rex.bind("pane/enter", "client.mode.exit")
