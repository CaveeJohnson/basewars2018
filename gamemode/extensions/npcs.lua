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

    timer.Simple(spawn_time, function()
        local npc = ents.Create(type)
        if not IsValid(npc) then return end
            npc:SetPos(pos)
            npc:DropToFloor()
        npc:Spawn()
        npc:Activate()

        sound.Play(summon_sound_done, pos)
    end)
end
