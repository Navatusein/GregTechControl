---------------------------------------------------Библиотеки-----------------------------------------------------------------

local GUI = require("GUI")
local system = require("System")
local filesystem = require("Filesystem")
local text = require("Text")
local event = require("Event")
local system = require("System") 

---------------------------------------------------Локализация----------------------------------------------------------------

local localization = system.getCurrentScriptLocalization()

---------------------------------------------------Переменные-----------------------------------------------------------------

local Machines_type = {
	{id = "universal", name = localization.variables_Machines_type_universal},
	{id = "cleanroom", name = localization.variables_Machines_type_cleanroom},	
	{id = "battery buffer", name = localization.variables_Machines_type_battery_buffer},
	{id = "power station", name = localization.variables_Machines_type_power_station}}

local Machines_list = {}--Основной список добавленых машинок

local Machines_proxy = {}--Основной список прокси машинок

local Machines_state = {}--Основной список состояния машинок

--local x = 60

local Settings_gtcs = {Program_work = true, Terminal_Name = "", Update_state_machine_work = true}

--------------------------------------------Создание робочего места-----------------------------------------------------------

local workspace = GUI.workspace()

---------------------------------------Добавление елементов на робочее место--------------------------------------------------

--Верхнее меню
local menu = workspace:addChild(GUI.menu(1, 1, workspace.width, 0xEEEEEE, 0x666666, 0x3366CC, 0xFFFFFF))

--Екран
workspace:addChild(GUI.panel(1, 2, workspace.width, workspace.height, 0x2D2D2D))

--Информационная панель
workspace:addChild(GUI.panel(38, 3, workspace.width-39, workspace.height-7, 0x1D1D1D))
workspace:addChild(GUI.text(40, 4, 0xFFFFFF, localization.info_text_info))

--Лейблы для информации
local Update_information_label_1 = workspace:addChild(GUI.label(40, 6, 5, 5, 0xFFFFFF, " "))
local Update_information_label_2 = workspace:addChild(GUI.label(40, 8, 5, 5, 0xFFFFFF, " "))
local Update_information_label_3 = workspace:addChild(GUI.label(40, 10, 5, 5, 0xFFFFFF, " "))
local Update_information_label_4 = workspace:addChild(GUI.label(40, 12, 5, 5, 0xFFFFFF, " "))
local Update_information_label_5 = workspace:addChild(GUI.label(40, 14, 5, 5, 0xFFFFFF, " "))
local Update_information_label_6 = workspace:addChild(GUI.label(40, 16, 5, 5, 0xFFFFFF, " "))
local Update_information_label_7 = workspace:addChild(GUI.label(40, 18, 5, 5, 0xFFFFFF, " "))
local Update_information_label_8 = workspace:addChild(GUI.label(40, 20, 5, 5, 0xFFFFFF, " "))
local Update_information_label_9 = workspace:addChild(GUI.label(40, 22, 5, 5, 0xFFFFFF, " "))
local Update_information_label_10 = workspace:addChild(GUI.label(40, 24, 5, 5, 0xFFFFFF, " "))

--Главный евент
local mainhandler

--Панель выбора машинки
workspace:addChild(GUI.panel(2, 3, 34, workspace.height-3, 0x1D1D1D))
workspace:addChild(GUI.text(4, 4, 0xFFFFFF, localization.main_text_machine))
local main_MachineList = workspace:addChild(GUI.list(4, 6, 30, workspace.height-7, 3, 0, 0xE1E1E1, 0x4B4B4B, 0xD2D2D2, 0x4B4B4B, 0x3366CC, 0xFFFFFF, false))

--Кнопки
local main_ButtonAdd = workspace:addChild(GUI.button(38, workspace.height-3, 30, 3, 0xEEEEEE, 0x000000, 0xAAAAAA, 0x0, localization.main_button_add))
local main_ButtonConfig = workspace:addChild(GUI.button(71, workspace.height-3, 55, 3, 0xEEEEEE, 0x000000, 0xAAAAAA, 0x0, localization.main_button_config))
local main_ButtonDelete = workspace:addChild(GUI.button(workspace.width-31, workspace.height-3, 30, 3, 0xEEEEEE, 0x000000, 0xAAAAAA, 0x0, localization.main_button_delete))

--Верхнее меню
menu:addItem("GTcontrolSlave", 0x0)

--Верхнее меню файл
local contextMenu_file = menu:addContextMenuItem(localization.menu_button_file)
contextMenu_file:addItem(localization.contextMenu_file_button_open).onTouch = function()
	File_Read(true)
	
