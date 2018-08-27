require 'nn'

local M = {}

function M.layer_string_to_nums(layer_string)
  local nums = {}
  for _, s in ipairs(layer_string:split('-')) do
    table.insert(nums, tonumber(s))
  end
  return nums
end

function M.compare_layer_strings(s1, s2)
  local left = M.layer_string_to_nums(s1)
  local right = M.layer_string_to_nums(s2)
  local out = nil
  for i = 1, math.min(#left, #right) do
    if left[i] < right[i] then
      out = true
    elseif left[i] > right[i] then
      out = false
    end
    if out ~= nil then break end
  end

  if out == nil then
    out = (#left > #right)
  end
  return out
end


function M.get_layer(net, layer_string)
  local nums = M.layer_string_to_nums(layer_string)
  local layer = net
  for i, num in ipairs(nums) do
    local count = 0
    for j = 1, #layer do
      if not layer:get(j)._ignore then
        count = count + 1
      end
      if count == num then
        layer = layer:get(j)
        break
      end
    end
  end
  return layer
end


function M.insert_after(net, layer_string, new_layer)
  new_layer._ignore = true
  local nums = M.layer_string_to_nums(layer_string)
  local container = net
  for i = 1, #nums do
    local count = 0
    for j = 1, #container do
      if not container:get(j)._ignore then
        count = count + 1
      end
      if count == nums[i] then
        if i < #nums then
          container = container:get(j)
          break
        elseif i == #nums then
          container:insert(new_layer, j + 1)
          return
        end
      end
    end
  end
end


function M.trim_network(net)
  local function contains_ignore(layer)
    if torch.isTypeOf(layer, nn.Container) then
      local found = false
      for i = 1, layer:size() do
        found = found or contains_ignore(layer:get(i))
      end
      return found
    else
      return layer._ignore == true
    end
  end
  local last_layer = 0
  for i = 1, #net do
    if contains_ignore(net:get(i)) then
      last_layer = i
    end
  end
  local num_to_remove = #net - last_layer
  for i = 1, num_to_remove do
    net:remove()
  end
  return net
end


return M

