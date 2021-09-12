--движение с запада на восток со смещением на юг
--вторая версия билдера, роботы и склады расположены над постройкой(не мешают соседним чанкам) 
--дорожки из блоков для склада нужно ставить, а ограничители нет. Робот остановится, когда под ним будет minecraft:air (пустота)
-- wget https://raw.githubusercontent.com/thedark1232/builder/main/Builder3.lua /home/builder3
component = require("component")
local fileSystem = require("filesystem")
local computer = require("computer")
local term = require("term")
local robot = require("robot")
local planks_table
--------------------------------------------------------------------------------------------
local test_game_mode = false --если включен тестовый мод, то робот не будет проверять энергию
--------------------------------------------------------------------------------------------
--названия папок построек из гитхаба
local build_dir_table = {"chiken", "castle_shop", "chrismas_tree_5and5", "home01", "tower", "angel", "ship1", "ship2", "pvp_spawn", "vitruvian_castle", "ImperialCaphedral", "tank01", "castleShop2"}
--таблица опасных блоков(можно дополнять блоками, который робот будет игнорировать), в других местах код менять не надо
local danger_blocks = {["minecraft:stone_button"] = "каменная кнопка",
			["minecraft:tallgrass"] = "высокая трава",
			["minecraft:lever"] = "рычаг",
			["OpenComputers:capacitor"] = "OpenComputers:capacitor",
			["minecraft:redstone_wire"] = "minecraft:redstone_wire",
			["minecraft:snow_layer"] = "слой снега",
			["minecraft:piston_extension"] = "minecraft:piston_extension",
			["minecraft:wooden_pressure_plate"] = "(игнорируется) дерев. нажим. плита",
			["minecraft:snow_slab"] = "(игнорируется)snow_slab",
			["minecraft:wooden_door"] = "(игнорируется) деревянная дверь",
			["minecraft:skull"] = "(игнорируется) череп",
			["minecraft:water"] = "вода",
			["minecraft:torch"] = "факел",
			["minecraft:lava"] = "лава",
			["minecraft:ladder"] = "лестница",
			["minecraft:wooden_button"] = "деревянная кнопка",
			["minecraft:flower_pot"] = "цветочный горшок",
			["minecraft:redstone_torch"] = "красный факел",
			["minecraft:carpet"] = "ковер",
			["minecraft:wall_sign"] = "навесная табличка",
			["minecraft:standing_sign"] = "табличка",
			["minecraft:chest"] = "сундук",
			["minecraft:jukebox"] = "тыква джека",
			["minecraft:lit_pumpkin"] = "светящаяся тыква джека",
			["minecraft:dragon_egg"] = "яйцо дракона",
			["minecraft:red_mushroom_block"] = "грибной блок",
			["minecraft:light_weighted_pressure_plate"] = "золота нажимная плита",
			["minecraft:gravel"] = "гравий",
			["minecraft:coal_ore"] = "угольная руда",
			["minecraft:trapped_chest"] = "сундук-ловушка",
			["minecraft:piston"] = "поршень",
			["minecraft:fence_gate"] = "калитка",
			["minecraft:fire"] = "огонь"}
--игнорируемые файлы при составлении списка схем для удаления
local ignore_files = {["energyChecker.lua"] = "ok", ["moveLibrary.lua"] = "ok", ["sizeLibrary.lua"] = "ok", ["table_planks.lua"] = "ok", ["filesLibrary.lua"] = "ok", ["algorithmLi.lua"] = "ok", ["pac4eT_pecypcoB_cTpouTeJI9l.lua"] = "ok", ["MyCoords"] = "ok"}
--игнорируемые блоки при определении высоты
local ignore_block_height = {["minecraft:air"] = "ok", ["Thaumcraft:blockAiry"] = "ok", ["OpenComputers:robot"] = "ok", ["minecraft:water"] = "ok", ["minecraft:flowing_water"] = "ok"}
--------------------------------------------------------------------------------------------
local done_load = false --первоначальная проверка загружаемых библиотек
local how_many_chanks = 1
local pair_count = 0 --количество своев в таблице, высчитывается при стартовых проверках
local count_names_blocks = {} --подсчитывает в функции таблицу имен блоков в чанке, для вывода через print()
local names_blocks = {} --а это сами названия блоков
components_and_librarys = {}
local all_block_in_chank = 0 --общее количество блоков в чанке
local robot_height = 0 --определение высоты робота до пола
local robot_slayer --вычисление последнего построенного слоя
local how_many_werehouses --настраиваемое при старте проги, сколько своев склада вверх?
local modem_is_avalible --наличие модема
local modem_robot_port, modem_comp_port --порты модема и компа, настраиваются в стартовой менюшке
local file_programm_name, creat
local navigate, geo, inv --компоненты
local moveLibrary, table_sides, energyChecker, filesLibrary, algorithmLi, pac4eT_pecypcoB_cTpouTeJI9l --библиотеки
local last_block --номер последнего построенного блока в схеме
local last_block_mode --булево значение(продолжает стройку с последнего места, либо начинает стройку заного)
local block_number --хранит количество блоков в слое, нужно для главного цикла
local hopper_block = false
local inv_size
local all_blocks = {}
local N, S, W, E = 2, 3, 4, 5 -- N = 2, S = 3, W = 4, E = 5 (цифры сторон света для поворота робота)
local programm_t
local table_blocks = {}
local start_position = {x,y,z}
local pair_blocks = {}
local pair_planks = {}
local energyMinimym = 10000 --минимальное количество энергии
local g_key = "OpenComputers:wrench" --гаечный ключ
local wooden_slab = "minecraft:wooden_slab" --ступеньки из дерева
local stone_slab = "minecraft:stone_slab" --ступеьки из камня
--таблица ступенек
local table_stairs = {[1] = "minecraft:stone_brick_stairs", [2] = "minecraft:stone_stairs", [3] = "minecraft:brick_stairs", [4] = "minecraft:spruce_stairs", [5] = "minecraft:oak_stairs", [6] = "minecraft:birch_stairs", [7] = "minecraft:jungle_stairs", [8] = "minecraft:acacia_stairs", [9] = "minecraft:dark_oak_stairs", [10] = "minecraft:quartz_stairs", [11] = "minecraft:nether_brick_stairs", [12] = "minecraft:sandstone_stairs"}
							--         каменные ступеньки,        ступеньки из булыжника          кирпичные ступеньки             еловые ступеньки                  дубовые ступеньки		       березовые ступеньки             тропические ступеньки             тупеньки из акации             ступеньки из тёмного дуба             кварцевые ступеньки                   адские ступеньки					ступеньки из песчаника
--таблица планок
local it_is_double = false
local it_is_planks = false
local wood = true
local table_planks = {} --таблица планок, библиотека загружается отдельно
--таблица деревьев
local table_of_trees = {[1] = "minecraft:log"}
--таблица листвы
	--допилить код здесь
