--движение с запада на восток
local component = require("component")
local fileSystem = require("filesystem")
local computer = require("computer")
local term = require("term")
local robot = require("robot")
local planks_table
--------------------------------------------------------------------------------------------
local test_game_mode = false --если включен тестовый мод, то робот не будет проверять энергию
--------------------------------------------------------------------------------------------
local done_load = false --первоначальная проверка загружаемых библиотек
local pair_count  = 0 --количество своев в таблице, высчитывается при стартовых проверках
local count_names_blocks = {} --подсчитывает в функции таблицу имен блоков в чанке, для вывода через print()
local names_blocks = {} --а это сами названия блоков
local all_block_in_chank = 0 --общее количество блоков в чанке
local hopper_block = false
local programm, file_programm_name, creat
local navigate
local geo = component.geolyzer
local inv
local inv_size
local move
local table_sides = {}
local programm_t = {}
local table_blocks = {}
local start_position = {x,y,z}
local pair_blocks = {}
local pair_planks = {}
--минимальное количество энергии
local energyMinimym = 10000
--гаечный ключ
local g_key = "OpenComputers:wrench"
--ступеньки из дерева
local wooden_slab = "minecraft:wooden_slab"
--ступеьки из камня
local stone_slab = "minecraft:stone_slab"
--таблица ступенек
local table_stairs = {[1] = "minecraft:stone_brick_stairs", [2] = "minecraft:stone_stairs", [3] = "minecraft:brick_stairs", [4] = "minecraft:spruce_stairs", [5] = "minecraft:oak_stairs", [6] = "minecraft:birch_stairs", [7] = "minecraft:jungle_stairs", [8] = "minecraft:acacia_stairs", [9] = "minecraft:dark_oak_stairs", [10] = "minecraft:quartz_stairs", [11] = "minecraft:nether_brick_stairs", [12] = "minecraft:sandstone_stairs"}
							--         каменные ступеньки,        ступеньки из булыжника          кирпичные ступеньки             еловые ступеньки                  дубовые ступеньки		       березовые ступеньки             тропические ступеньки             тупеньки из акации             ступеньки из тёмного дуба             кварцевые ступеньки                   адские ступеньки					ступеньки из песчаника
--таблица планок
local it_is_double = false
local it_is_planks = false
local wood = true
local table_planks = {} --таблица планок, библиотека загружается отдельно
local table_librarys = {} --таблица содержит загруженные самописные библиотеки, пример: table_librarys["sizeLibrary"].moveOut()
--таблица деревьев
local table_of_trees = {[1] = "minecraft:log"}
--таблицы названий по метаданным
local table_meta_planks_name = {[0] = "Дубовые доски", [1] = "Еловые доски", [2] = "Березовые доски", [3] = "Доски из тропического дерева", [4] = "Доски из акации", [5] = "Доски из тёмного дуба"}
local table_hardened_clay = {[0] = "белая обож. глина", [1] = "оранжевая обож. глина", [2] = "пурпурная обож. глина", [3] = "голубая обож. глина", [4] = "желтая обож. глина", [5] = "лаймовая обож. глина", [6] = "розовая обож. глина", [7] = "серая обож. глина", [8] = "светло-серая обож. глина", [9] = "бирюзовая обож. глина", [10] = "фиолетовая обож. глина", [11] = "синяя обож. глина", [12] = "коричневая обож. глина", [13] = "зеленая обож. глина", [14] = "красная обож. глина", [15] = "черная обож. глина"}
local table_hardened_glass = {[0] = "белое стекло", [1] = "оранжевое стекло", [2] = "пурпурное стекло", [3] = "голубое стекло", [4] = "желтое стекло", [5] = "лаймовое стекло", [6] = "розовое стекло", [7] = "серое стекло", [8] = "светло-серое стекло", [9] = "бирюзовое стекло", [10] = "фиолетовое стекло", [11] = "синее стекло", [12] = "коричневое стекло", [13] = "зеленое стекло", [14] = "красное стекло", [15] = "черное стекло"}
local table_hardened_glass_pane = {[0] = "белая стекл. панель", [1] = "оранжевая стекл. панель", [2] = "пурпурная стекл. панель", [3] = "голубая стекл. панель", [4] = "желтая стекл. панель", [5] = "лаймовая стекл. панель", [6] = "розовая стекл. панель", [7] = "серая стекл. панель", [8] = "светло-серая стекл. панель", [9] = "бирюзовая стекл. панель", [10] = "фиолетовая стекл. панель", [11] = "синяя стекл. панель", [12] = "коричневая стекл. панель", [13] = "зеленая стекл. панель", [14] = "красная стекл. панель", [15] = "черная стекл. панель"}
local table_wool = {[0] = "белая шерсть", [1] = "оранжевая шерсть", [2] = "пурпурная шерсть", [3] = "голубая шерсть", [4] = "желтая шерсть", [5] = "лаймовая шерсть", [6] = "розовая шерсть", [7] = "серая шерсть", [8] = "светло-серая шерсть", [9] = "бирюзовая шерсть", [10] = "фиолетовая шерсть", [11] = "синяя шерсть", [12] = "коричневая шерсть", [13] = "зеленая шерсть", [14] = "красная шерсть", [15] = "черная шерсть"}
----------------------------------Ф У Н К Ц И И -----------------------------------------------
--открывает файл return для сохранения первоначальных координат робота
function open_return_file()
	dofile("//home//return")
