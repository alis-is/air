local hjson = require "hjson"

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

local affected_files = {}

for i = 1, #packages do
	local package = packages[i]
	local version = versions[i]
	local sha256 = sha256s[i]
	local package_def_path = packageDefPaths[i]

	local version_data = {
		source = package,
		sha256 = sha256,
		version = version
	}

	local prerelease = ver.parse(version).prerelease
	local latest = "latest.json"
	if prerelease then
		latest = "latest-" .. prerelease .. ".json"
	end

	-- if prefixed with plugin: then it's a plugin
	local latest_directory = path.combine("ami/definition/", package_def_path)
	if string.sub(package_def_path, 1, 7) == "plugin:" then
		package_def_path = string.sub(package_def_path, 8)
		latest_directory = path.combine("ami/plugin/", package_def_path)
	end

	fs.mkdirp(latest_directory)
	local version_dir = path.combine(latest_directory, "v")
	fs.mkdirp(version_dir)

	local latest_path = path.combine(latest_directory, latest)
	local write_latest = true
	local ok, content = fs.safe_read_file(latest_path)
	if ok then
		local ok, last_latest = pcall(hjson.parse, content)
		if ok then
			write_latest = ver.compare(version, last_latest.version) == 1
		end
	end

	if write_latest then
		fs.write_file(latest_path, hjson.stringify_to_json(version_data))
		table.insert(affected_files, latest_path)
	end

	local version_path = path.combine(version_dir, version .. ".json")
	fs.write_file(version_path, hjson.stringify_to_json(version_data))
	table.insert(affected_files, version_path)
end

local quoted_files = table.map(affected_files, function(f) return "\"" .. f .. "\"" end)
io.write("[" .. string.join(", ", table.unpack(quoted_files)) .. "]")
