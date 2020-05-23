--[[
 hangman.lua
 Author: Eric Najork and David Najork

 Class: CSC 372: Comparative Programming Languages
 Assignment: Project #1, Part #3
 Instructor: Lester McCann
 TA: Tito Ferra and Josh Xiong
 Due: December 9th, 2019
 Description: this program implements the game of hangman
 as a World of Warcraft Addon. To open the game, use the
 slash command `/hm` or `/hangman` in the World of Warcraft
 client's chat. This addon is written to be compatible with
 WoW version 8.2.5 and Classic WoW.
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

-- loadRoot
--
-- Purpose: obtain a reference to the root frame
-- and initialize the game
-- Pre: this is a reference to the root frame
-- Post: the forwarding of keyboard inputs to the addon 
-- is disabled
-- Return: none
-- Parameters: this (the root frame)
-- Direction: in
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

-- rootEvents
--
-- Purpose: handle events connected to the root frame
-- Pre: event is a PLAYER_STARTED_MOVING, PLAYER_STOPPED_MOVING
-- or CURSOR_UPDATE event
-- Post: the opacity of the addon window is decreased when
-- the player moves and increased when they stop. Also, when
-- Escape is pressed, keyboard input no longer is forwarded
-- to the addon.
-- Return: none
-- Parameters: event
-- Direction: in
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

-- hookConfirm
--
-- Purpose: obtain a reference to the confirm button
-- Pre: this is a reference to the confirm button defined
-- in hangman.xml
-- Post: none
-- Return: none
-- Parameters: this (the confirm button)
-- Direction: in
function hookConfirm(this)
  confirmButton = this
end

-- minimize
--
-- Purpose: hide the addon frame
-- Pre: none
-- Post: keyboard input forwarding is disabled and the
-- addon frame is hidden
-- Return: none
-- Parameters: none
-- Direction: none
function minimize()
  if hidden then
    root:Show()
  else
    root:Hide()
  end
  hidden = not hidden
  root:EnableKeyboard(false)
end

-- focusGame
--
-- Purpose: enable keyboard input capturing
-- Pre: none
-- Post: keyboard input is forwarded to the addon frame
-- Return: none
-- Parameters: none
-- Direction: none
function focusGame()
  if not isOver then
    root:EnableKeyboard(true)
  end
end

-- escapePressed
--
-- Purpose: disable keyboard input capturing when escape
-- is pressed
-- Pre: none
-- Post: keyboard input is not forwarded to the addon frame
-- Return: none
-- Parameters: none
-- Direction: none
function escapePressed()
  root:EnableKeyboard(false)
end

-- handleKey
--
-- Purpose: handle keyboard keydown events
-- Pre: key is the string value of the key
-- that is currently down
-- Post: the keyboard event is handled
-- Return: none
-- Parameters: key (key that is down)
-- Direction: in
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

-- updatePreview
--
-- Purpose: update the display for user's currently
-- selected letter
-- Pre: key is the string value of the key
-- Post: the selection preview is updated
-- Return: none
-- Parameters: key (key that is down)
-- Direction: in
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

-- refresh
--
-- Purpose: restart the game of hangman
-- Pre: none
-- Post: the game is reset
-- Return: none
-- Parameters: none
-- Direction: none
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

-- obscure
--
-- Purpose: generate the string representation
-- of the obscured version of the current word.
-- ex: `DOG` becomes `- - - ` with no guesses
--     `DOG` becomes `- O - ` with "O" guessed.
-- Pre: str is the word to be obscured
-- Post: none
-- Return: the obscured version of given word
-- Parameters: str (the word being obscured)
-- Direction: both
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

-- unobscure
--
-- Purpose: generate the string representation
-- of the unobscured version of the current word.
-- ex: `DOG` becomes `D O G`
-- Pre: str is the word to be unobscured
-- Post: none
-- Return: the unobscured version of given word
-- Parameters: str (the word being unobscured)
-- Direction: both
function unobscure(str)
  local result = ""
  for i = 1, #str do
    result = result .. str:sub(i, i) .. " "
  end
  return result
end

-- correctContains
--
-- Purpose: check if a character is contained in the
-- correct guesses table
-- Pre: char is a letter
-- Post: none
-- Return: true if the character is contained in the
-- correct guess table, otherwise false
-- Parameters: char (the character to check for)
-- Direction: both
function correctContains(char)
  for i = 1, #correct do
    if correct[i] == char then
      return true
    end
  end
  return false
end

-- incorrectContains
--
-- Purpose: check if a character is contained in the
-- incorrect guesses table
-- Pre: char is a letter
-- Post: none
-- Return: true if the character is contained in the
-- incorrect guess table, otherwise false
-- Parameters: char (the character to check for)
-- Direction: both
function incorrectContains(char)
  for i = 1, #incorrect do
    if incorrect[i] == char then
      return true
    end
  end
  return false
end

-- wordContains
--
-- Purpose: check if a character is contained in the
-- word
-- Pre: char is a letter
-- Post: none
-- Return: true if the character is contained in the
-- word, otherwise false
-- Parameters: char (the character to check for)
-- Direction: both
function wordContains(char)
  for i = 1, #word do
    if word:sub(i, i) == char then
      return true
    end
  end
  return false
end

-- confirm
--
-- Purpose: confirm the letter selection
-- Pre: none
-- Post: add the guess to the word or incorrect
-- guess list. Increment the number of incorrect 
-- guesses the user has made and display if the
-- user has won or lost the game.
-- Return: none
-- Parameters: none
-- Direction: none
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

-- getIncorrect
--
-- Purpose: get the the string representation of the
-- list of incorrect guesses the user has made
-- Pre: none
-- Post: none
-- Return: the string representation of the list of
-- incorrect guesses the user has made
-- Parameters: none
-- Direction: out
function getIncorrect()
  local result = ""
  for i = 1, #incorrect do
    result = result .. " " .. incorrect[i]
  end
  return result
end

-- transitionEnd
--
-- Purpose: clear the screen of the current selection
-- preview and the confirm button. Also, disable all
-- keyboard input forwarding.
-- Pre: none
-- Post: clear the screen in preparation of the end
-- Return: none
-- Direction: none
function transitionEnd()
  root.previewPrefix:Hide()
  root.preview:Hide()
  confirmButton:Hide()
  root:EnableKeyboard(false)
end

-- win
--
-- Purpose: display the winning message
-- Pre: none
-- Post: display the winning message
-- Return: none
-- Parameters: none
-- Direction: none
function win()
  isOver = true
  transitionEnd()
  root.endText:SetText("YOU WIN!")
  root.endText:SetTextColor(0.5, 1.0, 0.5, 1.0)
end

-- lose
--
-- Purpose: display the losing message
-- Pre: none
-- Post: display the losing message
-- Return: none
-- Parameters: none
-- Direction: none
function lose()
  isOver = true
  transitionEnd()
  root.endText:SetText("YOU LOSE!")
  root.endText:SetTextColor(1.0, 0.5, 0.5, 1.0)
  root.word:SetText(unobscure(word))
end

-- slashCommand
--
-- Purpose: handle slash commands entered
-- by the user
-- Pre: msg is a string containing the text
-- that followed after the user's slash
-- command
-- Post: the slash command is handled
-- Return:none
-- Parameters: msg (the argument provided
-- to the slash command)
-- Direction: in
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