end
contextMenu_file:addItem(localization.contextMenu_file_button_save).onTouch = function()
	filesystem.writeTable("/Applications/GTcontrolSlave.app/Save.cfg", Machines_list)
end

--Верхнее меню инструменты
local contextMenu_tool = menu:addContextMenuItem(localization.menu_button_tool)
contextMenu_tool:addItem(localization.contextMenu_tool_button_methods).onTouch = function()
	local local_methods = {}
	for i,k in pairs(Machines_proxy[main_MachineList.selectedItem]) do
		table.insert(local_methods,i)
	end
	GUI.alert(local_methods)
end
contextMenu_tool:addItem(localization.contextMenu_tool_button_sensor).onTouch = function()
	GUI.alert(Machines_proxy[main_MachineList.selectedItem].getSensorInformation())
end
contextMenu_tool:addItem(localization.contextMenu_tool_button_test).onTouch = function()

end

--Верхнее меню закрыть
menu:addItem(localization.menu_button_close).onTouch = function()
	Settings_gtcs.Program_work = false
	event.removeHandler(mainhandler)
	workspace:stop()
	workspace:draw()
end

-------------------------------------------------Чтение из файла---------------------------------------------------------------

function File_Read(a)
	if filesystem.exists("/Applications/GTcontrolSlave.app/Save.cfg") then
		local Machines_list_local = filesystem.readTable("/Applications/GTcontrolSlave.app/Save.cfg")
		if Machines_list_local ~= nil then
			main_MachineList:remove()
			main_MachineList = workspace:addChild(GUI.list(4, 6, 30, workspace.height-7, 3, 0, 0xE1E1E1, 0x4B4B4B, 0xD2D2D2, 0x4B4B4B, 0x3366CC, 0xFFFFFF, false))
			local Machines_proxy_local = {}
			for i = 1, #Machines_list_local do
				local address_true = false
				if component.proxy(Machines_list_local[i].Machine_address) == nil then
					address_true = true
				end
				if address_true == true then
					local Machines_list_buff = {}
					for j=1, #Machines_list_local do
						if j < i then
							table.insert(Machines_list_buff,Machines_list_local[j])
						elseif j == i then
		
						elseif j > i then
							table.insert(Machines_list_buff,Machines_list_local[j])
						end
					end
					Machines_list_local = Machines_list_buff
				end	
			end
			for d = 1, #Machines_list_local do
				table.insert(Machines_proxy_local,component.proxy(Machines_list_local[d].Machine_address))
				main_MachineList:addItem(Machines_list_local[d].Machine_name).onTouch = function()--Вызов функции обновления информации на информационной панеле
					Update_information()
				end
			end
			
			Machines_list = Machines_list_local
			Machines_proxy = Machines_proxy_local
			filesystem.writeTable("/Applications/GTcontrolSlave.app/Save.cfg", Machines_list)
		elseif a == true then
			GUI.alert(localization.contextMenu_file_error_void)
		end
	elseif a == true then
		GUI.alert(localization.contextMenu_file_error_open)
	end
end

File_Read(false)

----------------------------------------------Добавление машинок---------------------------------------------------------------

main_ButtonAdd.onTouch = function()
	local Adding_machine = GUI.addBackgroundContainer(workspace, true, true, localization.adding_text_name)
	local Adding_address = Adding_machine.layout:addChild(GUI.input(2, 2, 30, 3, 0xEEEEEE, 0x555555, 0x999999, 0xFFFFFF, 0x2D2D2D, "", localization.adding_input_address))
	local Adding_Name = Adding_machine.layout:addChild(GUI.input(2, 2, 30, 3, 0xEEEEEE, 0x555555, 0x999999, 0xFFFFFF, 0x2D2D2D, "", localization.adding_input_name))
	local Adding_type = Adding_machine.layout:addChild(GUI.comboBox(3, 2, 30, 3, 0xEEEEEE, 0x2D2D2D, 0xCCCCCC, 0x888888))
	
	for i = 1, #Machines_type do
		Adding_type:addItem(Machines_type[i].name)	
	end
	
	local Adding_Confirm = Adding_machine.layout:addChild(GUI.button(2, 2, 30, 3, 0xEEEEEE, 0x000000, 0xAAAAAA, 0x0, localization.adding_button_confirm))
	Adding_Confirm.onTouch = function()
		if Adding_address.text == "" then
			GUI.alert(localization.adding_error_input_address)
		else 
			if Adding_Name.text == "" then
				GUI.alert(localization.adding_error_input_name)
			else	
				local address_true = false
				for address, name in component.list() do
					if address == Adding_address.text then
						address_true = true
						break
					end
				end
				if #Machines_list > 0 and address_true == true then
					for i = 1, #Machines_list do
						if Adding_address.text == Machines_list[i].Machine_address then
							address_true = false
							break
						end
					end
				end
				if address_true then
					local Machines_buff = {Machine_address = "", Machine_name = "", Machine_type = 0}
					Machines_buff.Machine_address = Adding_address.text
					Machines_buff.Machine_name = Adding_Name.text
					Machines_buff.Machine_type = Adding_type.selectedItem
					table.insert(Machines_proxy,component.proxy(Adding_address.text))
					table.insert(Machines_list,Machines_buff)
					main_MachineList:addItem(Adding_Name.text).onTouch = function()--Вызов функции обновления информации на информационной панеле
						Update_information()
					end
				else	
					GUI.alert(localization.adding_error_test_address)
				end	
			end
		end
		Adding_machine:remove()
	end
