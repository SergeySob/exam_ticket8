lgi = require 'lgi'

gtk = lgi.Gtk
gio = lgi.Gio

gtk.init()

bld = gtk.Builder()
bld:add_from_file('exam-08.glade')

local ui = bld.objects

local drawing_data = {} -- Хранение координат и цветов
local x = 0
local y = 0
local btn = false
local sr = 0
local sg = 0
local sb = 0

function clear_canvas()
    drawing_data = {} -- Очищаем массив с данными о рисовании
    ui.canvas:queue_draw() -- Перерисовываем холст
end

-- Привязываем обработчик к кнопке "clear"
ui.clear_button.on_clicked = function()
    clear_canvas()  -- Очищаем холст
end

function save_to_file()
    local file = io.open("drawing_data.txt", "w")
    if file then
        for _, data in ipairs(drawing_data) do
            -- Записываем данные с фиксированным количеством знаков после запятой
            -- Мы сохраняем цвета как значения из выбранного цвета (с нормализацией)
            local r = math.max(0, math.min(1, data.r))
            local g = math.max(0, math.min(1, data.g))
            local b = math.max(0, math.min(1, data.b))
            file:write(string.format("x: %.2f, y: %.2f, r: %.2f, g: %.2f, b: %.2f\n", data.x, data.y, r, g, b))
        end
        file:close()
    else
        print("Ошибка: невозможно открыть файл для записи.")
    end
end

function ui.canvas:on_button_press_event(evt)
    btn = true
end

function ui.canvas:on_button_release_event(evt)
    btn = false
    save_to_file() -- Сохраняем данные после завершения рисования
end

function ui.canvas:on_motion_notify_event(evt)
    if btn then
        x = evt.x
        y = evt.y
        -- Добавляем текущие координаты и цвет в массив
        table.insert(drawing_data, {x = x, y = y, r = sr, g = sg, b = sb})
        ui.canvas:queue_draw()
    end
end

-- Обработчик для color_chooser
function ui.color_chooser:on_color_set()
    local color = self:get_color()  -- Используем get_color вместо get_rgba
    sr = color.red / 65535  -- Преобразуем из диапазона 0-65535 в 0-1
    sg = color.green / 65535
    sb = color.blue / 65535
    print(string.format("\27[38;2;%d;%d;%dmВыбран цвет: R=%.2f, G=%.2f, B=%.2f\27[0m", 
        color.red, color.green, color.blue, sr, sg, sb))
end

-- Проверка наличия color_chooser
if ui.color_chooser then
    print("color_chooser загружен успешно!")
else
    print("Ошибка: color_chooser не найден!")
end

function ui.canvas:on_draw(cr)
    cr:set_source_rgb(1, 1, 1)
    cr:paint()

    -- Рисуем все сохраненные данные
    for _, data in ipairs(drawing_data) do
        cr:set_source_rgb(data.r, data.g, data.b)
        cr:rectangle(data.x - 5, data.y - 5, 10, 10)
        cr:fill()
    end
end

function ui_destroy()
    gtk.main_quit()
end

ui.wnd:show_all()
gtk.main()

