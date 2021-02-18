-- Made so you can add callbacks on to GuiObjects that can be modifed by the user

function table.slice(tbl, first, last, step)
  local sliced = {}

  for i = first or 1, last or #tbl, step or 1 do
    sliced[#sliced+1] = tbl[i]
  end

  return sliced
end


local ui_objects = {}


local changeable_ui_objects = {
    Checkbox = gui.Checkbox,
    Slider = gui.Slider,
    Keybox = gui.Keybox,
    Combobox = gui.Combobox,
    Editbox = gui.Editbox,
    ColorPicker = gui.ColorPicker,
    Listbox = gui.Listbox,
}

function handle_changeable_ui_object_creation(changeable_ui_object_name)
    return function(...)
        local args = {...}
        local changeable_ui_object = nil
        if type(args[#args]) == "function" then
            changeable_ui_object = changeable_ui_objects[changeable_ui_object_name](unpack(table.slice(args, 1, #args - 1)))
            table.insert(ui_objects, {old_value = changeable_ui_object:GetValue(), ui_object = changeable_ui_object, onchange_callback = args[#args]})
        else
            changeable_ui_object = changeable_ui_objects[changeable_ui_object_name](...)
        end
        return changeable_ui_object
    end
end


-- detour
for k, v in pairs(changeable_ui_objects) do
    gui[k] = handle_changeable_ui_object_creation(k)
end




function listen_for_changes()
    for k, v in pairs(ui_objects) do
        if v.ui_object:GetValue() ~= v.old_value then
            v.onchange_callback(v.ui_object, v.ui_object:GetValue())
        end
        v.old_value = v.ui_object:GetValue()
    end
end

callbacks.Register("Draw", "ListenForChanges", listen_for_changes)
-- example
local checkbox = gui.Checkbox(gui.Reference("Ragebot", "Aimbot", "Toggle"), "autorun", "Autorun", false, function(self, checked)
    if checked then
        self:SetPosY(250)
    else
        self:SetPosY(350)
    end
    print(checked)
end)

local slider = gui.Slider(gui.Reference("Ragebot", "Aimbot", "Toggle"), "test", "test", 50, 0, 10000, function(self, value)
    print(value)
end)
