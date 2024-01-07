local _hjson = require "hjson"

PACKAGE = os.getenv("PACKAGE")
PACKAGE_DEF_PATH = os.getenv("PACKAGE_DEF_PATH")
VERSION = os.getenv("VERSION")
SHA256 = os.getenv("SHA256")

if PACKAGE == nil then
	print("PACKAGE is not set")
	os.exit(1)
elseif VERSION == nil then
	print("VERSION is not set")
	os.exit(1)
elseif PACKAGE_DEF_PATH == nil then
	print("PACKAGE_DEF_PATH is not set")
	os.exit(1)
elseif SHA256 == nil then
	print("SHA256 is not set")
	os.exit(1)
end

local packages = string.split(PACKAGE, ",", true)
local versions = string.split(VERSION, ",", true)
local sha256s = string.split(SHA256, ",", true)
local packageDefPaths = string.split(PACKAGE_DEF_PATH, ",", true)
if #packages ~= #versions or #packages ~= #sha256s or #packages ~= #packageDefPaths  then
	print("PACKAGE, VERSION, SHA256 and PACKAGE_DEF_PATH must have the same number of elements")
	os.exit(1)
end

if #packages == 0 then
	print("PACKAGE, VERSION and SHA256 must have at least one element")
	os.exit(1)
end

local affectedFiles = {}

for i = 1, #packages do
	local _package = packages[i]
	local _version = versions[i]
	local _sha256 = sha256s[i]
	local _packageDefPath = packageDefPaths[i]

	local _versionData = {
		source = _package,
		sha256 = _sha256,
		version = _version
	}

	local _version = ver.parse(VERSION)
	local _latest = "latest.json"
	if _version.prerelease then
		_latest = "latest-" .. _version.prerelease .. ".json"
	end

	-- if prefixed with plugin: then it's a plugin
	local _latestDir = path.combine("ami/definition/", _packageDefPath)
	if string.sub(_package, 1, 7) == "plugin:" then
		_package = string.sub(_package, 8)
		_latestDir = path.combine("ami/plugins/", _package)
	end

	fs.mkdirp(_latestDir)
	local _vDir = path.combine(_latestDir, "v")
	fs.mkdirp(_vDir)

	local _latestPath = path.combine(_latestDir, _latest)
	local _writeLatest = true
	local _ok, _content = fs.safe_read_file(_latestPath)
	if _ok then
		local _ok, _lastLatest = pcall(_hjson.parse, _content)
		if _ok then
			_writeLatest = ver.compare(VERSION, _lastLatest.version) == 1
		end
	end

	if _writeLatest then
		fs.write_file(_latestPath, _hjson.stringify_to_json(_versionData))
		table.insert(affectedFiles, _latestPath)
	end

	local _versionPath = path.combine(_vDir, VERSION .. ".json")
	fs.write_file(_versionPath, _hjson.stringify_to_json(_versionData))
	table.insert(affectedFiles, _versionPath)
end

local quotedFiles = table.map(affectedFiles, function(f) return "\"" .. f .. "\"" end)
io.write("[" .. string.join(", ", table.unpack(quotedFiles)) .. "]")