end

-----------------------------------------------Удаление машинок----------------------------------------------------------------

main_ButtonDelete.onTouch = function()
	local Machines_list_local = {}
	local Machines_proxy_local = {}
	for i=1, #Machines_list do	
		if i < main_MachineList.selectedItem then
			table.insert(Machines_list_local,Machines_list[i])
			table.insert(Machines_proxy_local,component.proxy(Machines_list[i].Machine_address))
		elseif i == main_MachineList.selectedItem then
		
		elseif i > main_MachineList.selectedItem then
			table.insert(Machines_list_local,Machines_list[i])
			table.insert(Machines_proxy_local,component.proxy(Machines_list[i].Machine_address))
		end
	end	
	Machines_list = Machines_list_local
	Machines_proxy = Machines_proxy_local
	main_MachineList:remove()
	main_MachineList = workspace:addChild(GUI.list(4, 6, 30, workspace.height-7, 3, 0, 0xE1E1E1, 0x4B4B4B, 0xD2D2D2, 0x4B4B4B, 0x3366CC, 0xFFFFFF, false))
	for i=1, #Machines_list do
		table.insert(Machines_proxy,component.proxy(Machines_list[i].Machine_address))
		main_MachineList:addItem(Machines_list[i].Machine_name).onTouch = function()--Вызов функции обновления информации на информационной панеле
			Update_information()
		end
	end
end

---------------------------------------------------Настройки-------------------------------------------------------------------

main_ButtonConfig.onTouch = function()
	local Config = GUI.addBackgroundContainer(workspace, true, true, localization.config_text_name)
	
end

----------------------------------------------Информация об машинках-----------------------------------------------------------

function Update_information()
	Clear_screan()
	Update_information_label_1.text = localization.info_text_name .. " " .. Machines_list[main_MachineList.selectedItem].Machine_name
	Update_information_label_2.text = localization.info_text_address .. " " .. Machines_list[main_MachineList.selectedItem].Machine_address
	Update_information_label_3.text = localization.info_text_type .. " " .. Machines_type[Machines_list[main_MachineList.selectedItem].Machine_type].name
	Get_machines_state()
	
end

function Update_state_machine()
	if Machines_list[1] ~= nil then
		if Machines_list[main_MachineList.selectedItem].Machine_type == 1 then --Универсальный
			if Machines_state[main_MachineList.selectedItem].Machine_IsWork then
				Update_information_label_4.text = localization.info_text_has_work .. " " .. localization.info_text_work
			else
				Update_information_label_4.text = localization.info_text_has_work .. " " .. localization.info_text_dont_work
			end
			Update_information_label_5.text = localization.info_text_problems .. " " .. Machines_state[main_MachineList.selectedItem].Machine_Problems
			Update_information_label_6.text = localization.info_text_time .. " " .. Machines_state[main_MachineList.selectedItem].Machine_TimeWork .. "/" .. Machines_state[main_MachineList.selectedItem].Machine_TimeWorkMax
		elseif Machines_list[main_MachineList.selectedItem].Machine_type == 2 then --Чистая комната
						if Machines_state[main_MachineList.selectedItem].Machine_IsWork then
				Update_information_label_4.text = localization.info_text_has_work .. " " .. localization.info_text_work
			else
				Update_information_label_4.text = localization.info_text_has_work .. " " .. localization.info_text_dont_work
			end
			Update_information_label_5.text = localization.info_text_problems .. " " .. Machines_state[main_MachineList.selectedItem].Machine_Problems
			Update_information_label_6.text = localization.info_text_efficiency .. " " .. Machines_state[main_MachineList.selectedItem].Machine_Efficiency .. "%"
		elseif Machines_list[main_MachineList.selectedItem].Machine_type == 3 then --Хранилище батарей
			Update_information_label_4.text = localization.info_text_storedEu .. " " .. Machines_state[main_MachineList.selectedItem].Machine_StoredEU .. "/" .. Machines_state[main_MachineList.selectedItem].Machine_StoredEUMax
			Update_information_label_5.text = localization.info_text_avarageEu .. " " .. Machines_state[main_MachineList.selectedItem].Machine_InputEU .. "/" .. Machines_state[main_MachineList.selectedItem].Machine_OutputEU
	end
	workspace:draw()
	end
