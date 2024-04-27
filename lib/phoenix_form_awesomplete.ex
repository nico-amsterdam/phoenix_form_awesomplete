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

  The HTML combobox is very suitable for this. The combobox looks like a <select> but it doesn't limit the input. It consists of a <input type="text"> element combined with a <datalist> with <option> elements. When the standard combobox doesn't meet the requirements, a solution involving javascript can be used.
  When using LiveView the datalist of the HTML combobox can be made dynamic, with different suggestions based on the typed input. Like [this dictionary search demo](https://github.com/chrismccord/phoenix_live_view_example/blob/master/lib/demo_web/live/search_live.ex). And there are some fancy LiveView components available like the [Live Select](https://hex.pm/packages/live_select) with a stylish multiselect. These solutions are dynamic and don't necessary require a web service. However, you have to handle the input state on the server (again like [this](https://github.com/chrismccord/phoenix_live_view_example/blob/master/lib/demo_web/live/search_live.ex#L22)) and it only works in LiveView components.

  This Awesomplete component can be applied for these cases:
  - Outside and inside LiveView. It is even possible to make a HEEx fragment with autocomplete that works in both. See the next chapter.
  - It is specially suitable for suggestions supplied by HTTP web services that produce JSON.
  - It can give suggestions for a list with multiple values.
  - It doesn't force the user to pick on of the suggestions; other values can be entered.
  - It can highlight the input field when there is a match or no match.
  - The list with suggestions can be customized, for example to show an extra description.
  - The client stops interacting with the backend, and filters on it's own when enough characters have been typed and the suggestion list has become smaller than the search result limit.
  - Search requests can be cached by the browser, if the web service sets HTTP Cache headers.
  - It can fill dependend readonly fields/tags. The typical example would be a productcode with a product description shown in order lines. For the existing order lines the database can join the product description to be shown on the screen, but for new entries and when changing the productcode it has te be dynamicly looked up. This can be done while typing. After leaving the input field, the product description stays visible on the screen.

  ## Phoenix function components

  In HEEx templates and ~H sigils, function components offer a method of reuse.  
  And they make the HEEx markup arguable more readable.


  ### Use both inside and outside LiveView - via hooks

  For security reasons, LiveView doesn't execute the javascript in dynamicly loaded script tags. Adding new javascript after the page is loaded via the HTTP-request is what every malicious Cross Site Scripting (XSS) code tries to do. Via the Content-Security-Policy HTTP-header, it is possible to prevent dynamicly loaded scripts to be executed.
  In LiveView the javascript code is loaded as a static asset, and 
   [client hooks via the phx-hook](https://hexdocs.pm/phoenix_live_view/js-interop.html#client-hooks-via-phx-hook) can be used to execute javascript code for
   dynamicly added DOM elements.
  Instead of generating javascript code for every autocomplete field, a javascript hook
  is used which gets it's parameters at runtime.

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

      <.input field={@form[:country]} type="text" placeholder="Country" />

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

  ### Use outside LiveView, a.k.a. "dead" views - via page scripts

  The advantage of embedded page scripts is that anonymous functions and 
  functions defined on the same page can be used. 
  It also offers a smoother migration path from version 0.1.
  The EEx templates can be rewritten to use function components. 
  The input tag is separated from the script tag of Awesomplete,
  which makes it easier to customize the style of the input field.

  The <.autocomplete> tag in the HEEX template will produce a script in the HTML page.

  Example:

  ```elixir
  <.simple_form :let={f} for={@changeset} action={@action}>
    <.input field={f[:country]} type="text" label="Country" />
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


  ### Installation for using both inside and outside LiveView  

  - Add `phoenix_form_awesomplete`to the list of dependencies in `mix.exs`:
    ```elixir
    def deps do
      [
      {:phoenix_form_awesomplete, "~> 1.0"}
      ]
    end
    ```
  - Run
    ```sh
    mix deps.get
    ```
  - Add the import statement in assets/js/app.js
    ```javascript
    import { AwesompleteUtil, attachAwesomplete, copyValueToId } from "phoenix_form_awesomplete"
    ```
  - Add the Hooks Autocomplete and AutocompleteCopyValueToId in assets/js/app.js
    ```javascript
    const AU = AwesompleteUtil
        , customAwesompleteContext = {

      // These functions and objects can be referenced by name in the autocomplete function components.
      // This list can be customized.

      filterContains:   AU.filterContains
    , filterStartsWith: AU.filterStartsWith
    , filterWords:      AU.filterWords
    , filterOff:        AU.filterOff

    , item:             AU.item          // does NOT mark matching text 
    // , itemContains:     AU.itemContains  // this is the default, no need to specify it.
    , itemStartsWith:   AU.itemStartsWith
    , itemMarkAll:      AU.itemMarkAll   // also mark matching text inside the description
    , itemWords:        AU.itemWords     // mark matching words

      // add your custom functions and/or lists here

    }

    Hooks.Autocomplete = {
      mounted() { attachAwesomplete(this.el, customAwesompleteContext, {} /* defaultSettings */ ) }
    }

    Hooks.AutocompleteCopyValueToId = {
      mounted() { copyValueToId(this.el) }
    }
    ```
  - Add lib/<your_project>_web/components/[awesomplete_components.ex](https://github.com/nico-amsterdam/todo_trek/blob/main/lib/todo_trek_web/components/awesomplete_components.ex) 
    
    Rename the module to match your project. 
  - Add these function components in lib/<your_project>_web/components/core_components.ex:
    ```elixir
    @awesomplete <YourProject>Web.AwesompleteComponents

    defdelegate autocomplete(assigns), to: @awesomplete
    defdelegate copy_value_to_id(assigns), to: @awesomplete
    defdelegate copy_value_to_field(assigns), to: @awesomplete
    ```
  - Add in assets/css/app.css
    ```css
    @import "../../deps/phoenix_form_awesomplete/priv/static/awesomplete_bundle.css";
    ```
    If you want to modify this file, copy it to your assets/css directory and import that css file.
  - Run
    ```sh
    mix phx.server
    ```

  ### Installation for use outside LiveView only 

  - Add `phoenix_form_awesomplete`to the list of dependencies in `mix.exs`:
    ```elixir
    def deps do
      [
      {:phoenix_form_awesomplete, "~> 1.0"}
      ]
    end
    ```
  - Run
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
  - Add this code in assets/js/app.js
    ```javascript
    import { Awesomplete, AwesompleteUtil } from "phoenix_form_awesomplete"
    ```
  - In lib/<your_project>_web/components/layouts/root.html.heex remove 'defer' for app.js:
    ```elixir
    <script phx-track-static src={~p"/assets/js/app.js"}></script>
    ```
    Awesomplete and AwesompleteUtil must be loaded before running the inline scripts.
  - Add in assets/css/app.css
    ```elixir
    @import "../../deps/phoenix_form_awesomplete/priv/static/awesomplete_bundle.css";
    ```
    If you want to modify this file, copy it to your assets/css directory and import that css file.
  - Run
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


  It is possible to use aliases for the javascript library references in the generated page scripts 
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
    {:safe, attributes} = HTML.attributes_escape(script_attributes)
    HTML.raw(~s(<script#{attributes}>#{script}</script>))
  end

  @doc ~S"""
  Same as script/1 with a second argument for the script attributes.

  ## Example

      iex> PhoenixFormAwesomplete.script("alert(1);" , [nonce: "KG2FJFSN4LaCNyVRwTxRJjCB94Bdc41S"])
      {:safe, "<script nonce=\"KG2FJFSN4LaCNyVRwTxRJjCB94Bdc41S\">alert(1);</script>"}

      iex> PhoenixFormAwesomplete.script("alert(2);" , %{nonce: "KG2FJFSN4LaCNyVRwTxRJjCB94Bdc41S"})
      {:safe, "<script nonce=\"KG2FJFSN4LaCNyVRwTxRJjCB94Bdc41S\">alert(2);</script>"}

      iex> PhoenixFormAwesomplete.script("alert(3);" , %{type: "module", id: "x42"})
      {:safe, "<script id=\"x42\" type=\"module\">alert(3);</script>"}

  """
  def script(script, [])
      when is_binary(script) do
    HTML.raw("<script>#{script}</script>")
  end

  def script(script, script_attributes)
      when is_binary(script) 
      and script_attributes == %{} do
    HTML.raw("<script>#{script}</script>")
  end

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

  # Function below is a text_input replacement.
  # The text_input is removed from Phoenix.HTML.Form in Phoenix.HTML version 4.0.
  # Avoid a new dependency with PhoenixHTMLHelpers, which is meant for compatibility with old Phoenix versions,
  # and undesirable for most projects.
  # text_input will not be called anyway when using the supplied function components,
  # because these separate the input tag from the awesomplete script.
  defp text_input(form, field, opts) do
    {:safe, attributes} = 
      opts
      |> Keyword.put_new(:id,     Form.input_id(form, field))
      |> Keyword.put_new(:name, Form.input_name(form, field))
      |> Keyword.put_new(:type, "text")
      |> Enum.sort
      |> HTML.attributes_escape
    HTML.raw(~s(<input#{attributes}>))
  end

  @doc ~S"""
  This method generates an input tag and inline javascript code that starts Awesomplete. Use this in (L)EEx templates. For HEEx templates it recommended to use <.input in combination with awesomplete_script/2.

  Awesomplete options:
   * `ajax`            - Replace ajax function. Supplied function receives these parameters: (url, urlEnd, val, fn, xhr). fn is the callback function. Default: AwesompleteUtil.ajax. 
   * `assign`          - Assign the Awesomplete object to a variable. true/false/name. If true the variable name will be 'awe\_' + id of input tag. Default: false
   * `autoFirst`       - true/false. Automatically select the first element. Default: false. 
   * `combobox`        - Id of the combobox button. true/false/id. If true the assumed button id is 'awe\_btn\_' + id of the input tag. Default: false
   * `container`       - Container function as defined in [Awesomplete](http://leaverou.github.io/awesomplete/index.html#extensibility). By default a div element is added as the parent of the input element.
   * `convertInput`    - Convert input function. Internally convert input for comparison with the data list items. By default it trims the input and converts it to lowercase for a case-insensitive comparison.
   * `convertResponse` - Convert JSON response from ajax calls. This function is called with the parsed JSON, and allows conversion of the data before further processing. Default: nil - no conversion. 
   * `data`            - Data function as defined in [Awesomplete](http://leaverou.github.io/awesomplete/index.html#extensibility)
   * `debounce`        - Time in milliseconds to wait for additional user input before doing the ajax call to retrieve suggestions. It limits the rate at which the json service is called per user session.
   * `descr`           - Name of the field in the data list (the JSON response) that contains the description text to show below the value in the suggestion list. Default: no description
   * `descrSearch`     - true/false. Filter must also search the input value in the description field. Default: false
   * `filter`          - Filter function as defined in [Awesomplete](http://leaverou.github.io/awesomplete/index.html#extensibility). Mostly use Awesomplete.FILTER\_STARTSWITH or Awesomplete.FILTER\_CONTAINS. If label is different as value, filter on value with AweompleteUtil.filterStartsWith, AwesompleteUtil.filterContains or AwesompleteUtil.filterWords. To turn off filtering, use AwesompleteUtil.filterOff.
   * `item`            - Item function as defined in [Awesomplete](http://leaverou.github.io/awesomplete/index.html#extensibility). Default is to highlight all occurrences of the input text. Use AwesompleteUtil.itemStartsWith if that matches with the used filter.
   * `label`           - Name of the field in the data list (the JSON response) that contains the text that should be shown instead of the value. 
   * `list`            - Data list as defined in [Awesomplete](http://leaverou.github.io/awesomplete/index.html#extensibility).
   * `listLabel`       - Denotes a label to be used as aria-label on the generated autocomplete list.
   * `loadall`         - true/false. Use true if the data list contains all items, and the input value should not be used in ajax calls. Default: false
   * `limit`           - number. If a limit is specified, and the number of items returned by the server is equal or more as this limit, the AwesompleteUtil code assumes that there are more results, so it will re-query if more characters are typed to get more refined results. The limit:1 tells that not more than 1 result is expected, so the json service doesn’t have to return an array. With limit:0 it will always re-query if more characters are typed and the result doesn't have to be an array either. Limit:-1 will always requery and the expected result is an array. When no limit is specified, the code assumes that all possible suggestions are returned based on the typed characters, and it will not re-query if more characters are typed. It uses the specified filter for the suggestions in the dropdown. Default: no limit 
   * `maxItems`        - Maximum number of suggestions to display. Default: 10 
   * `minChars`        - Minimum characters the user has to type before the autocomplete popup shows up. Default: 2 
   * `multiple`        - true/false/characters. Separators to allow multiple values. If true, the separator will be the space character. Default: false
   * `nonce`           - Content-Security-Policy nonce attribute for the script tag. Default: no nonce. If specified it must contain a non-empty value.
   * `prepop`          - true/false. If true do lookup initial/autofilled value and send awesomplete-prepop event. Default: false 
   * `replace`         - Replace function as defined in [Awesomplete](http://leaverou.github.io/awesomplete/index.html#extensibility)
   * `sort`            - Sort function as defined in [Awesomplete](http://leaverou.github.io/awesomplete/index.html#extensibility)
   * `statusNoResults` - Screen reader text to replace the default: 'No results found'
   * `statusTypeXChar` - Screen reader text to replace the default: 'Type {0} or more characters for results'. The placeholder {0} will be replaced with the minimum number of characters (minChars).
   * `statusXResults`  - Screen reader text to replace the default: '{0} results found'. The placeholder {0} will be replaced with the number of results.
   * `url`             - url for ajax calls.
   * `urlEnd`          - Addition at the end of the url for the ajax call, after the input value. Or a function, which receives the value and must return the last part of the url after the base url. 
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
    script = awesomplete_script(form, field, awesomplete_opts)
    input = text_input(form, field, opts)
    HTML.html_escape([input, script])
  end

  # extract nonce, type and id from awesomplete_opts to script_opts
  # return {script_opts, awesomplete_opts}
  defp extract_script_options(awesomplete_opts)
      when is_list(awesomplete_opts) do

    {script_id, awesomplete_opts} = Keyword.pop(awesomplete_opts, :id)
    {type,      awesomplete_opts} = Keyword.pop(awesomplete_opts, :type)

    script_opts = if !is_nil(script_id), do: %{id: script_id}, else: %{}
    script_opts = if !is_nil(type), do: Map.put(script_opts, :type, type), else: script_opts

    # Empty nonce is also past on for error handling.
    if Keyword.has_key?(awesomplete_opts, :nonce) do
        {csp_nonce_value, awesomplete_opts_remainder} = Keyword.pop!(awesomplete_opts, :nonce)
        {Map.put(script_opts, :nonce, csp_nonce_value), awesomplete_opts_remainder}
    else
        {script_opts, awesomplete_opts}
    end
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
  def awesomplete_script(%{id: _awe_id} = ff, %{} = awesomplete_opts) do
    awesomplete_script(ff, Enum.to_list(awesomplete_opts))
  end

  def awesomplete_script(%{id: awe_id} = _ff, awesomplete_opts)
      when is_list(awesomplete_opts) do

    {script_opts, awesomplete_opts} = extract_script_options(awesomplete_opts)

    script(GenJS.awesomplete_js(awe_id, awesomplete_opts), script_opts)
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
  def awesomplete_script(form, field, %{} = awesomplete_opts) do
    awesomplete_script(form, field, Enum.to_list(awesomplete_opts))
  end

  def awesomplete_script(form, field, awesomplete_opts)
      when is_list(awesomplete_opts) do

    {script_opts, awesomplete_opts} = extract_script_options(awesomplete_opts)

    script(awesomplete_js(form, field, awesomplete_opts), script_opts)
  end
end
