local router = require "resty.router"
local config = require "conf.config"
local lfs = require "lfs"

local log = ngx.log
local ngx_exit = ngx.exit
local concat = table.concat
local io_open = io.open
local chdir = lfs.chdir
local mkdir = lfs.mkdir

local ERR = ngx.ERR
local WARN = ngx.WARN
local INFO = ngx.INFO

local prefix = config.destination.prefix

local r = router.new()

r:post('/upload/:icao', function(params)
    ngx.req.read_body()
    local body = ngx.req.get_body_data()

    if not body or #body == 0 then
        log(WARN, "No payload")
        ngx.status = 406
        ngx_exit(406)
        do return end
    end

    local t, err = chdir(prefix)
    if not t then
        local t, err = mkdir(prefix)
        if not t then
            log(WARN, "Could not create the images storage area")
            ngx.status = 406
            ngx_exit(406)
            do return end
        end
    end

    local t, err = chdir(concat{prefix, params.icao, "/"})
    if not t then
        local t, err = mkdir(concat{prefix, params.icao, "/"})
        if not t then
            log(WARN, "Could not create the datasource's images storage area")
            ngx.status = 406
            ngx_exit(406)
            do return end
        end
    end

    local path = concat{prefix, params.icao, "/image.jpg"}

    local file, err = io_open(path , "w+")
    if file then
        file:write(body)
        file:close()
        log(INFO, "Image updated; ", path)
    else
        if err then
            log(WARN, "Unable to write the file ", path, ": ", err)
        else
            log(WARN, "Unable to write the file ", path)
        end
    end


end)

local found = r:execute(ngx.req.get_method():lower(), ngx.var.uri)
if not found then
    ngx.status = 404
    ngx_exit(404)
end