end

function Clear_screan() 
	Update_information_label_4.text = " "
	Update_information_label_5.text = " "
	Update_information_label_6.text = " "
	Update_information_label_7.text = " "
	Update_information_label_8.text = " "
	Update_information_label_9.text = " "
	Update_information_label_10.text = " "
end

------------------------------------------------Состояние машинок--------------------------------------------------------------

function Get_machines_state() --Обновить данные машинок
	local Machines_state_local = {} --Отфильтрованые показания машинок
	for i = 1, #Machines_list do
		local buff_SensorInformation = Machines_proxy[i].getSensorInformation()
		local buff = text.serialize(buff_SensorInformation)
		if Machines_list[i].Machine_type == 1 then -- Универсальный
			local buff_machine_local = {Machine_name = "", Machine_type = "", Machine_IsWork = false, Machine_TimeWorkMax = 0, Machine_TimeWork = 0, Machine_Problems = 0}
			buff_machine_local.Machine_name = Machines_list[i].Machine_name
			buff_machine_local.Machine_type = Machines_type[Machines_list[i].Machine_type].id
			buff_machine_local.Machine_IsWork = Machines_proxy[i].hasWork()
			buff_machine_local.Machine_TimeWorkMax = Machines_proxy[i].getWorkMaxProgress()
			buff_machine_local.Machine_TimeWork = Machines_proxy[i].getWorkProgress()
			buff_machine_local.Machine_Problems = tonumber(string.match(string.match(buff,"Problems: §c%d+"),"%d+"))
			table.insert(Machines_state_local,buff_machine_local)
		elseif Machines_list[i].Machine_type == 2 then -- Чистая комната
			local buff_machine_local = {Machine_name = "", Machine_type = "", Machine_IsWork = false, Machine_Efficiency = 0, Machine_Problems = 0}
			buff_machine_local.Machine_name = Machines_list[i].Machine_name
			buff_machine_local.Machine_type = Machines_type[Machines_list[i].Machine_type].id
			buff_machine_local.Machine_IsWork = Machines_proxy[i].hasWork()
			buff_machine_local.Machine_Problems = tonumber(string.match(string.match(buff,"Problems: §c%d+"),"%d+"))
			buff_machine_local.Machine_Efficiency = tonumber(string.match(string.match(buff,"Efficiency: §e%d+"),"%d+"))
			table.insert(Machines_state_local,buff_machine_local)
			
		elseif Machines_list[i].Machine_type == 3 then -- Хранилище батарей
			local buff_machine_local = {Machine_name = "", Machine_type = "", Machine_StoredEU=0, Machine_StoredEUMax = 0, Machine_InputEU = 0, Machine_OutputEU = 0}
			buff_machine_local.Machine_name = Machines_list[i].Machine_name
			buff_machine_local.Machine_type = Machines_type[Machines_list[i].Machine_type].id
			buff_machine_local.Machine_StoredEU = tonumber(string.match(string.gsub(string.match(buff,"§a%d+........"),",", ""),"[%d,]+"))
			buff_machine_local.Machine_StoredEUMax = tonumber(string.match(string.gsub(string.match(buff,"EU / §e%d+........"),",", ""),"[%d,]+"))
			buff_machine_local.Machine_InputEU = Machines_proxy[i].getAverageElectricInput()
			buff_machine_local.Machine_OutputEU = Machines_proxy[i].getAverageElectricOutput()
			table.insert(Machines_state_local,buff_machine_local)
		end
		
	end
	Machines_state = Machines_state_local
	if Settings_gtcs.Update_state_machine_work then
		Update_state_machine()
	end
end

--------------------------------------------------Главный евент----------------------------------------------------------------
--[[
mainhandler=event.addHandler(function()
	Get_machines_state()
end,0.5)
]]
-------------------------------------------------Отрисовка экрана--------------------------------------------------------------

workspace:draw()
workspace:start(0)

--
--[[
while Settings_gtcs.Program_work do
	workspace:start(0)
end
]]