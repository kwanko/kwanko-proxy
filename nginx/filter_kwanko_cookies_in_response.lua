local set_cookie_filter = {
  -- exact matches
  "^neta=",
  "^neta_ssc=",
  "^netases=",
  "^netases_ssc=",
  "^netaoptout=",
  "^netaoptout_ssc=",
  "^metanotrack=",
  "^metanotrack_ssc=",
  "^cookie-policy=",
  -- starts with
  "^ct",
  "^convbwr",
  "^netattag",
  "^kwk",
}

-- get cookie list
local set_cookies = ngx.resp.get_headers()["Set-Cookie"] or {}

ngx.log(ngx.DEBUG, "filter_kwanko_cookies_in_response / set_cookies: <{" .. table.concat(set_cookies, ", ") .. "}>")

if next(set_cookies) == nil then -- exit here if no set-cookie
  return
end

-- build validated cookie header
local filtered_set_cookie_headers = {}
local found = false

for _, set_cookie in ipairs(set_cookies) do
  found = false
  for _, filter in ipairs(set_cookie_filter) do
    if string.match(set_cookie, filter) then
      found = true
      break
    end
  end
  if found then
    table.insert(filtered_set_cookie_headers, set_cookie)
  end
end

ngx.log(ngx.DEBUG, "filter_kwanko_cookies_in_response / filtered_set_cookie_headers: <{" .. table.concat(filtered_set_cookie_headers, ", ") .. "}>")

-- replace cookie header
ngx.header["Set-Cookie"] = filtered_set_cookie_headers

return
