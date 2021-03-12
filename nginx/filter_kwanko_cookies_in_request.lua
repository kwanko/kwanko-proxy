local cookie_filter = {
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
local raw_cookies = ngx.req.get_headers()["Cookie"]

ngx.log(ngx.DEBUG, "filter_kwanko_cookies_in_request / raw_cookies: <" .. (raw_cookies or "nil") .. ">")

if raw_cookies == nil or raw_cookies == "" then -- exit here if no cookies
  return
end

local cookies = {}
for cookie in string.gmatch(raw_cookies, "([^;]+)") do
  cookie = string.gsub(cookie, "^%s+", "")
  table.insert(cookies, cookie)
end

ngx.log(ngx.DEBUG, "filter_kwanko_cookies_in_request / cookies: <{" .. table.concat(cookies, ", ") .. "}>")

-- build validated cookie header
local filtered_cookie_header = ""
local found = false

for _, cookie in ipairs(cookies) do
  found = false
  for _, filter in ipairs(cookie_filter) do
    if string.match(cookie, filter) then
      found = true
      break
    end
  end
  if found then
    filtered_cookie_header = filtered_cookie_header .. cookie .. "; "
  end
end

filtered_cookie_header = string.gsub(filtered_cookie_header, "%s*$", "")
ngx.log(ngx.DEBUG, "filter_kwanko_cookies_in_request / filtered_cookie_header: <" .. filtered_cookie_header .. ">")

-- replace cookie header
--ngx.req.clear_header("Cookie")
ngx.req.set_header("Cookie", filtered_cookie_header)

return
