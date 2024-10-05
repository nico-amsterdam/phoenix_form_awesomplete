
# run with:
#    elixir awesomplete_via_channels.exs
# when ready, open browser url:
#    http://localhost:5001

# took https://github.com/wojtekmach/mix_install_examples/blob/main/phoenix_live_view.exs
# and added Awesomplete

Application.put_env(:sample, Example.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 5001],
  server: true,
  live_view: [signing_salt: "aaaaaaaa"],
  secret_key_base: String.duplicate("a", 64)
)

Mix.install([
  {:plug_cowboy, "~> 2.7"},
  {:jason, "~> 1.4"},
  {:phoenix, "~> 1.7.14"},
  {:phoenix_live_view, "~> 0.20 or ~> 1.0"},
  {:phoenix_html, "~> 4.1"},
  {:phoenix_form_awesomplete, "~> 1.0.0"},
  {:nimble_csv, "~> 1.2"}
])

defmodule Example.ErrorView do
  def render(template, _), do: Phoenix.Controller.status_message_from_template(template)
end

defmodule Example.Data do

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
    if Enum.member?(:ets.all(), :my_lb_cache) == false do
      :ets.new(:my_lb_cache, [:set, :public, :named_table])
    end

    list =
      "https://nico-amsterdam.github.io/awesomplete-util/csv/productcat.csv"
      |> get_product_category_list_from_url()

    :ets.insert(:my_lb_cache, {"product_category_list", list})
  end

  # call init once before calling this
  def get_product_category_list do
    # get it from the ets cache
    key = "product_category_list"
    [{^key, value}] = :ets.lookup(:my_lb_cache, key)
    value
  end

  def safe_downcase(text) do
    if is_nil(text), do: nil, else: String.downcase(text)
  end

  # call init once before calling this
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

defmodule Example.HomeLive do
  use Phoenix.LiveView, layout: {__MODULE__, :live}

  def mount(_params, _session, socket) do
    {:ok, assign(socket, :count, 0)}
  end

  defp phx_vsn, do: Application.spec(:phoenix, :vsn)
  defp lv_vsn, do: Application.spec(:phoenix_live_view, :vsn)

  def render("live.html", assigns) do
    ~H"""
    <script src={"https://cdn.jsdelivr.net/npm/phoenix@#{phx_vsn()}/priv/static/phoenix.min.js"}></script>
    <script src={"https://cdn.jsdelivr.net/npm/phoenix_live_view@#{lv_vsn()}/priv/static/phoenix_live_view.min.js"}></script>
    <link href="https://nico-amsterdam.github.io/awesomplete-util/css/awesomplete_bundle.css" rel="stylesheet">
    <script type="module">
      import { AwesompleteUtil, attachAwesomplete, copyValueToId }
        from 'https://nico-amsterdam.github.io/awesomplete-util/js/awesomplete_bundle.min.mjs'

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
        // , itemContains:     AU.itemContains  // this is the default, no need to specify it.
        , itemStartsWith:   AU.itemStartsWith
        , itemMarkAll:      AU.itemMarkAll   // also mark matching text inside the description
        , itemWords:        AU.itemWords     // mark matching words

        , jsonFlatten:      AU.jsonFlatten   // convertResponse utility to flatten JSON

        // add your custom functions and/or lists here

        , ajax2live:        ajax2live

      }

      Hooks.Autocomplete = {
        mounted() {
          const awe = attachAwesomplete(this.el, customAwesompleteContext, {} /* defaultSettings */ )
          this.handleEvent(`update-list-${awe.input.id}`,
            ({searchResult, searchPhrase}) => {
              AwesompleteUtil.updateList(awe, searchResult, searchPhrase)
            }
          )
        }
      }

      Hooks.AutocompleteCopyValueToId = {
        mounted() { copyValueToId(this.el) }
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
    <%= @inner_content %>
    """
  end

  def render(assigns) do
    ~H"""
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
            forfield="mytest"
            url="livesocket:update-prodcat-list"
            ajax="ajax2live"
            maxitems="10"
            minchars="1"
            value="name"
            descr="description"
            descrSearch="true"
            ></span>

      <button type="reset">Clear</button>
    </form>
    """
  end

  def handle_event("inc", _params, socket) do
    IO.inspect "inc"
    {:noreply, assign(socket, :count, socket.assigns.count + 1)}
  end

  def handle_event("dec", _params, socket) do
    {:noreply, assign(socket, :count, socket.assigns.count - 1)}
  end

  def handle_event("update-prodcat-list", %{"value" => val, "id" => id}, socket) do
    list = Example.Data.filter_product_category(val)
    {:noreply, push_event(socket, "update-list-#{id}", %{searchResult: list, searchPhrase: val})}
  end
end

defmodule Example.Router do
  use Phoenix.Router
  import Phoenix.LiveView.Router

  pipeline :browser do
    plug(:accepts, ["html"])
  end

  scope "/", Example do
    pipe_through(:browser)

    live("/", HomeLive, :index)
  end
end

defmodule Example.Endpoint do
  use Phoenix.Endpoint, otp_app: :sample
  socket("/live", Phoenix.LiveView.Socket)
  plug(Example.Router)
end

:ok = :inets.start()
:ok = :ssl.start()
Example.Data.init()
{:ok, _} = Supervisor.start_link([Example.Endpoint], strategy: :one_for_one)
Process.sleep(:infinity)

