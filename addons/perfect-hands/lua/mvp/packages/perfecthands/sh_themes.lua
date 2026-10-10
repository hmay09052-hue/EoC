local P = mvp.package.Get()

P.themes = P.themes or {}
P.themes.list = P.themes.list or {}

function P.themes.GetAll()
    return P.themes.list
end

function P.themes.Get(name)
    return P.themes.list[name]
end

function P.themes.Register(id, data)
    P.themes.list[id] = data

    mvp.q.LogInfo("Perfect Hands", "Registered theme " .. id)
end