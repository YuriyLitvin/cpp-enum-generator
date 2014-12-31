#!/usr/bin/env lua

local EnumGenerator = "EnumGenerator.lua"
local fGenerator, e = loadfile(EnumGenerator)
if not fGenerator then
	print("Error! Can't load EnumGenerator: "..e)
	os.exit(1)
end
dofile(EnumGenerator)

local ModuleName = ModuleNameGet() -- Name of this file without extension
local Options =
{
	InFileCsv = ModuleName..".csv",
	-- CsvDelim = ";", -- You can define the csv delimiter explicitly
	OutFileCpp = ModuleName..".cpp", -- Comment this line for generating data only in file *.hpp
	-- OutFileHppInclude = {"math.h", "string"}, -- Additional inclusions in file *.hpp
	OutFileHpp = ModuleName..".hpp"
}
FileCsvProcess(Options)
