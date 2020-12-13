local function AdminLog(message, colour, allowedPlys)
    local RF = RecipientFilter()
    for _, v in pairs(allowedPlys) do
        local canHear = hook.Call("canSeeLogMessage", GAMEMODE, v, message, colour)

        if canHear then
            RF:AddPlayer(v)
        end
    end

    umsg.Start("DRPLogMsg", RF)
        umsg.Short(colour.r)
        umsg.Short(colour.g)
        umsg.Short(colour.b) -- Alpha is not needed
        umsg.String(message)
    umsg.End()
end

function DarkRP.log(text, colour, noFileSave)
    if colour then
        CAMI.GetPlayersWithAccess("DarkRP_SeeEvents", fp{AdminLog, text, colour})
    end
end
