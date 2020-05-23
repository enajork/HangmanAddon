--[[
 written by topkek
--]]

local AddOn, config = ... -- import config
-- initialize global variables
words = config.words
PREFIX_INCORRECT = "INCORRECT: "
PREFIX_GUESSES = "GUESSES: "
SUFFIX_GUESSES = "/6"
MAX_GUESSES = 6
DEMO_MODE = false
DEV_MODE = false -- this should be false by default
incorrect = {}
correct = {}

function loadRoot(this)
  root = this
  root:EnableKeyboard(false)
  refresh()
  if DEV_MODE then
    root:Show()
    hidden = false
  else
    hidden = true
  end
end

function rootEvents(event)
  if event == "PLAYER_STARTED_MOVING" then
    root:SetAlpha(0.5)
    root:EnableKeyboard(false)
  elseif event == "PLAYER_STOPPED_MOVING" then
    root:SetAlpha(0.9)
  elseif event == "CURSOR_UPDATE" then
    root:EnableKeyboard(false)
  end
end

function hookConfirm(this)
  confirmButton = this
end

function minimize()
  if hidden then
    root:Show()
  else
    root:Hide()
  end
  hidden = not hidden
  root:EnableKeyboard(false)
end

function focusGame()
  if not isOver then
    root:EnableKeyboard(true)
  end
end

function escapePressed()
  root:EnableKeyboard(false)
end

function handleKey(key)
  if key == "ESCAPE" then
    -- unfocus the addon frame 
    -- when escape is pressed
    escapePressed()
  elseif key == "BACKSPACE" then
    -- clear the selection preview
    root.preview:SetText("")
  elseif key == "ENTER" then
    confirm()
  else
    updatePreview(key)
  end
end

function updatePreview(key)
  if isOver then
    return
  end
  -- only allow letters to be pressed and only ones that
  -- have not been guessed already
  if string.match(key, "%u") ~= nil and  #key == 1 
      and not correctContains(key) 
      and not incorrectContains(key) then
    root.preview:SetText(key)
  end
end

function refresh()
  -- reset variables
  isOver = false
  guesses = 0
  countCorrect = 0
  correct = {}
  incorrect = {}
  -- randomize the word
  word = words[math.random(#words)]
  if DEMO_MODE then print(word) end
  -- reset graphics
  root.word:SetText(obscure(word))
  root.preview:SetText("")
  root.incorrect:SetText(PREFIX_INCORRECT .. getIncorrect())
  root.guesses:SetText(PREFIX_GUESSES .. "0" .. SUFFIX_GUESSES)
  root.previewPrefix:Show()
  root.preview:Show()
  confirmButton:Show()
  root.endText:SetText("")
end

function obscure(str)
  -- countCorrect is used to determine the
  -- win condition (when countCorrect is
  -- equal to the length of the word)
  countCorrect = 0
  local result = ""
  for i = 1, #str do
    if correctContains(str:sub(i, i)) then
      result = result .. str:sub(i, i)
      countCorrect = countCorrect + 1
    else
      result = result .. "-"
    end
    result = result .. " "
  end
  return result
end

function unobscure(str)
  local result = ""
  for i = 1, #str do
    result = result .. str:sub(i, i) .. " "
  end
  return result
end

function correctContains(char)
  for i = 1, #correct do
    if correct[i] == char then
      return true
    end
  end
  return false
end

function incorrectContains(char)
  for i = 1, #incorrect do
    if incorrect[i] == char then
      return true
    end
  end
  return false
end

function wordContains(char)
  for i = 1, #word do
    if word:sub(i, i) == char then
      return true
    end
  end
  return false
end

function confirm()
  if root.preview:GetText() ~= nil and root.preview:GetText() ~= "" then
    if wordContains(root.preview:GetText()) then
      -- add correct guesses to the display
      table.insert(correct, root.preview:GetText())
      -- update the word display
      root.word:SetText(obscure(word))
      root.preview:SetText("")
      if countCorrect == #word then
        win()
      end
    else
      -- add incorrect guesses to the display
      table.insert(incorrect, root.preview:GetText())
      root.incorrect:SetText(PREFIX_INCORRECT .. getIncorrect())
      root.preview:SetText("")
      -- update the number of guesses used
      guesses = guesses + 1
      root.guesses:SetText(PREFIX_GUESSES .. tostring(guesses) .. SUFFIX_GUESSES)
      if guesses == 6 then
        lose()
      end
    end
  end
end

function getIncorrect()
  local result = ""
  for i = 1, #incorrect do
    result = result .. " " .. incorrect[i]
  end
  return result
end

function transitionEnd()
  root.previewPrefix:Hide()
  root.preview:Hide()
  confirmButton:Hide()
  root:EnableKeyboard(false)
end

function win()
  isOver = true
  transitionEnd()
  root.endText:SetText("YOU WIN!")
  root.endText:SetTextColor(0.5, 1.0, 0.5, 1.0)
end

function lose()
  isOver = true
  transitionEnd()
  root.endText:SetText("YOU LOSE!")
  root.endText:SetTextColor(1.0, 0.5, 0.5, 1.0)
  root.word:SetText(unobscure(word))
end

function slashCommand(msg)
  if msg == "" then
    -- minimize when the argument
    -- provided is empty
    minimize()
  elseif msg == "demo" then
    if not DEV_MODE then
      return
    end
    -- enable demo mode when the
    -- "demo" argument is provided
    DEMO_MODE = not DEMO_MODE
    print("DEMO_MODE: " .. tostring(DEMO_MODE))
    if DEMO_MODE then print(word) end
  end
end

-- create slash commands
SLASH_HANGMAN1 = "/hm"
SLASH_HANGMAN2 = "/hangman"
SlashCmdList["HANGMAN"] = slashCommand
