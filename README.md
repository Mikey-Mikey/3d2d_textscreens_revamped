# Textscreens Revamped
This repo contains all of the source code for the workshop addon.

## Font Addition Example
You can very easily add fonts using TEXTSCREEN_REVAMPED.AddFont()

Your folder structure has to at least have a clientside autorun lua file and the .ttf font in the resource/fonts folder of your addon.

### [lua/autorun/client/fontpack.lua](https://github.com/Mikey-Mikey/3d2d_textscreens_fontpack_example/blob/main/lua/autorun/client/fontpack.lua)
```lua
-- InitPostEntity is required since the TEXTSCREEN_REVAMPED table is not available before then.
-- The hook name ( second parameter ) can be whatever name you want but keep it unique to prevent conflictions.
-- I used fontpack.AddFonts because the addon name is "fontpack" and the hook adds fonts.
hook.Add( "InitPostEntity", "fontpack.AddFonts", function()
    if not TEXTSCREEN_REVAMPED then
        MsgC( Color( 255, 0, 0 ), "Textscreens Revamped is not installed!\n" )
        return
    end

    -- Add your fonts here. They have to be named exactly the same as the font in your addon's resource/fonts folder.
    -- If your font is a .otf you have to change the file extension to .ttf in your resource/fonts folder. It will not mess up the font.
    TEXTSCREEN_REVAMPED.AddFont( "VCR OSD Mono" ) -- Without the .ttf
end )
```

### [Github for the full fontpack example](https://github.com/Mikey-Mikey/3d2d_textscreens_fontpack_example)
