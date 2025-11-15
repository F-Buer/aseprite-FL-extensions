return {
  load_json = function(file_name)
    if not file_name then
      return nil
    end
    local json_file = io.open(file_name, 'r')
    local json_data = json_file and json_file:read("*all")
    _ = json_file and json_file:close()
    local status, result = pcall(json.decode, json_data)
    return (status and result) or nil
  end
}
