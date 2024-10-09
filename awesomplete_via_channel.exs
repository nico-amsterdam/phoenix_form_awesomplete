#!/usr/bin/env elixir

# run with:
#    elixir awesomplete_via_channel.exs
# when ready, open browser url:
#    http://localhost:5001

# took https://github.com/wojtekmach/mix_install_examples/blob/main/phoenix_live_view.exs
# and added Awesomplete
# switched to phoenix_playground to get LiveReload working

Application.put_env(:phoenix_playground, Demo.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 5001],
  server: true,
  live_view: [signing_salt: "aaaaaaaa"],
  secret_key_base: String.duplicate("a", 64)
)

Mix.install([
  {:phoenix_playground, "~> 0.1.7"},
  {:phoenix_form_awesomplete, "~> 1.0"},
  {:nimble_csv, "~> 1.2"}
])

#
# retrieve and filter product categories
#
defmodule Demo.Data do

  defp get_product_category_list_from_url(url) when is_binary(url) do
    # Read productcat.csv from url
    {:ok, {_status, _headers, body}} =
      :httpc.request(:erlang.binary_to_list(url))

    # productcat.csv does not contain column headers, so do not skip the first line
    body
    |> :erlang.list_to_binary
    |> NimbleCSV.RFC4180.parse_string(skip_headers: false)
    |> Stream.map(fn [name, code, descr] ->
         %{name: name, code: code, description: descr}
       end)
    |> Enum.to_list()
  end

  def init do
    # create ets table
    if Enum.member?(:ets.all(), :my_escript_cache) == false do
      :ets.new(:my_escript_cache, [:set, :public, :named_table])
    end

    list =
      "https://nico-amsterdam.github.io/awesomplete-util/csv/productcat.csv"
      |> get_product_category_list_from_url()

    :ets.insert(:my_escript_cache, {"product_category_list", list})
  end

  def get_product_category_list do
    # initialize ets table
    if Enum.member?(:ets.all(), :my_escript_cache) == false do
      init()
    end

    # get it from the ets cache
    key = "product_category_list"
    [{^key, value}] = :ets.lookup(:my_escript_cache, key)
    value
  end

  defp safe_downcase(text) do
    if is_nil(text), do: nil, else: String.downcase(text)
  end

  def filter_product_category(search_phrase) do
    search = safe_downcase(search_phrase)
    product_category_list = get_product_category_list()

    filter =
      fn rec ->
        String.contains?(String.downcase(rec.name), search) or
          String.contains?(String.downcase(rec.description), search)
      end

    Enum.filter(product_category_list, filter)
  end

end

defmodule Demo.ErrorView do
  def render(template, _), do: Phoenix.Controller.status_message_from_template(template)
end

defmodule Demo.Router do
  use Phoenix.Router
  import Phoenix.LiveView.Router

  pipeline :browser do
    plug :put_root_layout, html: {PhoenixPlayground.Layout, :root}
  end

  scope "/" do
    pipe_through :browser
    live "/", DemoLive
  end
end

defmodule Demo.Endpoint do
  use Phoenix.Endpoint, otp_app: :phoenix_playground
  plug Plug.Logger
  socket "/live", Phoenix.LiveView.Socket
  plug Plug.Static, from: {:phoenix, "priv/static"}, at: "/assets/phoenix"
  plug Plug.Static, from: {:phoenix_live_view, "priv/static"}, at: "/assets/phoenix_live_view"
  plug Plug.Static, from: {:phoenix_form_awesomplete, "priv/static"}, at: "/assets/phoenix_form_awesomplete"
  socket "/phoenix/live_reload/socket", Phoenix.LiveReloader.Socket
  plug Phoenix.LiveReloader
  plug Phoenix.CodeReloader, reloader: &PhoenixPlayground.CodeReloader.reload/2
  plug Demo.Router
end

