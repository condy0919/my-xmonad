import qualified Data.Map as M
import System.Exit

import XMonad
import XMonad.Actions.CopyWindow
import XMonad.Actions.CycleWS
import XMonad.Actions.DynamicWorkspaces
import qualified XMonad.Actions.FlexibleResize as Flex
import XMonad.Actions.GridSelect
import XMonad.Actions.Promote
import XMonad.Actions.ShowText
import XMonad.Actions.SinkAll
import XMonad.Actions.UpdatePointer
import XMonad.Actions.WindowBringer
import XMonad.Hooks.DynamicLog
import XMonad.Hooks.EwmhDesktops (ewmh, ewmhDesktopsStartup)
import XMonad.Hooks.FadeInactive
import XMonad.Hooks.ManageDocks
import XMonad.Hooks.ManageHelpers
import XMonad.Hooks.SetWMName
import XMonad.Hooks.UrgencyHook
import XMonad.Layout.BinarySpacePartition as BSP hiding (Swap)
import XMonad.Layout.Fullscreen
import XMonad.Layout.NoBorders
import XMonad.Layout.NoFrillsDecoration
import XMonad.Layout.Renamed
import XMonad.Layout.ShowWName
import XMonad.Layout.Simplest
import XMonad.Layout.SimplestFloat
import XMonad.Layout.SubLayouts
import XMonad.Layout.Tabbed
import XMonad.Layout.TwoPane
import XMonad.Layout.WindowNavigation
import XMonad.Prompt
import XMonad.Prompt.Man
import XMonad.Prompt.Pass
import qualified XMonad.StackSet as W
import XMonad.Util.Cursor
import XMonad.Util.EZConfig
import XMonad.Util.Run
import XMonad.Util.Scratchpad
import XMonad.Util.SpawnOnce
import XMonad.Util.Types
import XMonad.Util.Ungrab

-- Colors
base03     = "#002b36"
base02     = "#073642"
base01     = "#586e75"
base00     = "#657b83"
base0      = "#839496"
base1      = "#93a1a1"
base2      = "#eee8d5"
base3      = "#fdf6e3"
black      = "#000000"
white      = "#FFFFFF"
yellow     = "#b58900"
purple     = "#C678DD"
orange     = "#cb4b16"
red        = "#dc322f"
magenta    = "#dc3682"
violet     = "#6c71c4"
blue       = "#268bd2"
light_blue = "#51AFEF"
dark_blue  = "#3939ff"
cyan       = "#2aa198"
light_cyan = "#1ABC9C"
green      = "#859900"

-- Themes
topBarTheme =
  def
    { fontName = myFont
    , inactiveColor = base03
    , inactiveTextColor = base03
    , inactiveBorderColor = base03
    , activeColor = blue
    , activeTextColor = blue
    , activeBorderColor = blue
    , urgentColor = red
    , urgentTextColor = yellow
    , urgentBorderColor = red
    , decoHeight = 2
    }


tabTheme =
  def
    { fontName = myFont
    , activeColor = green
    , activeTextColor = base03
    , activeBorderColor = green
    , inactiveColor = base02
    , inactiveTextColor = base00
    , inactiveBorderColor = base02
    , urgentColor = red
    , urgentTextColor = red
    , urgentBorderColor = red
    }

showWNameTheme =
  def
    { swn_font = myWideFont
    , swn_fade = 0.5
    , swn_color = white
    , swn_bgcolor = black
    }

promptTheme =
  def
    { font = myFont
    , bgColor = base03
    , fgColor = blue
    , fgHLight = base03
    , bgHLight = blue
    , borderColor = base03
    , promptBorderWidth = 0
    , height = 20
    , position = Top
    }

-- Layouts
tabbedLayout = avoidStruts
  $ renamed [Replace "Tabbed"]
  $ noBorders (tabbed shrinkText tabTheme)

bspLayout = avoidStruts
  $ renamed [CutWordsLeft 1]
  $ noFrillsDeco shrinkText topBarTheme -- topbar
  $ windowNavigation
  $ renamed [Replace "BSP"]
  $ addTabs shrinkText tabTheme
  $ subLayout [] Simplest
  $ BSP.emptyBSP

floatLayout = avoidStruts
  $ renamed [Replace "Float"]
  $ windowNavigation
  $ simplestFloat

twoPaneLayout = avoidStruts
  $ renamed [Replace "Two"]
  $ windowNavigation
  $ TwoPane delta ratio
  where
    delta = 3/100
    ratio = 1/2


myLayoutHook =
  bspLayout ||| tabbedLayout ||| floatLayout ||| twoPaneLayout ||| noBorders Full

-------------------------------------------------------------
------------------- user settings ---------------------------
-------------------------------------------------------------