--таблицы названий по метаданным
local table_meta_planks_name = {[0] = "Дубовые доски", [1] = "Еловые доски", [2] = "Березовые доски", [3] = "Доски из тропического дерева", [4] = "Доски из акации", [5] = "Доски из тёмного дуба"}
local table_hardened_clay = {[0] = "белая обож. глина", [1] = "оранжевая обож. глина", [2] = "пурпурная обож. глина", [3] = "голубая обож. глина", [4] = "желтая обож. глина", [5] = "лаймовая обож. глина", [6] = "розовая обож. глина", [7] = "серая обож. глина", [8] = "светло-серая обож. глина", [9] = "бирюзовая обож. глина", [10] = "фиолетовая обож. глина", [11] = "синяя обож. глина", [12] = "коричневая обож. глина", [13] = "зеленая обож. глина", [14] = "красная обож. глина", [15] = "черная обож. глина"}
local table_hardened_glass = {[0] = "белое стекло", [1] = "оранжевое стекло", [2] = "пурпурное стекло", [3] = "голубое стекло", [4] = "желтое стекло", [5] = "лаймовое стекло", [6] = "розовое стекло", [7] = "серое стекло", [8] = "светло-серое стекло", [9] = "бирюзовое стекло", [10] = "фиолетовое стекло", [11] = "синее стекло", [12] = "коричневое стекло", [13] = "зеленое стекло", [14] = "красное стекло", [15] = "черное стекло"}
local table_hardened_glass_pane = {[0] = "белая стекл. панель", [1] = "оранжевая стекл. панель", [2] = "пурпурная стекл. панель", [3] = "голубая стекл. панель", [4] = "желтая стекл. панель", [5] = "лаймовая стекл. панель", [6] = "розовая стекл. панель", [7] = "серая стекл. панель", [8] = "светло-серая стекл. панель", [9] = "бирюзовая стекл. панель", [10] = "фиолетовая стекл. панель", [11] = "синяя стекл. панель", [12] = "коричневая стекл. панель", [13] = "зеленая стекл. панель", [14] = "красная стекл. панель", [15] = "черная стекл. панель"}
local table_wool = {[0] = "белая шерсть", [1] = "оранжевая шерсть", [2] = "пурпурная шерсть", [3] = "голубая шерсть", [4] = "желтая шерсть", [5] = "лаймовая шерсть", [6] = "розовая шерсть", [7] = "серая шерсть", [8] = "светло-серая шерсть", [9] = "бирюзовая шерсть", [10] = "фиолетовая шерсть", [11] = "синяя шерсть", [12] = "коричневая шерсть", [13] = "зеленая шерсть", [14] = "красная шерсть", [15] = "черная шерсть"}
------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------РАБОТА С КОМПОНЕНТАМИ-----------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------
--возвращает таблицу компонента при удачной загрузке(если этот компонент присутствует), при неудаче завершает работу программы
function components_and_librarys.getComponent(name)
	local arg1, arg2
	local component_name = "return component." ..name
	local func = load(component_name)
	arg1, arg2 = pcall(func)
	if arg1 then
		print(name .. " ...загружено")
		return arg2		
	else
		if name == "modem" then
			return
		else
			term.clear()
			print("при поиске компонента: " ..name)
			io.write("произошла ошибка: ")
			print(arg2)
			print("программа завершена")
			os.exit()
		end
	end
end
--пробует загрузить библиотку, если библиотека не найдена, завершит работу программы
function components_and_librarys.getLibrary(name)
	local arg1, arg2
	local library_name = "return require(\"" ..name.. "\")"
	local func = load(library_name)
	arg1, arg2 = pcall(func)
	if arg1 then
		print(name .. " ...загружено")
		return arg2
	else
		term.clear()
		print("при поиске библиотеки: " ..name)
		io.write("произошла ошибка: ")
		print(arg2)
		print("программа завершена")
		os.exit()
	end
end
------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------ФУНКЦИИ ОТЛАДКИ--------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------
--дебаг, нажать энтер для продолжения
function deb_enter(what_text)
	if what_text ~= nil then print(what_text) end
	print("жми ентер для продолжения")
	local lol_enter = io.read()
end
--10 секундный таймер
function weit_ten_seconds()
	computer.beep(1000, 0.2)
	for i = 10,1,-1 do
		os.sleep(1)
		print(i)
	end
end
--функция для дебага, ожидание 10 секунд с выводом времени на экран
function deb(print_text, wait_time)
	print(print_text, wait_time)
	print("ОСТАЛОСЬ ВРЕМЕНИ:")
	for i = wait_time, 1, -1 do
		print(i)
		os.sleep(1)
	end
end
------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------УПРАВЛЕНИЕ ФАЙЛАМИ-------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------
--функция для открытия файла
function try_load_data_base(name)
	programm = require(name)
end
--запись и чтение текущего слоя стройки
function file_slayer()
print("чтение файла высоты робота")
	local file_name = "robot_slayer.lua"
	--открыть файл в режиме чтения
	local file_p = io.open(file_name,"r")
	if file_p == nil then --ФАЙЛ НЕ СУЩЕСТВУЕТ
		robot_slayer = "не определено"
	else --ФАЙЛ СУЩЕСТВУЕТ
		local r = file_p:read()
		if r == nil then --ФАЙЛ ПУСТОЙ
			robot_slayer = "не определено"
			file_p:close()
		else --В ФАЙЛЕ ЕСТЬ ДАННЫЕ
			robot_slayer = tonumber(r)
			file_p:close()
		end
	end
end
--запись и чтение последнего поставленного блока в постройке
function file_last_block()
	print("чтение файла последнего блока робота")
	local file_name = "last_build_block.lua"
	--открыть файл в режиме чтения
	local file_p = io.open(file_name,"r")
	if file_p == nil then --ФАЙЛ НЕ СУЩЕСТВУЕТ
		last_block = 0
	else --ФАЙЛ СУЩЕСТВУЕТ
		local r = file_p:read()
		if r == nil then --ФАЙЛ ПУСТОЙ
			last_block = 0
			file_p:close()
		else --В ФАЙЛЕ ЕСТЬ ДАННЫЕ
			last_block = tonumber(r)
			file_p:close()
		end
	end
end
--запись и чтение высоты робота до пола
function file_robot_height()
	local file_name = "robot_height.lua"
	--открыть файл в режиме чтения
	local file_p = io.open(file_name,"r")
	if file_p == nil then --ФАЙЛ НЕ СУЩЕСТВУЕТ
		file_p = io.open(file_name,"w") --создать файл в режиме записи
		--запись параметров в файл
		robot_height = robot_go_down()
		file_p:write(robot_height)
		file_p:close(); return
	else --ФАЙЛ СУЩЕСТВУЕТ
		local r = file_p:read()
		if r == nil then --ФАЙЛ ПУСТОЙ
			file_p:close()
			file_p = io.open(file_name,"w") --создать файл в режиме записи
			robot_height = robot_go_down()
			file_p:write(robot_height)
			file_p:close(); return
		else --В ФАЙЛЕ ЕСТЬ ДАННЫЕ
			robot_height = robot_go_down(tonumber(r))
			file_p:close()
			file_p = io.open(file_name,"w") --создать файл в режиме записи
			file_p:write(robot_height)
			file_p:close(); return
		end
	end
end
--фунция перезаписи файла первоначальных координат
function creat_file()
	file = io.open("MyCoords","w")
	local x,z,y = navigate.getPosition()
	file:write(x.."\n"); file:write(y.."\n"); file:write(z.."\n")
	file:close()
