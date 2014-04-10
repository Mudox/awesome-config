-- vim: filetype=lua foldmethod=marker

--  Standard awesome library                                                            {{{1
local gears     = require("gears")
local awful     = require("awful")

awful.rules     = require("awful.rules")
require("awful.autofocus")

local wibox     = require("wibox")
local beautiful = require("beautiful")
local naughty   = require("naughty")
local menubar   = require("menubar")

-- widget librarys
local lain      = require("lain")
-- }}}1

--  Error handling                                                                      {{{1
-- Check if awesome encountered an error during startup and fell back to
-- another config (This code will only ever execute for the fallback config)
if awesome.startup_errors then
  naughty.notify({ preset = naughty.config.presets.critical,
      title = "Oops, there were errors during startup!",
      text = awesome.startup_errors })
end

-- Handle runtime errors after startup
do
  local in_error = false
  awesome.connect_signal("debug::error", function (err)
      -- Make sure we don't go into an endless error loop
      if in_error then return end
      in_error = true

      naughty.notify({ preset = naughty.config.presets.critical,
          title = "Oops, an error happened!",
          text = err })
      in_error = false
    end)
end
-- }}}1

--  Variable definitions                                                                {{{1

-- Themes define colours, icons, and wallpapers
beautiful.init(os.getenv("HOME") .. "/.config/awesome/themes/powerarrow-darker/theme.lua")

-- This is used later as the default terminal and editor to run.
terminal = "xterm"
editor = "gvim"
editor_cmd = terminal .. " -e " .. editor

-- Default modkey.
-- Usually, Mod4 is the key with a logo between Control and Alt.
-- If you do not like this or do not have such a key,
-- I suggest you to remap Mod4 to another key using xmodmap or other tools.
-- However, you can use another modifier like Mod1, but it may interact with others.
modkey = "Mod4"

-- Table of layouts to cover with awful.layout.inc, order matters.
local layouts =
{
  awful.layout.suit.max,
  --awful.layout.suit.max.fullscreen,
  awful.layout.suit.floating,
  awful.layout.suit.tile,
  awful.layout.suit.tile.left,
  awful.layout.suit.tile.bottom,
  awful.layout.suit.tile.top,
  awful.layout.suit.fair,
  awful.layout.suit.fair.horizontal,
  --awful.layout.suit.spiral,
  --awful.layout.suit.spiral.dwindle,
  awful.layout.suit.magnifier,
}

-- other varialbe added only for this module.
local config_dir = awful.util.getdir('config')
-- }}}1

--  Wallpaper                                                                           {{{1
if beautiful.wallpaper then
  for s = 1, screen.count() do
    gears.wallpaper.maximized(beautiful.wallpaper, s, true)
  end
end
-- }}}1

--  Tags                                                                                {{{1
-- Define a tag table which hold all screen tags.
tags = {}
for s = 1, screen.count() do
  -- Each screen has its own tag table.
  tags[s] = awful.tag({ 1, 2, 3, 4, 5, 6, 7, 8, 9 }, s, layouts[1])
end
-- }}}1

--  Menu                                                                                {{{1
-- Create a laucher widget and a main menu
myawesomemenu = {
  { "manual", terminal .. " -e man awesome" },
  { "edit config", editor_cmd .. " " .. awesome.conffile },
  { "restart", awesome.restart },
  { "quit", awesome.quit }
}

mymainmenu = awful.menu({ items = { { "awesome", myawesomemenu, beautiful.awesome_icon },
      { "open terminal", terminal }
    }
  })

mylauncher = awful.widget.launcher({ image = beautiful.awesome_icon,
    menu = mymainmenu })

-- Menubar configuration
menubar.utils.terminal = terminal -- Set the terminal for applications that require it
-- }}}1

