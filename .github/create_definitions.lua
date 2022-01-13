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

fs.mkdirp(PACKAGE_DEF_PATH)

local _latestPath = path.combine("ami/definition/", PACKAGE_DEF_PATH, _latest)
fs.write_file(_latestPath, _hjson.stringify_to_json(_versionData))

local _versionPath = path.combine("ami/definition/", PACKAGE_DEF_PATH, "v", VERSION .. ".json")
fs.write_file(_versionPath, _hjson.stringify_to_json(_versionData))