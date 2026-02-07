TEXTSCREEN_REVAMPED = TEXTSCREEN_REVAMPED or {}
if CLIENT then
    TEXTSCREEN_REVAMPED.RenderDistanceCVar = CreateClientConVar( "textscreen_render_distance", 4000, true, false )
    TEXTSCREEN_REVAMPED.ShowTextscreenBoundsCVar = CreateClientConVar( "textscreen_show_bounds", 0, true, false )
end

TEXTSCREEN_REVAMPED.RateLimitCVar = CreateConVar( "textscreen_revamped_ratelimit", 10, { FCVAR_REPLICATED, FCVAR_ARCHIVE } )