--  Wibox                                                                               {{{1
markup = lain.util.markup

-- Separators                                                                              {{{2
spr = wibox.widget.textbox(' ')         -- a space as a separator

arrl = wibox.widget.imagebox()          -- left arror line
arrl:set_image(beautiful.arrl)

arrl_dl = wibox.widget.imagebox()       -- left arror triangle leader reverted
arrl_dl:set_image(beautiful.arrl_dl)

arrl_ld = wibox.widget.imagebox()       -- left arror triangle leader
arrl_ld:set_image(beautiful.arrl_ld)
-- }}}2

-- Textclock                                                                               {{{2
clockicon = wibox.widget.imagebox(beautiful.widget_clock)
textclock = awful.widget.textclock(" %b %d   %H:%M")
-- }}}2

-- Calendar                                                                                {{{2
lain.widgets.calendar:attach(textclock, { font_size = 8 })
--- }}}2

-- Net                                                                                     {{{2
neticon = wibox.widget.imagebox(beautiful.widget_net)
neticon:buttons(awful.util.table.join(
  awful.button({ }, 1, function () awful.util.spawn_with_shell(iptraf) end)
  )
)
netwidget = wibox.widget.background(lain.widgets.net({
    settings = function()
        widget:set_markup(markup("#7AC82E", " " .. net_now.received)
                          .. " " ..
                          markup("#46A8C3", " " .. net_now.sent .. " "))
    end
}), "#313131")
--- }}}2

-- ALSA volume                                                                             {{{2
volicon = wibox.widget.imagebox(beautiful.widget_vol)
volumewidget = lain.widgets.alsa({
    settings = function()
        if volume_now.status == "off" then
            volicon:set_image(beautiful.widget_vol_mute)
        elseif tonumber(volume_now.level) == 0 then
            volicon:set_image(beautiful.widget_vol_no)
        elseif tonumber(volume_now.level) <= 50 then
            volicon:set_image(beautiful.widget_vol_low)
        else
            volicon:set_image(beautiful.widget_vol)
        end

        widget:set_text(" " .. volume_now.level .. "% ")
    end
})
--- }}}2

-- CPU                                                                                     {{{2
cpuicon = wibox.widget.imagebox(beautiful.widget_cpu)
cpuwidget = wibox.widget.background(lain.widgets.cpu({
    settings = function()
        widget:set_text(" " .. cpu_now.usage .. "% ")
    end
}), "#313131")
-- }}}2

-- Create a wibox for each screen and add it                                               {{{2
topbar = {}
promptboxes = {}
layoutboxes = {}
taglists = {}
taglists.buttons = awful.util.table.join(
  awful.button({ }, 1, awful.tag.viewonly),
  awful.button({ modkey }, 1, awful.client.movetotag),
  awful.button({ }, 3, awful.tag.viewtoggle),
  awful.button({ modkey }, 3, awful.client.toggletag),
  awful.button({ }, 4, function(t) awful.tag.viewnext(awful.tag.getscreen(t)) end),
  awful.button({ }, 5, function(t) awful.tag.viewprev(awful.tag.getscreen(t)) end)
)
mytasklist = {}
mytasklist.buttons = awful.util.table.join(
  awful.button({ }, 1, function (c)
      if c == client.focus then
        c.minimized = true
      else
        -- Without this, the following
        -- :isvisible() makes no sense
        c.minimized = false
        if not c:isvisible() then
          awful.tag.viewonly(c:tags()[1])
        end
        -- This will also un-minimize
        -- the client, if needed
        client.focus = c
        c:raise()
      end
    end),
  awful.button({ }, 3, function ()
      if instance then
        instance:hide()
        instance = nil
      else
        instance = awful.menu.clients({ width=250 })
      end
    end),
  awful.button({ }, 4, function ()
      awful.client.focus.byidx(1)
      if client.focus then client.focus:raise() end
    end),
  awful.button({ }, 5, function ()
      awful.client.focus.byidx(-1)
      if client.focus then client.focus:raise() end
    end))

for s = 1, screen.count() do
  -- Create a promptbox for each screen
  promptboxes[s] = awful.widget.prompt()
  -- Create an imagebox widget which will contains an icon indicating which layout we're using.
  -- We need one layoutbox per screen.
  layoutboxes[s] = awful.widget.layoutbox(s)
  layoutboxes[s]:buttons(awful.util.table.join(
      awful.button({ }, 1, function () awful.layout.inc(layouts, 1) end),
      awful.button({ }, 3, function () awful.layout.inc(layouts, -1) end),
      awful.button({ }, 4, function () awful.layout.inc(layouts, 1) end),
      awful.button({ }, 5, function () awful.layout.inc(layouts, -1) end)))
  -- Create a taglist widget
  taglists[s] = awful.widget.taglist(s, awful.widget.taglist.filter.all, taglists.buttons)

  -- Create a tasklist widget
  mytasklist[s] = awful.widget.tasklist(s, awful.widget.tasklist.filter.currenttags, mytasklist.buttons)

  -- Create the wibox
  topbar[s] = awful.wibox({ position = "top", screen = s })

  -- topbar left layout                                                                       {{{3
  local left_layout = wibox.layout.fixed.horizontal()

  left_layout:add(mylauncher)
  left_layout:add(taglists[s])
  left_layout:add(promptboxes[s])
  -- }}}3

  -- topbar right layout                                                                      {{{3
  local right_layout = wibox.layout.fixed.horizontal()

  if s == 1 then right_layout:add(wibox.widget.systray()) end
  right_layout:add(spr)
  right_layout:add(arrl)

  right_layout:add(arrl_ld)
  right_layout:add(cpuicon)
  right_layout:add(cpuwidget)

  right_layout:add(arrl_dl)
  right_layout:add(volicon)
  right_layout:add(volumewidget)

  right_layout:add(arrl_ld)
  right_layout:add(neticon)
  right_layout:add(netwidget)

  right_layout:add(arrl_dl)
  right_layout:add(textclock)

  right_layout:add(spr)
  right_layout:add(arrl_ld)
  right_layout:add(layoutboxes[s])
  -- }}}3

  -- Now bring it all together (with the tasklist in the middle)                              {{{3
  local layout = wibox.layout.align.horizontal()

  layout:set_left(left_layout)
  layout:set_middle(mytasklist[s])
  layout:set_right(right_layout)

  topbar[s]:set_widget(layout)
  -- }}}3
end
-- }}}2

-- }}}1