end
------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------РАЗНЫЕ МЕНЮШКИ С ВЫБОРОМ---------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------
--меню выбора стартовых опций программы
function open_main_menu()
	local my_x, my_z, my_y
	::try_again5::
	local multiplier = 1 --множитель передвижения робота по чанкам (работает только по N,S,W,E)
	my_x, my_z, my_y = navigate.getPosition()
	if my_x == nil or my_y == nil or my_z == nil then
		term.clear();
		computer.beep(400, 0.1)
		print("одно из направлений по навигации не определено")
		print("совмести навигацию с новой картой")
		os.exit()
	end
	                           --▀ █ ▄--
	print("█▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀ГЛАВНОЕ МЕНЮ:▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀█")
	print("█ 0 - выход из программы                         █")
	print("█ 1 - начать строительство объекта               █")
	print("█ 12 - место для вашей рекламы                   █")
	print("█▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄█")
	print("█ передвинуть робота на: █                       █")
	print("█ 2 - СЕВЕР              █                       █")
	print("█ 3 - ЮГ                 █                       █")
	print("█ 4 - ЗАПАД              █                       █")
	print("█ 5 - ВОСТОК             █                       █")
	print("█ 6 - СЕВЕРО-ЗАПАД       █                       █")
	print("█ 7 - СЕВЕРО-ВОСТОК      █                       █")
	print("█ 8 - ЮГО-ЗАПАД          █                       █")
	print("█ 9 - ЮГО-ВОСТОК         █▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀█")
	print("█ 10 - движение по Z     █                       █")
	io.write("█▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄█▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄█")
	if modem_is_avalible then --если компонент беспроводной сети вставлен в робота
		modem_robot_port = tonumber(filesLibrary.write_file("robot_port_number", 0)) --второй аргумент, значение возвращаемое по умолчанию, если файл не найден
		modem_comp_port = tonumber(filesLibrary.write_file("comp_port_number", 0)) --второй аргумент, значение возвращаемое по умолчанию, если файл не найден
		term.setCursor(30, 6);  io.write("МОДЕМ: ONLINE")
		term.setCursor(27, 7);  io.write("порт робота: " .. tostring(modem_robot_port))
		term.setCursor(27, 8);  io.write("порт компа: " .. tostring(modem_comp_port))
		term.setCursor(31, 9);  io.write("СМЕНА ПОРТОВ: ")
		term.setCursor(27, 10); io.write("20 - робота")
		term.setCursor(27, 11); io.write("21 - компа")
	else
		term.setCursor(30, 9); io.write("МОДЕМ: OFFLINE")
	end
	clear_input_window(28, 15, 22)
	term.setCursor(28, 15)
	io.write("ВВОД -> ")
	local chose_num = tonumber(io.read())
	if chose_num == nil then term.clear(); computer.beep(1000, 0.1); computer.beep(1000, 0.1); deb_enter("введена неизвестная команда"); term.clear(); goto try_again5
	elseif chose_num == 0 then term.clear(); computer.beep(1000, 0.1); computer.beep(1000, 0.1); print("программа завершена"); os.exit()
	elseif chose_num == 1 then term.clear(); scheme_menu()
	elseif chose_num == 2 then local mult1 = multi(); moveLibrary.moveOut(my_x, my_y, my_z + 1); moveLibrary.moveOut(my_x, my_y - mult1, my_z); term.clear(); creat_file(); goto try_again5
	elseif chose_num == 3 then local mult2 = multi(); moveLibrary.moveOut(my_x, my_y, my_z + 1); moveLibrary.moveOut(my_x, my_y + mult2, my_z); term.clear(); creat_file(); goto try_again5
	elseif chose_num == 4 then local mult3 = multi(); moveLibrary.moveOut(my_x, my_y, my_z + 1); moveLibrary.moveOut(my_x - mult3, my_y, my_z); term.clear(); creat_file(); goto try_again5
	elseif chose_num == 5 then local mult4 = multi(); moveLibrary.moveOut(my_x, my_y, my_z + 1); moveLibrary.moveOut(my_x + mult4, my_y, my_z); term.clear(); creat_file(); goto try_again5
	elseif chose_num == 6 then moveLibrary.moveOut(my_x, my_y, my_z + 1); moveLibrary.moveOut(my_x - 16, my_y - 16, my_z); term.clear(); creat_file(); goto try_again5
	elseif chose_num == 7 then moveLibrary.moveOut(my_x, my_y, my_z + 1); moveLibrary.moveOut(my_x + 16, my_y - 16, my_z); term.clear(); creat_file(); goto try_again5
	elseif chose_num == 8 then moveLibrary.moveOut(my_x, my_y, my_z + 1); moveLibrary.moveOut(my_x - 16, my_y + 16, my_z); term.clear(); creat_file(); goto try_again5
	elseif chose_num == 9 then moveLibrary.moveOut(my_x, my_y, my_z + 1); moveLibrary.moveOut(my_x + 16, my_y + 16, my_z); term.clear(); creat_file(); goto try_again5
	elseif chose_num == 10 then
		term.clear()
		print("отрицательно число двигает робота ниже, положительное выше")
		::must_do_again::
		print("--------------")
		io.write("введи число -> ")	
		local z_num = tonumber(io.read())
		if z_num == nil then term.clear(); computer.beep(1000, 0.1); print("НЕ КОРРЕКТНОЕ ЧИСЛО"); goto must_do_again end
		moveLibrary.moveOut(my_x, my_y, my_z + z_num); creat_file()
		goto try_again5
	elseif chose_num == 12 then
		goto try_again5
	elseif chose_num == 20 then --смена порта робота
		clear_input_window(28, 15, 22); term.setCursor(28, 15); filesLibrary.creat_file("robot_port_number", pcall_return_num(1, 65535))
		goto try_again5
	elseif chose_num == 21 then --смена порта компа
		clear_input_window(28, 15, 22); term.setCursor(28, 15); filesLibrary.creat_file("comp_port_number", pcall_return_num(1, 65535))
		goto try_again5
	else
		goto try_again5
	end
end

