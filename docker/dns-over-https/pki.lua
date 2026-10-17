local wardenPkiFiles = {
  ["/ca.cert.pem"] = "/etc/pki-public/ca.cert.pem",
  ["/ca.crl.pem"] = "/etc/pki-public/ca.crl.pem",
}

local function serveWardenPkiFile(req, resp)
  if req.method ~= "GET" and req.method ~= "HEAD" then
    resp.status = 405
    resp.headers = { ["Allow"] = "GET, HEAD" }
    return
  end

  local filePath = wardenPkiFiles[req.path]
  if not filePath then
    resp.status = 404
    return
  end

  local file = io.open(filePath, "rb")
  if not file then
    resp.status = 503
    resp.body = "PKI artifact unavailable"
    return
  end

  local body = file:read("*a")
  file:close()
  if body == nil then
    resp.status = 503
    resp.body = "PKI artifact unavailable"
    return
  end

  resp.status = 200
  resp.headers = {
    ["Cache-Control"] = "no-store",
    ["Content-Length"] = tostring(#body),
    ["Content-Type"] = "application/octet-stream",
  }
  if req.method == "GET" then
    resp.body = body
  end
end

registerWebHandler("/ca.cert.pem", serveWardenPkiFile)
registerWebHandler("/ca.crl.pem", serveWardenPkiFile)
