defmodule PhoenixFormAwesomplete do
  alias PhoenixFormAwesomplete.GenJS
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

      iex> {:safe, [input, script]} = PhoenixFormAwesomplete.awesomplete(:user, :drinks,
      ...> ["data-list": "beer, gin, soda, sprite, water, vodga, whine, whisky"], 
      ...> %{ minChars: 1 } )
      iex> to_string input
      "<input data-list=\"beer, gin, soda, sprite, water, vodga, whine, whisky\"" <>
      " id=\"user_drinks\" name=\"user[drinks]\" type=\"text\">"
      iex> script
      "<script>AwesompleteUtil.start('#user_drinks', {}, {minChars: 1});</script>"

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
       mix deps.compile --force phoenix_form_awesomplete
  """

  @doc ~S"""
  Create script tag with the supplied script. No defer or async because this is used for inline script.

  ## Example

      iex> PhoenixFormAwesomplete.script("alert(1);")
      {:safe, "<script>alert(1);</script>"}
  """
  def script(script)
      when is_binary(script) do
    HTML.raw("<script>#{script}</script>")
  end

  @doc ~S"""
  Same as script/1 with a second argument for the Content-Security-Policy nonce.

  ## Example

      iex> PhoenixFormAwesomplete.script("alert(1);" , "KG2FJFSN4LaCNyVRwTxRJjCB94Bdc41S")
      {:safe, "<script nonce=\"KG2FJFSN4LaCNyVRwTxRJjCB94Bdc41S\">alert(1);</script>"}
  """
  def script(script, csp_nonce)
      when is_binary(script) and is_binary(csp_nonce) and csp_nonce != "" do
    HTML.raw(~s(<script nonce="#{csp_nonce}">#{script}</script>))
  end

  @doc ~S"""
  Create javascript that listens to `awesomplete-prepop` and `awesomplete-match` events,
  and copies the `data_field` to the DOM element with the given target id.
  The `target id` is passed to the DOM document querySelector, and is typically 
  set as a hash character with an element id.
  The `target_id` can also be a javascript function.

  ## Example

      iex> ff = %Phoenix.HTML.FormField{form: "palet", field: "color", id: "palet_color", name: "palet[color]", errors: [], value: nil} 
      iex> PhoenixFormAwesomplete.copy_value_to_id_js(ff, "label", "#awe-color-result") 
      "AwesompleteUtil.startCopy('#palet_color', 'label', '#awe-color-result');"

  """
  def copy_value_to_id_js(%{id: awe_id} = _ff, data_field \\ nil, target_id) 
      when (is_nil(data_field) or is_binary(data_field)) and is_binary(target_id) do
    GenJS.copy_to_id_js("#" <> awe_id, data_field, target_id)
  end

  @doc ~S"""
  As copy_value_to_id_js/3 but with form and field parameters as used in Phoenix.HTML.Form functions
  instead of the Phoenix.HTML.FormField.

  ## Example

      iex> PhoenixFormAwesomplete.copy_to_id_js(:user, :color, "label", "#awe-color-result") 
      "AwesompleteUtil.startCopy('#user_color', 'label', '#awe-color-result');"

  """
  def copy_to_id_js(source_form, source_field, data_field \\ nil, target_id) 
      when (is_nil(data_field) or is_binary(data_field)) and is_binary(target_id) do
    source_id = "#" <> Form.input_id(source_form, source_field)
    GenJS.copy_to_id_js(source_id, data_field, target_id)
  end

  @doc ~S"""
  Create script tag with javascript that listens to `awesomplete-prepop` and `awesomplete-match` events,
  and copies the `data_field` to the DOM element with the given target id.
  The `target_id` can also be a javascript function. This function receives two parameters: event and dataField. 
  The event detail property contains an array with the matching list item. The array is empty when there is no match.

  ## Example
      iex> ff = %Phoenix.HTML.FormField{form: "palet", field: "color", id: "palet_color", name: "palet[color]", errors: [], value: nil} 
      iex> PhoenixFormAwesomplete.copy_value_to_id(ff, "label", "#awe-color-result") 
      {:safe,
       "<script>AwesompleteUtil.startCopy('#palet_color', 'label', '#awe-color-result');</script>"}

  """
  def copy_value_to_id(%{id: awe_id} = _ff, data_field \\ nil, target_id) 
      when (is_nil(data_field) or is_binary(data_field)) and is_binary(target_id) do
    script(GenJS.copy_to_id_js("#" <> awe_id, data_field, target_id))
  end

  @doc ~S"""
  As copy_value_to_id/3 but with form and field parameters as used in Phoenix.HTML.Form functions
  instead of the Phoenix.HTML.FormField.

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
  Same as copy_value_to_id/4 but with an additional last argument for the Content-Security-Policy nonce.

  ## Example

      iex> ff = %Phoenix.HTML.FormField{form: "palet", field: "color", id: "palet_color", name: "palet[color]", errors: [], value: nil} 
      iex> PhoenixFormAwesomplete.copy_value_to_id_script(ff, "label", "#awe-color-result", "KG2FJFSN4LaCNyVRwTxRJjCB94Bdc41S")
      {:safe,
       "<script nonce=\"KG2FJFSN4LaCNyVRwTxRJjCB94Bdc41S\">AwesompleteUtil.startCopy('#palet_color', 'label', '#awe-color-result');</script>"}

  """
  def copy_value_to_id_script(%{id: awe_id} = _ff, data_field \\ nil, target_id, csp_nonce) 
      when (is_nil(data_field) or is_binary(data_field))
       and is_binary(awe_id)    and awe_id != "" 
       and is_binary(target_id) and target_id != ""
       and is_binary(csp_nonce) and csp_nonce != "" do
    script(GenJS.copy_to_id_js("#" <> awe_id, data_field, target_id), csp_nonce)
  end

  @doc ~S"""
  Same as copy_to_id/4 but with an additional last argument for the Content-Security-Policy nonce.

  ## Example

      iex> PhoenixFormAwesomplete.copy_to_id_script(:user, :color, "label", "#awe-color-result", "KG2FJFSN4LaCNyVRwTxRJjCB94Bdc41S")
      {:safe,
       "<script nonce=\"KG2FJFSN4LaCNyVRwTxRJjCB94Bdc41S\">AwesompleteUtil.startCopy('#user_color', 'label', '#awe-color-result');</script>"}

  """
  def copy_to_id_script(source_form, source_field, data_field \\ nil, target_id, csp_nonce) 
      when (is_nil(data_field) or is_binary(data_field)) and is_binary(target_id) and is_binary(csp_nonce) and csp_nonce != "" do
    script(copy_to_id_js(source_form, source_field, data_field, target_id), csp_nonce)
  end

  @doc ~S"""
  Create script tag with javascript that listens to `awesomplete-prepop` and `awesomplete-match` events,
  and copies the `data_field` to the target field.

  ## Example

      iex> ff_awe = %Phoenix.HTML.FormField{form: "palet", field: "color", id: "palet_color", name: "palet[color]", errors: [], value: nil} 
      iex> ff_target = %Phoenix.HTML.FormField{form: "palet", field: "paint", id: "palet_paint", name: "palet[paint]", errors: [], value: nil} 
      iex> PhoenixFormAwesomplete.copy_value_to_field(ff_awe, "label", ff_target)  
      {:safe,
       "<script>AwesompleteUtil.startCopy('#palet_color', 'label', '#palet_paint');</script>"}

  """
  def copy_value_to_field(%{id: awe_id} = _ff, data_field \\ nil, %{id: target_id} = _target_ff) 
      when (is_nil(data_field) or is_binary(data_field)) 
       and is_binary(awe_id)    and awe_id != "" 
       and is_binary(target_id) and target_id != ""  do
    script(GenJS.copy_to_id_js("#" <> awe_id, data_field, "#" <> target_id))
  end

  @doc ~S"""
  As copy_value_to_field/3 but with form and field parameters as used in Phoenix.HTML.Form functions
  instead of the Phoenix.HTML.FormField's.

  ## Example

      iex> PhoenixFormAwesomplete.copy_to_field(:user, :color, "label", :door, :paint)  
      {:safe,
       "<script>AwesompleteUtil.startCopy('#user_color', 'label', '#door_paint');</script>"}

  """
  def copy_to_field(source_form, source_field, data_field \\ nil, target_form, target_field) 
      when is_nil(data_field) or is_binary(data_field) do
    target_id = "#" <> Form.input_id(target_form, target_field)
    script(copy_to_id_js(source_form, source_field, data_field, target_id))
  end

  @doc ~S"""
  Same as copy_value_to_field/3 but with an additional last argument for the Content-Security-Policy nonce.

  ## Example

      iex> ff_awe = %Phoenix.HTML.FormField{form: "palet", field: "color", id: "palet_color", name: "palet[color]", errors: [], value: nil} 
      iex> ff_target = %Phoenix.HTML.FormField{form: "palet", field: "paint", id: "palet_paint", name: "palet[paint]", errors: [], value: nil} 
      iex> PhoenixFormAwesomplete.copy_value_to_field_script(ff_awe, "label", ff_target, "KG2FJFSN4LaCNyVRwTxRJjCB94Bdc41S")
      {:safe,
       "<script nonce=\"KG2FJFSN4LaCNyVRwTxRJjCB94Bdc41S\">AwesompleteUtil.startCopy('#palet_color', 'label', '#palet_paint');</script>"}

  """
  def copy_value_to_field_script(%{id: awe_id} = _ff, data_field \\ nil, %{id: target_id} = _target_ff, csp_nonce) 
      when (is_nil(data_field) or is_binary(data_field)) 
       and is_binary(awe_id)    and awe_id != "" 
       and is_binary(target_id) and target_id != ""
       and is_binary(csp_nonce) and csp_nonce != "" do
    script(GenJS.copy_to_id_js("#" <> awe_id, data_field, "#" <> target_id), csp_nonce)
  end

  @doc ~S"""
  Same as copy_to_field/5 but with an additional last argument for the Content-Security-Policy nonce.

  ## Example

      iex> PhoenixFormAwesomplete.copy_to_field_script(:user, :color, "label", :door, :paint, "KG2FJFSN4LaCNyVRwTxRJjCB94Bdc41S")
      {:safe,
       "<script nonce=\"KG2FJFSN4LaCNyVRwTxRJjCB94Bdc41S\">AwesompleteUtil.startCopy('#user_color', 'label', '#door_paint');</script>"}

  """
  def copy_to_field_script(source_form, source_field, data_field \\ nil, target_form, target_field, csp_nonce) 
      when (is_nil(data_field) or is_binary(data_field)) 
       and is_binary(csp_nonce) and csp_nonce != "" do
    target_id = "#" <> Form.input_id(target_form, target_field)
    script(copy_to_id_js(source_form, source_field, data_field, target_id), csp_nonce)
  end

  @doc ~S"""
  This method generates javascript code for using Awesomplete(Util).

  ## Example

      iex> ff = %Phoenix.HTML.FormField{form: "user", field: "hobby", id: "user_hobby", name: "user[hobby]", errors: [], value: nil} 
      iex> PhoenixFormAwesomplete.awesomplete_js(ff , %{ minChars: 1 } )    
      "AwesompleteUtil.start('#user_hobby', {}, {minChars: 1});"

  """
  def awesomplete_js(%{id: awe_id} = _ff, awesomplete_opts) do
    GenJS.awesomplete_js(awe_id, awesomplete_opts)
  end

  @doc ~S"""
  This method generates javascript code for using Awesomplete(Util).

  ## Example

      iex> PhoenixFormAwesomplete.awesomplete_js(:user, :hobby, %{ minChars: 1 } )
      "AwesompleteUtil.start('#user_hobby', {}, {minChars: 1});"

  """
  def awesomplete_js(form, field, awesomplete_opts) do
    awe_id = Form.input_id(form, field)
    GenJS.awesomplete_js(awe_id, awesomplete_opts)
  end

  @doc ~S"""
  This method generates an input tag and inline javascript code that starts Awesomplete. Use this in (L)EEx templates. For HEEx templates it recommended to use <.input in combination with awesomplete_script/2.

  Awesomplete options:
   * `ajax`            - Replace ajax function. Supplied function receives these parameters: (url, urlEnd, val, fn, xhr). fn is the callback function. Default: AwesompleteUtil.ajax. 
   * `assign`          - Assign the Awesomplete object to a variable. true/false/name. If true the variable name will 'awe\_' + id of input tag. Default: false
   * `autoFirst`       - Automatically select the first element. Default: false. 
   * `combobox`        - Id of the combobox button. true/false/id. If true the assumed button id is 'awe\_btn\_' + id of the input tag. Default: false
   * `convertInput`    - Convert input function. Internally convert input for comparison with the data list items. By default it trims the input and converts it to lowercase for a case-insensitive comparison.
   * `convertResponse` - Convert JSON response from ajax calls. This function is called with the parsed JSON, and allows conversion of the data before further processing. Default: nil - no conversion. 
   * `csp_nonce`       - Content-Security-Policy nonce attribute for the script tag. Default: no nonce. If specified it must contain a non-empty value.
   * `data`            - Data function as defined in [Awesomplete](http://leaverou.github.io/awesomplete/index.html#extensibility)
   * `descr`           - Name of the field in the data list (the JSON response) that contains the description text to show below the value in the suggestion list. Default: no description
   * `descrSearch`     - Filter must also search the input value in the description field. Default: false
   * `value`           - Name of the field in the data list (the JSON response) that contains the value.
   * `filter`          - Filter function as defined in [Awesomplete](http://leaverou.github.io/awesomplete/index.html#extensibility). Mostly Awesomplete.FILTER\_STARTSWITH or Awesomplete.FILTER\_CONTAINS. If label is different as value, filter on value with AweompleteUtil.filterStartsWith or AwesompleteUtil.filterContains.
   * `item`            - Item function as defined in [Awesomplete](http://leaverou.github.io/awesomplete/index.html#extensibility). Default is to highlight all occurrences of the input text. Use AwesompleteUtil.itemStartsWith if that matches with the used filter.
   * `label`           - Name of the field in the data list (the JSON response) that contains the text that should be shown instead of the value. 
   * `list`            - Data list as defined in [Awesomplete](http://leaverou.github.io/awesomplete/index.html#extensibility).
   * `loadall`         - Data list contains all items. The input value will not be used in ajax calls. Default: false
   * `limit`           - number. If a limit is specified, and the number of items returned by the server is equal or more as this limit, the AwesompleteUtil code assumes that there are more results, so it will re-query if more characters are typed to get more refined results. The limit:1 tells that not more than 1 result is expected, so the json service doesn’t have to return an array. With limit:0 it will always re-query if more characters are typed. Default: no limit 
   * `maxItems`        - Maximum number of suggestions to display. Default: 10 
   * `minChars`        - Minimum characters the user has to type before the autocomplete popup shows up. Default: 2 
   * `multiple`        - true/false/characters. Separators to allow multiple values. If true, the separator will be the space character. Default: false
   * `prepop`          - true/false. If true do lookup initial/autofilled value and send awesomplete-prepop event. Default: false 
   * `replace`         - Replace function as defined in [Awesomplete](http://leaverou.github.io/awesomplete/index.html#extensibility)
   * `sort`            - Sort function as defined in [Awesomplete](http://leaverou.github.io/awesomplete/index.html#extensibility)
   * `url`             - url for ajax calls.
   * `urlEnd`          - Addition at the end of the url of the ajax call, after the input value. 

  ## Example

      iex> {:safe, [inp, scr]} = PhoenixFormAwesomplete.awesomplete(:user, :eyes, 
      ...> ["data-list": "blue, brown, green"],
      ...>  %{ minChars: 1, multiple: ",;", csp_nonce: "KG2FJFSN4LaCNyVRwTxRJjCB94Bdc41S" } )
      iex> to_string inp
      "<input data-list=\"blue, brown, green\" id=\"user_eyes\" name=\"user[eyes]\" type=\"text\">"
      iex> scr
      "<script nonce=\"KG2FJFSN4LaCNyVRwTxRJjCB94Bdc41S\">AwesompleteUtil.start('#user_eyes', " <> 
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
      "</script>"

  """
  def awesomplete(form, field, opts \\ [], awesomplete_opts)  
      when is_nil(opts) or is_list(opts) do
    # In HEEx it is possible to call this function with f.form, f.field, but it is better to use <.input and combine that with awesomplete_script/2
    script = awesomplete_script(form, field, awesomplete_opts)
    HTML.html_escape([Form.text_input(form, field, opts), script])
  end

  @doc ~S"""
  This method generates a script tag with javascript code for using Awesomplete(Util).

  ## Example

      iex> ff = %Phoenix.HTML.FormField{form: "user", field: "hobby", id: "user_hobby", name: "user[hobby]", errors: [], value: nil} 
      iex> PhoenixFormAwesomplete.awesomplete_script(ff, %{ minChars: 1 } )
      {:safe,
       "<script>AwesompleteUtil.start('#user_hobby', {}, {minChars: 1});</script>"}

      iex> PhoenixFormAwesomplete.awesomplete_script(:user, :hobby, %{ minChars: 1, csp_nonce: "KG2FJFSN4LaCNyVRwTxRJjCB94Bdc41S" } )
      {:safe,
       "<script nonce=\"KG2FJFSN4LaCNyVRwTxRJjCB94Bdc41S\">AwesompleteUtil.start('#user_hobby', {}, {minChars: 1});</script>"}

  """
  def awesomplete_script(%{id: awe_id} = _ff, %{csp_nonce: csp_nonce_value} = awesomplete_opts) do
    script(GenJS.awesomplete_js(awe_id, Map.delete(awesomplete_opts, :csp_nonce)), csp_nonce_value)
  end

  def awesomplete_script(%{id: awe_id} = _ff, awesomplete_opts)
      when is_list(awesomplete_opts) do
    case Keyword.has_key?(awesomplete_opts, :csp_nonce) do
       true  -> {csp_nonce_value, awesomplete_opts_remainder} = Keyword.pop!(awesomplete_opts, :csp_nonce) 
                script(GenJS.awesomplete_js(awe_id, awesomplete_opts_remainder), csp_nonce_value)
       false -> script(GenJS.awesomplete_js(awe_id, awesomplete_opts))
    end
  end

  def awesomplete_script(%{id: awe_id} = _ff, awesomplete_opts) do
    script(GenJS.awesomplete_js(awe_id, awesomplete_opts))
  end

  @doc ~S"""
  This method generates a script tag with javascript code for using Awesomplete(Util).
  As awesomplete_script/2 but with form and field parameters as used in Phoenix.HTML.Form functions
  instead of the Phoenix.HTML.FormField.


  ## Example

      iex> PhoenixFormAwesomplete.awesomplete_script(:user, :hobby, %{ minChars: 1 } )
      {:safe,
       "<script>AwesompleteUtil.start('#user_hobby', {}, {minChars: 1});</script>"}

      iex> PhoenixFormAwesomplete.awesomplete_script(:user, :hobby, %{ minChars: 1, csp_nonce: "KG2FJFSN4LaCNyVRwTxRJjCB94Bdc41S" } )
      {:safe,
       "<script nonce=\"KG2FJFSN4LaCNyVRwTxRJjCB94Bdc41S\">AwesompleteUtil.start('#user_hobby', {}, {minChars: 1});</script>"}

  """
  def awesomplete_script(form, field, %{csp_nonce: csp_nonce_value} = awesomplete_opts) do
    script(awesomplete_js(form, field, Map.delete(awesomplete_opts, :csp_nonce)), csp_nonce_value)
  end

  def awesomplete_script(form, field, awesomplete_opts)
      when is_list(awesomplete_opts) do
    case Keyword.has_key?(awesomplete_opts, :csp_nonce) do
       true  -> {csp_nonce_value, awesomplete_opts_remainder} = Keyword.pop!(awesomplete_opts, :csp_nonce) 
                script(awesomplete_js(form, field, awesomplete_opts_remainder), csp_nonce_value)
       false -> script(awesomplete_js(form, field, awesomplete_opts))
    end
  end

  def awesomplete_script(form, field, awesomplete_opts) do
    script(awesomplete_js(form, field, awesomplete_opts))
  end
end
