local _, ns = ...
local N = ns.N

N.Changelog = {
    {
        version = "1.0.1",
        date = "2026-10-12",
        notes = {
            "Click-Casting: the mouse wheel, keyboard keys and extra mouse buttons (6 and up) can be bound; macros now fire reliably.",
            "Frame width now updates the header and the shield, heal prediction and absorb bars right away.",
            "Icon rows and custom indicators: new \"Icons per row\" and \"Row spacing\" options, a larger spacing range, and fixes for the Anchor and size settings.",
            "The indicator preview shows the configured frame size and your class color.",
            "Test mode shows up to 8 raid groups, follows the group selection and custom sorting, and uses a 1 tank / 1 healer / 3 damage dealer party.",
            "Move handles: smaller, resizable, a \"Bar\" style with its own width, an X / Y offset, an ALT-only drag mode, only the edited group is shown, and party and raid frames can be moved in combat.",
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
