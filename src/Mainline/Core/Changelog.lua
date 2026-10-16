local _, ns = ...
local N = ns.N

N.Changelog = {
    {
        version = "1.0.4",
        date = "2026-10-16",
        notes = {
            "Raid groups can be laid out on a grid: Groups per row, Row spacing and Group flow give every raid group a fixed place, so for example groups 5 and 6 appear beside the first four rows (off by default).",
            "New settings search in the options window header (or Ctrl+F): type part of a setting's name, in your language or in English, and click a result to jump to it.",
            "Click-Casting presets: save the current bindings under a name and load or delete them later (per class, shared by all profiles). Resurrection spells now appear in the spell list as well.",
            "New aura rows (off by default): Debuffs 2, 3 and 4, each with its own filter, position and look, and Defensives & Externals, which shows both cooldown lists in one row.",
            "Utilities: the pull timer can show remaining or elapsed time (also with the total) and say Go! or 0 when it ends; Ready & Pull, Battle Res and Marks get a background, border, opacity and strata, and an option to show them only on mouseover.",
            "New Death Report utility (off by default): says when a group member dies, for you only or in the group chat, optionally only during encounters and only for tanks and healers.",
            "Health Bar Color has a Dead color for the health bar of dead or ghost units.",
            "Bar textures and fonts that other addons register with LibSharedMedia-3.0 can be chosen under Bar texture and in General > Fonts.",
            "New Debug console (General > Interface > Debug console, off by default): logs internal Nucleus messages into its own window.",
            "Less CPU in groups and raids: power events are only used while a power bar or power text is shown, events for one unit within a frame are handled together, and indicators find their frames through a lookup.",
            "Party, raid and pet frames are no longer created in the middle of combat after a login or /reload; they appear when the combat ends.",
            "Fixed Lua errors from the raid marker indicator, the marker bar and group pings when the game hides a value (Retail, Forever).",
        },
    },
    {
        version = "1.0.3",
        date = "2026-10-14",
        notes = {
            "Stack and timer text of the aura rows and custom indicators: choose the anchor point and the text color.",
            "Name: new Max characters option to shorten long names.",
            "New Column spacing option for the raid and group pet frames: the gap between the columns (the raid groups), next to Spacing between the frames of a column.",
            "Raid can use the Group's settings: in the Position tab, appearance, indicators, aura rows and custom indicators can each be shared between Group and Raid, so a change in one changes both.",
            "New Position tab: where the frames sit (anchor point, X / Y, centering, attach to owner) and copying settings between Group and Raid; the General card with the move handle settings is called Move handles.",
            "Block indicators show the cooldown animation, stack count and remaining time again (Retail, Forever).",
            "Cell import: icon, text and row positions that use a different anchor on the indicator than on the frame, rectangular icon sizes, icons per line and spacing of custom icon rows, and the Spotlight size now convert correctly.",
            "Fixed the Position of the icon indicators (Role, Class / Spec, Leader, Ready Check, Raid Marker, Status Icon, Combat Icon) and \"Show all classes\" of the Buffs row being reset after a reload.",
            "Hide Blizzard frames also hides the raid / party preview frames in Edit Mode and frames that ignore their container's transparency; the new /nucblizz command lists what is still visible.",
        },
    },
    {
        version = "1.0.2",
        date = "2026-10-13",
        notes = {
            "Fixed the health bar gradient falling back to the class color while health is hidden; Fade at Full Health also works then.",
            "Dispel spells such as Dispel Magic appear in the Click-Casting spell list.",
            "Click-Casting: the Item list shows your equipped trinkets and other usable equipped items, bound by slot so they follow a swap and work in combat.",
            "New \"Font outline\" option (thin, thick, none) for the name, health text and status indicators.",
            "\"Cast by\" choices (me, anyone, others) for custom indicators and the Debuffs row, so debuffs cast by players such as Weakened Soul can be shown.",
            "General tab split into \"All profiles\" and \"Per profile\" sections; Tooltip, Click-Casting, Utilities and Spotlight can be shared by all profiles; new tooltip position option.",
            "Frame position: anchor point, X / Y values and centering per group; a middle anchor point grows the group from the middle.",
            "Test Mode: a menu next to the button previews several groups at once, and the preview follows Group by and Sort.",
            "Frames redraw right away when a group member leaves; Spotlight units can be moved up and down; Auto Switch has a Battleground (10) rule.",
            "Fixed Attach to owner, the time text color and decimals, and the Glow distance being reset on every login.",
            "Smaller changes: one \"Move tools\" switch, Spotlight in Copy settings, larger group name offsets, X / Y names for Attach to owner, \"Group\" instead of \"Party\" in English, no duplicate movers in Test Mode, the language follows the game by default (it was German); marker buttons set marks through /tm.",
            "NPC frames are on by default and show friendly boss units (such as the end boss of Temple of Sethraliss) next to the group frames; companions stay among the group frames unless \"Move companions here\" is on; new /nucnpc command.",
            "First version of Classic Era and TBC support, so far tested only by the author: simpler than Retail and Forever (no ping, heal / shield prediction, private auras or targeted spell bars), spells match by name so every rank works, plus a Targeted Spells indicator that only exists there.",
        },
    },
    {
        version = "1.0.1",
        date = "2026-10-12",
        notes = {
            "Click-Casting: mouse wheel, keyboard keys and extra mouse buttons (6 and up) can be bound; macros fire reliably.",
            "Frame width updates the header and the shield, heal prediction and absorb bars right away.",
            "Icon rows and custom indicators: new \"Icons per row\" and \"Row spacing\", a larger spacing range, and fixes for Anchor and size.",
            "The indicator preview shows the configured frame size and your class color.",
            "Test mode shows up to 8 raid groups, follows the group selection and custom sorting, and uses a 1 tank / 1 healer / 3 damage dealer party.",
            "Move handles: smaller and resizable, a \"Bar\" style, X / Y offset, ALT-only drag mode, only the edited group is shown; party and raid frames can be moved in combat.",
            "The minimap button is a standard LibDBIcon button, so button managers can group it.",
            "Fixed the \"Reload now\" button after changing the language.",
        },
    },
    {
        version = "1.0.0",
        date = "2026-10-08",
        notes = {
            "First Release",
        },
    },
}