end
--функция используется вместе с pcall для безопастной проверке библиотек
function load_library(library_name)
	table_librarys[library_name] = require(library_name)
end
--безопастная загрузка таблицы планок
--загружается русская или английская версия - можно проверить в инвентаре робота командой =component.inventory_controller.getStackInInternalSlot(1).label
function load_table_planks()
	planks_table = require("table_planks")
end
--функция выводит сообщения на экран и выходит из программы, если загрузка библиотеки поизошла неудачно
function load_library_fail(library_name)
	computer.beep(1000,0.1)
	computer.beep(1000,0.1)
	
	print("загрузка библиотеки " ..library_name)
	print("закончилась неудачей")
end
--дебаг, нажать энтер для продолжения
function deb_enter(what_text)
	if what_text == nil then what_text = "имеет значение nil" end
	print(what_text)
	print("жми ентер для продолжения")
	local lol_enter = io.read()
end
--задать имя программы
function set_programm_name()
	term.clear()
	local file, fileName
	file = io.open("ProgrammName")
	if file == nil then
		term.clear()
		print("файл с названием программы не создан")
		file = io.open("ProgrammName","w")
		print("введи название программы")
		::fileName_again::
		fileName = io.read()
		if fileName == "2" then os.exit() end
		file:write(fileName)
		file:close()
		if fileName ~= nil then
			print("ищу файл с названием "..fileName)
			local try, _ = pcall(try_load_data_base, fileName)
			if not try then
				print("ФАЙЛ: " ..fileName.." НЕ НАЙДЕН, ЗАПИСАТЬ НОВОЕ НАЗВАНИЕ ПРОГРАММЫ, 2 = ВЫХОД")
				goto fileName_again
			end
		else
			print("введи название программы еще раз")
			goto fileName_again
		end
		return
	else
		fileName = file:read("*a")
		file:close()
		file = io.open("ProgrammName","w")
		print("выбери действие:")
		print("1 - открыть файл: " ..fileName)
		print("2 - записать новый файл")
		print("3 - выход")
		print("4 - открыть файл не в безопастном режиме, на свой страх и риск")
		local chose_mode = io.read()
		if chose_mode == "1" then
			print("ОТКРЫВАЮ")
			local try, _ = pcall(try_load_data_base, fileName)
			if not try then print("файл не найден, проверь в названии отсутствите ==> .lua"); file:write(fileName); file:close(); os.exit() end
			file:write(fileName)
			file:close()
		elseif chose_mode == "2" then
			print("введи название программы, - \"без использования .lua\"")
			creat = io.read()
			print("ищу файл: " .. creat)
			try,_ = pcall(try_load_data_base, creat)
			if not try then term.clear(); print("ФАЙЛ " ..creat.. " НЕ НАЙДЕН, проверь в название присутствите ==> .lua"); print("выход из программы"); file:write(fileName); file:close(); os.exit() end
			file:write(creat)
			file:close()
		elseif chose_mode == "3" then
			print("выход из программы")
			file:write(fileName)
			file:close()
			os.exit()
		elseif chose_mode == "4" then
			print("введи название программы, - \"без использования .lua\"")
			creat = io.read()
			print("ищу файл: " .. creat)
			file:write(creat)
			file:close()
			programm = require(creat)
			print("слава богам, файл успешно найден")
		else
			print("неизвестное действие, программа завершена")
			file:write(fileName)
			file:close()
			os.exit()
		end
	end
end
--защищенная функция для открытия файла
function try_load_data_base(name)
	programm = require(name)
end
--10 секундный таймер
function weit_ten_seconds()
	computer.beep(1000, 0.2)
	for i = 10,1,-1 do
		os.sleep(1)
		print(i)
	end
