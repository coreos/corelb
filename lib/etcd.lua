-- Copyright 2013 CoreOS, Inc
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.

local http = require("resty.http")
local hc = http:new()
local cjson = require("cjson")

local debug = false

local dprint = function(msg)
  if debug == true then
    print("etcd: " .. msg)
  end
end

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
  local ok, code, headers, status, body = hc:request{
    url = url,
    method = "GET"
  }

  dprint("get: " .. url)

  return self:_handleRequest(body, code)
end

-- set places the key and value into the etcd data store
function Client:set(key, value)
  local url = self:_keyURL(key)
  local ok, code, headers, status, body = hc:request{
    url = url,
    body = "value="..value,
    method = "POST"
  }

  dprint("set: " .. url .. " value: " .. value)
  return self:_handleRequest(body, code)
end

return Client
