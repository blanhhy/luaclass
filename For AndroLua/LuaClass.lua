--定义或继承一个class
function class(data, superclass)
  if Type(data) == "table" then
    local receipts = {}
    for key, value in pairs(data) do
      if Type(key) == "string" then
        receipts[key] = value
      end
    end
    if superclass then
      local super = superclass()
      local overridden = {}
      local level = #super + 1
      for key, value in pairs(receipts) do
        if super[key] then
          overridden[key] = super[key]
        end
        super[key] = value
      end
      receipts = super
      receipts[level] = overridden
    end
    return function(...)
      local object = {
        [ "__user_custom_data_type__" ] = "class",
      }
      table.override(object, receipts)
      if Type(object.__init__) == "function" then
        object.__init__(object, ...)
      end
      return object
    end
  end
end



--调用超类的方法（可嵌套）
function super(object)
  local replace = table.copy(object)
  local generation = #replace
  for key, value in pairs(replace) do
    local superclass_method = replace[generation][key]
    if Type(value) == "function" and superclass_method then
      local subclass_method = value
      replace[key] = function(...)
        local extra = select(select("#", ...), ...)
        if extra == "__indirect_calls__" then
          return subclass_method(...)
         else
          extra = "__indirect_calls__"
          return superclass_method(..., extra)
        end
      end
      --[[
      replace[key] = function(...)
        local params = {...}
        local count = #params
        if params[count] == "__indirect_calls__" then
          params[count] = nil
          return subclass_method(table.disband(params))
         else
          params[count + 1] = "__indirect_calls__"
          return superclass_method(table.disband(params))
        end
      end
    ]]
      --上面一部分的另一种实现方法
    end
  end
  replace[generation] = nil
  return replace
end



--列出所有属性和方法
function listattr(object)
  if type(object) == "class" then
    local propertis = "Property:\n"
    local methods = "Method:\n  __init__ ="..string.sub(tostring(object.__init__), 10)
    local extract = table.detach(object)
    extract.__user_custom_data_type__ = nil
    extract.__init__ = nil
    for key, value in pairs(extract) do
      if Type(value) == "function" then
        methods = methods.."\n  "..key.." ="..string.sub(tostring(value), 10)
       else
        propertis = propertis.."  "..key.." = "..tostring(value).."\n"
      end
    end
    return(propertis..methods)
   else
    error()
  end
end



--打印一个class实例
function printc(object)
  import "com.google.android.material.card.MaterialCardView"
  local layout =
  {
    MaterialCardView,
    cardBackgroundColor="#B2353535",
    cardElevation="0dp",
    radius="25",
    {
      TextView,
      textSize="13sp",
      TextColor="#ffffff",
      layout_width="wrap",
      layout_height="wrap",
      padding="3%w",
      paddingLeft="4.4%w",
      paddingRight="4.4%w",
      gravity="left",
      text=tostring(listattr(object)),
    },
  }
  Toast.makeText(activity, '', Toast.LENGTH_SHORT).setView(loadlayout(layout)).show()
end