end
--ищет, в каком слоте есть определенный блок
--если такого блока нет, возвращает 0, иначе возвращает номер слота с блоком
--аргументы(имя блока, это двойной блок, его метаданные и wood - какой именно тип планки, деревянный или каменный)
function find_block(block_name, is_double, meta, wood, is_planks)
	local num, table_slot
	if is_double or is_planks then
		for i = 1,inv_size do
			table_slot = inv.getStackInInternalSlot(i)
			if table_slot ~= nil then
				if table_slot.name == block_name and table_slot.label == table_planks[wood][meta]["label"] then
					return i
				end
			end
		end
	elseif block_name == "minecraft:planks" or block_name == "minecraft:stained_hardened_clay" or block_name == "minecraft:stained_glass" or block_name == "minecraft:stained_glass_pane" or block_name == "minecraft:wool" then
		for i = 1,inv_size do
			table_slot = inv.getStackInInternalSlot(i)
			if table_slot ~= nil then
				if table_slot.name == block_name and table_slot.damage == meta then
					return i
				end
			end
		end
	else
		for i = 1,inv_size do
			table_slot = inv.getStackInInternalSlot(i)
			if table_slot ~= nil then
				if table_slot.name == block_name then
					return i
				end
			end
		end
	end
	return 0
end
--переложить предмет из первого слота робота в любой другой
function first_slot_transfer()
	local table_slot
	table_slot = inv.getStackInInternalSlot(1)
	if table_slot ~= nil then
	robot.select(1)
		for i = 2,inv_size do
			table_slot = inv.getStackInInternalSlot(i)
			if table_slot == nil then
				robot.transferTo(i)
				return
			end
		end
	else
		return
	end
	::try_again1::
	term.clear()
	print("ВСЕ СЛОТЫ ИНВЕНТАРЯ РОБОТА ЗАНЯТЫ")
	print("ПЕРЕЛОЖИ САМОСТОЯТЕЛЬНО ПРЕДМЕТ ИЗ ПЕРВОГО СЛОТА, В ЛЮБОЙ ДРУГОЙ")
	print("И НАЖМИ ЕНТЕР")
	computer.beep(1000, 5)
	local enter = io.read()
	table_slot = inv.getStackInInternalSlot(1)
	if table_slot ~= nil then goto try_again1 end
	term.clear()
end
--ставит ступеньки в мир
--аргументы(метадата_ступенек, номер_слота_ступенек, номер_слота_гаечного_ключа)
function build_stairs(metadata, stairs_slot_num, g_key_slot_num)
	--deb("номер слота ступенек: " ..stairs_slot_num.. " номер_слота_ключа " ..g_key_slot_num)
	--print("энтер для продолжения")
	--local ennn = io.read()
	local to_first_slot = 1
	if slot_num == 0 then
		print("не могу найти ступеньки")
		print("программа завершена")
		os.exit()
	end
	local _,z,_ = navigate.getPosition()
	if metadata >= 4 then
		table_librarys["moveLibrary"].z_move(z - 1)
		first_slot_transfer() --переложить предмет из первого слота в любой другой
		robot.select(to_first_slot)
		inv.equip() 		  --проверить, нет ли предмета в руке робота
		first_slot_transfer() --переложить еще раз предмет из первого слота, если он там есть
		robot.select(stairs_slot_num)
		robot.transferTo(to_first_slot)
		::try_again2::
		repeat until robot.useDown()
		computer.beep(400, 0.1)
		computer.beep(1000, 0.1)
		computer.beep(400, 0.1)
		computer.beep(1000, 0.1)
		if geo.analyze(0).name == "minecraft:air" then deb("ЖДУ 10 СЕКУНД"); goto try_again2 end
		robot.select(g_key_slot_num)
		inv.equip()
		while geo.analyze(0).metadata ~= metadata do robot.useDown() end
		table_librarys["moveLibrary"].z_move(z)
		inv.equip()
	else
		robot.select(stairs_slot_num)
		inv.equip()
		::try_again2::
		robot.useDown()
		computer.beep(400, 0.1)
		computer.beep(1000, 0.1)
		computer.beep(400, 0.1)
		computer.beep(1000, 0.1)
		table_librarys["moveLibrary"].z_move(z - 1)
		if geo.analyze(0).name == "minecraft:air" then computer.beep(400, 2); table_librarys["moveLibrary"].z_move(z); deb("жду 10 секунд") goto try_again2 end
		computer.beep(1000, 0.1)
		inv.equip()
		robot.select(g_key_slot_num)
		inv.equip()
		while geo.analyze(0).metadata ~= metadata do robot.useDown() end
		table_librarys["moveLibrary"].z_move(z)
		inv.equip()
	end
end
--ставит обычные блоки в мир
--единственный аргумент(номер_слота_необходимого_блока)
function build_blocks(block_number_slot, hopper)
	local _,z,_ = navigate.getPosition()
	robot.select(block_number_slot)
	inv.equip()
	::try_again3::
	repeat until robot.useDown()
	computer.beep(400, 0.1)
	computer.beep(1000, 0.1)
	computer.beep(400, 0.1)
	computer.beep(1000, 0.1)
	if not hopper then table_librarys["moveLibrary"].z_move(z - 1)
		if geo.analyze(0).name == "minecraft:air" then
			table_librarys["moveLibrary"].z_move(z)
			computer.beep(400, 2)
			deb("ЖДУ 10 СЕКУНД")
			goto try_again3
		end
		computer.beep(1000, 0.1)
		table_librarys["moveLibrary"].z_move(z)
	end
	inv.equip()