-- My favored terminal.
myTerminal = "alacritty"
myScratchpadTerminal = "alacritty --class scratchpad"

-- Fonts
myFont = "xft:DejaVu Sans Mono:size=9:bold:antialias=true"
myWideFont = "xft:DejaVu Sans Mono:size=120:bold:antialias=true"

-- Rofi is unparalleled.
myLauncherCommand = "rofi"
myLauncherConfig = "-sort -matching fuzzy -theme Arc-Dark"
myLauncher = myLauncherCommand ++ " " ++ myLauncherConfig ++ " -show run"

-- imitate dmenu
myDMenu = myLauncherCommand
myDMenuArgs = ["-dmenu", "-i"] ++ words myLauncherConfig

-- Powerful yet simple to use screenshot tool
myScreenshot = "flameshot gui -p ~/Pictures/Screenshots"

-- A suckless screensaver
myScreensaver = "slock"

-- my Emacs
myEmacsClientCommand = "emacsclient -a \"\" -c"

-- Workspaces
-- The default number of workspaces and their names.
myWorkspaces = map show [1..9]


-- Manage hook
myManageHook =
  composeAll
    [ isFullscreen --> (doF W.focusDown <+> doFullFloat)
    , isDialog --> doCenterFloat
    , appName =? "desktop_window" --> doIgnore
    -- firefox download dialog
    , appName =? "Places" --> doCenterFloat
    , className =? "Display" --> doCenterFloat
    , className =? "GoldenDict" --> doCenterFloat
    -- xmonad use xmessage to show parsed errors
    , className =? "Xmessage" --> doCenterFloat
    -- Fast and light imlib2-based image viewer
    , className =? "feh" --> doCenterFloat
    -- a free, open source, and cross-platform media player
    , className =? "mpv" --> doCenterFloat
    -- zeal, an offline API documentation browser
    , className =? "Zeal" --> doCenterFloat
    -- if the given window is of type DOCK, reveals it
    , manageDocks
    -- scratchpad where
    --   distance from left edge = 12.5%
    --   distance from top edge  = 25%
    --   width                   = 75%
    --   height                  = 50%
    , scratchpadManageHook (W.RationalRect 0.125 0.25 0.75 0.5)
    ]

-- Startup hook
-- Perform an arbitrary action each time xmonad starts or is restarted.
myStartupHook = do
  ewmhDesktopsStartup
  -- Set the mouse cursor style
  setDefaultCursor xC_left_ptr
  -- HiDPI solution
  spawnOnce "xrdb -merge ~/.Xresources"
  -- Screenshot app
  spawnOnce "flameshot"
  -- Clipboard
  spawnOnce "parcellite"
  -- Input Method
  spawnOnce "fcitx5"
  -- Set background wallpaper
  spawnOnce "feh --bg-scale ~/.xmonad/background.jpg"
  -- X compositor
  spawnOnce "picom -cCGfF -o 0.38 -O 200 -I 200 -t 0 -l 0 -r 3 -D2 -m 0.8"
  -- Status bar
  spawnOnce "polybar main"

-------------------------------------------------------------
--------------------------- mouse ---------------------------

-- Mouse bindings
myMouseBindings (XConfig {XMonad.modMask = modm}) =
  M.fromList
    [ ((modm, button1), (\w -> focus w >> mouseMoveWindow w))
    , ((modm, button2), (\w -> focus w >> windows W.swapMaster))
    -- Resize floating windows from any corner.
    , ((modm, button3), (\w -> focus w >> Flex.mouseResizeWindow w))
    ]


-- Focus rules
-- True if your focus shoud follow your mouse cursor.
myFocusFollowsMouse :: Bool
myFocusFollowsMouse = True

