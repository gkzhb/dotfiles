-- Set up the logger
local log = hs.logger.new('WindowMover', 'info')

-- Function to get spaceId by space name
function getSpaceIdByName(spaceName)
  local spaceNames = hs.spaces.missionControlSpaceNames()
  for uuid, desktops in pairs(spaceNames) do
    log.i("UUID: " .. uuid)                                     -- Log the UUID
    for index, name in pairs(desktops) do
      log.i("Index: " .. index .. ", Name: " .. tostring(name)) -- Log the index and name
      if name == spaceName then
        log.i("Found spaceId for " .. spaceName .. ": " .. index)
        return index
      end
    end
  end
  log.w("Space not found: " .. spaceName)
  return nil
end

-- Convert seconds to microseconds
local timeUnit = 1000 * 1000
-- delay: in seconds
function asyncLeftClick(point, delay, onFinished)
  local module = hs.eventtap
  module.event.newMouseEvent(module.event.types["leftMouseDown"], point):post()
  -- module.event.newMouseEvent(module.event.types["leftMouseDragged"], point):post()

  hs.timer.doAfter(delay, function()
    module.event.newMouseEvent(module.event.types["leftMouseUp"], point):post()
    if onFinished then
      onFinished()
    end
  end)
end

-- Get offset based on window title
local function getOffsetByTitle(title)
  -- TODO update diff
  if title == "Chrome" then
    return 10, 20
  elseif title == "Visual Studio Code" then
    return 15, 25
  elseif title == "iTerm2" then
    return 5, 15
  elseif title == "Finder" then
    return 8, 18
  else
    return 5, 15  -- default offset
  end
end

-- Move window to space
function moveWindowToSpace(window, spaceNumber)
    log.i("Moving window " .. window:title() .. " to space " .. spaceNumber)
  local prevCursorPoint = hs.mouse.absolutePosition()
  local winFrame = window:frame()
  
  local xOffset, yOffset = getOffsetByTitle(window:title())
  local point = hs.geometry(winFrame.x + xOffset, winFrame.y + yOffset)
  asyncLeftClick(point, 1, function()
    -- restore cursor position
    hs.mouse.absolutePosition(prevCursorPoint)
  end)
  -- Switch to target space with Mission Control shortcuts
  if spaceNumber < 10 then
    hs.eventtap.keyStroke({ 'alt' }, tostring(spaceNumber), 0.2 * timeUnit)
  else
    hs.eventtap.keyStroke({ 'alt', 'ctrl' }, tostring(spaceNumber - 10), 0.2 * timeUnit)
  end
end

-- Function to move focused window to a specific space
function moveFocusedWindowToSpace(spaceNumber)
  local spaceName = "Desktop " .. spaceNumber
  log.i("Attempting to move window to " .. spaceName)
  local focusedWindow = hs.window.focusedWindow()
  if focusedWindow then
    moveWindowToSpace(focusedWindow, spaceNumber)
  else
    log.w("No focused window")
    hs.alert.show("No focused window")
  end
end

-- TODO: cmd and alt are reversed?
-- Bind keys cmd + shift + 0-9
for i = 0, 9 do
  hs.hotkey.bind({ "alt", "shift" }, tostring(i), function()
    log.i("Hotkey pressed: cmd + shift + " .. i)
    if i == 0 then
      moveFocusedWindowToSpace(10)
    else
      moveFocusedWindowToSpace(i)
    end
  end)
end
-- Bind keys alt + shift + 1-6
for i = 1, 6 do
  hs.hotkey.bind({ "cmd", "shift" }, tostring(i), function()
    log.i("Hotkey pressed: alt + shift + " .. i)
    moveFocusedWindowToSpace(i + 10)
  end)
end
