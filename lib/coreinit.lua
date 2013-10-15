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

local debug = false

local dprint = function(msg)
  if debug == true then
    print("coreinit: " .. msg)
  end
end

local Machine = {}

function Machine:new(init, key)
  local m = {}
  setmetatable(m, self)
  self.__index = self

  self._id = key
  self._etcd = init._etcd

  return m
end

function Machine:_key()
  return initPrefix .. machinePrefix .. self._id
end

function Machine:_getAddrs()
  return self._etcd:get(self:_key(self._id) .. "/addrs")
end

-- sync grabs the data on this machine from the datastore and caches it
function Machine:sync()
  local value, err = self:_getAddrs()
  if err ~= nil then
    dprint("problem getting addrs for machine " .. self._id .. ": " .. err.errorCode)
    return err
  end

  self._addrs, err = cjson.decode(value.value)
  dprint(self._addrs[1].addr)

  return nil
end

function Machine:addrs()
  return self._addrs
end

function Machine:id()
  return self._id
end

local Unit = {}

-- new returns a new etcd.Init object
function Unit:new(init, unit)
  local u = {}
  setmetatable(u, self)
  self.__index = self
  self._init = init
  self._etcd = init._etcd
  self._unit = unit
  return u
end

local basename = function (string_, suffix)
  string_ = string_ or ''
  local basename = string.gsub (string_, '[^/]*/', '')
  if suffix then
    basename = string.gsub (basename, suffix, '')
  end
  return basename
end

function Unit:machines()
  local dir, err = self._etcd:get(self:_unitKey(self._unit) .. "/")
  if err ~= nil then
    print("ERROR: Failed to get the unit " .. self._unit .. " from coreinit")
    return {}, err
  end

  local machines = {}
  for i, machine in ipairs(dir) do
    machine = self._init:machine(basename(machine.key))
    err = machine:sync()
    if err ~= nil then
      print("ERROR: Failed to sync machine " .. machine .. " from coreinit " .. err.errorCode)
    else
      table.insert(machines, machine)
      dprint("created machine with id " .. machine:id())
    end
  end

  return machines
end

function Unit:_unitKey(unit)
  return initPrefix .. systemPrefix .. unit
end

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

function Init:machine(machine)
  return Machine:new(self, machine)
end

function Init:unit(unit)
  return Unit:new(self, unit)
end

return Init
