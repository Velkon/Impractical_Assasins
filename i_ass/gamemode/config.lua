GM:Print("Loading config...")
file.CreateDir(GM.Name)

function GM:LoadFile(s,fun)
    if file.Exists("data/" .. GM.Name .. "/" .. s,"GAME") then
        GM:Print("\tLoading data/" .. GM.Name .. "/" .. s .. "...")
        fun(file.Read("data/" .. GM.Name .. "/" .. s,"GAME"))
    elseif file.Exists("gamemodes/" .. engine.ActiveGamemode() .. "/data/" .. GM.Name .. "/" .. s,"GAME") then
        GM:Print("\tLoading data/" .. GM.Name .. "/" .. s .. " from the gamemode...")
        fun(file.Read("gamemodes/" .. engine.ActiveGamemode() .. "/data/" .. GM.Name .. "/" .. s,"GAME"))
    else
        GM:Print("\t->data/" .. GM.Name .. "/" .. s .. " not found, ignoring...")
    end
end

GM:LoadFile(game.GetMap() .. "_custom_spawns.txt",function(s)
    local a = util.JSONToTable(s)
    if not a then
        ErrorNoHalt("\t[" .. GM.Name .. "] Could not load custom spawns for this map! Are you sure it's in JSON format?\nPlease check the gm_construct one for an example.\n")
    else
        GM.CustomSpawns = a
    end
end)