defmodule DemoLive do
  use Phoenix.LiveView

  def mount(_params, _session, socket) do
    {:ok, assign(socket, count: 0)}
  end

  def render(assigns) do
    ~H"""
    <link href="./assets/phoenix_form_awesomplete/awesomplete_bundle.css" rel="stylesheet">
    <script type="module">
      import { AwesompleteUtil, attachAwesomplete }
        from './assets/phoenix_form_awesomplete/awesomplete_bundle.mjs'

      let Hooks = {}

      let liveSocket = new window.LiveView.LiveSocket("/live", window.Phoenix.Socket, {hooks: Hooks})

      function ajax2live(url, urlEnd, val, fn, xhr) {
        if (url && url.startsWith('livesocket:')) {
            const awe = this
                , phxEvent = url.substr(url.indexOf(':') + 1)
                , phxData = {'value':val, 'id':awe.input.id}

            // secretly use this internal function to push events
            liveSocket.execJSHookPush(awe.input, phxEvent, phxData, () => {
              console.log('requested ' + phxEvent + ' "' + val + '"')
            })
        }
        else
        {
            AwesompleteUtil.ajax(url, urlEnd, val, fn, xhr)
        }
      }

      const AU = AwesompleteUtil,
            customAwesompleteContext =
      {

        // These functions and objects can be referenced by name in mytest-autocomplete
        // This list can be customized.

          filterContains:   AU.filterContains
        , filterStartsWith: AU.filterStartsWith
        , filterWords:      AU.filterWords
        , filterOff:        AU.filterOff

        , item:             AU.item          // does NOT mark matching text
        , itemContains:     AU.itemContains  // this is the default, no need to specify it.
        , itemStartsWith:   AU.itemStartsWith
        , itemMarkAll:      AU.itemMarkAll   // also mark matching text inside the description
        , itemWords:        AU.itemWords     // mark matching words

        , jsonFlatten:      AU.jsonFlatten   // convertResponse utility to flatten JSON

        // add your custom functions and/or lists here

        , ajax2live:        ajax2live

      }

      Hooks.Autocomplete = {
        mounted() {
          this.awe = attachAwesomplete(this.el, customAwesompleteContext, {} /* defaultSettings */ )
          this.aweCallBackRef = this.handleEvent(`update-list-${this.awe.input.id}`, 
            ({searchResult, searchPhrase}) => 
              AwesompleteUtil.updateList(this.awe, searchResult, searchPhrase)
          )
        },
        // The code below in this Autocomplete hook is optional. 
        // It's useful for handling changes in the hooked element with LiveReload or via LiveView assigns.
        unmount() {
          if (this.aweCallBackRef) {
             this.removeHandleEvent(this.aweCallBackRef)
             delete this.aweCallBackRef
          }
          if (this.awe) {
            AwesompleteUtil.detach(this.awe)
            this.awe.destroy()
            delete this.awe
          }
        },
        updated() {
          this.unmount()
          this.mounted()
        },
        destroyed() {
          this.unmount()
        }
      }

      liveSocket.connect()
      liveSocket.disableDebug() // less console output
    </script>
    <style>
      /* border red/green is difficult to see with colored outline */
      input.autocomplete:focus-visible {
        outline: unset
      }
      .awesomplete ul li p {
        margin-top: 0;
        margin-bottom: 0
      }
      form {
        margin-bottom: 780px
      }
      input {
        width: 100%
      }
    </style>

    <form onsubmit="return false">

      Live view update counter:
      <p />
      <%= @count %>
      <button phx-click="inc">+</button>
      <button phx-click="dec">-</button>
      <p />
      Autocomplete:
      <p />
      <label id="mytest-label" phx-update="ignore">
        Product category
        <input name="mytest" id="mytest" type="text"
               phx-debounce="blur"
               class="autocomplete" />
      </label>

      <span id="mytest-autocomplete"
            phx-hook="Autocomplete"
            class="hidden"
            forField="mytest"
            url="livesocket:update-prodcat-list"
            ajax="ajax2live"
            maxItems="10"
            minChars="1"
            value="name"
            descr="description"
            descrSearch="true"
            ></span>

      <button type="reset">Clear</button>
    </form>
    """
  end

  def handle_event("inc", _params, socket) do
    {:noreply, update(socket, :count, &(&1 + 1))}
  end

  def handle_event("dec", _params, socket) do
    {:noreply, update(socket, :count, &(&1 - 1))}
  end

  def handle_event("update-prodcat-list", %{"value" => val, "id" => id}, socket) do
    list = Demo.Data.filter_product_category(val)
    {:noreply, push_event(socket, "update-list-#{id}", %{searchResult: list, searchPhrase: val})}
  end
end

:inets.start()
:ssl.start()
PhoenixPlayground.start(endpoint: Demo.Endpoint)

