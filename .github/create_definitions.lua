local _hjson = require"hjson"

SOURCE = os.getenv("SOURCE")
PACKAGE_DEF_PATH = os.getenv("PACKAGE_DEF_PATH")
VERSION = os.getenv("VERSION")
SHA256 = os.getenv("SHA256")

local _versionData = {
	source = SOURCE,
	sha256 = SHA256,
	version = VERSION
}

local _version = ver.parse(VERSION)
local _latest = "latest.json"
if _version.prerelease then
	_latest = "latest-" .. _version.prerelease .. ".json"
end

local _latestDir = path.combine("ami/definition/", PACKAGE_DEF_PATH)
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
end

local _versionPath = path.combine(_vDir, VERSION .. ".json")
fs.write_file(_versionPath, _hjson.stringify_to_json(_versionData))
