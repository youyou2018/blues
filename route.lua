local tinsert = table.insert
local Route =  {}

function Route:Init()
end

function Route:getInstance()
        local instance = {}
        instance.map = {
            get = {},   --get
            post = {}   --post
        }

        instance.id = 1

        local base = {}
        function base.register(this, baseA, baseB, url, callback, meta)
                lp("$$$$$$$$$$[  base. register  ]$$$$$$$$$$$$$$$$$$$")
                lp(meta)
                lp(type(this))
                for k,v  in pairs(this) do
                        lp(k,v)
                end
                lp(type(baseA))
                for k,v  in pairs(baseA) do
                        lp(k,v)
                end
                lp(type(baseB))
                for k,v  in pairs(baseB) do
                        lp(k,v)
                end
                lp("$$$$$$$$$$$$$$$$$$$$$$$$$$$$$")

                --get
                if meta == "GET" then
                        tinsert(this.map.get, {url, callback})
                elseif meta == "POST" then
                        tinsert(this.map.post, {url, callback})
                end
        end

        base.__call = base.register
        setmetatable(instance, base)
        return instance
end

function Route:run(router)
        --get
        --post
        local url = "/def"
        local method = "GET"

        if method == "POST" then
                for k,v in pairs(router.map.post) do
                        lp(router.map.post[k][1])
                        lp(router.map.post[k][2])
                        if router.map.post[k][1] == url then
                                return router.map.post[k][2]
                        end
                end
        end

        if method == "GET" then
                for k,v in pairs(router.map.get) do
                        lp(router.map.get[k][1])
                        lp(router.map.get[k][2])
                        if router.map.get[k][1] == url then
                                return router.map.get[k][2]
                        end
                end
        end

--[[
        if method == "get" then
                return router.map.get[1][2]
        elseif method == "post" then
                return router.map.post[1][2]
        end
--]]
        --return router.map
end

function Route:match()
        return true
end

return Route
