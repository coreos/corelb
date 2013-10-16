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


local init = require("coreinit")

local debug = true

local dprint = function(msg)
  if debug == true then
    print("coreinit/loadbalancer: " .. msg)
  end
end

local LoadBalancer = {}

function LoadBalancer:new(conf)
  local l = {}
  setmetatable(l, self)
  self.__index = self

  self._init = init:new(conf.etcd)
  self._unit = self._init:unit(conf.unit)

  dprint("created loadbalancer for unit: " .. conf.unit .. " and etcd: " .. conf.etcd)
  return l
end

function LoadBalancer:sync()
  local machines, err = self._unit:machines()

  if err ~= nil then
    print("Error getting machines: " .. err.errorCode)
    return err
  end

  -- This has to be here so we don't overwrite our cache in case of sync failure
  self._machines = machines

  return nil
end

function LoadBalancer:upstream()
  local machine
  if (self._machines) == nil or (self._machines[1] == nil) then
    print("Error: No machines to load balance!")
    return nil
  end
  machine = self._machines[1]
  local addr = machine:addrs()[1].addr
  addr = string.match(addr, "(.+)/")
  return "http://" .. addr .. ":8000"
end

return LoadBalancer