end
--функция для дебага, ожидание 10 секунд с выводом времени на экран
function deb(print_text)
	print(print_text)
	print("ОСТАЛОСЬ ВРЕМЕНИ:")
	for i = 10, 1, -1 do
		print(i)
		os.sleep(1)
	end
end
--возвращение на базу в поисках предмета, если его не оказалось в инвентаре
--затем возвращение обратно на поле. аргумент check_meta имеет булево значение, и проверяет блоки с одинаковым названием, но разными метаданными
--такики, как блоки досок. блоки шерсти и стекла разных цветов. Если имеет значение true, будет произведена проверка
function return_and_find_item(block_name, meta, check_meta)
	local sycle = 0
	local pos_x, pos_z, pos_y = navigate.getPosition()
	return_on_start_position()
	--проверка энергии
	table_librarys["energyChecker"].check_energy_in_base()
	table_librarys["moveLibrary"].z_move(start_position.z + 1)
	for rForward = 1,3 do
		while geo.analyze(3).name == "OpenComputers:robot" do computer.beep(1000, 1); table_librarys["moveLibrary"].z_move(start_position.z + 2); term.clear(); print("на моем пути робот"); print("пытаюсь уступить дорогу"); weit_ten_seconds(); table_librarys["moveLibrary"].z_move(start_position.z + 1) end
		table_librarys["moveLibrary"].x_y_move(start_position.x - rForward, start_position.y)
	end
	::next_check::
	while geo.analyze(0).name ~= block_name do
		if geo.analyze(3).name == "minecraft:air" or geo.analyze(3).name == "Thaumcraft:blockAiry" or geo.analyze(3).name == "OpenComputers:robot" then
			table_librarys["moveLibrary"].x_y_move(start_position.x - 3, start_position.y + sycle)
		end
		sycle = sycle + 1
		if geo.analyze(3).name ~= "minecraft:air" then --робот останавливает поиск, когда ему встречается блок на пути
			if geo.analyze(3).name ~= "Thaumcraft:blockAiry" then
				if geo.analyze(3).name ~= "OpenComputers:robot" then
					term.clear()
					if block_name == "minecraft:stained_hardened_clay" then
						print("не могу найти предмет")
						print(table_hardened_clay[meta])
					elseif block_name == "minecraft:stained_glass_pane" then
						print("не могу найти предмет")
						print(table_hardened_glass_pane[meta])
					elseif block_name == "minecraft:stained_glass" then
						print("не могу найти предмет")
						print(table_hardened_glass[meta])
					elseif block_name == "minecraft:wool" then
						print("не могу найти предмет")
						print(table_wool[meta])				
					elseif block_name == "minecraft:planks" then
						if meta < 6 then
							print("конкретное название: " ..table_meta_planks_name[meta]); computer.beep(1000, 10)
						else
							print("метаданные: \"" ..meta.. "\" не совпадают с таблицей метаданных досок"); computer.beep(1000, 10)
						end
					else
						print("не могу найти предмет " ..block_name)
					end
					print("положи предмет в робота и нажми ентер")
					local ent = io.read()
					move(start_position.x, start_position.y, start_position.z)
					table_librarys["moveLibrary"].z_move(pos_z)
					move(pos_x, pos_y, pos_z)
					return
				end
			end
		end
	end
	--проверка на совпадение метаданных блока(проверяет, если только это блоки с одинаковым именем, но разными метаданными(доски, шерсть разных цветов, стекло разных цветов)
	if check_meta then
		if geo.analyze(0).metadata ~= meta then
			table_librarys["moveLibrary"].x_y_move(start_position.x - 3, start_position.y + sycle)
			sycle = sycle + 1
			goto next_check
		end
	end
	table_librarys["moveLibrary"].z_move(start_position.z + 2) --поднятся на блок выше к воронкам
	local slot_number = 0
	while find_block(block_name, false, meta, false, false) == 0 do end
	slot_number = find_block(block_name,  false, meta, false, false)
	while robot.count(slot_number) < 50 do term.clear(); print("количество блоков собрано: " ..robot.count(slot_number).. " из 50"); computer.beep(1000, 0.1); end
	term.clear()
	move(start_position.x, start_position.y, start_position.z + 1)
	table_librarys["moveLibrary"].z_move(pos_z)
	move(pos_x, pos_y, pos_z)
end
--возврат на стартовую позицию робота
function return_on_start_position()
	move(start_position.x, start_position.y, start_position.z)
end
--проверка энергии в поле
function check_energy_in_line(energyMin)
	if table_librarys["energyChecker"].how_much_enegry(energyMin + 500) then
		local now_position_x, now_position_z, now_position_y = navigate.getPosition()
		move(start_position.x, start_position.y, start_position.z)
		table_librarys["energyChecker"].check_energy_in_base()
		move(start_position.x, start_position.y, now_position_z)
		move(now_position_x, now_position_y, now_position_z)
	end
end
--определение блока, если это ступеньки, то возврщает true, иначе вернет false
function it_is_stairs(block_name)
	for _,v in pairs(table_stairs) do
		if v == block_name then return true end
	end
	return false
end
--определение блока, если это плиты, то возвращает true, иначе вернет false
function is_is_planks(block_name)
	if table_planks[1] == block_name or table_planks[2] == block_name then return true end
	return false
end
--посчитать все слои таблицы
function all_slyers()
	local allSlayers = 0
	for k,_ in pairs(programm_t) do
		allSlayers = allSlayers + 1
	end
	return allSlayers
end
--поставить планку в мир
--аргументы(доски находятся в нижнем положении?, это двойные доски?)
function build_planks(it_is_down, it_is_bouble)
	local stone_or_wood = ""
	local _,mov_z,_ = navigate.getPosition()
	--ставит планку с самого низу
	if it_is_down and it_is_bouble == false then
		inv.equip()
		::build_again::
		repeat until robot.useDown()
		table_librarys["moveLibrary"].z_move(mov_z - 1)
		if geo.analyze(0).name == "minecraft:air" then
			table_librarys["moveLibrary"].z_move(mov_z)
			computer.beep(1000, 0.1)
			deb("ЖДУ 10 СЕК")
			goto build_again
		end
		table_librarys["moveLibrary"].z_move(mov_z)
		inv.equip()
	--ставит двойные планки
	elseif it_is_bouble	then
		if wood == "wooden" then stone_or_wood = "minecraft:double_wooden_slab" else stone_or_wood = "minecraft:double_stone_slab" end
		inv.equip()
		repeat until robot.useDown()
		::build_again2::
		repeat until robot.useDown()
		table_librarys["moveLibrary"].z_move(mov_z - 1)
			if geo.analyze(0).name ~= stone_or_wood then
				table_librarys["moveLibrary"].z_move(mov_z)
				computer.beep(1000, 0.1)
				deb("ЖДУ 10 СЕК")
				goto build_again2
			end
		table_librarys["moveLibrary"].z_move(mov_z)
		inv.equip()
	--ставит планки сверху
	else
		robot.transferTo(1)
		table_librarys["moveLibrary"].z_move(mov_z - 1)
		::build_again3::
		repeat until robot.useDown()
		if geo.analyze(0).name == "minecraft:air" then
			computer.beep(1000, 0.1)
			deb("ЖДУ 10 СЕК")
			goto build_again3
		end
		table_librarys["moveLibrary"].z_move(mov_z)
		first_slot_transfer()
	end
end
--запись расположения блоков под воронками для робота
function create_file_hopper_blocks(need_create_new_table)
	if need_create_new_table then
	
	else
	
	end
end
--менюшка выбора стартовых опций программы
function open_main_menu()
	local my_x, my_z, my_y
	::try_again5::
	my_x, my_z, my_y = navigate.getPosition()
	print("               ГЛАВНОЕ МЕНЮ:")
	print("0 - выход из программы")
	print("1 - начать строительство объекта")
	print("12 - управление ресурсами")
	print("---------------------------------------------")
	print("передвинуть робота на:")
	print("2 - СЕВЕР")
	print("3 - ЮГ")
	print("4 - ЗАПАД")
	print("5 - ВОСТОК")
	print("6 - СЕВЕРО-ЗАПАД")
	print("7 - СЕВЕРО-ВОСТОК")
	print("8 - ЮГО-ЗАПАД")
	print("9 - ЮГО-ВОСТОК")
	print("10 - не используемый номер")
	local chose_num = tonumber(io.read())
	if chose_num == nil then term.clear(); computer.beep(1000, 0.1); computer.beep(1000, 0.1); deb_enter("введена неизвестная команда"); term.clear(); goto try_again5
	elseif chose_num == 0 then term.clear(); computer.beep(1000, 0.1); computer.beep(1000, 0.1); print("программа завершена"); os.exit()
	elseif chose_num == 1 then term.clear(); print("приступаю к строительству")
	elseif chose_num == 2 then move(my_x, my_y, my_z + 1); move(my_x, my_y - 16, my_z); term.clear(); creat_file(); goto try_again5
	elseif chose_num == 3 then move(my_x, my_y, my_z + 1); move(my_x, my_y + 16, my_z); term.clear(); creat_file(); goto try_again5
	elseif chose_num == 4 then move(my_x, my_y, my_z + 1); move(my_x - 16, my_y, my_z); term.clear(); creat_file(); goto try_again5
	elseif chose_num == 5 then move(my_x, my_y, my_z + 1); move(my_x + 16, my_y, my_z); term.clear(); creat_file(); goto try_again5
	elseif chose_num == 6 then move(my_x, my_y, my_z + 1); move(my_x - 16, my_y - 16, my_z); term.clear(); creat_file(); goto try_again5
	elseif chose_num == 7 then move(my_x, my_y, my_z + 1); move(my_x + 16, my_y - 16, my_z); term.clear(); creat_file(); goto try_again5
	elseif chose_num == 8 then move(my_x, my_y, my_z + 1); move(my_x - 16, my_y + 16, my_z); term.clear(); creat_file(); goto try_again5
	elseif chose_num == 9 then move(my_x, my_y, my_z + 1); move(my_x + 16, my_y + 16, my_z); term.clear(); creat_file(); goto try_again5
	elseif chose_num == 10 then term.clear(); deb_enter("надо допилить код..."); term.clear(); goto try_again5
	elseif chose_num == 12 then
		term.clear()
		local _,err = pcall(build_warehouse)
		if type(err) == "string" then print(err); print("проверь наличие файла warehouse"); print("программа завершена"); computer.beep(1000,0.1); computer.beep(1000,0.1); os.exit() end
		for k,v in pairs(pair_blocks) do print(k,v) end
		for key, val in pairs(pair_planks) do print(key,val) end
		goto try_again5
	end
end
--функция строительства склада с ресурсами и воронками
function open_build_warehouse()
	pair_blocks, pair_planks = dofile("warehouse")
end
--фунция перезаписи файла первоначальных координат
function creat_file()
	file = io.open("MyCoords","w")
	local x,z,y = navigate.getPosition()
	file:write(x.."\n"); file:write(y.."\n"); file:write(z.."\n")
	file:close()
end
--проверка компонента навигации робота(вызывается в безопастном режиме)
function check_component_navigation()
	navigate = component.navigation
end
--проверка компонента контроллер инвентаря робота(вызывается в безопастном режиме)
function check_inventory_controller()
	inv = component.inventory_controller
end
--вернуться на базу за планками
function return_to_base_and_get_planks(block_name, meta_num, block_num_in_inventory) --первые 2 аргумента берутся из таблицы строительства блоков, последний аргумент. это номер слота, в котором находится необходимый блок у робота
	move_block_from_robot_arm() --перемещение предмета руки робота, если он в нем есть, в любой свободный слот, кроме первого слота
	local slab
	if meta_num >= 8 then meta_num = meta_num - 8 end
	if block_name == "minecraft:wooden_slab" then slab = "wooden" else slab = "stone" end
	local my_now_x, my_now_z, my_now_y = navigate.getPosition()
	::try_again6::
	move(start_position.x, start_position.y, start_position.z)
	table_librarys["energyChecker"].check_energy_in_base()
	table_librarys["moveLibrary"].z_move(start_position.z + 1)
	for rForward = 1,5 do
		while geo.analyze(3).name == "OpenComputers:robot" do computer.beep(1000, 1); table_librarys["moveLibrary"].z_move(start_position.z + 2); term.clear(); print("на моем пути робот"); print("пытаюсь уступить дорогу"); weit_ten_seconds(); table_librarys["moveLibrary"].z_move(start_position.z + 1) end
		table_librarys["moveLibrary"].x_y_move(start_position.x - rForward, start_position.y)
	end
	while navigate.getFacing() ~= 3 do table_sides[3][navigate.getFacing()]() end --поворот на юг
	term.clear()
	while geo.analyze(3).name == "minecraft:air" or geo.analyze(3).name == "OpenComputers:robot" or geo.analyze(3).name == "Thaumcraft:blockAiry" do
		local analyze = geo.analyze(0)
		if analyze.name == block_name and analyze.metadata == meta_num then
			robot.transferTo(1) --перемещение из активного слота в первый слот робота
			table_librarys["moveLibrary"].z_move(start_position.z + 2)
			while robot.count(1) < 50 do computer.beep(1000,0.1); term.clear(); print("всего блоков: " ..robot.count(1)) end
			move(start_position.x - 4, start_position.y, start_position.z + 1)
			move(start_position.x, start_position.y, start_position.z + 1)
			robot.select(1) --выбрать первый слот у робота
			robot.transferTo(block_num_in_inventory) --перемещение предмета из первого слота, в слот, который был изначально
			robot.select(block_num_in_inventory) --делает активным изначальный слот робота
			--возвращение на позицию, где робота был на стройке до этого
			move(start_position.x, start_position.y, my_now_z)
			move(my_now_x, my_now_y, my_now_z)
			return
		end
		robot.forward()
	end
	term.clear()
	print("НЕ МОГУ НАЙТИ - " ..table_planks[slab][meta_num]["label"])
	print("повторный просмотр склада через:")
	computer.beep(1000,10)
	weit_ten_seconds()
	goto try_again6
end
--проверка блока в руку робота. вернут true, если есть блок в рукe, иначе вернет false
function block_in_robot_arm()
	local arg_one, arg_two = robot.durability()
	if arg_one ~= nil then return true end
	if arg_two == "tool cannot be damage" then return true end
	return false
end
--наайти свободный слот, кроме первого и выделить его
function find_free_slot_and_select_it()
	local find_slot
	for i = 2,inv_size do
		find_slot = inv.getStackInInternalSlot(i)
		if find_slot == nil then
			robot.select(i)
			return
		end
	end
end
--перемещает блок, либо инструмент из руки робота, в первый свободный слот
function move_block_from_robot_arm()
	if block_in_robot_arm() then
		local save_slot = robot.select() --запомнить выделенный слот в инвентаре
		find_free_slot_and_select_it() --переместить предмет из руку робота в любой свободный слот, кроме первого
		inv.equip()
		robot.select(save_slot) --выделить слот, который был выделен до перемещения
	end
end
----------------------------------Н А Ч А Л О  Р А Б О Т Ы--------------------------------------------
do
	--проверка необходимых библиотек
	print("ПЕРВОНАЧАЛЬНЫЕ ПРОВЕРКИ НАЛИЧИЯ БИБЛИОТЕК")
	print("поиск компонента: навигация")
	done_load,_ = pcall(check_component_navigation)
	if not done_load then print("компонент навигации не найден"); deb_enter("программа будет завершена"); os.exit() end
	print("поиск компонента: контроллер инвентаря")
	done_load, _ = pcall(check_inventory_controller)
	if not done_load then print("компонент контроллера инвентаря не найден"); deb_enter("программа будет завершена"); os.exit() end
	done_load,_ = pcall(load_library, "sizeLibrary")
	if not done_load then load_library_fail("sizeLibrary"); deb_enter("программа будет завершена"); os.exit() end
	print("загружено")
	done_load,_ = pcall(load_library, "moveLibrary")
	if not done_load then load_library_fail("moveLibrary") deb_enter("программа будет завершена"); os.exit() end
	print("загружено")
	done_load,_ = pcall(load_library, "energyChecker")
	if not done_load then load_library_fail("energyChecker") deb_enter("программа будет завершена"); os.exit() end
	print("загружено")
	done_load,_ =  pcall(load_table_planks)
	if not done_load then load_library_fail("table_planks") deb_enter("программа будет завершена"); os.exit() end
	print("загружено")
	inv_size = robot.inventorySize()
	term.clear()
	local _,err = pcall(open_return_file)
	if type(err) == "string" then print(err); print("проверь наличие файла return"); print("программа завершена"); computer.beep(1000,0.1); computer.beep(1000,0.1); os.exit() end 
	print("все библиотеки успешно загружены")
	move = table_librarys["moveLibrary"].moveOut
	table_sides = table_librarys["sizeLibrary"].build_pair_sizes()
	os.sleep(2)
	term.clear()
	--задать файл с названием базы данных, где хранятся блоки для постройки(их метаданные, расположение и т.д.)
	set_programm_name()
	--получение таблицы расположения блоков программы
	programm_t = programm.build_pair()
	--менюшка выбора стартовых опций программы
	open_main_menu()
	term.clear()
	--определить начальные координаты
	start_position.x, start_position.z, start_position.y = navigate.getPosition()
	--определить, сколько всего слоев присутствует в схеме
	local allSlay = all_slyers()
	--определение слоя для строительства
	print("С какого слоя нужно строить? Всего слоев в поле: " ..allSlay)
	print("если 0, то выход из программы")
	local slayer = io.read()
	local sl_plus = tonumber(slayer)
	if slayer == "0" then os.exit() end
	slayer = tostring(slayer)
	--загрузка таблицы планок
	table_planks = planks_table.build_pair()
	for sl = sl_plus, allSlay do
		slayer = tostring(sl)
		table_librarys["moveLibrary"].z_move(start_position.z + tonumber(slayer) + 1) --выдвижение на высоту ввверх
		for i = #programm_t[slayer].x,1,-1 do
		move_block_from_robot_arm() --перемещение предмета руки робота, если он в нем есть, в любой свободный слот, кроме первого слота
		hopper_block = false
		---------------------ОПРЕДЕЛЕНИЕ ОПАСНЫХ БЛОКОВ----------------------------------
			if programm_t[slayer].name[i] == "minecraft:double_wooden_slab" then programm_t[slayer].name[i] = table_planks[1]; it_is_double = true; wood = "wooden" end --двойные плиты из дерева меняет на доски
			if programm_t[slayer].name[i] == "minecraft:double_stone_slab" then programm_t[slayer].name[i] = table_planks[2]; it_is_double = true; wood = "stone" end --двойне плиты из камня меняет на каменные кирпичи
			if programm_t[slayer].name[i] == table_planks[1] then it_is_planks = true; wood = "wooden" end
			if programm_t[slayer].name[i] == table_planks[2] then it_is_planks = true; wood = "stone" end
			if programm_t[slayer].name[i] == "minecraft:lit_redstone_lamp" then programm_t[slayer].name[i] = "minecraft:redstone_lamp" end
			if programm_t[slayer].name[i] == "minecraft:monster_egg" then programm_t[slayer].name[i] = "minecraft:stonebrick" end
			if programm_t[slayer].name[i] == "minecraft:stone_button" then programm_t[slayer].name[i] = "minecraft:trapdoor" end
			if programm_t[slayer].name[i] == "minecraft:hopper" then hopper_block = true end
			if programm_t[slayer].name[i] == "minecraft:hopper" then hopper_block = true end
			if programm_t[slayer].name[i] == "speedyhoppers:speedyhopper_mk1" then hopper_block = true end
		---------------------------------------------------------------------------------
			if programm_t[slayer].name[i] ~= "minecraft:trapdoor" then
				--определение оставшегося количества энергии
				if not test_game_mode then check_energy_in_line(energyMinimym) end
				--выдвижение по координатам
				table_librarys["moveLibrary"].x_y_move(start_position.x + programm_t[slayer].x[i], start_position.y + programm_t[slayer].y[i])
				--определение нужного блока в инвентаре для строительства
				::check_again::
				first_slot_transfer() --переложить предмет из первого слота робота в любой другой
				local block_num = find_block(programm_t[slayer].name[i], it_is_double, programm_t[slayer].meta[i], wood, it_is_planks)
				--если блок не найден, вернуться на базу в поисках его в сунуках
				if block_num == 0 then 
					--проверка, если это доски или нет
					if programm_t[slayer].name[i] == table_planks[1] or programm_t[slayer].name[i] == table_planks[2] then
						first_slot_transfer()
						block_num = 1
						robot.select(1)
						return_to_base_and_get_planks(programm_t[slayer].name[i], programm_t[slayer].meta[i], block_num)
						first_slot_transfer()
						block_num = find_block(programm_t[slayer].name[i], it_is_double, programm_t[slayer].meta[i], wood, it_is_planks)
					else
						if programm_t[slayer].name[i] == "minecraft:planks" or programm_t[slayer].name[i] == "minecraft:stained_hardened_clay" or programm_t[slayer].name[i] == "minecraft:stained_glass" or programm_t[slayer].name[i] == "minecraft:stained_glass_pane" or programm_t[slayer].name[i] == "minecraft:wool" then
							return_and_find_item(programm_t[slayer].name[i], programm_t[slayer].meta[i], true)
							goto check_again
						else
							return_and_find_item(programm_t[slayer].name[i], programm_t[slayer].meta[i], false)
							goto check_again
						end
					end
				end
				first_slot_transfer()
				if it_is_stairs(programm_t[slayer].name[i]) then
					first_slot_transfer()
					::try_again4::
					local g_key_slot = find_block(g_key, false, 1, false, false)
					if g_key_slot == 0 then
						computer.beep(1000,2)
						print("НЕ МОГУ НАЙТИ ГАЕЧНЫЙ КЛЮЧ")
						print("ПОЛОЖИ КЛЮЧ В ИНВЕНТАРЬ РОБОТА И НАЖМИ ЕНТЕР")
						local entt = io.read()
						goto try_again4
					end
					build_stairs(programm_t[slayer].meta[i], block_num, g_key_slot)
				elseif is_is_planks(programm_t[slayer].name[i]) then
					local plank_name
					if programm_t[slayer].name[i] == table_planks[1] then plank_name = "wooden" end
					if programm_t[slayer].name[i] == table_planks[2] then plank_name = "stone" end 
					if block_num ~= 0 then
						robot.select(block_num) --робот выбирает планки здесь
						while robot.count(block_num) < 2 do
							return_to_base_and_get_planks(programm_t[slayer].name[i], programm_t[slayer].meta[i], block_num)
						end
					end
					term.clear()
					build_planks(table_planks[plank_name][programm_t[slayer].meta[i]]["down"], it_is_double, wood) --робот выбирает блок не в функции
				else
					build_blocks(block_num, hopper_block)
				end
			end
			it_is_double = false
			it_is_planks = false
		end
	end
	return_on_start_position()
	term.clear()
	print("СТРОИТЕЛЬСТВО ЗАВЕРШЕНО")
	for end_build = 1, 5 do
		computer.beep(400,0.5)
		computer.beep(800,0.5)
	end
end