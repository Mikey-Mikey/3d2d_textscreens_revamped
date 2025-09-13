-- Library that parses my custom markup language for the text screens.

local TextscreenMarkup = {}
TextscreenMarkup.__index = TextscreenMarkup

--[[ pseudo lineData structure:
line = {
	blocks = {
		block = {
			text = "",
			fontName = "",
			color = "0,0,0",
		}
	}
}
]]


function TextscreenMarkup:new(lineData)
	
end

function TextscreenMarkup:Draw(x, y, xAlign, yAlign)

end

local tags = {
	["font"] = {
		opener = "<font=",
		closer = "</font>",
		attributes = "%s"
	}
}

function TextscreenMarkup.parse(txt)
	local fontStack = {} -- Stack of fonts in-use.
	fontStack[1] = "NewFont" -- Default font is always on top.

	local markupObj = TextscreenMarkup:new()

	return markupObj
end