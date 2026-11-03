-- The idea is to have one modifier family per domain:
--   cmd+*        tabs and panes
--   cmd+shift+*  sessions
-- The same key means the same verb in the tab and session families:
--   n new, r rename, x close, [ ] previous/next
--   cmd+x closes the focused pane, or the tab when it is the only pane
--   cmd+d / cmd+shift+d split a pane right / down (the client's defaults);
--     the one cmd+shift+* key that isn't a session action
--   cmd+f opens a floating pane, cmd+h/j/k/l or cmd+arrows focus a pane,
--     cmd+z zooms it
--   cmd+p enters pane mode to resize and move panes

-- Sessions
rex.bind("cmd+shift+o", "session.switch")
rex.bind("cmd+shift+n", "session.new")
rex.bind("cmd+shift+r", "session.rename")
rex.bind("cmd+shift+x", "session.close")
rex.bind("cmd+shift+[", "session.previous")
rex.bind("cmd+shift+]", "session.next")

-- Tabs
rex.bind("cmd+n", "client.tab.new")
rex.unbind("cmd+t")
rex.unbind("cmd+w")
rex.bind("cmd+r", "client.tab.rename")
rex.bind("cmd+[", "client.tab.previous")
rex.bind("cmd+]", "client.tab.next")

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
-- cmd+f opens a floating shell over the current tab, in the focused pane's
-- directory; cmd+x closes it.
rex.action({
  name = "float",
  title = "New Floating Pane",
  run = function(ctx)
    local cwd
    local ok, result = pcall(rex.call, "block.method", {
      session_id = ctx.session_id,
      block_id = ctx.block_id,
      method = "pwd",
    })
    if ok and result and result.pwd then
      -- pwd is a file://host/path URL
      cwd = result.pwd:gsub("^file://[^/]*", ""):gsub("%%(%x%x)", function(hex)
        return string.char(tonumber(hex, 16))
      end)
    end
    rex.session.new_layer({
      bounds = { 0.067, 0.067, 0.866, 0.866 },
      focus = true,
      layout = {
        block = { flavor = "com.superlogical.terminal.shell", label = "float", options = { cwd = cwd } },
      },
    })
  end,
})
rex.bind("cmd+f", "float")
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