--  Mouse bindings                                                                      {{{1
root.buttons(awful.util.table.join(
    awful.button({ }, 3, function () mymainmenu:toggle() end),
    awful.button({ }, 4, awful.tag.viewnext),
    awful.button({ }, 5, awful.tag.viewprev)
))
-- }}}1

--  Key bindings                                                                        {{{1

--  Global keys                                                                            {{{2
globalkeys = awful.util.table.join(
  awful.key({ modkey, }, "Left", awful.tag.viewprev ),
  awful.key({ modkey, }, ",", awful.tag.viewprev ),
  awful.key({ modkey, }, "Right", awful.tag.viewnext ),
  awful.key({ modkey, }, ".", awful.tag.viewnext ),
  awful.key({ modkey, }, "Escape", awful.tag.history.restore),

  awful.key({ modkey, }, "j",
    function ()
      awful.client.focus.byidx( 1)
      if client.focus then client.focus:raise() end
    end),
  awful.key({ modkey, }, "k",
    function ()
      awful.client.focus.byidx(-1)
      if client.focus then client.focus:raise() end
    end),
  --awful.key({ modkey, }, "w", function () mymainmenu:show() end),

  -- Layout manipulation
  awful.key({ modkey, "Shift" }, "j", function () awful.client.swap.byidx( 1) end),
  awful.key({ modkey, "Shift" }, "k", function () awful.client.swap.byidx( -1) end),
  awful.key({ modkey, "Control" }, "j", function () awful.screen.focus_relative( 1) end),
  awful.key({ modkey, "Control" }, "k", function () awful.screen.focus_relative(-1) end),
  awful.key({ modkey, }, "u", awful.client.urgent.jumpto),
  awful.key({ modkey, }, "Tab",
    function ()
      awful.client.focus.history.previous()
      if client.focus then
        client.focus:raise()
      end
    end),
  awful.key({ modkey, }, "f",
    function ()
      awful.layout.set(awful.layout.suit.max.fullscreen)
    end),
  awful.key({ modkey, }, "m",
    function ()
      awful.layout.set(awful.layout.suit.max)
    end),

  -- Standard program
  awful.key({ }, "Print", function () awful.util.spawn("screen_shot") end),
  awful.key({ modkey, }, "Return", function () awful.util.spawn(terminal) end),
  awful.key({ modkey, }, "g", function () awful.util.spawn(editor) end),
  awful.key({ modkey, }, "a", function () awful.util.spawn(
      "gvim --role 'vim-chameleon-startup' --cmd 'let g:mdx_chameleon_cur_mode = \"startup\" | set lines=9 columns=40 | winpos 750 300' -c 'set cmdheight=1' -c 'ChamStartup' -c xa") end),
  awful.key({ modkey, "Control" }, "r", awesome.restart),
  awful.key({ modkey, "Shift" }, "q", awesome.quit),

  awful.key({ modkey, }, "l", function () awful.tag.incmwfact( 0.05) end),
  awful.key({ modkey, }, "h", function () awful.tag.incmwfact(-0.05) end),
  awful.key({ modkey, "Shift" }, "h", function () awful.tag.incnmaster( 1) end),
  awful.key({ modkey, "Shift" }, "l", function () awful.tag.incnmaster(-1) end),
  awful.key({ modkey, "Control" }, "h", function () awful.tag.incncol( 1) end),
  awful.key({ modkey, "Control" }, "l", function () awful.tag.incncol(-1) end),
  awful.key({ modkey, }, "space", function () awful.layout.inc(layouts, 1) end),
  awful.key({ modkey, "Shift" }, "space", function () awful.layout.inc(layouts, -1) end),

  awful.key({ modkey, "Control" }, "n", awful.client.restore),

  -- Prompt
  awful.key({ modkey }, "r", function () promptboxes[mouse.screen]:run() end),
  awful.key({ modkey }, "x",
    function ()
      awful.prompt.run({ prompt = "Run Lua code: " },
        promptboxes[mouse.screen].widget,
        awful.util.eval, nil,
        awful.util.getdir("cache") .. "/history_eval")
    end),

  -- Menubar
  awful.key({ modkey }, "p", function() menubar.show() end)
)
-- }}}2

--  Client kyes                                                                            {{{2
clientkeys = awful.util.table.join(
  awful.key({ modkey, "Shift" }, "c", function (c) c:kill() end),
  awful.key({ modkey, "Control" }, "space", awful.client.floating.toggle ),
  awful.key({ modkey, "Control" }, "Return", function (c) c:swap(awful.client.getmaster()) end),
  awful.key({ modkey, }, "o", awful.client.movetoscreen ),
  awful.key({ modkey, }, "t", function (c) c.ontop = not c.ontop end),
  awful.key({ modkey, }, "n",
    function (c)
      -- The client currently has the input focus, so it cannot be
      -- minimized, since minimized clients can't have the focus.
      c.minimized = true
    end)
)
-- }}}2

-- Bind all key numbers to tags.
-- Be careful: we use keycodes to make it works on any keyboard layout.
-- This should map on the top row of your keyboard, usually 1 to 9.
for i = 1, 9 do
  globalkeys = awful.util.table.join(
    globalkeys,
    awful.key({ modkey }, "#" .. i + 9,
      function ()
        local screen = mouse.screen
        local tag = awful.tag.gettags(screen)[i]
        if tag then
          awful.tag.viewonly(tag)
        end
      end),
    awful.key({ modkey, "Control" }, "#" .. i + 9,
      function ()
        local screen = mouse.screen
        local tag = awful.tag.gettags(screen)[i]
        if tag then
          awful.tag.viewtoggle(tag)
        end
      end),
    awful.key({ modkey, "Shift" }, "#" .. i + 9,
      function ()
        if client.focus then
          local tag = awful.tag.gettags(client.focus.screen)[i]
          if tag then
            awful.client.movetotag(tag)
          end
        end
      end),
    awful.key({ modkey, "Control", "Shift" }, "#" .. i + 9,
      function ()
        if client.focus then
          local tag = awful.tag.gettags(client.focus.screen)[i]
          if tag then
            awful.client.toggletag(tag)
          end
        end
      end))
end

clientbuttons = awful.util.table.join(
  awful.button({ }, 1, function (c) client.focus = c; c:raise() end),
  awful.button({ modkey }, 1, awful.mouse.client.move),
  awful.button({ modkey }, 3, awful.mouse.client.resize))

-- load the 'run or raise' function
local ror = require("aweror")

-- -- generate and add the 'run or raise' key bindings to the globalkeys table
globalkeys = awful.util.table.join(globalkeys, ror.genkeys(modkey))

-- Set keys
root.keys(globalkeys)
-- }}}1

