
local lpsPosition = Sensors.lpsPosition
local unpack = table.unpack
-----------------------------------------------------------------------------------------------------------------------------------------






-----------------------------------------
-- Блок обработки работки светодиодов ---
---------------------------------------------------------------------------------------------------------------------------------------------

-- Количество светодиодов 
-- Если есть модуль LED, то ledNumber = 29
local ledNumber = 4

-- Создание порта управления светодиодами
local leds = Ledbar.new(ledNumber)

-- Функция смены цвета светодиодов
local function changeColor(r, g, b)
    -- Поочередное изменение цвета каждого из 4-х светодиодов
    for i=0, ledNumber - 1, 1 do
        leds:set(i, r, g, b)
    end
end 

-- Таблица цветов в формате RGB для передачи в функцию changeColor
local colors = {	red = 		{1, 0, 0},
					green = 	{0, 1, 0},
					blue = 		{0, 0, 1},
					purple = 	{0.5, 0, 0.5},
					cyan = 		{0, 0.5, 0.5},
					yellow = 	{0.5, 0.5, 0},
					white = 	{0.33, 0.33, 0.33},
					black = 	{0, 0, 0}
}


-------------------------------------------------------------------





-------------------------
-- Блок работы с uart ---
---------------------------------------------------------------------------------------------------------------------------------------------

--  инициализируем Uart интерфейс
local uartNum = 4 -- номер Uart интерфейса (USART4)
local baudRate = 9600 -- скорость передачи данных
local dataBits = 8
local stopBits = 1
local parity = Uart.PARITY_NONE
local uart = Uart.new(uartNum, baudRate, parity, stopBits) --  создание протокола обмена



local message = {"A", "X", 0, "Y", 0, "Z", 0, "\n"}

-- получает на вход текущие координаты, в которых нужно сделать фотографию
local function uart_send_message(x, y, z)
	
	message[3] = x
	message[5] = y
	message[7] = z
	
	for i=1, 8, 1 do
        uart:write(message[i], string.len(message[i]))
    end
	
end



local function test_uart()
	lpsX, lpsY, lpsZ = lpsPosition()
	uart_send_message(lpsX, lpsY, lpsZ)
end

local time_photo = 0.4
timer_uart = Timer.new(time_photo, function() test_uart() end)

-------------------------------------------------------------------



----------------------------------------
-- Блок обработки движения по тчокам ---
---------------------------------------------------------------------------------------------------------------------------------------------

local input = {
    copter = 2,
    z = 2.2, -- высота полета
	
    x1 = 1.5, -- левая граница
    x2 = 6.25, -- правая граница
    y1 = 1.5, -- нижняя граница
    y2 = 6.0,
    
    n_x = 5, -- количество точек по горизонтали
    d_y = 0.4, -- шаг по вертикали
     
    gals = 6 -- количество шагов по вертикали
}


local d_x = (input.x2 - input.x1) / input.n_x
local vector = 1

local x = input.x1 - d_x
local y = input.y1

if input.copter == 2 then
    x = input.x2
    input.d_y = input.d_y * -1
    y = input.y2 - input.d_y   
end

local function nextPoint()
	
	x = x + d_x * vector
    
    if x > input.x2 then
        
        y = y + input.d_y
        vector = -1
        x = x + d_x * vector
		input.gals = input.gals - 1
		
    elseif x < input.x1 then
    
        y = y + input.d_y
        vector = 1
        x = x + d_x * vector
		input.gals = input.gals - 1
		
    end 
	
	if input.gals > 0 then
	    ap.updateYaw(0)
        ap.goToLocalPoint(x, y, input.z)
        
    elseif input.gals == 0 then
        timer_uart:stop()
        input.gals = input.gals - 1
        if input.copter == 1 then
            ap.goToLocalPoint(input.x1, input.y1, input.z)
        else
            ap.goToLocalPoint(input.x2, input.y2, input.z)
        end
        
        
    elseif input.gals == -1 then
		
        Timer.callLater(1, function() ap.push(Ev.MCE_LANDING) end)
    end
	 
	
end

-------------------------------------------------------------------




-- Функция обработки событий, автоматически вызывается автопилотом
function callback(event)
    -- Когда коптер поднялся на высоту взлета Flight_com_takeoffAlt, переходим к полету по точкам
    if(event == Ev.TAKEOFF_COMPLETE) then
		timer_uart:start()
        Timer.callLater(0.5 , function() nextPoint() end)
    end
    
	-- Когда коптер достиг текущей точки, переходим к следующей
    if(event == Ev.POINT_DECELERATION) then
        nextPoint()
    end
    
	-- Когда коптер приземлился, выключаем светодиоды
    if (event == Ev.COPTER_LANDED) then
        changeColor(table.unpack(colors.black))
    end
end


-- Старт полета с пульта
function start()
	local _,_,_,_,_,ch6,_,ch8 = Sensors.rc() -- SWD and SWA
	if ch6 < 1 and ch8 > 0 then
	    changeColor(table.unpack(colors.white))
	    -- Предстартовая подготовка
        ap.push(Ev.MCE_PREFLIGHT)

	    -- Таймер, через 2 секунды вызывающий функцию взлета
        Timer.callLater(2, function() ap.push(Ev.MCE_TAKEOFF) end)
	
	else
		changeColor(table.unpack(colors.black))
		Timer.callLater(0.2, function() start() end)
	    
	end

end



start()
