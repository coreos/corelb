-- Copyright (C) 2013 by Leaf Corcoran
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy of
-- this software and associated documentation files (the "Software"), to deal in
-- the Software without restriction, including without limitation the rights to
-- use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
-- of the Software, and to permit persons to whom the Software is furnished to do
-- so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in all
-- copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
-- SOFTWARE.

--
-- This implements LuaSocket's http.request on top of a proxy_pass within
-- nginx.
--
-- Add the following location to your server:
--
-- location /proxy {
--     internal;
--     rewrite_by_lua "
--       local req = ngx.req
--
--       for k,v in pairs(req.get_headers()) do
--         if k ~= 'content-length' then
--           req.clear_header(k)
--         end
--       end
--
--       if ngx.ctx.headers then
--         for k,v in pairs(ngx.ctx.headers) do
--           req.set_header(k, v)
--         end
--       end
--     ";
--
--     resolver 8.8.8.8;
--     proxy_http_version 1.1;
--     proxy_pass $_url;
-- }
--
--
-- Add the following to your default location:
--
-- set $_url "";
--


local ltn12 = require("ltn12")
local proxy_location = "/proxy"
local methods = {
  ["GET"] = ngx.HTTP_GET,
  ["HEAD"] = ngx.HTTP_HEAD,
  ["PUT"] = ngx.HTTP_PUT,
  ["POST"] = ngx.HTTP_POST,
  ["DELETE"] = ngx.HTTP_DELETE,
  ["OPTIONS"] = ngx.HTTP_OPTIONS
}
local set_proxy_location
set_proxy_location = function(loc)
  proxy_location = loc
end
local request
request = function(url, str_body)
  local return_res_body
  local req
  if type(url) == "table" then
    req = url
  else
    return_res_body = true
    req = {
      url = url,
      source = str_body and ltn12.source.string(str_body),
      headers = {
        ["Content-type"] = "application/x-www-form-urlencoded"
      }
    }
  end
  req.method = req.method or (req.source and "POST" or "GET")
  local body
  if req.source then
    local buff = { }
    local sink = ltn12.sink.table(buff)
    ltn12.pump.all(req.source, sink)
    body = table.concat(buff)
  end
  local res = ngx.location.capture(proxy_location, {
    method = methods[req.method],
    body = body,
    ctx = {
      headers = req.headers
    },
    vars = {
      _url = req.url
    }
  })
  local out
  if return_res_body then
    out = res.body
  else
    if req.sink then
      ltn12.pump.all(ltn12.source.string(res.body), req.sink)
    end
    out = 1
  end
  return out, res.status, res.header
end
return {
  request = request,
  set_proxy_location = set_proxy_location
}
