#!/usr/bin/env lua

local colors= {
  red = 31,
  white = 0,
}
local function makeColor(colorNumber)
  return string.format('\27[%dm', tostring(colorNumber))
end
local function getCmdOutput(cmd)
  local openPop = assert(io.popen(cmd))
  local output = openPop:read('*all')
  openPop:close()
  return output
end

local visibleSpaceCsv = getCmdOutput('yabai -m query --spaces  | jq -r \'map(select((."has-focus" == true) or (.label | length > 0) or (.windows | length > 0)))[] | [.index, .label, .display, ."has-focus"] | @csv\'')
-- print(visibleSpaceCsv)
local display = tonumber(getCmdOutput('yabai -m query --displays --display | jq ".index"'))
-- print(display)
local function split(str, sep)
  local ret = {}
  for v in string.gmatch(str, '([^' .. sep .. ']*)') do
    table.insert(ret, v)
  end
  return ret
end
local spaces = split(visibleSpaceCsv, '\n')
local spaceInfo = {}
local temp
for _, space in pairs(spaces) do
  if #space > 0 then
    temp = split(space, ',') -- index, label, display, visible
    table.insert(spaceInfo, temp)
  end
end
local function getDisplayName(item, display)
  local ret
  if item[2] and #(item[2]) > 2 then
    ret = string.sub(item[2], 2, -2) .. '(' .. item[1] .. ')'
  else
    ret = item[1]
  end
  if item[4] == 'true' then
    if display == tonumber(item[3]) then
      ret = '' .. ret .. ''
    end
    ret = makeColor(colors.red) .. ret .. makeColor(colors.white)
  end
  return ret
end
local str = ''
local currentDisplay = 0
for _, item in pairs(spaceInfo) do
  if currentDisplay ~= item[3] then
    str = str .. ' '
    currentDisplay = item[3]
  end
  str = str .. ' ' .. getDisplayName(item, display)
end
str = str .. '  | font="FiraCode Nerd Font" ansi=true'
print(str)
print('---')
print('yabai spaces')