--  Rules                                                                               {{{1
awful.rules.rules = {
  -- All clients will match this rule.
  { rule = { },
    properties = { border_width = beautiful.border_width,
      border_color = beautiful.border_normal,
      focus = awful.client.focus.filter,
      keys = clientkeys,
      buttons = clientbuttons } },
  -- Always float these application windows.
  { rule_any = { class = { "feh", "MPlayer", "pinentry", "gimp", "Vlc", "Shutter" } },
    properties = { floating = true } },
  -- Specific application open in specific tag.
  { rule = { class = "Firefox" },
    properties = { tag = tags[1][2] } },
  { rule = { class = "VirtualBox" },
    properties = { tag = tags[1][4] } },
  -- Gapping issue.
  { rule_any = { class = { "Gvim", "XTerm" } },
    properties = { size_hints_honor = false } },
  -- vim startup mode.
  { rule = { class = "Gvim", role = "vim-chameleon-startup" },
    properties = { floating = true } },
}
-- }}}1

--  Signals                                                                             {{{1
-- Signal function to execute when a new client appears.
client.connect_signal("manage", function (c, startup)
    -- Enable sloppy focus
    c:connect_signal("mouse::enter", function(c)
        if awful.layout.get(c.screen) ~= awful.layout.suit.magnifier
        and awful.client.focus.filter(c) then
          client.focus = c
        end
      end)

    if not startup then
      -- Set the windows at the slave,
      -- i.e. put it at the end of others instead of setting it master.
      -- awful.client.setslave(c)

      -- Put windows in a smart way, only if they does not set an initial position.
      if not c.size_hints.user_position and not c.size_hints.program_position then
        awful.placement.no_overlap(c)
        awful.placement.no_offscreen(c)
      end
    end

    local titlebars_enabled = false
    if titlebars_enabled and (c.type == "normal" or c.type == "dialog") then
      -- buttons for the titlebar
      local buttons = awful.util.table.join(
        awful.button({ }, 1, function()
            client.focus = c
            c:raise()
            awful.mouse.client.move(c)
          end),
        awful.button({ }, 3, function()
            client.focus = c
            c:raise()
            awful.mouse.client.resize(c)
          end)
      )

      -- Widgets that are aligned to the left
      local left_layout = wibox.layout.fixed.horizontal()
      left_layout:add(awful.titlebar.widget.iconwidget(c))
      left_layout:buttons(buttons)

      -- Widgets that are aligned to the right
      local right_layout = wibox.layout.fixed.horizontal()
      right_layout:add(awful.titlebar.widget.floatingbutton(c))
      right_layout:add(awful.titlebar.widget.maximizedbutton(c))
      right_layout:add(awful.titlebar.widget.stickybutton(c))
      right_layout:add(awful.titlebar.widget.ontopbutton(c))
      right_layout:add(awful.titlebar.widget.closebutton(c))

      -- The title goes in the middle
      local middle_layout = wibox.layout.flex.horizontal()
      local title = awful.titlebar.widget.titlewidget(c)
      title:set_align("center")
      middle_layout:add(title)
      middle_layout:buttons(buttons)

      -- Now bring it all together
      local layout = wibox.layout.align.horizontal()
      layout:set_left(left_layout)
      layout:set_right(right_layout)
      layout:set_middle(middle_layout)

      awful.titlebar(c):set_widget(layout)
    end
  end)

client.connect_signal("focus", function(c) c.border_color = beautiful.border_focus end)
client.connect_signal("unfocus", function(c) c.border_color = beautiful.border_normal end)
-- }}}1

--  Autostart                                                                           {{{1

local autostart_targets = {
  "ibus-daemon -drx",
  "firefox",
  "VirtualBox",
  "dropboxd",
  --"play /usr/share/sounds/freedesktop/stereo/service-login.oga",
  "gvim"
}

for i = 1, #autostart_targets do
  awful.util.spawn_with_shell("run_once " .. autostart_targets[i])
end
--  }}}1

-- Timers
auto_wallpaper = timer( {timeout = 60} )
auto_wallpaper:connect_signal("timeout", function()
  awful.util.spawn_with_shell(
    'DISPLAY=:1.0 feh --bg-center "$(find /home/mudox/.wallpaper/ | shuf | head -n 1)"')
end)
auto_wallpaper:start()
