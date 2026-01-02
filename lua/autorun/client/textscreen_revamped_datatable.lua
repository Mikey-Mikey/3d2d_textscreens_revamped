TEXTSCREEN_REVAMPED = TEXTSCREEN_REVAMPED or {}

TEXTSCREEN_REVAMPED.FONTS = {
    -- These are custom fonts
    "Coolvetica",
    "Oxanium",
    "Segment",
    "Spicy Sale",

    -- These are the default fonts 
    "Arial",
    "Times New Roman",
    "Comic Sans MS",
}

TEXTSCREEN_REVAMPED.STYLES = {
    {
        style = "regular",
        weight = "regular"
    },
    {
        style = "regular",
        weight = "bold"
    },
    {
        style = "italic",
        weight = "regular"
    },
    {
        style = "italic",
        weight = "bold"
    }
}

TEXTSCREEN_REVAMPED.DEFAULT_PRESETS = {
    ["default"] = {
        entries = {
            {
                text = "[Insert Text Here]",
                effectData = {
                    font = "Arial",
                    size = 6,
                    color = {
                        r = 255,
                        g = 255,
                        b = 255,
                        a = 255
                    },
                    shadowColor = {
                        r = 0,
                        g = 0,
                        b = 0,
                        a = 0
                    },
                    strokeColor = {
                        r = 0,
                        g = 0,
                        b = 0,
                        a = 255
                    },
                    stroke = 1
                }
            },
        }
    },
    ["garry's mod textscreens revamped"] = {
        entries = {
            {
                text = "garry's mod",
                effectData = {
                    font = "Coolvetica",
                    size = 6,
                    color = {
                        r = 180,
                        g = 220,
                        b = 255,
                        a = 255
                    },
                    shadowColor = {
                        r = 0,
                        g = 180,
                        b = 255,
                        a = 255
                    },
                    strokeColor = {
                        r = 0,
                        g = 0,
                        b = 0,
                        a = 0
                    },
                    stroke = 1
                }
            },
            {
                text = "textscreens revamped",
                effectData = {
                    font = "Coolvetica",
                    size = 6,
                    color = {
                        r = 255,
                        g = 192,
                        b = 255,
                        a = 255
                    },
                    shadowColor = {
                        r = 255,
                        g = 0,
                        b = 255,
                        a = 255
                    },
                    strokeColor = {
                        r = 0,
                        g = 0,
                        b = 0,
                        a = 0
                    },
                    stroke = 1
                }
            },
        }
    }
}

TEXTSCREEN_REVAMPED.DOMPurify = include( "includes/purify.lua" )