--меню выбора схемы
function scheme_menu()
	term.clear()
	local file, fileName
	file = io.open("ProgrammName")
	if file ~= nil then
		fileName = file:read("*a")
		file:close()
	else
		fileName = "отсутствует"
	end
		file = io.open("ProgrammName","w")
		                        --▀ █ ▄--
	    print("█▀▀▀▀▀▀▀▀▀▀▀▀▀ УПРАВЛЕНИЕ  СХЕМАМИ: ▀▀▀▀▀▀▀▀▀▀▀▀▀█")
	    print("█  1 - загрузка схемы:")
	    print("█  2 - записать новой схемы                      █")
	    print("█  3 - скачать схему из инета                    █")
	    print("█  4 - открыть схему без pcall(дебаг)            █")
	    print("█  0 - выход                                     █")
	    print("█▄▄▄▄▄▄▄▄ УДАЛЕНИЕ СТАРЫХ СХЕМ ИЗ ПАПКИ: ▄▄▄▄▄▄▄▄█")
	    print("█                                                █")
	    print("█                                                █")
	    print("█                                                █")
	    print("█                                                █")
	    print("█                                                █")
	    print("█                                                █")
	    print("█▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀█")
	    print("█                                                █")
	    io.write("█▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄█")
		term.setCursor(23, 2)
		io.write(fileName)
		term.setCursor(50, 2)
		io.write("█")
		--проверка папки /usr/lib/ на наличии схем для удаления
		local all_schems = {}
		for scheme in fileSystem.list("/usr/lib/") do if ignore_files[scheme] == nil then all_schems[#all_schems + 1] = scheme end end
		::chooseAgain::
		for cl = 8, 13 do clear_input_window(2, cl, 48) end
		for k, v in ipairs(all_schems) do
			if k < 7 then
				term.setCursor(3, k + 7)
				io.write(k + 4 .. " - " .. v)
			end
		end
		clear_input_window(3, 15, 48); term.setCursor(3, 15)
		io.write("ВВОД -> ")
		local chose_mode = io.read()
		if chose_mode == "5" or chose_mode == "6" or chose_mode == "7" or chose_mode == "8" or chose_mode == "9" or chose_mode == "10" then
			all_schems = delete_scheme(tonumber(chose_mode), all_schems)
			goto chooseAgain
		end
		if chose_mode == "1" and fileName ~= "отсутствует" then
			clear_input_window(3, 15, 48); term.setCursor(3, 15)
			io.write("ЗАГРУЗКА... ОБОЖДИ")
			local try, _ = pcall(function() programm_t = require(fileName).build_pair() end)
			if not try then term.clear(); print("ОШИБКА ПРИ ОТКРЫТИЕ ФАЙЛА..."); computer.beep(400, 1); file:write(fileName); file:close(); os.exit() end
			file:write(fileName)
			file:close()
		elseif chose_mode == "2" then
			fileSystem.remove("/home/robot_slayer.lua")
			clear_input_window(3, 15, 48); term.setCursor(3, 15); io.write("введи название схемы ->                        █"); term.setCursor(27, 15, 48)
			creat = io.read()
			clear_input_window(3, 15, 48); term.setCursor(3, 15); io.write("ищу файл: " .. creat)
			try, _ = pcall(function() programm_t = require(creat).build_pair() end)
			if not try then term.clear(); print("схема " ..creat.. " не найдена, проверь в название отсутствие ==> .lua"); print("выход из программы"); file:write(fileName); file:close(); os.exit() end
			file:write(creat)
			file:close()
		elseif chose_mode == "0" then
			term.clear()
			print("выход из программы")
			file:write(fileName)
			file:close()
			os.exit()
		elseif chose_mode == "4" then
			fileSystem.remove("/home/robot_slayer.lua")
			clear_input_window(3, 15, 48); term.setCursor(3, 15)
			io.write("введи название схемы -> ")
			creat = io.read()
			clear_input_window(3, 15, 48); term.setCursor(3, 15)
			io.write("ищу файл: " .. creat)
			file:write(creat)
			file:close()
			programm_t = require(creat).build_pair()
			clear_input_window(3, 15, 48); term.setCursor(3, 15)
			io.write("Схема успешно загружена. Жми любую кнопку... ")
			local delete = io.read()
		elseif chose_mode == "3" then
			local build_dir_name, build_dir_num
			fileSystem.remove("/home/robot_height.lua")
			fileSystem.remove("/home/robot_slayer.lua")
			term.clear()
			print("ВЫБОР ПОСТРОЙКИ:")
			for k,v in ipairs(build_dir_table) do print(k .. ": " ..v) end
			build_dir_num = pcall_return_num(1, #build_dir_table)
			::again_name::
			print("введи номер схемы"); local build_name = io.read()
			os.execute("wget https://raw.githubusercontent.com/thedark1232/" ..build_dir_table[build_dir_num].. "/main/" ..build_name.. " /usr/lib/"..build_name..".lua")
			local a,b = pcall(function() require(build_name).build_pair() end)
			if not a then fileSystem.remove("/usr/lib/" ..build_name..".lua"); goto again_name end
			file:write(build_name)
			programm_t = require(build_name).build_pair()
			file:close()
		else
			term.clear()
			print("неизвестное действие, программа завершена")
			computer.beep(400, 2)
			file:write(fileName)
			file:close()
			os.exit()
		end
end
------------------------------------------------------------------------------------------------------------------------------
--------------------------------------ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ, С СИЛЬНОЙ СВЯЗЬЮ-----------------------------------------------
------------------------------------------------------------------------------------------------------------------------------
--посчитать множитель по чанкам
function multi()
	term.clear()
	print("на сколько чанков двигаемся?")
	::must_do_again2::
	print("--------------")
	io.write("введи число -> ")	
	local num = tonumber(io.read())
	if num == nil then term.clear(); computer.beep(1000, 0.1); print("НЕ КОРРЕКТНОЕ ЧИСЛО"); goto must_do_again2 end
	return 16 * num
end
--посчитать все слои таблицы
function all_slyers()
	local allSlayers = 0
	for k,_ in pairs(programm_t) do
		allSlayers = allSlayers + 1
	end
	return allSlayers
end
--передвижение робота вниз, пока не достигнет пола(возращает количество пройденых блоков вниз, сам пробот считается нулевым блоком)
function robot_go_down(value_height)
	term.clear()
	print("НАСТРОЙКИ ВЫСОТЫ ОТ РОБОТА ДО ПОЛА")
	print("выбор действия:")
	print("1 - ручной ввод")
	print("2 - авто. режим")
	if value_height ~= nil then
		print("3 - оставить высоту " ..value_height)
	end
	::choose_again::
	local choose_value = pcall_return_num(1, 3) --минимальное и максимальное значение
	if choose_value == 1 then
		term.clear()
		print("введи расстояние от робота до пола")
		print("робот считается нулевым блоком")
		return pcall_return_num(0, 300)
	elseif choose_value == 2 then
		local r_height = 0
		while true do
			if ignore_block_height[geo.analyze(0).name] == nil then return r_height end
			repeat until robot.down()
			r_height = r_height + 1	
		end
	elseif value_height ~= nil and choose_value == 3 then
		return value_height
	else
		term.clear()
		deb_enter("бля, заебал.. вводи цифру нормально!!"); os.exit()
	end
end
--очищает выбранную строку в информационном окошке робота
function clear_input_window(x, y, lenght)
	term.setCursor(x, y)
	x = lenght - x
	for i = 1, x do
		io.write(" ")
	end
end
--удаление определенного поля со схемой:вовращает таблицу с оставшимися схемами
function delete_scheme(choose_number, scheme_table)
	local t_num = choose_number - 4
	local del_line = choose_number + 3
	if scheme_table[t_num] ~= nil then
		fileSystem.remove("/usr/lib/" .. scheme_table[t_num])
		table.remove(scheme_table, t_num)
	end
	return scheme_table
end
------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------ФУНКЦИИ РАБОТЫ С ИНВЕНТАРЕМ РОБОТА-------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------
--ищет, в каком слоте есть определенный блок ,если такого блока нет, возвращает 0, иначе возвращает номер слота с блоком
--аргументы(имя блока, это двойной блок, его метаданные и wood - какой именно тип планки, деревянный или каменный)
function find_block(block_name, is_double, meta, wood, is_planks)
	local num, table_slot, all_blocks_slot
	--поиск плит или двойных плит по имени и лейблу
	if is_double or is_planks then 
		--term.clear(); deb_enter("проверка в таблице слотов плит и двойных плит")
		all_blocks_slot = all_blocks[block_name .. table_planks[wood][meta]["label"]]
		if robot.count(all_blocks_slot) > 1 then
			table_slot = inv.getStackInInternalSlot(all_blocks_slot)
			if table_slot.name == block_name and table_slot.label == table_planks[wood][meta]["label"] then return all_blocks_slot end
		end	
		for i = 1,inv_size do
			table_slot = inv.getStackInInternalSlot(i)
			if table_slot ~= nil then
				if table_slot.name == block_name and table_slot.label == table_planks[wood][meta]["label"] then
					all_blocks[block_name .. table_planks[wood][meta]["label"]] = i
					return i
				end
			end
		end
	--поиск досок, цветной обож. глины, цвеного стекла, цветной стеклянной панели или цветной шерсти
	elseif block_name == "minecraft:planks" or block_name == "minecraft:stained_hardened_clay" or block_name == "minecraft:stained_glass" or block_name == "minecraft:stained_glass_pane" or block_name == "minecraft:wool" then
		--term.clear(); deb_enter("проверка в таблице слотов цветных блоков")
		all_blocks_slot = all_blocks[block_name .. tostring(meta)]
		if robot.count(all_blocks_slot) ~= 0 then
			table_slot = inv.getStackInInternalSlot(all_blocks_slot)
			if table_slot.name == block_name and table_slot.damage == meta then return all_blocks_slot end
		end	
		for i = 1,inv_size do
			table_slot = inv.getStackInInternalSlot(i)
			if table_slot ~= nil then
				if table_slot.name == block_name and table_slot.damage == meta then
					all_blocks[block_name .. tostring(meta)] = i
					return i
				end
			end
		end
	--поиск остальных блоков по имени
	else
		--term.clear(); deb_enter("проверка в таблице слотов обычных блоков")
		all_blocks_slot = all_blocks[block_name]
		if robot.count(all_blocks_slot) ~= 0 then
			table_slot = inv.getStackInInternalSlot(all_blocks_slot)
			if table_slot.name == block_name then return all_blocks_slot end
		end	
		for i = 1,inv_size do
			table_slot = inv.getStackInInternalSlot(i)
			if table_slot ~= nil then
				if table_slot.name == block_name then
					all_blocks[block_name] = i
					return i
				end
			end
		end
	end
	return 0
end
--запись всех блоков в инвентаре робота в таблицу и вернуть ее(связь с локальной таблицей all_blocks
function save_all_blocks_from_inventory_in_table()
	local table_slot
	term.clear()
	print("СОХРАНЕНИЕ ИНВЕНТАРЯ РОБОТА В ТАБЛИЦУ:")
	for slot = 1, inv_size do
		term.setCursor(1, 2)
		print(slot .. " из " .. inv_size)
		table_slot = inv.getStackInInternalSlot(slot)
		if table_slot ~= nil then
			all_blocks[table_slot.name] = slot
		end
	end
	setmetatable(all_blocks, {__index = function(t, k) t[k] = 1; return t[k] end})
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
--найти свободный слот, кроме первого и выделить его
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
--определение блока, если это плиты, то возвращает true, иначе вернет false
function is_is_planks(block_name)
	if table_planks[1] == block_name or table_planks[2] == block_name then return true end
	return false
end
--определение блока, если это ступеньки, то возврщает true, иначе вернет false
function it_is_stairs(block_name)
	for _,v in pairs(table_stairs) do
		if v == block_name then return true end
	end
	return false
end
--найти что то в инвентаре робота и вернуть номер слота = !ищет по именам!
function find_something(name)
	local item
	local invS = robot.inventorySize()
	for i = invS, 1, -1 do 
		term.clear()
		print("поиск: " ..name.. " в роботе - " ..i.. " из " ..invS)
		item = inv.getStackInInternalSlot(i)
		if item ~= nil then
			if item.name == name then
				return i
			end
		end
	end
	return 0
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
--проверка блока в руку робота. вернут true, если есть блок в рукe, иначе вернет false
function block_in_robot_arm()
	local arg_one, arg_two = robot.durability()
	if arg_one ~= nil then return true end
	if arg_two == "tool cannot be damage" then return true end
		return false
end
------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------ПРОВЕРКИ ВВОДА ЗНАЧЕНИЙ ПОЛЬЗОВАТЕЛЕМ------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------
--ввод цифры с проверками(минимальное значение, максимальное значение)
function pcall_return_num(min_num, max_num)
	::again_choose::
	io.write("ввод числа -> ")
	local number = tonumber(io.read()) or 0
	if number == nil then io.write(" ошибка ввода. "); computer.beep(1000,1); goto again_choose end
	if number < min_num or number > max_num then io.write(" ошибка ввода. "); computer.beep(1000, 1); goto again_choose end
	return number
end
------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------СТРОИТЕЛЬНЫЕ ФУНКЦИИ---------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------
--ставит ступеньки в мир (метадата_ступенек, номер_слота_ступенек, номер_слота_гаечного_ключа)
function build_stairs(metadata, stairs_slot_num, g_key_slot_num)
	--deb("номер слота ступенек: " ..stairs_slot_num.. " номер_слота_ключа " ..g_key_slot_num)
	--print("энтер для продолжения")
	--local ennn = io.read()
	local to_first_slot = 1
	if stairs_slot_num == 0 then
		print("не могу найти ступеньки")
		print("программа завершена")
		os.exit()
	end
	local _,z,_ = navigate.getPosition()
	local size_place = 3
	if metadata >= 4 then
		first_slot_transfer() --переложить предмет из первого слота в любой другой
		robot.select(to_first_slot)
		inv.equip() 		  --проверить, нет ли предмета в руке робота
		first_slot_transfer() --переложить еще раз предмет из первого слота, если он там есть
		robot.select(stairs_slot_num)
		robot.transferTo(to_first_slot)
		robot.select(1)
		robot.useDown()
		::try_again2::
		computer.beep(400, 0.1)
		computer.beep(1000, 0.1)
		computer.beep(400, 0.1)
		computer.beep(1000, 0.1)
		local geoAnalyze = geo.analyze(0).name
		if geoAnalyze == "minecraft:air" or geoAnalyze == "Thaumcraft:blockAiry" or geoAnalyze == "minecraft:water" or geoAnalyze == "minecraft:flowing_water" then
			computer.beep(400, 2); deb("ЖДУ 3 СЕКУНДЫ", 3)
			if size_place == 0 then
				size_place = 3
			elseif size_place > 0 and size_place < 6 then
				size_place = size_place + 1
			elseif size_place > 5 then
				size_place = 3
			end
			robot.placeDown(size_place)
			goto try_again2 
		end
		computer.beep(1000, 0.1)
		robot.select(g_key_slot_num)
		inv.equip()
		while geo.analyze(0).metadata ~= metadata do robot.useDown() end
		inv.equip()
	else
		moveLibrary.z_move(z + 1)
		--repeat until robot.up()
		robot.select(stairs_slot_num)
		inv.equip()
		::try_again2::
		computer.beep(400, 0.1)
		computer.beep(1000, 0.1)
		computer.beep(400, 0.1)
		computer.beep(1000, 0.1)
		robot.useDown()
		moveLibrary.z_move(z)
		local geoAnalyze2 = geo.analyze(0).name
		if geoAnalyze2 == "minecraft:air" or geoAnalyze2 == "Thaumcraft:blockAiry" or geoAnalyze2 == "minecraft:water" or geoAnalyze2 == "minecraft:flowing_water" then computer.beep(400, 2); moveLibrary.z_move(z + 1); deb("ЖДУ 3 СЕКУНДЫ", 3); goto try_again2 end
		computer.beep(1000, 0.1)
		inv.equip()
		robot.select(g_key_slot_num)
		inv.equip()
		while geo.analyze(0).metadata ~= metadata do robot.useDown() end
		moveLibrary.z_move(z)
		inv.equip()
	end
end
--ставит обычные блоки в мир (номер_слота_необходимого_блока)
function build_blocks(block_number_slot, hopper, block_name)
	--deb_enter("выбираю слот с блоком")
	robot.select(block_number_slot)
	--inv.equip()
	::try_again3::
	--deb_enter("ставлю его в мир")
	robot.placeDown()
	computer.beep(400, 0.1)
	computer.beep(1000, 0.1)
	computer.beep(400, 0.1)
	computer.beep(1000, 0.1)
	--deb_enter("проверяю на совпадение блока под собой")
	if geo.analyze(0).name ~= block_name then
		if geo.analyze(0).name == "minecraft:lit_redstone_lamp" then computer.beep(1000, 0.1); return end
		computer.beep(400, 2)
		deb("ЖДУ 3 СЕКУНДЫ", 3)
		goto try_again3
	end
	computer.beep(1000, 0.1)
end
--поставить планку в мир
--аргументы(доски находятся в нижнем положении?, это двойные доски?)
function build_planks(it_is_down, it_is_bouble)
	local stone_or_wood = ""
	local yBeJIu4eHue_BpeMeHu_oJugaHu9l = 0
	local _,mov_z,_ = navigate.getPosition()
	--ставит планку с самого низу
	if it_is_down and it_is_bouble == false then
		inv.equip()
		::build_again::
		moveLibrary.z_move(mov_z + 1)	
		computer.beep(400, 0.1)
		computer.beep(1000, 0.1)
		computer.beep(400, 0.1)
		computer.beep(1000, 0.1)
		os.sleep(yBeJIu4eHue_BpeMeHu_oJugaHu9l)
		robot.useDown()
		moveLibrary.z_move(mov_z)
		local geoAnalyze = geo.analyze(0).name
		if geoAnalyze == "minecraft:air" or geoAnalyze == "Thaumcraft:blockAiry" or geoAnalyze == "minecraft:water" or geoAnalyze == "minecraft:flowing_water" then
			computer.beep(400, 2)
			deb("ЖДУ 3 СЕКУНДЫ", 3)
			yBeJIu4eHue_BpeMeHu_oJugaHu9l = yBeJIu4eHue_BpeMeHu_oJugaHu9l + 1
			if yBeJIu4eHue_BpeMeHu_oJugaHu9l > 5 Then yBeJIu4eHue_BpeMeHu_oJugaHu9l = 5 end
			goto build_again
		end
		computer.beep(1000, 0.1)
		moveLibrary.z_move(mov_z)
		inv.equip()
	--ставит двойные планки
	elseif it_is_bouble	then
		if wood == "wooden" then stone_or_wood = "minecraft:double_wooden_slab" else stone_or_wood = "minecraft:double_stone_slab" end
		inv.equip()
		moveLibrary.z_move(mov_z + 1)
		computer.beep(400, 0.1)
		computer.beep(1000, 0.1)
		computer.beep(400, 0.1)
		computer.beep(1000, 0.1)
		robot.useDown()
		::build_again2::
		os.sleep(yBeJIu4eHue_BpeMeHu_oJugaHu9l)
		robot.useDown()
		moveLibrary.z_move(mov_z)
			if geo.analyze(0).name ~= stone_or_wood then
				moveLibrary.z_move(mov_z + 1)
				computer.beep(400, 2)
				deb("ЖДУ 3 СЕКУНДЫ", 3)
				yBeJIu4eHue_BpeMeHu_oJugaHu9l = yBeJIu4eHue_BpeMeHu_oJugaHu9l + 1
				if yBeJIu4eHue_BpeMeHu_oJugaHu9l > 5 Then yBeJIu4eHue_BpeMeHu_oJugaHu9l = 5 end
				goto build_again2
			end
		computer.beep(1000, 0.1)
		moveLibrary.z_move(mov_z)
		inv.equip()
	--ставит планки сверху
	else
		robot.transferTo(1)
		--moveLibrary.z_move(mov_z - 1)
		::build_again3::
		os.sleep(yBeJIu4eHue_BpeMeHu_oJugaHu9l)
		robot.useDown()
		local geoAnalyze2 = geo.analyze(0).name
		if geoAnalyze2 == "minecraft:air" or geoAnalyze2 == "Thaumcraft:blockAiry" or geoAnalyze2 == "minecraft:water" or geoAnalyze2 == "minecraft:flowing_water" then
			computer.beep(400, 2)
			deb("ЖДУ 3 СЕКУНДЫ", 3)
			yBeJIu4eHue_BpeMeHu_oJugaHu9l = yBeJIu4eHue_BpeMeHu_oJugaHu9l + 1
			if yBeJIu4eHue_BpeMeHu_oJugaHu9l > 5 Then yBeJIu4eHue_BpeMeHu_oJugaHu9l = 5 end
			goto build_again3
		end
		first_slot_transfer()
	end
end
--возвращение на базу в поисках предмета, если его не оказалось в инвентаре, затем возвращение обратно на поле.
--аргумент check_meta имеет булево значение, и проверяет блоки с одинаковым названием, но разными метаданными
--такии, как блоки досок. блоки шерсти и стекла разных цветов. Если имеет значение true, будет произведена проверка
function return_and_find_item(block_name, meta, check_meta)
	local sycle = 0
	local wh_number = 1 --номер проверяемого склада
	local posZ = 1
	local pos_x, pos_z, pos_y = navigate.getPosition()
	local reverse_move = false
	local meta_mode = false
	return_on_start_position()
	--проверка энергии
	energyChecker.check_energy_in_base()
	moveLibrary.z_move(start_position.z + posZ)
	for rForward = 1,3 do
		while geo.analyze(3).name == "OpenComputers:robot" do computer.beep(1000, 1); moveLibrary.z_move(start_position.z + 2); term.clear(); print("на моем пути робот"); print("пытаюсь уступить дорогу"); weit_ten_seconds(); moveLibrary.z_move(start_position.z + 1) end
		moveLibrary.x_y_move(start_position.x + rForward, start_position.y)
	end
	::next_check::
	while geo.analyze(0).name ~= block_name or meta_mode do
		meta_mode = false
		moveLibrary.x_y_move(start_position.x + 3, start_position.y + sycle)
		if reverse_move then sycle = sycle - 1 else sycle = sycle + 1 end
		if geo.analyze(0).name == "minecraft:air" and wh_number ~= how_many_werehouses then
			wh_number = wh_number + 1
			posZ = posZ + 6
			if reverse_move then reverse_move = false; sycle = sycle + 2 else reverse_move = true; sycle = sycle - 2 end
			moveLibrary.z_move(start_position.z + posZ)
			moveLibrary.x_y_move(start_position.x + 3, start_position.y + sycle)
		elseif geo.analyze(0).name == "minecraft:air" and wh_number == how_many_werehouses then --робот останавливает поиск, когда закончились блоки под ним
			turn_NSWE(W) --мордой на запад
			while geo.analyze(1).name == "OpenComputers:robot" do repeat until robot.back() end --найти парковочное место для робота, в ожидании блока
			repeat until robot.up()
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
			term.clear()
			moveLibrary.z_move(start_position.z + posZ + 2)
			moveLibrary.moveOut(start_position.x, start_position.y, start_position.z)
			moveLibrary.z_move(pos_z)
			moveLibrary.moveOut(pos_x, pos_y, pos_z)
			return	
		end
	end
	--проверка на совпадение метаданных блока(проверяет, если только это блоки с одинаковым именем, но разными метаданными(доски, шерсть разных цветов, стекло разных цветов)
	if check_meta then
		if geo.analyze(0).metadata ~= meta then
			meta_mode = true
			goto next_check
		end
	end
	turn_NSWE(W) --мордой на запад
	local slot_number = 0
	moveLibrary.z_move(start_position.z + posZ + 1) --поднятся на блок выше к воронкам
	local find_block_sycle = 0
	while find_block(block_name, false, meta, false, false) == 0 do
		find_block_sycle = find_block_sycle + 1
		if find_block_sycle > 3 then
			term.clear()
			print("В ВОРОНКЕ ЗАКОНЧИЛИСЬ БЛОКИ")
			computer.beep(400, 1)
		end
	end
	slot_number = find_block(block_name,  false, meta, false, false)
	local first_check = robot.count(slot_number) --записать количество блоков в слоте до начала подхода к воронке
	term.clear()
	deb("ОЖИДАНИЕ 5 СЕКУНД ДО ПРОВЕРКИ", 5)
	term.clear()
	local second_check = robot.count(slot_number) --записать количество блоков в слоте после ожидания 5 секунд, после подхода к воронке
	if second_check == first_check then
		while robot.count(slot_number) < 50 do term.clear(); print("количество блоков собрано: " ..robot.count(slot_number).. " из 50"); print("в воронке закончились блоки"); print("жду заполнения воронки!!"); computer.beep(400, 1) end
	else
		while robot.count(slot_number) < 60 do term.clear(); print("количество блоков собрано: " ..robot.count(slot_number).. " из 60"); computer.beep(1000, 0.1); end
	end
	term.clear()
	moveLibrary.moveOut(start_position.x, start_position.y, start_position.z + 1)
	moveLibrary.z_move(pos_z)
	moveLibrary.moveOut(pos_x, pos_y, pos_z)
end
--вернуться на базу за планками
function return_to_base_and_get_planks(block_name, meta_num, block_num_in_inventory) --первые 2 аргумента берутся из таблицы строительства блоков, последний аргумент. это номер слота, в котором находится необходимый блок у робота
	move_block_from_robot_arm() --перемещение предмета руки робота, если он в нем есть, в любой свободный слот, кроме первого слота
	local slab
	if meta_num >= 8 then meta_num = meta_num - 8 end
	if block_name == "minecraft:wooden_slab" then slab = "wooden" else slab = "stone" end
	local my_now_x, my_now_z, my_now_y = navigate.getPosition()
	::try_again6::
	moveLibrary.moveOut(start_position.x, start_position.y, start_position.z)
	energyChecker.check_energy_in_base()
	moveLibrary.z_move(start_position.z + 1)
	for rForward = 1,5 do
		while geo.analyze(3).name == "OpenComputers:robot" do computer.beep(1000, 1); moveLibrary.z_move(start_position.z + 2); term.clear(); print("на моем пути робот"); print("пытаюсь уступить дорогу"); weit_ten_seconds(); moveLibrary.z_move(start_position.z + 1) end
		moveLibrary.x_y_move(start_position.x + rForward, start_position.y)
	end
	turn_NSWE(S)
	term.clear()
	while geo.analyze(0).name ~= "minecraft:air" do
		local analyze = geo.analyze(0)
		if analyze.name == block_name and analyze.metadata == meta_num then
			robot.transferTo(1) --перемещение из активного слота в первый слот робота
			local first_check2 = robot.count(1)
			turn_NSWE(W) --мордой на запад
			moveLibrary.z_move(start_position.z + 2)
			term.clear(); deb("ЖДУ 5 СЕКУНД ДО НАЧАЛА ПРОВЕРКИ", 5); term.clear()
			local second_check2 = robot.count(1)
			if second_check2 == first_check2 then
				while robot.count(slot_number) < 50 do term.clear(); print("количество планок собрано: " ..robot.count(1).. " из 50"); print("в воронке закончились планки"); print("жду заполнения воронки!!"); computer.beep(400, 1) end
			else
				while robot.count(1) < 60 do computer.beep(1000, 0.1); term.clear(); print("всего блоков: " ..robot.count(1).. " из 60") end
			end
			moveLibrary.moveOut(start_position.x + 4, start_position.y, start_position.z + 1)
			moveLibrary.moveOut(start_position.x, start_position.y, start_position.z + 1)
			robot.select(1) --выбрать первый слот у робота
			robot.transferTo(block_num_in_inventory) --перемещение предмета из первого слота, в слот, который был изначально
			robot.select(block_num_in_inventory) --делает активным изначальный слот робота
			--возвращение на позицию, где робот был на стройке до этого
			moveLibrary.moveOut(start_position.x, start_position.y, my_now_z)
			moveLibrary.moveOut(my_now_x, my_now_y, my_now_z)
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
------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------ПРОЧИЕ ФУНКЦИИ------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------
--повороты робота по сторонам света
function turn_NSWE(side)
	while navigate.getFacing() ~= side do table_sides[side][navigate.getFacing()]() end
end
--возврат на стартовую позицию робота
function return_on_start_position()
	moveLibrary.moveOut(start_position.x, start_position.y, start_position.z)
	while navigate.getFacing() ~= 5 do table_sides[5][navigate.getFacing()]() end --мордой на восток
end
--проверка энергии в поле
function check_energy_in_line(energyMin)
	if energyChecker.how_much_enegry(energyMin + 500) then
		local now_position_x, now_position_z, now_position_y = navigate.getPosition()
		moveLibrary.moveOut(start_position.x, start_position.y, start_position.z)
		energyChecker.check_energy_in_base()
		moveLibrary.moveOut(start_position.x, start_position.y, now_position_z)
		moveLibrary.moveOut(now_position_x, now_position_y, now_position_z)
	end
end
--функция строительства склада с ресурсами и воронками
function open_build_warehouse()
	pair_blocks, pair_planks = dofile("warehouse")
end
------------------------------------------------Н А Ч А Л О  Р А Б О Т Ы------------------------------------------------------
do
	--проверка необходимых библиотек и компонентов----------------------------------------
	term.clear()
	print("ПЕРВОНАЧАЛЬНЫЕ ПРОВЕРКИ НАЛИЧИЯ БИБЛИОТЕК И КОМПОНЕНТОВ")
	--компоненты
	navigate = components_and_librarys.getComponent("navigation")
	geo = components_and_librarys.getComponent("geolyzer")
	inv = components_and_librarys.getComponent("inventory_controller")
	modem = components_and_librarys.getComponent("modem")
	components_and_librarys.getComponent("angel")
	--библиотеки
	table_sides = components_and_librarys.getLibrary("sizeLibrary").build_pair_sizes()
	moveLibrary = components_and_librarys.getLibrary("moveLibrary")
	energyChecker = components_and_librarys.getLibrary("energyChecker")
	table_planks = components_and_librarys.getLibrary("table_planks").build_pair()
	filesLibrary = components_and_librarys.getLibrary("filesLibrary")
	algorithmLi = components_and_librarys.getLibrary("algorithmLi")
	pac4eT_pecypcoB_cTpouTeJI9l = components_and_librarys.getLibrary("pac4eT_pecypcoB_cTpouTeJI9l")
	
	--------------------------------------------------------------------------------------
	--присваивание переменных
	inv_size = robot.inventorySize() --определение размера инвентаря робота
	if modem == nil then modem_is_avalible = false else modem_is_avalible = true end --определение доступности модема
	local _,err = pcall(function() dofile("/home/return") end)
	if type(err) == "string" then print(err); print("проверь наличие файла return"); print("программа завершена"); computer.beep(1000,0.1); computer.beep(1000,0.1); os.exit() end
	
	open_main_menu() --менюшка выбора стартовых опций программы	
	start_position.x, start_position.z, start_position.y = navigate.getPosition() --определить начальные координаты
	local allSlay = all_slyers() --определить, сколько всего слоев присутствует в схеме
	file_slayer()--определение слоя для строительства
	term.clear()
	print("Всего слоев в схеме: " ..allSlay)
	print("0 = выход из программы")
	print("последний построенный слой: " ..robot_slayer)
	io.write("С какого слоя нужно строить?: -> ")
	local slayer = tostring(io.read())
	local sl_plus = tonumber(slayer)
	if slayer == "0" then term.clear(); print("ошибка чтения слоя"); print("программа завершена"); os.exit() end
	--определение последнего построенного блока в слое
	term.clear()
	file_last_block(); last_block_mode = false
	if tonumber(last_block) > 1 then
		print("Всего блоков в в слое номер " .. slayer .. " -> " .. #programm_t[slayer].x)
		print("0 = выход из программы")
		print("последний построенный блок: " .. last_block)
		print("-------------------------------")
		print("1 = продолжить стройку")
		print("2 = начать слой с нуля")
		local what = pcall_return_num(0, 2)
		if what == 1 then
			last_block_mode = true
			last_block = tonumber(last_block) - 1
		elseif what == 2 then
			last_block_mode = false
		else
			term.clear(); print("программа завершена"); os.exit()
		end
	end
	--определение количества чанков по оси х
	term.clear()
	print("НАСТРОЙКИ АЛГОРИТМА ЛИ")
	print("определение количества чанков в ширину по Х оси")
	print("1: - 1 чанк 17 блоков")
	print("2: - 2 чанка 33 блока")
	print("3: - 3 чанка 49 блоков")
	local chanks_num = pcall_return_num(1, 3)
	if chanks_num == 1 then
		how_many_chanks = 17
	elseif chanks_num == 2 then
		how_many_chanks = 33
	elseif chanks_num == 3 then
		how_many_chanks = 49
	end
	--определение количества складов в постройке
	term.clear()
	print("определение количества складов с блоками:")
	::repeat_choose::
	how_many_werehouses = pcall_return_num(1, 10)
	--проверка гаечного ключа перед стартом программы
	local try_numbers = 0
	repeat 
		if try_numbers > 0 then
			term.clear()
			computer.beep(1000, 0.1); computer.beep(1000, 0.1); computer.beep(1000, 0.1)
			deb_enter("ПОЛОЖИ ГАЕЧНЫЙ ГЛЮЧ В ПОСЛЕДНИЙ СЛОТ РОБОТА!")
		end
		try_numbers =  try_numbers + 1
	until find_something("OpenComputers:wrench") ~= 0
	local noMep_cJIoTa_rae4Horo_kJII04a = find_something("OpenComputers:wrench")
	if noMep_cJIoTa_rae4Horo_kJII04a ~= robot.inventorySize() then
		if inv.getStackInInternalSlot(robot.inventorySize()) ~= nil then
			robot.select(robot.inventorySize())
			robot.drop()
		end
		robot.select(noMep_cJIoTa_rae4Horo_kJII04a)
		robot.transferTo(robot.inventorySize)
	end
	--проверка высоты от робота до пола
	file_robot_height()
	--первочатальное заполнение инвентаря робота
	local po6oT_3a6paJI_Bce_npegmeTbl = false
	while not po6oT_3a6paJI_Bce_npegmeTbl do
		deb_enter("вход в функцию забора всех предметов")
		po6oT_3a6paJI_Bce_npegmeTbl = pac4eT_pecypcoB_cTpouTeJI9l.zanpaBuTb_po6oTa_pecypcaMu_u_BepHyTb_Ta6JIucy_cJIoToB(danger_blocks, 1, 1)
		if po6oT_3a6paJI_Bce_npegmeTbl then
			deb_enter("роботу удалось забрать все предметы")
		else
			deb_enter("роботу НЕ удалось забрать все предметы")
		end
	end
	--сохранение всех блоков в роботе в таблицу
	save_all_blocks_from_inventory_in_table()
-------------------------------------------------------------ЦИКЛ СТРОИТЕЛЬСТВА-------------------------------------------------------------
	for sl = sl_plus, allSlay do
		slayer = tostring(sl)
		moveLibrary.z_move(start_position.z + tonumber(slayer) - robot_height + 2) --выдвижение на высоту ввверх
		programm_t[slayer] = algorithmLi.buildAllWays(programm_t[slayer], how_many_chanks)
		if not last_block_mode then --продолжение стройки, если выбран last_block_mode пользователем
			block_number = #programm_t[slayer].x
		else
			block_number = tonumber(last_block)
			last_block_mode = false
		end
		for i = block_number, 1, -1 do
			move_block_from_robot_arm() --перемещение предмета руки робота, если он в нем есть, в любой свободный слот, кроме первого слота
			hopper_block = false
			---------------------ОПРЕДЕЛЕНИЕ ОПАСНЫХ БЛОКОВ----------------------------------
			--таблица опастных блоков находится в начале кода(в разделе таблиц)
			--вносить туда блоки, который робот должен игнорироватть при стройке
			local programm_t_slayer_name_i = programm_t[slayer].name[i]
			if danger_blocks[programm_t_slayer_name_i] == nil then
				if programm_t_slayer_name_i == "minecraft:double_wooden_slab" then programm_t[slayer].name[i] = table_planks[1]; it_is_double = true; wood = "wooden" end --двойные плиты из дерева меняет на доски
				if programm_t_slayer_name_i == "minecraft:double_stone_slab" then programm_t[slayer].name[i] = table_planks[2]; it_is_double = true; wood = "stone" end --двойне плиты из камня меняет на каменные кирпичи
				if programm_t_slayer_name_i == table_planks[1] then it_is_planks = true; wood = "wooden" end
				if programm_t_slayer_name_i == table_planks[2] then it_is_planks = true; wood = "stone" end
				if programm_t_slayer_name_i == "minecraft:lit_redstone_lamp" then programm_t[slayer].name[i] = "minecraft:redstone_lamp" end
				if programm_t_slayer_name_i == "minecraft:monster_egg" then programm_t[slayer].name[i] = "minecraft:stonebrick" end
				if programm_t_slayer_name_i == "minecraft:hopper" then hopper_block = true end
				if programm_t_slayer_name_i == "minecraft:mossy_cobblestone" then programm_t[slayer].name[i] = "minecraft:cobblestone" end
				if programm_t_slayer_name_i == "minecraft:bedrock" then programm_t[slayer].name[i] = "minecraft:stone" end
				if programm_t_slayer_name_i == "minecraft:hopper" then programm_t[slayer].name[i] = "minecraft:gold_block" end
				
			else
				programm_t[slayer].name[i] = "minecraft:trapdoor"
			end
			---------------------------------------------------------------------------------
			if programm_t[slayer].name[i] ~= "minecraft:trapdoor" then
				--определение оставшегося количества энергии
				if not test_game_mode then check_energy_in_line(energyMinimym) end
				--выдвижение по координатам
				moveLibrary.x_y_move(start_position.x + programm_t[slayer].x[i], start_position.y + programm_t[slayer].y[i])
				--определение нужного блока в инвентаре для строительства
				::check_again::
				first_slot_transfer() --переложить предмет из первого слота робота в любой другой
				local block_num = find_block(programm_t[slayer].name[i], it_is_double, programm_t[slayer].meta[i], wood, it_is_planks)
				--если блок не найден, вернуться на базу в поисках его в сундуках
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
					
					build_blocks(block_num, hopper_block, programm_t[slayer].name[i])
				end
			end
			it_is_double = false
			it_is_planks = false
			local fileLastBlock = io.open("last_build_block.lua", "w"); fileLastBlock:write(i); fileLastBlock:close() --записать готовый остроенный блок в таблицу
		end
		local file_sl = io.open("robot_slayer.lua", "w"); file_sl:write(sl); file_sl:close() --записать готовый слой в таблицу
	end
	return_on_start_position()
	term.clear()
	print("СТРОИТЕЛЬСТВО ЗАВЕРШЕНО")
	local file_sl2 = io.open("robot_slayer.lua", "w"); file_sl2:close()
	local fileLastBloc2 = io.open("last_build_block.lua", "w"); fileLastBloc2:close()
	for end_build = 1, 3 do
		computer.beep(400,0.5)
		computer.beep(800,0.5)
	end
end
