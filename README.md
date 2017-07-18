# ActionMirroringFrame
Addon for WoW 1.12 (vanilla)

## Features
Display a frame showing used actions.

## Settings
Command line options (/amf, /actionmirroringframe):

Command        | Argument(s)      | Default | Effect
---------------|------------------|---------|--------------------------------------------------------------------------------------------
usage          |                  |         | display usage instructions
standby        | [true\|false]    | false   | disable/enable the mirroring frame for this session
show           | [true\|false]    | false   | show/hide the movable handle, the handle can be clicked to change overflow growth direction
timeout        | [\<seconds>]     | 1.00    | activation duration
flashtime      | [\<seconds>]     | 0.20    | activation hightlight duration
scale          | [\<coefficient>] | 1.00    | scale of the frame
overflow       | [\<num>]         | 2       | number of extra mirrors
overflowTime   | [\<seconds>]     | 0.66    | time withing the mirror will overflow
sticky         | [true\|false]    | true    | if true, active actions will now timeout (e.g. casting actions)
color          | cast\|click      |         | display color picking for: <ul><li>*cast*: actions in progress</li><li>*click*: actions just used</li></ul>
cooldownTip    | [true\|false]    |         | show/hide cooldown time over mirrors
costTip        | [true\|false]    |         | show/hide missing mana/rage/energy over mirrors
cooldownTipThreshold | [<seconds>]| 1.5     | set the minimum duration of the cooldown for the cooldown tip to be shown
