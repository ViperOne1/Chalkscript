async_http.init('raw.githubusercontent.com','/ViperOne1/Chalkscript/main/raw/Chalkscript-Raw.lua',function(a)
    local err = select(2,load(a))
    if err then
        util.toast("-Chalkscript-\n\nScript Failed to Download off Github.")
    return end
    local f = io.open(filesystem.scripts_dir()..SCRIPT_RELPATH, "wb")
    f:write(a)
    f:close()
    util.toast("-Chalkscript\n\nSuccessfully Installed Chalkscript.\nHave Fun!")
    util.restart_script()
end)
async_http.dispatch()
repeat 
    util.yield()
until response
util.keep_running()
