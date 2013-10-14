local http = require("http")
local cjson = require("cjson")

-- Client implements a new etcd Client
local Client = {}

local keyPrefix = "/v1/keys"

-- new returns a new etcd.Client object
function Client:new(url)
  local c = {}
  setmetatable(c, self)
  self.__index = self
  c.base_url = url or "http://127.0.0.1:4001"
  return c
end

-- _keyURL generates the URL for an etcd key based on the base_url and prefix
function Client:_keyURL(key)
  return self.base_url .. keyPrefix .. "/" .. key
end

-- _handleRequest unwraps an etcd request
function Client:_handleRequest(body, code)
  if code ~= 200 then
    local err = {errorCode = code}
    return nil, err
  end

  value = cjson.decode(body)

  if value.errorCode ~= nil then
    return nil, err
  end

  return value
end

-- get grabs a key out of the etcd data store
function Client:get(key)
  local url = self:_keyURL(key)
  local body, code = http.request(url)

  return self:_handleRequest(body, code)
end

-- set places the key and value into the etcd data store
function Client:set(key, value)
  local url = self:_keyURL(key)
  local body, code = http.request(url, "value="..value)
  return self:_handleRequest(body, code)
end

return {
  Client = Client
}
