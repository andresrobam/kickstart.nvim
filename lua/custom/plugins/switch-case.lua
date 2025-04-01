-- local function isAllowedChar(ch, nextToSeparator)
--   if nextToSeparator then
--     return ch:find('[A-Za-z]')
--   else
--     return ch:find('[A-Za-z_-]')
--   end
-- end
--
-- local function isSeparator(ch)
--   return ch == '-' or ch == '_'
-- end
--
-- local function getWord(line, column)
--   local ch = line:sub(column, column)
--   if not isAllowedChar(ch, false) then
--     return ''
--   end
--   local out = ch
--   local sep = isSeparator(ch)
--   for i = column + 1, #line do
--     ch = line:sub(i, i)
--     if isAllowedChar(ch, sep) then
--       out = out .. ch
--       sep = isSeparator(ch)
--     else
--       break
--     end
--   end
--   for i = column - 1, 1, -1 do
--     ch = line:sub(i, i)
--     if isAllowedChar(ch, sep) then
--       out = ch .. out
--       sep = isSeparator(ch)
--     else
--       break
--     end
--   end
--   return out
-- end

local function switch_case()
  local line, col = unpack(vim.api.nvim_win_get_cursor(0))
  local word = vim.fn.expand '<cword>'
  local word_start = vim.fn.matchstrpos(vim.fn.getline '.', '\\k*\\%' .. (col + 1) .. 'c\\k*')[2]

  local function splitByString(input, splitter)
    local t = {}
    for str in string.gmatch(input, '([^' .. splitter .. ']+)') do
      table.insert(t, str)
    end
    return t
  end

  local function upper(str)
    return str:upper()
  end

  local function lower(str)
    return str:lower()
  end

  local function splitBeforeEveryCapitalLetter(input)
    local out = {}
    for i = 1, #input do
      local char = input:sub(i, i)
      if char == char:upper() then
        table.insert(out, '')
      end
      if #out == 0 then
        table.insert(out, '')
      end
      out[#out] = out[#out] .. char
    end
    return out
  end

  local function splitByUnderscore(input)
    return splitByString(input, '_')
  end

  -- local function splitByDash(input)
  --   return splitByString(input, '-')
  -- end

  local function firstUpper(str)
    return (str:lower():gsub('^%l', string.upper))
  end

  local function getReplacement(str, oldCase, newCase)
    local split = oldCase[4](str)
    local out = newCase[5](split[1])
    for i = 2, #split do
      out = out .. newCase[3] .. newCase[6](split[i])
    end
    return out
  end

  local function replace(str)
    vim.api.nvim_buf_set_text(0, line - 1, word_start, line - 1, word_start + #word, { str })
  end

  local cases = {
    { 'camelCase', '^[a-z]+[A-Z][a-zA-Z]*$', '', splitBeforeEveryCapitalLetter, lower, firstUpper },
    { 'PascalCase', '^[A-Z][a-zA-Z]*$', '', splitBeforeEveryCapitalLetter, firstUpper, firstUpper },
    { 'SCREAMING_SNAKE_CASE', '^[A-Z]+_[_A-Z]*$', '_', splitByUnderscore, upper, upper },
    { 'snake_case', '^[a-z]+_[_a-z]*$', '_', splitByUnderscore, lower, lower },
    -- { 'TRAIN-CASE', '^[A-Z]+-[-A-Z]*$', '-', splitByDash, upper, upper },
    -- { 'kebab-case', '^[a-z]+-[-a-z]*$', '-', splitByDash, lower, lower },
  }

  local match = 0
  for i = 1, #cases do
    if word:find(cases[i][2]) then
      match = i
      break
    end
  end

  if match == 0 then
    return
  end

  local newCase = match + 1

  if newCase > #cases then
    newCase = 1
  end

  replace(getReplacement(word, cases[match], cases[newCase]))
end

return { switch_case = switch_case }
