local P = mvp.package.Get()

P.animations = P.animations or {}
P.animations.list = {}
P.animations.listSeq = {}

function P.animations.GetAll()
    return P.animations.list
end

function P.animations.Get(id)
    return P.animations.list[id]
end

function P.animations.Add(id, data)
    P.animations.list[id] = data
    P.animations.listSeq[#P.animations.listSeq + 1] = id
end

mvp.loader.LoadFile("packages/" .. P:GetCWD() .. "/sh_animations_list.lua")