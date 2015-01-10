--[=[******************** (C) COPYRIGHT 2014 J&DSoft ***************************
* File Name          : EnumGenerator.lua
* Author             : Litvin Yuriy
* Tags               : Cpp, Enum, Generator
* TS First Code      : 2012-06
* TS Idea            : 2014-09-19
* TS Version         : 2014-12-13 15:16:17
* Description        : This is a generator of cpp enumerations from csv-table.
*****************************************************************************]=]


-- **************************** Utils.lua **************************************

-- "nil" -> nil, "false" -> false, "true" -> true, "123.45" -> 123.45, "something other" -> "something other", (not string) -> nil
function StringToValue(s)
	if type(s) == "string" then
		local value
		if s == "false" then
			value = false
		elseif s == "true" then
			value = true
		else
			local n = tonumber(s)
			if n ~= nil then
				value = n
			elseif s ~= "nil" then
				value = s -- string
			end
		end
		return value
	end
end


-- Производит чтение файла и возвращает массив строк
function FileByStringRead(NameFile)
	local f, e = io.open(NameFile, "r")
	if not f then
		return nil, e
	end

	local t = {}
	local l = f:read("*l")
	while l do
		table.insert(t, l)
		l = f:read("*l")
	end
	io.close(f)
	return t
end


-- Производит поиск строки sfind в sfull справа налево, возращает индекс начала найденной строки
function StringRLFind(sfull, sfind)
	local i = string.find(string.reverse(sfull), string.reverse(sfind), 1, true)
	if i then
		return #sfull - i - #sfind + 2
	end
end


