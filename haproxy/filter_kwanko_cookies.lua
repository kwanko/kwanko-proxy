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

local function filter_kwanko_cookies(txn)
  local headers = txn.http:req_get_headers()
  local raw_cookies = nil
  if headers["cookie"] ~= nil and headers["cookie"][0] ~= nil then
    raw_cookies = headers["cookie"][0]
  end
  core.Debug("filter_kwanko_cookies / raw_cookies: <" .. (raw_cookies or "nil") .. ">")
  if raw_cookies == nil or raw_cookies == "" then -- exit here if no cookies
    return ""
  end

  -- get cookie list
  local cookies = {}
  for cookie in string.gmatch(raw_cookies, "([^;]+)") do
    cookie = string.gsub(cookie, "^%s+", "")
    table.insert(cookies, cookie)
  end
  core.Debug("filter_kwanko_cookies / cookies: <{" .. table.concat(cookies, ", ") .. "}>")

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
  core.Debug("filter_kwanko_cookies / filtered_cookie_header: <" .. filtered_cookie_header .. ">")

  if filtered_cookie_header == "" then
    txn.http:req_del_header("cookie")
    return
  end

  txn.http:req_set_header("cookie", filtered_cookie_header)

  return
end

local function filter_kwanko_set_cookies(txn)
  -- get set-cookie list
  local headers = txn.http:res_get_headers()
  local set_cookies = headers["set-cookie"] or {}

  if next(set_cookies) == nil then -- exit here if no set-cookie
    core.Debug("filter_kwanko_set_cookies / no set-cookie header found")
    return
  end

  -- index of arrays returned in headers starts at 0 instead of (the norm for lua),
  -- that breaks some utilities (ipairs, table.concat, ...) that skip the first element at index 0.
  core.Debug("filter_kwanko_set_cookies / set_cookies: <{" .. table.concat(set_cookies, ", ", 0) .. "}>")

  -- build validated set-cookie header
  local filtered_set_cookie_headers = {}
  local found = false

  for _,set_cookie in pairs(set_cookies) do
    found = false
    for _, filter in ipairs(cookie_filter) do
      if string.match(set_cookie, filter) then
        found = true
        break
      end
    end
    if found then
      table.insert(filtered_set_cookie_headers, set_cookie)
    end
  end

  core.Debug("filter_kwanko_set_cookies / filtered_set_cookie_headers: <{" .. table.concat(filtered_set_cookie_headers, ", ") .. "}>")

  -- remove set-cookie header and insert filtered headers
  txn.http:res_del_header("set-cookie")
  for _, set_cookie in ipairs(filtered_set_cookie_headers) do
    txn.http:res_add_header("set-cookie", set_cookie)
  end
end

core.register_action("filter_kwanko_cookies", {"http-req"}, filter_kwanko_cookies)
core.register_action("filter_kwanko_set_cookies", {"http-res"}, filter_kwanko_set_cookies)
