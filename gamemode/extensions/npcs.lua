local ext = basewars.createExtension"npcs"
basewars.npcs = {}

sound.Add({
    channel = CHAN_AUTO,
    name    = "bw.npc_summon.1",
    level   = 100,
    sound   = ")npc/antlion/attack_double1.wav",
    volume  = 0.8,
    pitch   = {40, 45}
})

sound.Add({
    channel = CHAN_AUTO,
    name    = "bw.npc_summon.2",
    level   = 100,
    sound   = ")ambient/atmosphere/thunder1.wav",
    volume  = 0.8,
    pitch   = {200, 200}
})

sound.Add({
    channel = CHAN_AUTO,
    name    = "bw.npc_summon.done",
    level   = 100,
    sound   = ")weapons/mortar/mortar_explode3.wav",
    volume  = 0.8,
    pitch   = {80, 90}
})

if CLIENT then

    timer.Create(ext:getTag(), 60, 0, game.RemoveRagdolls)

    --register spawning effect
    local Effect = {}
    function Effect:Init(data)

        local EmitterPos = data:GetOrigin()
        local Size = data:GetScale()
        local Lifetime = data:GetMagnitude()
        local Emitter = ParticleEmitter(EmitterPos)

        self.DieTime = CurTime() + Lifetime

        for i = 0, 100 do
            timer.Simple(Lifetime / 100 * i, function()
                if not Emitter or not Emitter.Add then return end
                local part = Emitter:Add("effects/fire_embers3", EmitterPos)
                if part then
                    part:SetDieTime(5)
                    part:SetRoll(math.Rand(0, 360))
                    part:SetStartAlpha(255)
                    part:SetEndAlpha(0)
                    part:SetStartSize(10 * Size)
                    part:SetEndSize(5)
                    part:SetGravity(Vector(0, 0, 10))
                    part:SetVelocity(VectorRand() * 20 * Vector(1,1,0.5))
                end
            end)
        end

        for i = 0, 100 do
            timer.Simple(Lifetime / 100 * i, function()
                if not Emitter or not Emitter.Add then return end
                local part = Emitter:Add("effects/ar2ground2", EmitterPos)
                if part then
                    part:SetDieTime(2)
                    --part:SetRoll(math.Rand(0, 360))
                    part:SetRoll(0)
                    part:SetStartAlpha(255)
                    part:SetEndAlpha(0)
                    part:SetStartSize(50 * Size)
                    part:SetEndSize(0)
                    part:SetGravity(Vector(0, 0, 50))
                end
            end)
        end

        for i = 0, 20 do
            if not Emitter or not Emitter.Add then return end
            local part = Emitter:Add("effects/fire_cloud1", EmitterPos)
            if part then
                part:SetDieTime(5)
                part:SetRoll(math.Rand(0,360))
                part:SetStartAlpha(255)
                part:SetEndAlpha(0)
                part:SetStartSize(7 * Size)
                part:SetEndSize(2)
                part:SetGravity(Vector(0, 0, 30))
                part:SetVelocity(VectorRand() * 20 * Vector(1,1,2))
            end
        end

        timer.Simple(Lifetime + 2, function()
            if IsValid(Emitter) then
                Emitter:Finish()
            end
        end)

    end

    function Effect:Think()
        if self.DieTime and CurTime() > self.DieTime then
            return false
        end

        return true
    end

    function Effect:Render()
    end

    effects.Register(Effect, "basewars_npcspawn", true)


    local renderer = basewars.hrefMat("http://q2f2.u.catgirlsare.sexy/Ia3v.png") -- runes
    local rot = 0

    ext.spawning = {}

    function ext:PostDrawTranslucentRenderables(depth, sky)
        if depth or sky then return end
        local new = {}
        local ct = CurTime()

        local add = FrameTime() * 50
        rot = rot + add -- speed
        for _, v in ipairs(self.spawning) do
            local mult = math.min(1, (1 - ((v.spawns_at - ct) / v.spawn_time)) * 2)

            cam.Start3D2D(v.pos, Angle(0, rot + (add * mult * 10), 0), v.scale * mult)
                renderer(-32, -32, 64, 64)
            cam.End3D2D()

            if v.spawns_at > ct then
                table.insert(new, v)
            end

        end

        self.spawning = new
    end

    net.Receive(ext:getTag(), function()
        table.insert(ext.spawning, {
            pos        = net.ReadVector() + Vector(0, 0, 0.01),
            spawn_time = net.ReadUInt(8),
            scale      = net.ReadUInt(8),
            spawns_at  = net.ReadFloat(),
        })
    end)

    return
