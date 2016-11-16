defmodule PhoenixFormAwesomplete do
  alias Phoenix.HTML
  alias Phoenix.HTML.Form

  # @util & @lea allows you to use aliases or replacement libraries. The default names are a bit long.
  # For example use: `var aw = Awesomplete, au = AwesompleteUtil;`. This could shorten the average page size.
  @util Application.get_env(:phoenix_form_awesomplete, :util) || "AwesompleteUtil"
  @lea  Application.get_env(:phoenix_form_awesomplete, :awesomplete) || "Awesomplete"

  def script(script) do
    HTML.raw("<script>#{script}</script>")
  end

  def copy_to_id(source_form, source_field, data_field \\ nil, target_id) 
      when (is_nil(data_field) or is_binary(data_field)) and is_binary(target_id) do
    script(copy_to_id_js(source_form, source_field, data_field, target_id))
  end

  # target_id can also be function, so you can control the output.
  def copy_to_id_js(source_form, source_field, data_field \\ nil, target_id) 
      when (is_nil(data_field) or is_binary(data_field)) and is_binary(target_id) do
    source_id = Form.field_id(source_form, source_field)
    # In JS strings must be quoted, but functions not. 
    # Assume it is a function if it starts with an alfanumeric characters and doesn't contain space
    # or it can be an inlined function or it can be a function-name with bind
    is_function = String.contains?(target_id, "{") || target_id =~ ~r/^\w[^\s]*$/
    target = if is_function, do: target_id, else: "'#{target_id}'"
    "#{@util}.startCopy('##{source_id}', '#{data_field}', #{target});"
  end

  def copy_to_field(source_form, source_field, data_field \\ nil, target_form, target_field) 
      when is_nil(data_field) or is_binary(data_field) do
    target_id = Form.field_id(target_form, target_field)
    script(copy_to_id_js(source_form, source_field, data_field, "##{target_id}"))
  end

  defp opts_to_string(opts) do
     opts 
     |> Enum.map_join(", ", fn{k,v} -> val = to_string(v); "#{k}: #{val}" end)
  end

  defp to_integer(val) do
    if is_nil(val) or is_integer(val), do: val, else: String.to_integer(val)
  end
  

  #
    # This method generates javascript code for using Awesomplete(Util) in a friendly way.
  #
  def awesomplete(form, field, opts \\ [], awesomplete_opts) do
    script = awesomplete_js(form, field, awesomplete_opts)
    HTML.html_escape([Form.text_input(form, field, opts), script(script)])
  end

  #
    # This method generates javascript code for using Awesomplete(Util) in a friendly way.
  #
  def awesomplete_script(form, field, awesomplete_opts) do
    script = awesomplete_js(form, field, awesomplete_opts)
    script(script)
  end

  #
    # This method generates javascript code for using Awesomplete(Util) in a friendly way.
  #
  def awesomplete_js(form, field, awesomplete_opts) do
    element_id = Form.field_id(form, field)
    awesomplete_js(element_id, awesomplete_opts)
  end

  #
    # This method generates javascript code for using Awesomplete(Util) in a friendly way.
  #
  def awesomplete_js(element_id, awesomplete_opts) do
    awesomplete_opts = Enum.to_list awesomplete_opts

    # 
      # Some of the options (filter, replace, data) are popped to be added later again.
      # Unrecognized options are passed on to Awesomplete.
    # 
    {assign,            awesomplete_opts} = Keyword.pop(awesomplete_opts, :assign, false)
    {ajax_fun,          awesomplete_opts} = Keyword.pop(awesomplete_opts, :ajax)
    {combobox,          awesomplete_opts} = Keyword.pop(awesomplete_opts, :combobox, false)
    {conv_input_fun,    awesomplete_opts} = Keyword.pop(awesomplete_opts, :convertInput)
    {conv_response_fun, awesomplete_opts} = Keyword.pop(awesomplete_opts, :convertResponse)
    {data_fun,          awesomplete_opts} = Keyword.pop(awesomplete_opts, :data)
    {descr_fld,         awesomplete_opts} = Keyword.pop(awesomplete_opts, :descr)
    {descr_search,      awesomplete_opts} = Keyword.pop(awesomplete_opts, :descrSearch, false) 
    {fld_name,          awesomplete_opts} = Keyword.pop(awesomplete_opts, :value)
    {filter_fun,        awesomplete_opts} = Keyword.pop(awesomplete_opts, :filter)
    {item_fun,          awesomplete_opts} = Keyword.pop(awesomplete_opts, :item)
    {label_fld,         awesomplete_opts} = Keyword.pop(awesomplete_opts, :label)
    {loadall,           awesomplete_opts} = Keyword.pop(awesomplete_opts, :loadall, false)
    {limit,             awesomplete_opts} = Keyword.pop(awesomplete_opts, :limit)
    {multiple,          awesomplete_opts} = Keyword.pop(awesomplete_opts, :multiple)
    {prepop,            awesomplete_opts} = Keyword.pop(awesomplete_opts, :prepop, false)
    {replace_fun,       awesomplete_opts} = Keyword.pop(awesomplete_opts, :replace)
    {url,               awesomplete_opts} = Keyword.pop(awesomplete_opts, :url)
    {url_end,           awesomplete_opts} = Keyword.pop(awesomplete_opts, :urlEnd)

    # generated js code uses @util & @lea but in the input we expect the standard Awesomplete & AwesompleteUtil names.
    starts_with = filter_fun == "Awesomplete.FILTER_STARTSWITH" or filter_fun == "AwesompleteUtil.filterStartsWith"

    # 
      # Be permissive about all kind of parameter combinations, but these we really can't handle:
    # 
    if is_nil(fld_name)  and descr_fld != nil, do: raise ArgumentError, "'descr' without 'value' parameter."
    if is_nil(fld_name)  and label_fld != nil, do: raise ArgumentError, "'label' without 'value' parameter."
    if is_nil(descr_fld) and descr_search, do: raise ArgumentError, "Cannot search description texts without knowing the description field. Please supply descr parameter."
    
    # 
      # Convert limit to integer
    # 
    limit = to_integer(limit)
    
    maxItems = to_integer(Keyword.get(awesomplete_opts, :maxItems, 10)) 

    # 
      # Determine which characters are used to separate multiple items
      # For example in multiple color selection: red,blue,yellow the multiple_char is the comma
      # Assume space as separator if multiple=true,
    # 
    multiple_char = cond do
      is_nil(multiple) or multiple == false -> nil
      multiple == true -> " "
      true -> multiple
    end

    # 
      # For multiple items, if the separator is typed, the last field is considered complete. 
      # The separator is included in the search in the filter,
      # and because the items do not contain the separator, the suggestion list will close.
      # However, for the combobox, closing the list and waiting for the first characters is not desirable,
      # because the combo button is there to be able to show all items.
    # 
    filter_match_sep = if combobox, do: "", else: "([#{multiple_char}]\\s*)?"

    # 
      # Select the text that should be considered as the current input.
      # Will be used in the convertInput function and in the filter.
      # For multiple items, only the last item is considered to be input for the suggestion list lookup.
    # 
    conv_input_str = 
      if is_nil(multiple_char) do
        "input" 
      else
        "input.replace(/[#{multiple_char}]\\s*$/, '').match(/[^#{multiple_char}]*$/)[0]"
      end

    filter_str =
      if is_nil(multiple_char) do
        "input" 
      else
        "input.match(/[^#{multiple_char}]*#{filter_match_sep}$/)[0]"
      end

    data_val = if is_nil(fld_name) or (is_nil(descr_fld) and is_nil(label_fld)), do: "data", else: "data.value"
    starts_with_filter_fun = cond do
      is_nil(descr_fld) and is_nil(label_fld) and maxItems !== 0 and filter_fun == "Awesomplete.FILTER_STARTSWITH" -> "#{@lea}.FILTER_STARTSWITH"
      descr_search -> "function(data, input) { return #{@util}.filterStartsWith(data, #{filter_str}) || #{@lea}.FILTER_STARTSWITH(data.value.substring(data.value.lastIndexOf('|')+1), #{filter_str}); }"
      true -> "#{@util}.filterStartsWith"
    end

    filter_opts = cond do
      is_nil(multiple_char) and is_nil(filter_fun) and data_val == "data" -> []
      is_nil(multiple_char) and is_nil(descr_fld) and is_nil(label_fld) and maxItems !== 0 and (is_nil(filter_fun) or filter_fun == "Awesomplete.FILTER_CONTAINS") -> []
      is_nil(multiple_char) and (is_nil(filter_fun) or filter_fun == "Awesomplete.FILTER_CONTAINS" or filter_fun == "AwesompleteUtil.filterContains") -> [filter: "#{@util}.filterContains"]
      is_nil(multiple_char) and data_val == "data" -> [filter: filter_fun]
      is_nil(multiple_char) and starts_with and is_nil(item_fun) -> [filter: starts_with_filter_fun , item: "#{@util}.itemStartsWith"]
      is_nil(multiple_char) and starts_with -> [filter: starts_with_filter_fun]
      is_nil(multiple_char) -> [filter: "function(data, input) { return (#{filter_fun})(data.value, input); }"]
      starts_with and descr_search -> [filter: starts_with_filter_fun]
      starts_with -> [filter: "function(data, input) { return #{@lea}.FILTER_STARTSWITH(#{data_val}, #{filter_str}); }"]
      is_nil(filter_fun) -> [filter: "function(data, input) { return #{@lea}.FILTER_CONTAINS(#{data_val}, #{filter_str}); }"]
      true -> [filter: "function(data, input) { return (#{filter_fun})(#{data_val}, #{filter_str}); }"]
    end 

    filter_opts = cond do
      is_nil(item_fun) and is_nil(multiple_char) -> filter_opts
      is_nil(item_fun) and starts_with ->  filter_opts ++ [item: "function(text, input) { return #{@util}.itemStartsWith(text, #{filter_str}); }"]
      is_nil(item_fun) ->  filter_opts ++ [item: "function(text, input) { return #{@util}.itemContains(text, #{filter_str}); }"]
      true -> filter_opts ++ [item: "function(text, input) { return (#{item_fun})(text, #{filter_str}); }"]
    end

    conv_input_opts = cond do
      is_nil(multiple_char) and is_nil(conv_input_fun) -> [] 
      is_nil(multiple_char) -> [convertInput: conv_input_fun] 
      is_nil(conv_input_fun) -> [convertInput: "function(input) { return #{conv_input_str}.trim().toLowerCase(); }"]
      true -> [convertInput: "function(input) { return (#{conv_input_fun})(#{conv_input_str}.trim().toLowerCase()); }"]
    end 
       
    assign_replace_text = 
      if is_nil(multiple_char) do
        "text"
      else
        "this.input.value.match(/^.+#{multiple_char}\\s*|/)[0] + text + '" <> String.at(multiple_char, 0) <> " '"
      end

    multiple_replace_opts = cond do
      is_nil(multiple_char) -> []
      is_nil(replace_fun) -> [replace: "function(data) { var text=data.value; this.input.value = #{assign_replace_text}; }"]
      true -> [replace: "function(data) { var text=data.value; (#{replace_fun}).(#{assign_replace_text}); }"]
    end

    label_str = if label_fld, do: "(rec['#{label_fld}'] || '').replace('<p>', '<p >')", else: "rec['#{fld_name}']"
    data_fun_result = cond do
      is_nil(descr_fld) and is_nil(label_fld) -> "rec['#{fld_name}']"
      is_nil(descr_fld) -> "{ label:#{label_str}, value:rec['#{fld_name}'] }"
      !descr_search -> "{ label: #{label_str}+'<p>'+(rec['#{descr_fld}'] || ''), value: rec['#{fld_name}'] }"
      true -> "{ label: #{label_str}+'<p>'+#{@util}.mark(rec['#{descr_fld}'] || '', #{conv_input_str}, #{starts_with}), value: rec['#{fld_name}']+'|'+(rec['#{descr_fld}'] || '').replace('|', ' ') }"
    end

    data_fun_str = if is_nil(data_fun), do: "function(rec, input) { return #{data_fun_result}; }", else: "function(rec, input) { return (#{data_fun})(#{data_fun_result}, input); }"

    awesomplete_opts = cond do
      is_nil(fld_name) and is_nil(data_fun) -> awesomplete_opts ++ multiple_replace_opts
      is_nil(fld_name) -> awesomplete_opts ++ [data: data_fun] ++ multiple_replace_opts
      !descr_search ->       awesomplete_opts ++ [data: data_fun_str] ++ multiple_replace_opts
      is_nil(replace_fun) -> awesomplete_opts ++ [data: data_fun_str, replace: "function(data) { var text = data.value.substring(0, data.value.lastIndexOf('|')); this.input.value = #{assign_replace_text}; }"]
      true -> awesomplete_opts ++ [data: data_fun_str, replace: "function(data) { var text = data.value.substring(0, data.value.lastIndexOf('|')); (#{replace_fun}).(#{assign_replace_text}); }"]
    end

    awesomplete_opts = awesomplete_opts ++ filter_opts
    awesomplete_opts = if is_nil(replace_fun) or descr_search or multiple_char != nil, do: awesomplete_opts, else: awesomplete_opts ++ [replace: replace_fun] 
    awe_opts_str = "{" <> opts_to_string(awesomplete_opts) <> "}"

    assign_var  = if assign == true,  do: "awe_#{element_id}", else: "#{assign}" 
    assign_text = if assign == false, do: "", else: "var #{assign_var}=" 
    # id of the combo button. Assume awe_btn_<awesomplete element id> if combobox=true. Or take the combobox supplied value.
    combo_btn_id  = if combobox == true, do: "awe_btn_#{element_id}", else: "#{combobox}" 
    util_opts = if is_nil(url), do: [], else: [url: "'#{url}'"] 
    util_opts = if is_nil(url_end),  do: util_opts, else: util_opts ++ [urlEnd: "'#{url_end}'"] 
    util_opts = if is_nil(limit),    do: util_opts, else: util_opts ++ [limit: limit] 
    util_opts = if is_nil(ajax_fun), do: util_opts, else: util_opts ++ [ajax: ajax_fun] 
    util_opts = if is_nil(conv_response_fun), do: util_opts,  else: util_opts ++ [convertResponse: conv_response_fun] 
    util_opts = if loadall, do: util_opts ++ [loadall: true], else: util_opts 
    util_opts = if prepop,  do: util_opts ++ [prepop: true],  else: util_opts 
    util_opts = util_opts ++ conv_input_opts
    util_opts_str = "{" <> opts_to_string(util_opts) <> "}" 

    awe_script = "#{assign_text}#{@util}.startAwesomplete('##{element_id}', #{util_opts_str}, #{awe_opts_str})"

    script = cond do
       combobox == false ->    "#{awe_script};"
       assign   == false ->    "#{@util}.startClick('##{combo_btn_id}', #{awe_script});"
       true -> "#{awe_script};\n#{@util}.startClick('##{combo_btn_id}', #{assign_var});"
    end

    script
  end
end