-- "C:/Dropbox/Enums.lua" -> ("C:/Dropbox", "Enums", "lua")
function ParsePath(path)
	local dir, name, ext
	dir = string.match(path, "(.*)[\\/]")
	if dir then
		name = string.sub(path, #dir + 2)
	else
		name = path
	end
	local i = StringRLFind(name, ".")
	if i then
		ext = string.sub(name, i + 1)
		name = string.sub(name, 1, i - 1)
	end
	if #name == 0 then
		name = nil
	end
	return dir, name, ext
end


-- Возвращает базовое имя запускаемого модуля без расширения и без путей
function ModuleNameGet()
	return select(2, ParsePath(arg[0]))
end


-- Возвращает true, если key является валидным ключем индексного (из последовательности) элемента таблицы t
local function TableKeyIsChild(t, key)
	local n = tonumber(key)
	return n and n == math.floor(n) and n >= 1 and n <= #t
end


-- Производит полное (рекурсивное) копирование таблицы, опции: skip, deep, properties
function TableTreeCopy(a, b, opt)
	b = b or {}

	if type(a) ~= "table" or type(b) ~= "table" then
		error("one or both parameters must be of type table but received "..type(a).." and "..type(b))
		return
	end
	
	local skip = opt and opt.skip -- пропускать уже имеющиеся ключи?
	local deep = opt and opt.deep -- копировать таблицы по значению?
	local properties = opt and opt.properties -- копировать только свойства?
	
	for k,v in pairs(a) do
		if b[k] ~= nil and skip then
		elseif properties and TableKeyIsChild(a, k) then
		else
			if type(v) == 'table' and deep then
				b[k] = TableTreeCopy(v, {}, opt)
			else
				b[k] = v
			end
		end
	end
	
	if opt and opt.setmetatable then
		setmetatable(b, getmetatable(a))
	end

	return b
end


-- Копирует свойства (непоследовательные ключи) одной таблицы в другую
-- Если skip = true, то уже существующие ключи не будут перезаписаны
function TablePropertiesCopy(a, b, skip)
	return TableTreeCopy(a, b, {skip = skip, deep = true, properties = true})
end


-- ****************************** FileCsv.lua **********************************

-- Возвращает массив из "count" элементов стоки "s" файла CSV, учитывает использование кавычек (") и их экранирование ("")
local function CSVString_ArrayItemGet(s, count, delim)
	delim = delim or ";"

	local cmax = 0 -- номер самого правого столбца с данными

	local r = {}
	local c = 1 -- номер столбца
	local i = 1 -- номер символа
	while c <= count do
		local Item = ""

		-- Режим генерации пустых ячеек?
		if i > #s then
		-- Последовательность в кавычках?
		elseif string.sub(s, i, i) == "\"" then
			i = i + 1
			local f = string.find(s, "\""..delim, i, true)
			-- Избавляемся от ложного окончания '..."""";";'
			while f and string.sub(s, f-1, f-1) == "\"" do
				f = string.find(s, "\""..delim, f+1, true)
			end
			-- Нашли разделитель?
			if f then
				Item = string.sub(s, i, f-1)
				i = i + #Item + 2
			else
				Item = string.sub(s, i, #s-1)
				i = i + #Item + 1
			end
			-- Заменяем "" на "
			Item = string.gsub(Item, "\"\"", "\"")
		else
			local f = string.find(s, delim, i, true)
			-- Нашли разделитель?
			if f then
				Item = string.sub(s, i, f-1)
				i = i + #Item + 1
			else
				Item = string.sub(s, i)
				i = i + #Item
			end
		end
		
		-- Текущий столбец имеет данные?
		if Item ~= "" then
			cmax = c
		end

		table.insert(r, Item)
		c = c + 1
	end

	return r, cmax
end


-- Возвращает максимальное количество столбцов в части CSV файла
local function CSVPart_ColumnCountGet(t, delim)
	delim = delim or ";"

	local cmax = 0
	for i=1,#t do
		if t[i] ~= "" then
			local t, c = CSVString_ArrayItemGet(t[i], 100, delim) -- До 100 столбцов!!
			if c > cmax then
				cmax = c
			end
		end
	end

	return cmax
end


-- Преобразовавает массив сток с разделителями в массив массивов элементов
local function FileCSV_ArrayStringToArrayItem(ts, ColumnCount, delim)
	local ti = {}

	for i,v in ipairs(ts) do
		local t, cellWithData = CSVString_ArrayItemGet(v, ColumnCount, delim) -- преобразовываем строки с разделителем в массив строк
		if cellWithData > 0 then -- строка имеет данные?
			table.insert(ti, t)
		end
	end
	
	TablePropertiesCopy(ts, ti)

	return ti
end


-- "1 + (2 + (3 - 2) * 2) - 4" -> "2 + (3 - 2) * 2" - возвращает часть строки внутри самых левых наружных круглых скобок
function String_GetInnerPart(s)
	local r = string.match(s, "%b()")
	if r then
		r = string.sub(r, 2, #r - 1)
	end
	return r
end


-- "PartBegin(Type=Enum, Name=Color, ...)" -> {Type="Enum", Name="Color", ...}
local function String_ParseOptions(s)
	local t = {}
	local i = 0
	s = String_GetInnerPart(s) -- выделяем часть внутри круглых скобок
	if s then
		while i < #s do
			local ib, ie, key = string.find(s, "%s*([%a%d_]+)%s*[=:]%s*", i)
			if ib then
				local firstChar = string.sub(s, ie + 1, ie + 1)
				local value
				if string.find(firstChar, "[%(%[{]") then -- чтение блока сбалансированого скобками, например: (long string 1), [long string 2]
					local map = {["("] = ")", ["["] = "]", ["{"] = "}"}
					local lastChar = map[firstChar]
					local pattern = "%b"..firstChar..lastChar
					ie, value = select(2, string.find(s, "("..pattern..")", ie + 1))
					value = string.sub(value, 2, #value - 1) -- удаляем скобки вокруг
				else
					ie, value = select(2, string.find(s, "([%a%d_%-%+]*)%s*", ie + 1)) -- чтение простого значения (без пробелов)
				end
				value = StringToValue(value)
				--print("key = "..tostring(key)..", value = "..tostring(value)..", type(value) = "..type(value))
				t[key] = value
				i = ie + 1
			else -- если ключей больше нет
				break;
			end
		end
	end
	return t
end


-- Обнаруживает разделитель значений в строках формата CSV
local function CsvDelimiterDetect(FileStrings)
	local Delimiters = ",;:\t "
	local Statistic = {}
	local Delimiter, Max = nil, 0
	local i = 1
	while i <= 10 and i <= #FileStrings do
		local s = FileStrings[i]
		local d = 1
		while d <= #Delimiters do
			local s2, count = string.gsub(s, string.sub(Delimiters, d, d), "d")
			Statistic[d] = (Statistic[d] or 0) + count
			if Statistic[d] > Max then
				Max = Statistic[d]
				Delimiter = string.sub(Delimiters, d, d)
			end
			d = d + 1
		end
		i = i + 1
	end
	if Delimiter then
		print("Info: csv-delimiter detected as '"..Delimiter.."'")
	else
		error("Error! Can't to detect csv-delimiter.")
	end
	return Delimiter
end


-- Производит обработку содержимого файла CSV, создает дерево ключ и массив значений для каждой части файла (поблочно)
function FileCSVToTreeParts(FileName, delim)
	local FileStrings, e = FileByStringRead(FileName) -- читаем файл в виде массива строк
	if not FileStrings then
		return nil, e
	end

	if delim then
		print("Info: csv-delimiter defined as '"..delim.."'")
	else
		delim = CsvDelimiterDetect(FileStrings)
	end

	local tout = {} -- результирующее дерево
	local PartCur -- таблица текущего блока

	for i=1,#FileStrings do
		local s,sprocessed = FileStrings[i]
		
		-- Строка может содержать начало или конец блока?
		if string.find(s, "PartBegin", 1, true) or string.find(s, "PartEnd", 1, true) then
			local c0 = CSVString_ArrayItemGet(s, 1, delim)[1] -- первая ячейка строки
			
			local ib = string.find(c0, "PartBegin", 1, true)
			if ib then
				if PartCur then
					error("Error in string "..i..". Повторное открытие блока, нельзя вкладывать блоки друг в друга.")
				end
				PartCur = String_ParseOptions(c0) -- Открытие блока
				PartCur.CSVLineBegin = i
			end

			local ie = string.find(c0, "PartEnd", 1, true)
			if ie then
				if not PartCur then
					error("Error in string "..i..". Попытка закрыть неоткрытый блок.")
				end
				PartCur.CSVLineEnd = i
				
				-- Закрытие блока
				local ColumnCountMax = CSVPart_ColumnCountGet(PartCur, delim) --  максимальное колчество столбцов в блоке
				local PartCurCells = FileCSV_ArrayStringToArrayItem(PartCur, ColumnCountMax, delim)
				table.insert(tout, PartCurCells)
				PartCur = nil
			end
			sprocessed = true
		end
		
		if PartCur and not sprocessed then
			table.insert(PartCur, s)
		end
	end
	return tout
end


-- **************************** TemplateHpp.lua ********************************
local TemplateHpp =
[[
<<NamespaceEnumNamePrivate()>>class <<EnumName()>>
{
public:
    enum Value
    {
        <<IndexValues(LineNewIndent = 8)>>
    };
    static const int ValueCount = <<ValueCount()>>;
    static const Value ValueInvalid = <<ValueInvalidName()>>;

    <<EnumName()>>(Value val = ValueInvalid) : m_ValueCur(val) {}
    <<EnumName()>>(const <<EnumName()>> &other) : m_ValueCur(other.m_ValueCur) {}<<EnumNameConstructorIntBody()>>
    explicit <<EnumName()>>(const char * val) : m_ValueCur(ValueInvalid)
    {
        int index = NS_JDSoft::NS_EnumGenerator::<<StringFind()>>(<<NamespaceValues()>>StringValues, ValueCount, val);
        if (index >= 0) m_ValueCur = Value(index);
    }

    <<EnumName()>> &operator =(Value val) { m_ValueCur = val; return *this; }
    <<EnumName()>> &operator =(const <<EnumName()>> &other) { m_ValueCur = other.m_ValueCur; return *this; }

    bool operator ==(Value val) const { return m_ValueCur == val; }
    bool operator ==(const <<EnumName()>> &other) const { return m_ValueCur == other.m_ValueCur; }

    bool isValid() const { return m_ValueCur != ValueInvalid; }

    Value toValue() const { return m_ValueCur; }<<EnumNameStableIdBlock()>>
    const char * toString() const { return <<NamespaceValues()>>StringValues[m_ValueCur]; }<<EnumNameUserMethods(LineNewIndent = 4)>>

    static const char * enumName() { return "<<EnumName()>>"; }
private:<<EnumNameDataDeclaration(LineNewIndent = 4)>>
    Value m_ValueCur;
};
]]


local TemplateCpp =
[[
const char * const <<EnumName()>>::StringValues[<<EnumName()>>::ValueCount]=
{
    <<StringValues(LineNewIndent = 4)>>
};<<EnumNameBodyDynamic(LineNewIndent = 0)>>
]]


-- ******************************** Enum.lua ***********************************

local mc = {} -- ModuleContext

local EnumDefault = 
{
	NameSorted = true, -- сортировать имена значений перечисления?
	IDIntegerSorted = false, -- формировать массив отсортированных IDInteger?
	ValueInvalidName = "Invalid",
	ValueInvalidIDInteger = -1,
	ValueInvalidInsertFirst = true
}

local ColumnUserDefault = 
{
	Type = "String", -- тип данных по умолчанию
	ToCreate = true, -- создать метод to(ColumnName)
	Use = true
}

local ColumnUserTypePredefined = 
{
	String = {TypeHpp = "const char *", ValueDefault = "", ValuePostProcess = function(val)
		val = string.gsub(val, "“", "\"") --замена левой нестандартной кавычки
		val = string.gsub(val, "”", "\"") --замена правой нестандартной кавычки
		return string.format("%q", val)
	end},
	Integer = {TypeHpp = "const int", ValueDefault = 0}
}


local function LineHeader_Process(data, columns)
	columns = columns or {}
	-- Обрабатываем каждое значение строки
	for i=1,#data do
		local cell = data[i]
		local columnId = string.match(cell, "%s*([%a%d_]+)%s*")
		if columns[columnId] or columns[i] then
			error("Error! LineHeader_Process. Дублирование идентификатора столбца - "..columnId..".")
		end
		local tcolumn = {Id = columnId, Index = i}
		local options = String_ParseOptions(cell)
		TablePropertiesCopy(options, tcolumn, true) -- мягко копируем значения свойств
		columns[columnId] = tcolumn
		columns[i] = tcolumn
	end
	return columns
end


-- Разбор основных строк блока (Header, Comment, ...)
local function PartAny_LinesWithType_Process(tin)
	local tout = TablePropertiesCopy(tin)
	for i,v in ipairs(tin) do
		local stringType = tin[i][1]
		
		-- Делаем копию без 1-го столбца
		local tnew = TableTreeCopy(tin[i])
		table.remove(tnew, 1)
		
		local processor = {
			Header = function() tout.Columns = LineHeader_Process(tnew, tout.Columns) end,
			Comment = function() end,
			[""] = function() table.insert(tout, tnew) end
		}
		local p = processor[stringType]
		if not p then
			error("Error! Unknown type of string: "..stringType)
		end
		p()
	end
	return tout
end


local function PartTypeEnumDefault_Process(part)
	local tin = PartAny_LinesWithType_Process(part)
	
	-- Разбор столбцов блока
	if not tin.Columns.Key or not tin.Columns.Value then
		error("Error! No column \"Key\" or column \"Value\" in part EnumDefault.")
	end
	local columnKeyIndex = tin.Columns.Key.Index
	local columnValueIndex = tin.Columns.Value.Index
	
	local tout = {}
	for i,v in ipairs(tin) do
		local key = tin[i][columnKeyIndex]
		local value = tin[i][columnValueIndex]
		tout[key] = StringToValue(value)
	end

	-- Применение данных
	TableTreeCopy(tout, EnumDefault)
end


local function PartTypeEnum_Process(part)
	local name = part.Name
	if not name then
		error("Error! Name of enum is not set. Line = "..part.CSVLineBegin)
	end
	
	mc.EnumNames = mc.EnumNames or {}
	if mc.EnumNames[name] then
		error(string.format("Error! Redefination of 'EnumName = %s'. Line = %d.", name, part.CSVLineBegin))
	end
	mc.EnumNames[name] = true
	
	local tin = PartAny_LinesWithType_Process(part)
	-- Разбор столбцов блока
	local tout = TableTreeCopy(tin)
	TablePropertiesCopy(EnumDefault, tout, true) -- мягко копируем значения свойств по умолчанию из EnumDefault

	-- Проверить валидность данных по столбцам
	local columns = tout.Columns
	
	-- Обработка столбца Name
	local ColumnNameIndex = columns.Name.Index
	local Rows = {}
	local ArrayName = {}
	for i=1,#tin do
		local rowId = tin[i][ColumnNameIndex]
		if Rows[rowId] then
			error("Error! Имя значения перечисления повторяется: "..rowId)
		end
		local trow = {Id = rowId, Index = i, IndexIn = i} -- IndexIn - изначальный индекс значения во входном блоке
		Rows[rowId] = trow
		Rows[i] = trow
		table.insert(ArrayName,rowId)
	end
	
	-- Добавить свойство ValueInvalidName, если его нет
	local reindex
	local invalidName = tout.ValueInvalidName
	if not Rows[invalidName] then
		local rowId = invalidName
		local i
		local first = tout.ValueInvalidInsertFirst
		if first then
			i = 1
			reindex = true
		else
			i = #Rows + 1
		end
		local trow = {Id = rowId, Index = i}
		if columns.IDInteger then
			trow.IDInteger = tout.ValueInvalidIDInteger
		end
		Rows[rowId] = trow
		table.insert(Rows, i, trow)
		table.insert(ArrayName, i, rowId)
	end

	-- NameSorted
	if tout.NameSorted then
		table.sort(ArrayName)
		reindex = true
	end
	
	if reindex then
		for i=1,#ArrayName do
			Rows[i] = Rows[ArrayName[i]]
			Rows[i].Index = i
		end
	end
	
	-- Обработка столбца IDInteger
	if columns.IDInteger then
		local ColumnIDIntegerIndex = columns.IDInteger.Index
		
		-- Проверка наличия хотя бы одного значения в колонке
		local count = 0
		for i=1,#tin do
			local cell = tin[i][ColumnIDIntegerIndex]
			if cell ~= "" then
				count = count + 1
			end
		end
		--print("В колонке IDInteger найдено "..count.." непустых значений.")
		
		if count > 0 then
			local SetIDInteger = {} -- множество значений для проверки уникальности
			for i=1,#tin do
				local rowId = tin[i][ColumnNameIndex]
				local cell = tin[i][ColumnIDIntegerIndex]
				if cell == "" then
					error("Error! Значение IDInteger должно быть задано для каждого элемента.")
				end
				local idInteger = tonumber(cell)
				-- Все значения должны быть заданы
				if not idInteger then
					error("Error! Невозможно вычислить IDInteger: "..cell)
				end
				if idInteger ~= math.floor(idInteger) then
					error("Error! IDInteger должен быть целочисленным: "..idInteger)
				end
				if SetIDInteger[idInteger] then
					error("Error! IDInteger в перечислении повторяется: "..idInteger)
				end
				SetIDInteger[idInteger] = true
				-- Out
				Rows[rowId].IDInteger = idInteger
				--print("IDInteger = ", idInteger)
			end
			tout.IDIntegerUse = true -- использовать столбец IDInteger!
		end
	end

	-- Обработка столбца CommentCpp
	if columns.CommentCpp then
		local ColumnCommentIndex = columns.CommentCpp.Index
		for i=1,#tin do
			local rowId = tin[i][ColumnNameIndex]
			local comment = tin[i][ColumnCommentIndex]
			Rows[rowId].CommentCpp = comment
			--print("comment = ", comment)
		end
	end

	-- Обработка пользовательских столбцов
	local columnsProcessed = {Name = true, IDInteger = true, CommentCpp = true}
	for columnIndex=1,#columns do
		local columnId = columns[columnIndex].Id
		if not columnsProcessed[columnId] then
			local column = columns[columnIndex]
			TablePropertiesCopy(ColumnUserDefault, column, true) -- копируем значения по умолчанию для пользовательских столбцов
			local columnWithType = ColumnUserTypePredefined[column.Type] or {TypeHpp = "const "..column.Type, ValueDefault = "", ValuePostProcess = function(val) return column.Type.."("..tostring(val)..")" end}
			TablePropertiesCopy(columnWithType, column, true) -- копируем значения по умолчанию для данного типа столбца
			for i=1,#tin do
				local rowId = tin[i][ColumnNameIndex]
				local data = tin[i][columnIndex]
				-- Out
				Rows[rowId][columnId] = data
				--print("data = ", data)
			end
			columnsProcessed[columnId] = true
		end
	end

	tout.Rows = TableTreeCopy(Rows)
	tout.Rows.ArrayName = ArrayName

	return tout
end


local function PartsAllProcess(parts)
	local PartTypeAnyToProcessor =
	{
		Enum = PartTypeEnum_Process,
		EnumDefault = PartTypeEnumDefault_Process
	}

	for i,v in ipairs(parts) do
		local type = v.Type
		local processor = PartTypeAnyToProcessor[type]
		if processor then
			parts[i] = processor(v) or parts[i] -- вызываем частные обработчики для типов, если обработчик не изменяет данные, то он может их не возвращать
			local info = "Info: Part(Type="..type
			if v.Name then
				info = info..", Name="..v.Name
			end
			info = info..") processed."
			print(info)
		else
			print("Warning! Unknown type of part: "..tostring(type))
		end
	end
end


local PartTypeEnum_Creator =
{
	EnumName = function (part) 
		return part.Name
	end,
	NamespaceEnumNamePrivate = function (part, opt)
		local useCpp = opt and opt.useCpp
		local res = ""
		if not useCpp then
			res = [[
namespace <<EnumName()>>Private
{
    static const char * const StringValues[] =
    {
        <<StringValues(LineNewIndent = 8)>>
    };<<EnumNameBodyDynamic(LineNewIndent = 4)>>
}

]]
		end
		return res
	end,
	StringValues = function (part, opt)
		local rows = part.Rows
		local arrayName = rows.ArrayName
		local spaceCount = opt and opt.LineNewIndent or 4
		local res = ""
		if #rows > 0 then
			local indent = string.rep(" ", spaceCount)
			res = res.."\""
			local delim = "\",\n"..indent.."\""
			res = res..table.concat(arrayName, delim)
			res = res.."\""
		end
		return res
	end,
	EnumNameBodyDynamic = function (part, opt)
		local textNew = ""
		local rows = part.Rows
		local spaceCount = (opt and opt.LineNewIndent or 4)
		local indent = string.rep(" ", spaceCount)
		local indentValues = string.rep(" ", spaceCount + 4)
		local delim = ",\n"..indentValues
		local useCpp = opt and opt.useCpp
		local wordValueCount = ""
		if useCpp then
			wordValueCount = "ValueCount"
		end
		local isCpp = useCpp and opt.isCpp
		local wordStatic = "static "
		local nameNamespace = ""
		if isCpp then
			wordStatic = ""
			nameNamespace = part.Name.."::"
			wordValueCount = nameNamespace..wordValueCount
		end
		local vIndent = "\n\n"
		if useCpp and not isCpp then
			vIndent = "\n"
		end

		if part.IDIntegerUse then
			local arrayIDInteger = {}
			for i = 1, #rows do
				table.insert(arrayIDInteger, i, rows[i].IDInteger)
			end
			local res = table.concat(arrayIDInteger, delim)
			local defination = " =\n"..indent.."{\n"..indentValues..res.."\n"..indent.."}"
			if useCpp and not isCpp then
				defination = ""
			end
			local s = vIndent..indent..wordStatic.."const int "..nameNamespace.."IDInteger["..wordValueCount.."]"..defination..";"
			
			-- IDIntegerSorted
			if part.IDIntegerSorted then
				local arrayObj = {} -- with {Id = IDInteger, Index = Index}
				for i = 1, #rows do
					table.insert(arrayObj, {Id = rows[i].IDInteger, Index = rows[i].Index - 1})
				end
				table.sort(arrayObj, function(a, b) return a.Id < b.Id end)
				-- toString
				local arrayS = {} 
				for i = 1, #arrayObj do
					local s = string.format("{%d, %d}", arrayObj[i].Id, arrayObj[i].Index)
					table.insert(arrayS, s)
				end
				local res = table.concat(arrayS, delim)
				local defination = " =\n"..indent.."{\n"..indentValues..res.."\n"..indent.."}"
				if useCpp and not isCpp then
					defination = ""
				end
				local stringIDIntegerSorted = vIndent..indent..wordStatic.."const NS_JDSoft::NS_EnumGenerator::_DSValueSorted<int> "..nameNamespace.."IDIntegerSorted["..wordValueCount.."]"..defination..";"
				s = s..stringIDIntegerSorted
			end
			textNew = textNew..s
		end

		-- Обработка пользовательских столбцов
		local columns = part.Columns
		local columnsProcessed = {Name = true, IDInteger = true, CommentCpp = true}
		for columnIndex=1,#columns do
			local columnId = columns[columnIndex].Id
			local use = columns[columnIndex].Use and columns[columnIndex].ToCreate or columns[columnIndex].FromCreate
			if not columnsProcessed[columnId] and use then
				local column = columns[columnIndex]
				local arrayData = {}
				for i = 1, #rows do
					local data = rows[i][columnId] or column.ValueDefault
					local valuePostProcess = column.ValuePostProcess
					if valuePostProcess then
						data = valuePostProcess(data)
					end
					table.insert(arrayData, i, data)
				end
				local res = table.concat(arrayData, delim)
				local defination = " =\n"..indent.."{\n"..indentValues..res.."\n"..indent.."}"
				if useCpp and not isCpp then
					defination = ""
				end
				local hppOut = vIndent..indent..wordStatic..column.TypeHpp.." "..nameNamespace..columnId.."["..wordValueCount.."]"..defination..";"
				--print("hppOut = ", hppOut)
				textNew = textNew..hppOut
				columnsProcessed[columnId] = true
			end
		end
		return textNew
	end,
	EnumNameDataDeclaration = function (part, opt)
		local useCpp = opt and opt.useCpp
		local res = ""
		if useCpp then
			res = res.."\n"..[[    static const char * const StringValues[ValueCount];<<EnumNameBodyDynamic(LineNewIndent = 4)>>]].."\n"
		end
		return res
	end,
	EnumNameUserMethods =  function (part, opt)
		local textFull = ""
		local rows = part.Rows
		local spaceCount = (opt and opt.LineNewIndent or 4)
		local indent = string.rep(" ", spaceCount)
		local indentValues = string.rep(" ", spaceCount + 4)
		local delim = ",\n"..indentValues

		-- Обработка пользовательских столбцов
		local columns = part.Columns
		local columnsProcessed = {Name = true, IDInteger = true, CommentCpp = true}
		for columnIndex=1,#columns do
			local columnId = columns[columnIndex].Id
			local use = columns[columnIndex].Use and columns[columnIndex].ToCreate or columns[columnIndex].FromCreate
			if not columnsProcessed[columnId] and use then
				local column = columns[columnIndex]
				local textColumn = ""
				if column.ToCreate then
					-- const int & toInt2() const { return MessagePrivate::Int2[m_ValueCur]; }
					local ref = ""
					if column.Type ~= "String" then
						ref = " &"
					end
					local templte = column.TypeHpp..ref.." to"..column.Id.."() const { return <<NamespaceValues()>>"..column.Id.."[m_ValueCur]; }"
					textColumn = textColumn..templte
				end
				--print("textColumn = ", textColumn)
				if #textColumn > 0 then
					textColumn = "\n"..indent..textColumn
				end
				textFull = textFull..textColumn
				columnsProcessed[columnId] = true
			end
		end
		return textFull
	end,
	NamespaceValues = function (part, opt)
		local useCpp = opt and opt.useCpp
		local nameNamespace = part.Name.."Private::"
		if useCpp then
			nameNamespace = ""
		end
		return nameNamespace
	end,
	EnumNameStableIdBlock = function (part, opt)
		if part.IDIntegerUse then
			return "\n"..[[    int toInt() const { return <<NamespaceValues()>>IDInteger[m_ValueCur]; }]]
		else
			return ""
		end
	end,
	EnumNameConstructorIntBody = function (part, opt)
		if part.IDIntegerUse then
			local nameFunction = "ValueFindLinear"
			local nameArray = "<<NamespaceValues()>>IDInteger" -- Example: ColorPrivate::IDInteger
			if part.IDIntegerSorted then
				nameFunction = "ValueFindBinary"
				nameArray = nameArray.."Sorted"
			end
			local template = "\n"..[[
    explicit <<EnumName()>>(int val) : m_ValueCur(ValueInvalid)
    {
        int index = NS_JDSoft::NS_EnumGenerator::<<NameFunctionAny>>(<<NameArrayAny>>, ValueCount, val);
        if (index >= 0) m_ValueCur = Value(index);
    }]]
			local s = template
			s = string.gsub(s, "<<NameFunctionAny>>", nameFunction)
			s = string.gsub(s, "<<NameArrayAny>>", nameArray)
			return s
		else
			return ""
		end
	end,
	IndexValues = function (part, opt)
		local rows = part.Rows
		local arrayName = part.ArrayName
		local spaceCount = opt and opt.LineNewIndent or 4
		local indent = string.rep(" ", spaceCount)
		local delim = "\n"..indent
		local sout = ""
		for i = 1, #rows do
			local row = rows[i]
			local s = row.Id.." = "..(row.Index - 1)
			if i ~= #rows then
				s = s..","
			end
			if row.CommentCpp and row.CommentCpp ~= "" then
				s = s.." //! "..row.CommentCpp -- Комментарий для doxygen
			end
			if i ~= #rows then
				s = s..delim
			end
			sout = sout..s
		end
		return sout
	end,
	StringFind = function (part)
		if part.NameSorted then
			return "StringFindBinary"
		else
			return "StringFindLinear"
		end
	end,
	ValueCount = function (part) 
		return #part.Rows
	end,
	ValueInvalidName = function (part)
		return part.ValueInvalidName
	end
}


local function PartTypeEnum_Replacer(template, part, options_default)
	local function Replacer(sin) -- EnumName() -> Example: Color
		local data = string.sub(sin, 3, #sin-2) -- <<EnumName()>> -> EnumName()
		local fparameters = String_GetInnerPart(data) -- EnumName(a = 2) -> a = 2
		if not fparameters then
			error(string.format("Error! Нет скобок при вызове функции: \"%s\". ", sin))
		end
		local fname = string.sub(data, 1, string.find(data, "(", 1, true) - 1) -- EnumName() -> EnumName
		--print("fname = "..fname, "fparameters = "..fparameters)
		local options = TablePropertiesCopy(options_default)
		if #fparameters > 0 then
			local r, o = pcall(loadstring("return {"..fparameters.."}"))
			if not r then
				error("Error in evaluating: "..fparameters)
			end
			TablePropertiesCopy(o, options) -- жестко копируем значения свойств (с перезаписью)
		end
		local p = PartTypeEnum_Creator[fname]
		if p then
			return p(part, options)
		else
			print(string.format("Error! Replacer. Function %s was not found!", fname))
		end
		return sin
	end
	
	-- Replace template with the text values
	local out, n = string.gsub(template, "<<.->>", Replacer)
	local i = 1
	while n > 0 and i <= 10 do -- 10 is max depth for regenerating code
		out, n = string.gsub(out, "<<.->>", Replacer)
		i = i + 1
	end
	return out
end


-- Создание файла "*.hpp"
local function FileHppCreate(parts, fileName, options)
	-- Открытие файла
	local f = io.open(fileName, "w")
	if not f then
		error("Can't create file \""..fileName.."\"!")
	end

	-- Предупреждение об автогенерации, начало файла
	f:write("/* AUTOGENERATED FILE. DO NOT EDIT. BEGIN. "..os.date("%Y-%m-%d %H:%M:%S")..". */\n\n");

	-- Защита от повторного включения, начало
	local OneInclude = "JDSOFT_ENUMGENERATOR_"..string.upper(select(2, ParsePath(fileName))).."_"..string.upper(select(3, ParsePath(fileName)))
	f:write("#ifndef "..OneInclude.."\n")
	f:write("#define "..OneInclude.."\n")
	f:write("\n")

	-- Подключаемые файлы
	f:write(string.format('#include "%s"\n', "EnumUtils.hpp"))
	if options.OutFileHppInclude then
		f:write("\n")
		for i,v in ipairs(options.OutFileHppInclude) do
			f:write(string.format('#include "%s"\n', v))
		end
	end
	f:write("\n\n\n")

	-- Символьные имена параметров
	local hppParts = {}
	for i,v in ipairs(parts) do
		local type = v.Type
		if type == "Enum" then
			local hppData = PartTypeEnum_Replacer(TemplateHpp, v, options)
			table.insert(hppParts, hppData)
		end
	end
	local hppText = table.concat(hppParts, "\n\n")
	f:write(hppText)

	-- Защита от повторного включения, конец
	f:write("\n\n\n")
	f:write("#endif // "..OneInclude.."\n")

	-- Предупреждение об автогенерации, конец файла
	f:write("\n")
	f:write("/* AUTOGENERATED FILE. DO NOT EDIT. END. */\n");

	io.close(f)
	print("File \""..fileName.."\" was created.")
end


-- Создание файла "*.cpp"
local function FileCppCreate(parts, fileName, options)
	-- Открытие файла
	local f = io.open(fileName, "w")
	if not f then
		error("Can't create file \""..fileName.."\"!")
	end

	-- Предупреждение об автогенерации, начало файла
	f:write("/* AUTOGENERATED FILE. DO NOT EDIT. BEGIN. "..os.date("%Y-%m-%d %H:%M:%S")..". */\n\n");

	-- Подключаемые файлы
	local obj = {ParsePath(options.OutFileHpp)}
	local includeFile = obj[2].."."..obj[3]
	f:write(string.format('#include "%s"\n', includeFile))
	f:write("\n\n\n")

	-- Символьные имена параметров
	local hppParts = {}
	for i,v in ipairs(parts) do
		local type = v.Type
		if type == "Enum" then
			local hppData = PartTypeEnum_Replacer(TemplateCpp, v, options)
			table.insert(hppParts, hppData)
		end
	end
	local hppText = table.concat(hppParts, "\n\n")
	f:write(hppText)

	-- Предупреждение об автогенерации, конец файла
	f:write("\n")
	f:write("/* AUTOGENERATED FILE. DO NOT EDIT. END. */\n");

	io.close(f)
	print("File \""..fileName.."\" was created.")
end


-- Convert FileCsv to FileHpp (and FileCpp) with Options
function FileCsvProcess(Options)
	local InFileCsv = Options.InFileCsv or "in.cvs"
	local OutFileHpp = Options.OutFileHpp or "out.hpp"
	local parts, e = FileCSVToTreeParts(InFileCsv, Options.CsvDelim)
	if not parts then
		print("Error!", e)
		return nil, e
	end
	PartsAllProcess(parts)

	-- Generating output files
	local options = TableTreeCopy(Options)
	if options.OutFileCpp then
		options.useCpp = true
	end
	FileHppCreate(parts, OutFileHpp, options)
	if options.useCpp then
		FileCppCreate(parts, Options.OutFileCpp, TableTreeCopy(options, {isCpp = true}))
	end

	print("Successfully completed!")
end

--************************* (C) COPYRIGHT 2014 J&DSoft *************************
