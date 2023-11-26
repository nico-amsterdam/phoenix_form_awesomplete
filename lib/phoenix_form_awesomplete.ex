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

  [Online demo](https://nico-amsterdam.github.io/awesomplete-util/phoenix.html)

  ## Use cases

  An autocomplete component is a free text input that provides suggestions while typing. It is not necessary to choose one of the suggestions, but of course a form validator can reject disallowed input.

  The HTML combobox is very suitable for this. It is a combination of a <select> with a <input type="text"> element, and it has a <datalist> with <option> and <optgroup> elements. When the standard combobox doesn't meet the requirements, a solution involving javascript can be used.
  When using LiveView the datalist of the HTML combobox can be made dynamic, with different suggestions based on the typed input. Like [this dictionary search demo](https://github.com/chrismccord/phoenix_live_view_example/blob/master/lib/demo_web/live/search_live.ex). And there are some fancy LiveView components available like the [Live Select](https://hex.pm/packages/live_select) with a stylish multiselect. These solutions are dynamic and don't necessary require a web service. However, you have to handle the input state on the server (again like [this](https://github.com/chrismccord/phoenix_live_view_example/blob/master/lib/demo_web/live/search_live.ex#L22)) and it only works in LiveView components.

  This Awesomplete component can be applied for these cases:
  - Outside and inside LiveView. It is even possible to make a HEEx fragment with autocomplete that works in both. See next chapter.
  - It is specially suitable for suggestions supplied by Http web services that produce JSON.
  - It can give suggestions for a list with multiple values.
  - It doesn't force the user to pick on of the suggestions; other values can be entered.
  - It can highlight the input field if there is a match or no match.
  - The list with suggestions can be customized, for example to show an extra description.
  - The client stops interacting with the backend and filters on it's own when enough characters have been typed and the suggestionlist has become smaller than the search result limit.
  - It can fill dependend readonly fields/tags. The typical example would be a productcode with a product description shown in order lines. For the existing order lines the database can join the product description to be shown on the screen, but for new entries and when changing the productcode it has te be dynamicly looked up. This can be done while typing. After leaving the input field, the product description stays visible on the screen.

  ## Phoenix function components

  In HEEx templates and ~H sigils, function components offer a method of reuse.  
  And they make the HEEx markup arguable more readable.

  ### Outside LiveView, a.k.a. "dead" views

  When currently using Awesomplete, the templates can easily be rewritten to use
  function components. The input tag is seperated from the script tag of Awesomplete,
  which makes it easier to customize the style of the input field.

  Example:

  ```elixir
  <.simple_form :let={f} for={@changeset} action={@action}>
    <.input field={f[:country]} type="text" label="Country" autocomplete="off" />
    <.autocomplete    forField={f[:country]}
                      url="https://restcountries.com/v2/all"
                      loadall="true"
                      prepop="true"
                      minChars="1" 
                      maxItems="8" 
                      value="name"
                      nonce={@script_src_nonce}
                      />
  </.simple_form>
  ```

  The nonce in the example above, is to allow inline script to be executed
  in combination with a Content-Security-Policy that doesn't 
  allow unsafe evals or unsafe inline scripts.

  ### Both inside and outside LiveView

  For security reasons, LiveView doesn't execute the javascript in dynamicly loaded script tags. Adding new javascript after the page is loaded via HTTP-request is what every malicious Cross Site Scripting (XSS) code tries to do. Via the Content-Security-Policy http header, it is possible to prevent dynamicly loaded script to be executed.
  In LiveView the javascript code is loaded as a static asset, and 
   [client hooks via phx-hook](https://hexdocs.pm/phoenix_live_view/js-interop.html#client-hooks-via-phx-hook) can be used to execute javascript code for
   dynamicly added DOM elements.
  Instead of generating javascript code for every autocomplete field, a javascript hook
  is used which gets it's parameters at runtime. This javascript hook can handle the straightforward cases, but could need some tweaking for the corner cases. If these corner cases are complex and only applicable for a small subset of pages/components, you might consider to split off new client hooks.

  The beauty of the client hooks is that this can be used both inside and outside LiveView as they both use the mounted callback. This makes it possible define a reusable component with autocomplete fields, which can be incorporated inside and outside LiveView.

  Example:

  ```elixir
  <.simple_form
    for={@form}
    id="list-form"
    phx-target={@myself}
    phx-change="validate"
    phx-submit="save"
  >
    <div phx-update="ignore" id={"#{@form[:country].id}-domspace"}>

      <.input field={@form[:country]} type="text" placeholder="Country" autocomplete="off" />

      <.autocomplete    forField={@form[:country]}
                        url="https://restcountries.com/v2/all"
                        loadall="true"
                        prepop="true"
                        minChars="1" 
                        maxItems="8" 
                        value="name"                          
                        />

    </div>
  </.simple_form>
  ```
 
  ## Security

  ### Content-Security-Policy

  As mentioned before, use a safe Content-Security-Policy (CSP):
  - do not allow unsafe eval
  - do not allow unsafe inline script
  - In the connect_src whitelist only the url's of trusted sites. Make sure that the url's of Awesomplete cannot be tampered with.

  ### Trusted web services

  Use only trusted web services. As an extra safety measure it possible to sanatize or escape HTML in the JSON responses via a convertResponse function. As external web services 
  are used directly, than this service will not only see the searched text but also the
  client IP address. 

  
  ## Installation

  ### Installation for use outside LiveView only 

  - Add `phoenix_form_awesomplete`to the list of dependencies in `mix.exs`:
    ```elixir
    def deps do
      [
      {:phoenix_form_awesomplete, "~> 0.2"}
      ]
    end
    ```
  - run
    ```sh
    mix deps.get
    ```
  - Add lib/<your_project>_web/components/[awesomplete_script_components.ex](https://github.com/nico-amsterdam/phoenix-csp-outside-liveview/blob/main/hello_world/lib/hello_world_web/components/awesomplete_script_components.ex).

    Rename the module to match your project. 
  - Add these function components in lib/<your_project>_web/components/core_components.ex:
    ```elixir
    @awesomplete <YourProject>Web.AwesompleteScriptComponents

    defdelegate autocomplete(assigns), to: @awesomplete
    defdelegate copy_value_to_id(assigns), to: @awesomplete
    defdelegate copy_value_to_field(assigns), to: @awesomplete
    ``` 
  - copy [awesomplete.css](https://github.com/LeaVerou/awesomplete/blob/gh-pages/awesomplete.css) to assets/css 
  - copy [awesomplete-util.min.js](https://nico-amsterdam.github.io/awesomplete-util/js/awesomplete-util.min.js) to assets/vendor
  - copy [awesomplete-v2020.min.js](https://nico-amsterdam.github.io/awesomplete-util/js/awesomplete-v2020.min.js) to assets/vendor
  - create assets/js/awesomplete.js:
    ```elixir
    import Awesomplete from '../vendor/awesomplete-v2020.min.js'
    import AwesompleteUtil from '../vendor/awesomplete-util.min.js'

    // expose Awesomplete
    window.Awesomplete = Awesomplete
    window.AwesompleteUtil = AwesompleteUtil
    ```
  - in config/config.exs add awesomplete.css and awesomplete.js in the esbuild config:
    ```elixir
    ~w(js/app.js js/awesomplete.js css/awesomplete.css --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    ```
  - add in assets/css/app.css
    ```elixir
    @import "awesomplete.css";
    ```
  - add styles in assets/css/app.css
    ```css
    /*
    * Awesomplete
    */
    div.awesomplete {display: block}
    div.awesomplete ul li p {display: block; font-size: small; margin-left: 1em}
    div.awesomplete .awe-found {border: 2px solid green}
    .hide-not-found div.awesomplete .awe-not-found {border-color: lightblue}
    div.awesomplete .awe-not-found {border: 2px solid red}
    .awe-btn .caron { pointer-events: none }
    ```
  - In lib/<your_project>_web/components/layouts/root.html.heex add this to the head:
    ```elixir
    <script phx-track-static src={~p"/assets/js/awesomplete.js"}></script>
    <link rel="stylesheet" href={~p"/assets/css/awesomplete.css"}>
    ```
  - run
    ```sh
    mix phx.server
    ```



  ### Installation for using both inside and outside LiveView  

  - Add the [Hooks Autocomplete and AutocompleteCopyValueToId](https://github.com/nico-amsterdam/todo_trek/blob/main/assets/js/app.js#L78) in assets/js/app.js
  - Add lib/<your_project>_web/components/[awesomplete_components.ex](https://github.com/nico-amsterdam/todo_trek/blob/main/lib/todo_trek_web/components/awesomplete_components.ex) 
    
    Rename the module to match your project. 
  - Add these function components in lib/<your_project>_web/components/core_components.ex:
    ```elixir
    @awesomplete <YourProject>Web.AwesompleteComponents

    defdelegate autocomplete(assigns), to: @awesomplete
    defdelegate copy_value_to_id(assigns), to: @awesomplete
    defdelegate copy_value_to_field(assigns), to: @awesomplete
    ```
  - copy [awesomplete-util.min.js](https://nico-amsterdam.github.io/awesomplete-util/js/awesomplete-util.min.js) to assets/vendor
  - copy [awesomplete-v2020.min.js](https://nico-amsterdam.github.io/awesomplete-util/js/awesomplete-v2020.min.js) to assets/vendor
  - in assets/js/app.js add:
    ```elixir
    import Awesomplete from '../vendor/awesomplete-v2020.min.js'
    import AwesompleteUtil from '../vendor/awesomplete-util.min.js'
    ```
  - copy [awesomplete.css](https://github.com/LeaVerou/awesomplete/blob/gh-pages/awesomplete.css) to assets/css 
  - in config/config.exs add awesomplete.css in the esbuild config:
    ```elixir
    ~w(js/app.js css/awesomplete.css --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    ```
  - add in assets/css/app.css
    ```elixir
    @import "awesomplete.css";
    ```
  - add styles in assets/css/app.css
    ```css
    /*
    * Awesomplete
    */
    div.awesomplete {display: block}
    div.awesomplete ul li p {display: block; font-size: small; margin-left: 1em}
    div.awesomplete .awe-found {border: 2px solid green}
    .hide-not-found div.awesomplete .awe-not-found {border-color: lightblue}
    div.awesomplete .awe-not-found {border: 2px solid red}
    .awe-btn .caron { pointer-events: none }
    ```
  - lib/<your_project>_web/components/layouts/root.html.heex add this to the head:
    ```elixir
    <link rel="stylesheet" href={~p"/assets/css/awesomplete.css"}>
    ```
  - run
    ```sh
    mix phx.server
    ```

  ## PhoenixFormAwesomplete raw example

  ### IEx

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
  
  defp script_to_html(script, script_attributes) do
    attributes = Enum.map_join(script_attributes, " ", fn{k, v} -> "#{k}=\"#{v}\"" end)
    HTML.raw(~s(<script #{attributes}>#{script}</script>))
  end

  @doc ~S"""
  Same as script/1 with a second argument for the script attributes.

  ## Example

      iex> PhoenixFormAwesomplete.script("alert(1);" , [nonce: "KG2FJFSN4LaCNyVRwTxRJjCB94Bdc41S"])
      {:safe, "<script nonce=\"KG2FJFSN4LaCNyVRwTxRJjCB94Bdc41S\">alert(1);</script>"}

      iex> PhoenixFormAwesomplete.script("alert(2);" , %{nonce: "KG2FJFSN4LaCNyVRwTxRJjCB94Bdc41S"})
      {:safe, "<script nonce=\"KG2FJFSN4LaCNyVRwTxRJjCB94Bdc41S\">alert(2);</script>"}

  """
  def script(script, script_attributes)
      when is_binary(script)
       and is_list(script_attributes) do
    # It is easy to make mistakes when passing the nonce. Fail early.
    if Keyword.has_key?(script_attributes, :nonce) do
      if length(Keyword.get_values(script_attributes, :nonce)) > 1, do: raise(ArgumentError, "Script with multiple nonce attributes")
      :ok = case Keyword.get(script_attributes, :nonce) do
         nil -> raise(ArgumentError, "Script nonce attribute is nil") 
         "" -> raise(ArgumentError, "Script nonce attribute is empty") 
         _ -> :ok
      end
    end
    script_to_html(script, script_attributes)
  end

  def script(script, %{nonce: csp_nonce_value} = script_attributes)
      when is_binary(script) do
    :ok = case csp_nonce_value do
         nil -> raise(ArgumentError, "Script nonce attribute is nil") 
         "" -> raise(ArgumentError, "Script nonce attribute is empty") 
         _ -> :ok
    end
    script_to_html(script, script_attributes)
  end

  def script(script, %{} = script_attributes)
      when is_binary(script) do
    script_to_html(script, script_attributes)
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
  The source_form and target_form parameters are either a Phoenix.HTML.Form struct or an atom.

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
  The `target id` is passed to the DOM document querySelector, and is typically 
  set as a hash character with an element id.
  The `target_id` can also be a javascript function.

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
  The source_form parameter is either a Phoenix.HTML.Form struct or an atom.

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
  Same as copy_value_to_id/4 but with an additional last argument for script attributes.

  ## Example

      iex> ff = %Phoenix.HTML.FormField{form: "palet", field: "color", id: "palet_color", name: "palet[color]", errors: [], value: nil} 
      iex> PhoenixFormAwesomplete.copy_value_to_id_script(ff, "label", "#awe-color-result", [nonce: "KG2FJFSN4LaCNyVRwTxRJjCB94Bdc41S"])
      {:safe,
       "<script nonce=\"KG2FJFSN4LaCNyVRwTxRJjCB94Bdc41S\">AwesompleteUtil.startCopy('#palet_color', 'label', '#awe-color-result');</script>"}

  """
  def copy_value_to_id_script(%{id: awe_id} = _ff, data_field \\ nil, target_id, script_attributes) 
      when (is_nil(data_field) or is_binary(data_field))
       and is_binary(awe_id)    and awe_id != "" 
       and is_binary(target_id) and target_id != "" do
    script(GenJS.copy_to_id_js("#" <> awe_id, data_field, target_id), script_attributes)
  end

  @doc ~S"""
  Same as copy_to_id/4 but with an additional last argument for the script attributes.

  ## Example

      iex> PhoenixFormAwesomplete.copy_to_id_script(:user, :color, "label", "#awe-color-result", [nonce: "KG2FJFSN4LaCNyVRwTxRJjCB94Bdc41S"])
      {:safe,
       "<script nonce=\"KG2FJFSN4LaCNyVRwTxRJjCB94Bdc41S\">AwesompleteUtil.startCopy('#user_color', 'label', '#awe-color-result');</script>"}

  """
  def copy_to_id_script(source_form, source_field, data_field \\ nil, target_id, script_attributes) 
      when (is_nil(data_field) or is_binary(data_field))
       and is_binary(target_id) do
    script(copy_to_id_js(source_form, source_field, data_field, target_id), script_attributes)
  end

  @doc ~S"""
  Create script tag with javascript that listens to `awesomplete-prepop` and `awesomplete-match` events on the source form field,
  and copies the `data_field` to the target form field.

  ## Example

      iex> ff_source = %Phoenix.HTML.FormField{form: "palet", field: "color", id: "palet_color", name: "palet[color]", errors: [], value: nil} 
      iex> ff_target = %Phoenix.HTML.FormField{form: "palet", field: "paint", id: "palet_paint", name: "palet[paint]", errors: [], value: nil} 
      iex> PhoenixFormAwesomplete.copy_value_to_field(ff_source, "label", ff_target)  
      {:safe,
       "<script>AwesompleteUtil.startCopy('#palet_color', 'label', '#palet_paint');</script>"}

  """
  def copy_value_to_field(%{id: source_id} = _source_ff, data_field \\ nil, %{id: target_id} = _target_ff) 
      when (is_nil(data_field) or is_binary(data_field)) 
       and is_binary(source_id) and source_id != "" 
       and is_binary(target_id) and target_id != ""  do
    script(GenJS.copy_to_id_js("#" <> source_id, data_field, "#" <> target_id))
  end

  @doc ~S"""
  As copy_value_to_field/3 but with form and field parameters as used in Phoenix.HTML.Form functions
  instead of the Phoenix.HTML.FormField's. 
  The source_form and target_form parameters are either a Phoenix.HTML.Form struct or an atom.

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
  Same as copy_value_to_field/3 but with an additional last argument for the script attributes.

  ## Example

      iex> ff_source = %Phoenix.HTML.FormField{form: "palet", field: "color", id: "palet_color", name: "palet[color]", errors: [], value: nil} 
      iex> ff_target = %Phoenix.HTML.FormField{form: "palet", field: "paint", id: "palet_paint", name: "palet[paint]", errors: [], value: nil} 
      iex> PhoenixFormAwesomplete.copy_value_to_field_script(ff_source, "label", ff_target, [nonce: "KG2FJFSN4LaCNyVRwTxRJjCB94Bdc41S"])
      {:safe,
       "<script nonce=\"KG2FJFSN4LaCNyVRwTxRJjCB94Bdc41S\">AwesompleteUtil.startCopy('#palet_color', 'label', '#palet_paint');</script>"}

  """
  def copy_value_to_field_script(%{id: source_id} = _source_ff, data_field \\ nil, %{id: target_id} = _target_ff, script_attributes) 
      when (is_nil(data_field) or is_binary(data_field)) 
       and is_binary(source_id) and source_id != "" 
       and is_binary(target_id) and target_id != "" do
    script(GenJS.copy_to_id_js("#" <> source_id, data_field, "#" <> target_id), script_attributes)
  end

  @doc ~S"""
  Same as copy_to_field/5 but with an additional last argument for the script attributes.

  ## Example

      iex> PhoenixFormAwesomplete.copy_to_field_script(:user, :color, "label", :door, :paint, [nonce: "KG2FJFSN4LaCNyVRwTxRJjCB94Bdc41S"])
      {:safe,
       "<script nonce=\"KG2FJFSN4LaCNyVRwTxRJjCB94Bdc41S\">AwesompleteUtil.startCopy('#user_color', 'label', '#door_paint');</script>"}

  """
  def copy_to_field_script(source_form, source_field, data_field \\ nil, target_form, target_field, script_attributes) 
      when (is_nil(data_field) or is_binary(data_field)) do
    target_id = "#" <> Form.input_id(target_form, target_field)
    script(copy_to_id_js(source_form, source_field, data_field, target_id), script_attributes)
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
   * `data`            - Data function as defined in [Awesomplete](http://leaverou.github.io/awesomplete/index.html#extensibility)
   * `debounce`        - Time in milliseconds to wait for additional user input before doing the ajax call to retrieve suggestions. It limits the rate at which the json service is called per user session.
   dd, making e this to reduce the frequency of ajax calls.
   * `descr`           - Name of the field in the data list (the JSON response) that contains the description text to show below the value in the suggestion list. Default: no description
   * `descrSearch`     - Filter must also search the input value in the description field. Default: false
   * `filter`          - Filter function as defined in [Awesomplete](http://leaverou.github.io/awesomplete/index.html#extensibility). Mostly Awesomplete.FILTER\_STARTSWITH or Awesomplete.FILTER\_CONTAINS. If label is different as value, filter on value with AweompleteUtil.filterStartsWith or AwesompleteUtil.filterContains.
   * `item`            - Item function as defined in [Awesomplete](http://leaverou.github.io/awesomplete/index.html#extensibility). Default is to highlight all occurrences of the input text. Use AwesompleteUtil.itemStartsWith if that matches with the used filter.
   * `label`           - Name of the field in the data list (the JSON response) that contains the text that should be shown instead of the value. 
   * `list`            - Data list as defined in [Awesomplete](http://leaverou.github.io/awesomplete/index.html#extensibility).
   * `loadall`         - Data list contains all items. The input value will not be used in ajax calls. Default: false
   * `limit`           - number. If a limit is specified, and the number of items returned by the server is equal or more as this limit, the AwesompleteUtil code assumes that there are more results, so it will re-query if more characters are typed to get more refined results. The limit:1 tells that not more than 1 result is expected, so the json service doesn’t have to return an array. With limit:0 it will always re-query if more characters are typed. Default: no limit 
   * `maxItems`        - Maximum number of suggestions to display. Default: 10 
   * `minChars`        - Minimum characters the user has to type before the autocomplete popup shows up. Default: 2 
   * `multiple`        - true/false/characters. Separators to allow multiple values. If true, the separator will be the space character. Default: false
   * `nonce`           - Content-Security-Policy nonce attribute for the script tag. Default: no nonce. If specified it must contain a non-empty value.
   * `prepop`          - true/false. If true do lookup initial/autofilled value and send awesomplete-prepop event. Default: false 
   * `replace`         - Replace function as defined in [Awesomplete](http://leaverou.github.io/awesomplete/index.html#extensibility)
   * `sort`            - Sort function as defined in [Awesomplete](http://leaverou.github.io/awesomplete/index.html#extensibility)
   * `url`             - url for ajax calls.
   * `urlEnd`          - Addition at the end of the url of the ajax call, after the input value. 
   * `value`           - Name of the field in the data list (the JSON response) that contains the value.

  ## Example

      iex> {:safe, [inp, scr]} = PhoenixFormAwesomplete.awesomplete(:user, :eyes, 
      ...> ["data-list": "blue, brown, green"],
      ...>  %{ minChars: 1, multiple: ",;", nonce: "KG2FJFSN4LaCNyVRwTxRJjCB94Bdc41S" } )
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

      iex> PhoenixFormAwesomplete.awesomplete_script(:user, :hobby, %{ minChars: 1, nonce: "KG2FJFSN4LaCNyVRwTxRJjCB94Bdc41S" } )
      {:safe,
       "<script nonce=\"KG2FJFSN4LaCNyVRwTxRJjCB94Bdc41S\">AwesompleteUtil.start('#user_hobby', {}, {minChars: 1});</script>"}

  """
  def awesomplete_script(%{id: awe_id} = _ff, %{nonce: csp_nonce_value} = awesomplete_opts) do
    script(GenJS.awesomplete_js(awe_id, Map.delete(awesomplete_opts, :nonce)), %{nonce: csp_nonce_value})
  end

  def awesomplete_script(%{id: awe_id} = _ff, awesomplete_opts)
      when is_list(awesomplete_opts) do
    case Keyword.has_key?(awesomplete_opts, :nonce) do
       true  -> {csp_nonce_value, awesomplete_opts_remainder} = Keyword.pop!(awesomplete_opts, :nonce) 
                script(GenJS.awesomplete_js(awe_id, awesomplete_opts_remainder), %{nonce: csp_nonce_value})
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
  The form parameter is either a Phoenix.HTML.Form struct or an atom.

  ## Example

      iex> PhoenixFormAwesomplete.awesomplete_script(:user, :hobby, %{ minChars: 1 } )
      {:safe,
       "<script>AwesompleteUtil.start('#user_hobby', {}, {minChars: 1});</script>"}

      iex> PhoenixFormAwesomplete.awesomplete_script(:user, :hobby, %{ minChars: 1, nonce: "KG2FJFSN4LaCNyVRwTxRJjCB94Bdc41S" } )
      {:safe,
       "<script nonce=\"KG2FJFSN4LaCNyVRwTxRJjCB94Bdc41S\">AwesompleteUtil.start('#user_hobby', {}, {minChars: 1});</script>"}

  """
  def awesomplete_script(form, field, %{nonce: csp_nonce_value} = awesomplete_opts) do
    script(awesomplete_js(form, field, Map.delete(awesomplete_opts, :nonce)), %{nonce: csp_nonce_value})
  end

  def awesomplete_script(form, field, awesomplete_opts)
      when is_list(awesomplete_opts) do
    case Keyword.has_key?(awesomplete_opts, :nonce) do
       true  -> {csp_nonce_value, awesomplete_opts_remainder} = Keyword.pop!(awesomplete_opts, :nonce) 
                script(awesomplete_js(form, field, awesomplete_opts_remainder), %{nonce: csp_nonce_value})
       false -> script(awesomplete_js(form, field, awesomplete_opts))
    end
  end

  def awesomplete_script(form, field, awesomplete_opts) do
    script(awesomplete_js(form, field, awesomplete_opts))
  end
end
