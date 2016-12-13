defmodule PhoenixFormAwesomplete do
  alias Phoenix.HTML
  alias Phoenix.HTML.Form

  @moduledoc ~S"""

PhoenixFormAwesomplete is a [Phoenix form helper](https://hexdocs.pm/phoenix_html/Phoenix.HTML.Form.html) 
that utilizes Lea Verou's autocomplete / autosuggest / typeahead / 
inputsearch [Awesomplete widget](https://leaverou.github.io/awesomplete/index.html).

It comes with an AwesompleteUtil [javascript library](https://nico-amsterdam.github.io/awesomplete-util/index.html) 
which adds the following features:

- Dynamic remote data loading; based on what is typed-in it performs an ajax lookup.
- Allow HTML markup in the shown items. Show value with description. Optionally search in the description text.
- Show when there is an exact match.
- Show when there isn't a match.
- When there is an exact match show related data (supplied in the remote data) in other parts of the page.
- Select the highlighted item with the tab-key. 

  ## Example

      iex> PhoenixFormAwesomplete.awesomplete(:user, :drinks,
      ...> ["data-list": "beer, gin, soda, sprite, water, vodga, whine, whisky"], 
      ...> %{ minChars: 1 } )
      {:safe,
       ["<input data-list=\"beer, gin, soda, sprite, water, vodga, whine, whisky\"" <>
        " id=\"user_drinks\" name=\"user[drinks]\" type=\"text\">", 
        "<script>AwesompleteUtil.start('#user_drinks', {}, {minChars: 1});</script>"]}

  The first three parameters are passed on unchanged to the Phoenix form [text_input](https://hexdocs.pm/phoenix_html/Phoenix.HTML.Form.html#text_input/3) which generates the input tag.
  `minChars` is an option for the Awesomplete object which is started with inline javascript.
  Just adding the `multiple` option changes the generated javascript code completely, the PhoenixFormAwesomplete module
  takes care of that. 
  Instead of an server side generated data-list it is possible to specify an url of a JSON web service and 
  let the client-code lookup the data list on-demand while typing. 
  Look at the [live examples](https://nico-amsterdam.github.io/awesomplete-util/phoenix.html) with code.


  It is possible to use aliases for the javascript library references in the generated code 
  via the environment variables `util` and `awesomplete`.
  The default names, `AwesompleteUtil` and `Awesomplete` respectively, are a bit long.
  This can shorten the average page size.
  For example use this javascript: 
       var AU = AwesompleteUtil, AW = Awesomplete; 
  and change the variables via the application config:
       :phoenix_form_awesomplete, util:         "AU"
       :phoenix_form_awesomplete, awesomplete:  "AW"
  After changing the config/config.exs run: 
       touch deps/phoenix_form_awesomplete/mix.exs
       mix deps.compile phoenix_form_awesomplete
  """

  # @util & @awe refer to the default javascript libraries.
  @util Application.get_env(:phoenix_form_awesomplete, :util) || "AwesompleteUtil"
  @awe  Application.get_env(:phoenix_form_awesomplete, :awesomplete) || "Awesomplete"

  @doc ~S"""
  Create script tag with the supplied script. No defer or async because this is used for inline script.

  ## Example

      iex> PhoenixFormAwesomplete.script("alert(1);")
      {:safe, "<script>alert(1);</script>"}
  """
  def script(script) do
    HTML.raw("<script>#{script}</script>")
  end

  @doc ~S"""
  Create script tag with javascript that listens to `awesomplete-prepop` and `awesomplete-match` events,
  and copies the `data_field` to the DOM element with the given target id.
  The `target_id` can also be a javascript function. This function receives two parameters: event and dataField. The event detail property contains an array with the matching list item. The array is empty when there is no match.

  ## Example

      iex> PhoenixFormAwesomplete.copy_to_id(:user, :color, "label", "#awe-color-result") 
      {:safe,
       "<script>AwesompleteUtil.startCopy('#user_color', 'label', '#awe-color-result');</script>"}

  """
  def copy_to_id(source_form, source_field, data_field \\ nil, target_id) 
      when (is_nil(data_field) or is_binary(data_field)) and is_binary(target_id) do
    script(copy_to_id_js(source_form, source_field, data_field, target_id))
  end

  @doc ~S"""
  Create javascript that listens to `awesomplete-prepop` and `awesomplete-match` events,
  and copies the `data_field` to the DOM element with the given target id.
  The `target_id` can also be a javascript function.

  ## Example

      iex> PhoenixFormAwesomplete.copy_to_id_js(:user, :color, "label", "#awe-color-result") 
      "AwesompleteUtil.startCopy('#user_color', 'label', '#awe-color-result');"

  """
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

  @doc ~S"""
  Create script tag with javascript that listens to `awesomplete-prepop` and `awesomplete-match` events,
  and copies the `data_field` to the target field.

  ## Example

      iex> PhoenixFormAwesomplete.copy_to_field(:user, :color, "label", :door, :paint)  
      {:safe,
       "<script>AwesompleteUtil.startCopy('#user_color', 'label', '#door_paint');</script>"}

  """
  def copy_to_field(source_form, source_field, data_field \\ nil, target_form, target_field) 
      when is_nil(data_field) or is_binary(data_field) do
    target_id = Form.field_id(target_form, target_field)
    script(copy_to_id_js(source_form, source_field, data_field, "##{target_id}"))
  end

  # Converts map with options to a comma separated string with key:value pairs..
  defp opts_to_string(opts) do
     opts 
     |> Enum.map_join(", ", fn{k,v} -> val = to_string(v); "#{k}: #{val}" end)
  end

  # optionally convert string to integer
  defp to_integer(val) do
    if is_nil(val) or is_integer(val), do: val, else: String.to_integer(val)
  end

  @doc ~S"""
  This method generates an input tag and inline javascript code that starts Awesomplete.

  Awesomplete options:
   * `ajax`            - Replace ajax function. It must have these parameters: (url, urlEnd, val, fn, xhr). fn is the callback function. Default: AwesompleteUtil.ajax. 
   * `assign`          - Assign the Awesomplete object to a variable. true/false/name. If true the variable name will 'awe_' + id of input tag. Default: false
   * `autoFirst`       - Automatically select the first element. Default: false. 
   * `combobox`        - Id of the combobox button. true/false/id. If true the assumed button id is 'awe_btn_' + id of the input tag. Default: false
   * `convertInput`    - Convert input function. Internally convert input for comparison with data list. By default it lowercase's and trims the input, so the comparison is case-insensitive.
   * `convertResponse` - Convert JSON response from ajax calls. This function is called with the parsed JSON, and allows conversion of the data before further processing. Default: nil - no conversion. 
   * `data`            - Data function as defined in [Awesomplete](http://leaverou.github.io/awesomplete/index.html#extensibility)
   * `descr`           - Name of the field in the data list (the JSON response) that contains the description text to show below the value in the suggestion list. Default: no description
   * `descrSearch`     - Filter must also search the input value in the description field. Default: false
   * `value`           - Name of the field in the data list (the JSON response) that contains the value.
   * `filter`          - Filter function as defined in [Awesomplete](http://leaverou.github.io/awesomplete/index.html#extensibility). Mostly Awesomplete.FILTER_STARTSWITH or Awesomplete.FILTER_CONTAINS. If label is different as value, filter on value with AweompleteUtil.filterStartsWith or AwesompleteUtil.filterContains.
   * `item`            - Item function as defined in [Awesomplete](http://leaverou.github.io/awesomplete/index.html#extensibility). Default is to highlight all occurrences of the input text. Use AwesompleteUtil.itemStartsWith if that matches with the used filter.
   * `label`           - Name of the field in the data list (the JSON response) that contains the text that should be shown instead of the value. 
   * `list`            - Data list as defined in [Awesomplete](http://leaverou.github.io/awesomplete/index.html#extensibility).
   * `loadall`         - Data list contains all items. In ajax calls the passed on value will be empty. Default: false
   * `limit`           - number. If a limit is specified, if the limit or more results are returned by the server the AwesompleteUtil assumes that there are more results, so it will re-query if more characters are typed to get more refined results. The limit:1 tells that not more than 1 result is expected, so the json service doesn't have to return an array. With limit:0 it will always re-query if more characters are typed. Default: no limit
   * `maxItems`        - Maximum number of suggestions to display. Default: 10 
   * `minChars`        - Minimum characters the user has to type before the autocomplete popup shows up. Default: 2 
   * `multiple`        - true/false/characters. Separators to allow multiple values. If true, the separator will be the space character. Default: false
   * `prepop`          - true/false. If true do lookup initial/autofilled value and send awesomplete-prepop event. Default: false 
   * `replace`         - Replace function as defined in [Awesomplete](http://leaverou.github.io/awesomplete/index.html#extensibility)
   * `sort`            - Sort function as defined in [Awesomplete](http://leaverou.github.io/awesomplete/index.html#extensibility)
   * `url`             - url for ajax calls.
   * `urlEnd`          - Addition at the end of the url of the ajax call, after the value. 

  ## Example

      iex> PhoenixFormAwesomplete.awesomplete(:user, :eyes, ["data-list": "blue, brown, green"],
      ...>  %{ minChars: 1, multiple: ",;" } )
      {:safe,
       ["<input data-list=\"blue, brown, green\" id=\"user_eyes\" name=\"user[eyes]\" type=\"text\">",
        "<script>AwesompleteUtil.start('#user_eyes', " <> 
        "{convertInput: function(input) {" <>
        " return input.replace(/[,;]\\s*$/, '').match(/[^,;]*$/)[0].trim().toLowerCase(); }}, " <>
        "{minChars: 1, " <> 
        "replace: function(data) {" <>
        " var text=data.value;" <> 
        " this.input.value = this.input.value.match(/^.+[,;]\\s*|/)[0] + text + ', '; }, " <>
        "filter: function(data, input) {" <>
        " return Awesomplete.FILTER_CONTAINS(data, input.match(/[^,;]*([,;]\\s*)?$/)[0]); }, " <>
        "item: function(text, input) {" <>
        " return AwesompleteUtil.itemContains(text, input.match(/[^,;]*([,;]\\s*)?$/)[0]); }});" <>
        "</script>"]}

  """
  def awesomplete(form, field, opts \\ [], awesomplete_opts) do
    script = awesomplete_js(form, field, awesomplete_opts)
    HTML.html_escape([Form.text_input(form, field, opts), script(script)])
  end

  @doc ~S"""
  This method generates a script tag with javascript code for using Awesomplete(Util).

  ## Example

      iex> PhoenixFormAwesomplete.awesomplete_script(:user, :hobby, %{ minChars: 1 } )
      {:safe,
       "<script>AwesompleteUtil.start('#user_hobby', {}, {minChars: 1});</script>"}

  """
  def awesomplete_script(form, field, awesomplete_opts) do
    script = awesomplete_js(form, field, awesomplete_opts)
    script(script)
  end

  @doc ~S"""
  This method generates javascript code for using Awesomplete(Util).

  ## Example

      iex> PhoenixFormAwesomplete.awesomplete_js(:user, :hobby, %{ minChars: 1 } )    
      "AwesompleteUtil.start('#user_hobby', {}, {minChars: 1});"

  """
  def awesomplete_js(form, field, awesomplete_opts) do
    element_id = Form.field_id(form, field)
    awesomplete_js(element_id, awesomplete_opts)
  end

  # returns filter_opts with added item
  defp addItem(filter_opts, item_fun, starts_with, multiple_char, filter_str, descr_search) do
    cond do
      is_nil(item_fun) and is_nil(multiple_char) and descr_search -> filter_opts ++ [item: "#{@util}.itemMarkAll"]
      is_nil(item_fun) and is_nil(multiple_char) -> filter_opts
      is_nil(item_fun) and starts_with -> filter_opts ++ [item: "function(text, input) { return #{@util}.itemStartsWith(text, #{filter_str}); }"]
      is_nil(item_fun) and descr_search ->  filter_opts ++ [item: "function(text, input) { return #{@util}.itemMarkAll(text, #{filter_str}); }"]
      is_nil(item_fun) ->  filter_opts ++ [item: "function(text, input) { return #{@util}.itemContains(text, #{filter_str}); }"]
      is_nil(multiple_char) -> filter_opts ++ [item: "#{item_fun}"]
      true -> filter_opts ++ [item: "function(text, input) { return (#{item_fun})(text, #{filter_str}); }"]
    end
  end

  # 
    # Be permissive about all kind of parameter combinations, except for these:
  # 
  defp parameterChecks(fld_name, label_fld, descr_fld, descr_search) do
    # We could take the default of 'value' for the 'value' parameter (a.k.a. fld_name,) but it's more clear to be explicit.
    if is_nil(fld_name)  and descr_fld != nil, do: raise ArgumentError, "'descr' without 'value' parameter."
    if is_nil(fld_name)  and label_fld != nil, do: raise ArgumentError, "'label' without 'value' parameter."
    if is_nil(descr_fld) and descr_search, do: raise ArgumentError, "Cannot search description texts without knowing the description field. Please supply descr parameter."
  end

  # 
    # Determine which characters are used to separate multiple items
    # For example in multiple color selection: red,blue,yellow the multiple_char is the comma
    # Assume space as separator if multiple=true,
  # 
  defp construct_multiple_char(multiple) do
    cond do
      is_nil(multiple) or multiple == false -> nil
      multiple == true -> " "
      true -> multiple
    end
  end

  # return list with convertInput function
  defp construct_conv_input_opts(multiple_char, conv_input_fun, conv_input_str) do
    cond do
      is_nil(multiple_char) and is_nil(conv_input_fun) -> [] 
      is_nil(multiple_char) -> [convertInput: conv_input_fun] 
      is_nil(conv_input_fun) -> [convertInput: "function(input) { return #{conv_input_str}.trim().toLowerCase(); }"]
      true -> [convertInput: "function(input) { return (#{conv_input_fun})(#{conv_input_str}.trim().toLowerCase()); }"]
    end
  end

  # define the replacement text, mainly used in the replace function
  defp construct_assign_replace_text(multiple_char) do
    if is_nil(multiple_char) do
      "text"
    else
      "this.input.value.match(/^.+[#{multiple_char}]\\s*|/)[0] + text + '" <> String.at(multiple_char, 0) <> " '"
    end
  end

  # return list with replace function
  defp construct_multiple_replace_opts(multiple_char, replace_fun, assign_replace_text) do
    cond do
      is_nil(multiple_char) -> []
      is_nil(replace_fun) -> [replace: "function(data) { var text=data.value; this.input.value = #{assign_replace_text}; }"]
      true -> [replace: "function(data) { var text=data.value; (#{replace_fun}).(#{assign_replace_text}); }"]
    end
  end

  # return javascript code for the result part of the data function
  defp construct_data_fun_result(fld_name, label_fld, descr_fld, descr_search) do
    label_str = 
      if label_fld do
        "(rec['#{label_fld}'] || '').replace('<p>', '<p >')"
      else
        "rec['#{fld_name}']"
      end

    cond do
      is_nil(descr_fld) and is_nil(label_fld) -> "rec['#{fld_name}']"
      is_nil(descr_fld) -> "{ label:#{label_str}, value:rec['#{fld_name}'] }"
      !descr_search -> "{ label: #{label_str}+'<p>'+(rec['#{descr_fld}'] || ''), value: rec['#{fld_name}'] }"
      true          -> "{ label: #{label_str}+'<p>'+(rec['#{descr_fld}'] || ''), value: rec['#{fld_name}']+'|'+(rec['#{descr_fld}'] || '').replace('|', ' ') }"
    end
  end

  # return javascript of all options
  defp construct_awe_script(element_id, util_opts_str, awe_opts_str, assign, combobox) do
    assign_var  = if assign == true,  do: "awe_#{element_id}", else: "#{assign}" 
    assign_text = if assign == false, do: "", else: "var #{assign_var}=" 

    awe_script = "#{assign_text}#{@util}.start('##{element_id}', #{util_opts_str}, #{awe_opts_str})"

    # id of the combo button. Assume awe_btn_<awesomplete element id> if combobox=true. Or take the combobox supplied value.
    combo_btn_id  = if combobox == true, do: "awe_btn_#{element_id}", else: "#{combobox}" 

    # awe_script, combobox, assign, combo_btn_id, assign_var
    cond do
       combobox == false ->    "#{awe_script};"
       assign   == false ->    "#{@util}.startClick('##{combo_btn_id}', #{awe_script});"
       true -> "#{awe_script};\n#{@util}.startClick('##{combo_btn_id}', #{assign_var});"
    end
  end
     
  @doc ~S"""
  This method generates javascript code for using Awesomplete(Util).

  ## Example

      iex> PhoenixFormAwesomplete.awesomplete_js('user_hobby', %{ minChars: 1 } ) 
      "AwesompleteUtil.start('#user_hobby', {}, {minChars: 1});"

  """
  def awesomplete_js(element_id, awesomplete_opts) do
    awesomplete_opts = Enum.to_list awesomplete_opts

    # 
      # Some of the options (data, filter, item, replace) are popped to be added later again.
      # Unrecognized options are passed on to Awesomplete.
    # 
    {ajax_fun,          awesomplete_opts} = Keyword.pop(awesomplete_opts, :ajax)
    {assign,            awesomplete_opts} = Keyword.pop(awesomplete_opts, :assign, false)
    {combobox,          awesomplete_opts} = Keyword.pop(awesomplete_opts, :combobox, false)
    {conv_input_fun,    awesomplete_opts} = Keyword.pop(awesomplete_opts, :convertInput)
    {conv_response_fun, awesomplete_opts} = Keyword.pop(awesomplete_opts, :convertResponse)
    {data_fun,          awesomplete_opts} = Keyword.pop(awesomplete_opts, :data)
    {descr_fld,         awesomplete_opts} = Keyword.pop(awesomplete_opts, :descr)
    {descr_search,      awesomplete_opts} = Keyword.pop(awesomplete_opts, :descrSearch, false) 
    {filter_fun,        awesomplete_opts} = Keyword.pop(awesomplete_opts, :filter)
    {fld_name,          awesomplete_opts} = Keyword.pop(awesomplete_opts, :value)
    {item_fun,          awesomplete_opts} = Keyword.pop(awesomplete_opts, :item)
    {label_fld,         awesomplete_opts} = Keyword.pop(awesomplete_opts, :label)
    {loadall,           awesomplete_opts} = Keyword.pop(awesomplete_opts, :loadall, false)
    {limit,             awesomplete_opts} = Keyword.pop(awesomplete_opts, :limit)
    {multiple,          awesomplete_opts} = Keyword.pop(awesomplete_opts, :multiple)
    {prepop,            awesomplete_opts} = Keyword.pop(awesomplete_opts, :prepop, false)
    {replace_fun,       awesomplete_opts} = Keyword.pop(awesomplete_opts, :replace)
    {url,               awesomplete_opts} = Keyword.pop(awesomplete_opts, :url)
    {url_end,           awesomplete_opts} = Keyword.pop(awesomplete_opts, :urlEnd)

    parameterChecks(fld_name, label_fld, descr_fld, descr_search) 

    # generated js code uses @util & @awe but in the input we expect the standard Awesomplete & AwesompleteUtil names.
    starts_with = filter_fun == "Awesomplete.FILTER_STARTSWITH" or filter_fun == "AwesompleteUtil.filterStartsWith"

    # 
      # Convert limit to integer
    # 
    limit = to_integer(limit)
    
    multiple_char = construct_multiple_char(multiple)

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

    # when there is no descr_fld or label_fld we let the data function just return one string instead of a value and label
    data_val =
      if is_nil(fld_name) or (is_nil(descr_fld) and is_nil(label_fld)) do
        "data" 
      else
        "data.value"
      end

    starts_with_filter_fun = cond do
      is_nil(descr_fld) and is_nil(label_fld) and filter_fun == "Awesomplete.FILTER_STARTSWITH" -> "#{@awe}.FILTER_STARTSWITH"
      descr_search -> "function(data, input) { return #{@util}.filterStartsWith(data, #{filter_str}) || #{@awe}.FILTER_STARTSWITH(data.value.substring(data.value.lastIndexOf('|')+1), #{filter_str}); }"
      true -> "#{@util}.filterStartsWith"
    end

    filter_opts = cond do
      is_nil(multiple_char) and is_nil(filter_fun) and data_val == "data" -> []
      is_nil(multiple_char) and is_nil(descr_fld) and is_nil(label_fld) and (is_nil(filter_fun) or filter_fun == "Awesomplete.FILTER_CONTAINS") -> []
      is_nil(multiple_char) and (is_nil(filter_fun) or filter_fun == "Awesomplete.FILTER_CONTAINS" or filter_fun == "AwesompleteUtil.filterContains") -> [filter: "#{@util}.filterContains"]
      is_nil(multiple_char) and data_val == "data" -> [filter: filter_fun]
      is_nil(multiple_char) and starts_with and is_nil(item_fun) -> [filter: starts_with_filter_fun , item: "#{@util}.itemStartsWith"]
      is_nil(multiple_char) and starts_with -> [filter: starts_with_filter_fun]
      is_nil(multiple_char) -> [filter: "function(data, input) { return (#{filter_fun})(data.value, input); }"]
      starts_with and descr_search -> [filter: starts_with_filter_fun]
      starts_with -> [filter: "function(data, input) { return #{@awe}.FILTER_STARTSWITH(#{data_val}, #{filter_str}); }"]
      is_nil(filter_fun) -> [filter: "function(data, input) { return #{@awe}.FILTER_CONTAINS(#{data_val}, #{filter_str}); }"]
      true -> [filter: "function(data, input) { return (#{filter_fun})(#{data_val}, #{filter_str}); }"]
    end 
    
    # add item: in filter_opts
    filter_opts = addItem(filter_opts, item_fun, starts_with, multiple_char, filter_str, descr_search)

    conv_input_opts = construct_conv_input_opts(multiple_char, conv_input_fun, conv_input_str)
       
    assign_replace_text = construct_assign_replace_text(multiple_char)

    multiple_replace_opts = construct_multiple_replace_opts(multiple_char, replace_fun, assign_replace_text)

    data_fun_result = construct_data_fun_result(fld_name, label_fld, descr_fld, descr_search)

    data_fun_str = 
      if is_nil(data_fun) do
        "function(rec, input) { return #{data_fun_result}; }"
      else
        "function(rec, input) { return (#{data_fun})(#{data_fun_result}, input); }"
      end

    awesomplete_opts = cond do
      is_nil(fld_name) and is_nil(data_fun) -> awesomplete_opts ++ multiple_replace_opts
      is_nil(fld_name) -> awesomplete_opts ++ [data: data_fun] ++ multiple_replace_opts
      !descr_search ->       awesomplete_opts ++ [data: data_fun_str] ++ multiple_replace_opts
      is_nil(replace_fun) -> awesomplete_opts ++ [data: data_fun_str, replace: "function(data) { var text = data.value.substring(0, data.value.lastIndexOf('|')); this.input.value = #{assign_replace_text}; }"]
      true -> awesomplete_opts ++ [data: data_fun_str, replace: "function(data) { var text = data.value.substring(0, data.value.lastIndexOf('|')); (#{replace_fun}).(#{assign_replace_text}); }"]
    end

    awesomplete_opts = awesomplete_opts ++ filter_opts
    awesomplete_opts = 
      if is_nil(replace_fun) or descr_search or multiple_char != nil do
        awesomplete_opts
      else
        awesomplete_opts ++ [replace: replace_fun] 
      end

    util_opts = if is_nil(url), do: [], else: [url: "'#{url}'"] 
    util_opts = if is_nil(url_end),  do: util_opts, else: util_opts ++ [urlEnd: "'#{url_end}'"] 
    util_opts = if is_nil(limit),    do: util_opts, else: util_opts ++ [limit: limit] 
    util_opts = if is_nil(ajax_fun), do: util_opts, else: util_opts ++ [ajax: ajax_fun] 
    util_opts = if is_nil(conv_response_fun), do: util_opts,  else: util_opts ++ [convertResponse: conv_response_fun] 
    util_opts = if loadall, do: util_opts ++ [loadall: true], else: util_opts 
    util_opts = if prepop,  do: util_opts ++ [prepop: true],  else: util_opts 
    util_opts = util_opts ++ conv_input_opts

    util_opts_str = "{" <> opts_to_string(util_opts) <> "}" 
    awe_opts_str  = "{" <> opts_to_string(awesomplete_opts) <> "}"

    construct_awe_script(element_id, util_opts_str, awe_opts_str, assign, combobox)
  end
end
