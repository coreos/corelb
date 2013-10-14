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

local etcd = require("etcd")

local initPrefix = "coreos.com/coreinit/"
local machinePrefix = "machines/"
local systemPrefix = "system/"

local Init = {}

-- new returns a new etcd.Init object
function Init:new(url)
  local c = {}
  setmetatable(c, self)
  self.__index = self
  url = url or "http://127.0.0.1:4001"
  self._etcd = etcd:new(url)
  return c
end

function Init:_machineKey(machine)
  return initPrefix .. machinePrefix .. machine
end

function Init:_unitKey(unit)
  return initPrefix .. systemPrefix .. unit
end

function Init:machine(machine)
  return self._etcd:get(self:_machineKey(machine))
end

function Init:unit(unit)
  return self._etcd:get(self:_unitKey(unit))
end

return Init
