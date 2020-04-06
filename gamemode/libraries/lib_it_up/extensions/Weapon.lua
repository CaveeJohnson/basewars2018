local WEAPON = FindMetaTable("Weapon")

--https://github.com/ZehMatt/Lambda/blob/develop/entities/weapons/weapon_physcannon.lua#L2276-L2308



if CLIENT then
    local pi = math.pi
    local tg = math.tan

    function WEAPON:PositionToViewmodel(pos, inverse)

        local origin = EyePos()
        local fov = LocalPlayer():GetFOV()
        local worldx = tg( fov * pi / 360 )
        local viewx = tg( self.ViewModelFOV * pi / 360 )
        local factorX = worldx / viewx
        local factorY = factorX

        local ang = EyeAngles()
        local right = ang:Right()
        local up = ang:Up()
        local fwd = ang:Forward()

        local tmp = pos - origin
        local transformed = Vector( right:Dot(tmp), up:Dot(tmp), fwd:Dot(tmp) )

        if inverse then
            if factorX ~= 0 and factorY ~= 0 then
                transformed.x = transformed.x / factorX
                transformed.y = transformed.y / factorX
            else
                transformed.x = 0
                transformed.y = 0
            end
        else
            transformed.x = transformed.x * factorX
            transformed.y = transformed.y * factorX
        end

        return origin + (right * transformed.x) + (up * transformed.y) + (fwd * transformed.z)

    end
end