-------------------------------------------------------------
------------------------- keyboard --------------------------
-- Key bindings
myKeybindings =
  let zipKey mod keys xs f = zipWith (\k x -> (mod ++ k, f x)) keys xs
      wsKeys = map show [1 .. 9]
  in
    -- Workspaces
    -- mod-[1..9], Switch to  workspace N
    zipKey "M-" wsKeys [0 ..] (withNthWorkspace W.greedyView) ++
    -- mod-shift-[1..9], Move client to workspace N
    zipKey "M-S-" wsKeys [0 ..] (withNthWorkspace W.shift) ++
    -- mod-control-[1..9], Copy client to workspace N
    zipKey "M-C-" wsKeys [0 ..] (withNthWorkspace copy) ++
    -- Workspace browsing
    [("M-n", nextWS), ("M-p", prevWS), ("M-<Escape>", toggleWS)] ++

    -- Quit and Restart
    [ ("M-S-q", io (exitWith ExitSuccess))
    , ("M-C-r", spawn "xmonad --recompile && xmonad --restart")

    -- Take a screenshot
    -- Release xmonad's keyboard grab, so other grabbers can do their thing.
    , ("<Print>", unGrab >> spawn myScreenshot)

    -- Standard programs
    , ("M-r", spawn myLauncher)
    , ("M-<Return>", spawn myTerminal)
    , ("M-S-<Return>", scratchpadSpawnActionCustom $ myScratchpadTerminal)

    -- Functional keys
    , ("<XF86AudioMute>", spawn "amixer -q set Master toggle")
    , ("<XF86AudioLowerVolume>", spawn "amixer -q set Master 1%-")
    , ("<XF86AudioRaiseVolume>", spawn "amixer -q set Master 1%+")
    , ("<XF86MonBrightnessDown>", spawn "xbacklight -10")
    , ("<XF86MonBrightnessUp>", spawn "xbacklight +10")
    , ("<XF86Display>", spawn "xset dpms force standby")
    , ("<XF86Favorites>", spawn myScreensaver)

    -- Layouts
    -- Using M-S-<Space> to reset the layout on the current workspace to default.
    , ("M-<Space>", sendMessage NextLayout)

    -- Screens
    -- Make mouse cursor move to the next screen
    , ("M-o", nextScreen >> updatePointer (0.5, 0.5) (0, 0))
    , ("M-S-o", shiftNextScreen >> updatePointer (0.5, 0.5) (0, 0))
    , ("M-C-o", swapNextScreen)

    -- Windows
    , ("M-a", promote)
    , ("M-t", withFocused $ windows . W.sink)
    , ("M-,", sendMessage (IncMasterN 1))
    , ("M-.", sendMessage (IncMasterN (-1)))
    , ("M-<Tab>", windows W.focusDown)
    , ("M-S-<Tab>", windows W.focusUp)
    , ("M-S-t", sinkAll)
    , ("M-S-c", kill)

    -- Urgent event happened
    , ("M-<Backspace>", focusUrgent)
    , ("M-S-<Backspace>", clearUrgents)

    -- Directional navigation of windows
    , ("M-h", sendMessage $ Go L)
    , ("M-l", sendMessage $ Go R)
    , ("M-j", sendMessage $ Go D)
    , ("M-k", sendMessage $ Go U)

    -- Swap adjacent windows
    , ("M-S-h", sendMessage $ Swap L)
    , ("M-S-l", sendMessage $ Swap R)
    , ("M-S-j", sendMessage $ Swap D)
    , ("M-S-k", sendMessage $ Swap U)

    -- Bindings for manage sub tabs in layouts
    -- Merge windows
    , ("M-C-h", sendMessage $ pullGroup L)
    , ("M-C-l", sendMessage $ pullGroup R)
    , ("M-C-k", sendMessage $ pullGroup U)
    , ("M-C-j", sendMessage $ pullGroup D)
    , ("M-C-m", withFocused (sendMessage . MergeAll))
    , ("M-C-u", withFocused (sendMessage . UnMerge))

    -- Bindings for BinarySpacePartition
    -- Resize windows
    , ("M-[", sendMessage $ ExpandTowards L)
    , ("M-]", sendMessage $ ExpandTowards R)
    , ("M-S-[", sendMessage $ ExpandTowards U)
    , ("M-S-]", sendMessage $ ExpandTowards D)

    -- Jump to windows
    , ("M-b", bringMenuConfig $ def {menuCommand = myDMenu, menuArgs = myDMenuArgs})
    , ("M-g", gotoMenuConfig $ def {menuCommand = myDMenu, menuArgs = myDMenuArgs})

    -- Prompts
    , ("M-m p", passPrompt promptTheme)
    , ("M-m m", manPrompt promptTheme)
    , ("M-m e", spawn myEmacsClientCommand)
    ]


myForbiddenKeys =
  [ "M-q"
  , "M-w"
  , "M-e"
  , "M-S-q"
  , "M-S-w"
  , "M-S-e"
  , "M-S-r"
  , "M-S-/"
  ]

-- Run xmonad with all the defaults we set up.
main = do
  xmonad . docks $ -- automatically manage dock type programs, such as statusbar
    ewmh $ withUrgencyHook NoUrgencyHook
      def
        { terminal = myTerminal
        , focusFollowsMouse = myFocusFollowsMouse
        , focusedBorderColor = dark_blue
        -- Rebind Mod to the Windows key
        , modMask = mod4Mask
        , mouseBindings = myMouseBindings
        , workspaces = myWorkspaces
        , manageHook = myManageHook
        -- Check invalid/duplicated keybindings first
        , startupHook = checkKeymap def myKeybindings >> myStartupHook
        , handleEventHook = fullscreenEventHook <+> handleTimerEvent
        , layoutHook = myLayoutHook
        } `additionalKeysP`
    myKeybindings `removeKeysP`
    myForbiddenKeys