end

util.AddNetworkString(ext:getTag())

local summon_sound1     = Sound("bw.npc_summon.1")
local summon_sound2     = Sound("bw.npc_summon.2")
local summon_sound_done = Sound("bw.npc_summon.done")

ext.typeList = {
    ["npc_antlionguard"] = {spawn_time = 8, scale = 4,}
}

function basewars.npcs.spawn(type, pos)
    local type_vars = ext.typeList[type]

    local spawn_time = type_vars and type_vars.spawn_time or 5
    local scale = type_vars and type_vars.scale or 1

    net.Start(ext:getTag())
        net.WriteVector(pos)
        net.WriteUInt(spawn_time, 8)
        net.WriteUInt(scale, 8)
        net.WriteFloat(CurTime() + spawn_time)
    net.Broadcast()

    sound.Play(summon_sound1, pos)
    sound.Play(summon_sound2, pos)

    local eff = EffectData()
    eff:SetOrigin(pos)
    eff:SetScale(scale)
    eff:SetMagnitude(spawn_time)
    util.Effect("basewars_npcspawn", eff)
    --util.Effect("Explosion", eff)

    timer.Simple(spawn_time, function()
        local npc_data = list.Get("NPC")[type] or {}
        local npc = ents.Create(npc_data["Class"] or type)
        if not IsValid(npc) then return end
            local weapon = npc_data["Weapons"] or npc_data["weapon"]
            if weapon then
                if istable(weapon) then
                    weapon = table.Random(weapon)
                end

                npc:SetKeyValue("additionalequipment", weapon)
            end

            npc:SetPos(pos + Vector(0, 0, 16))
            npc:SetAngles(Angle(0, math.random(0, 360), 0))
            npc:DropToFloor()
        npc:Spawn()

        local model = npc_data["Model"] or npc_data["model"]
        if model then
            npc:SetModel(model)
        end

        local scale = npc_data["Scale"] or npc_data["scale"]
        if scale then
            npc:SetModelScale(scale)
        end

        local health = npc_data["Health"] or npc_data["health"]
        if health and health > 0 then
            npc:SetHealth(health)
            npc:SetMaxHealth(health)
        end

        local spawnflags = npc_data["SpawnFlags"] or npc_data["spawn_flags"]
        if spawnflags and spawnflags > 0 then
            npc:SetKeyValue("spawnflags", spawnflags)
        end

        local keyvalues = npc_data["KeyValues"] or npc_data["key_values"]
        if keyvalues then
            for k, v in pairs(keyvalues) do
                npc:SetKeyValue(k, v)
            end
        end

        local wepprof = npc_data["WeaponProficiency"] or npc_data["weapon_proficiency"]
        if npc.SetCurrentWeaponProficiency and wepprof then
            local weaponProficiency = nil

            if     wepprof == "Poor" then
                weaponProficiency = WEAPON_PROFICIENCY_POOR
            elseif wepprof == "Average" then
                weaponProficiency = WEAPON_PROFICIENCY_AVERAGE
            elseif wepprof == "Good" then
                weaponProficiency = WEAPON_PROFICIENCY_GOOD
            elseif wepprof == "Very good" then
                weaponProficiency = WEAPON_PROFICIENCY_VERY_GOOD
            elseif wepprof == "Perfect" then
                weaponProficiency = WEAPON_PROFICIENCY_PERFECT
            elseif isnumber(wepprof) then
                weaponProficiency = wepprof
            end

            if weaponProficiency then
                npc:SetCurrentWeaponProficiency(weaponProficiency)
            end
        end

        npc:Activate()
        npc:Fire("StartPatrolling")
        npc:Fire("SetReadinessHigh")
        if npc.SetNPCState then npc:SetNPCState(NPC_STATE_COMBAT) end

        sound.Play(summon_sound_done, pos)
    end)
end

function basewars.npcs.findSpawnable()
    local areas = navmesh.GetAllNavAreas()

    for _, v in RandomPairs(areas) do
        local p = v:GetRandomPoint()

        if not v:IsUnderwater() and not basewars.bases.getForPos(p) then
            return p
        end
    end

    return false
end
