# PhoenixFormAwesomplete

[![Hex version](https://img.shields.io/hexpm/v/phoenix_form_awesomplete.svg?color=blue "Hex version")](https://hex.pm/packages/phoenix_form_awesomplete)
![Hex downloads](https://img.shields.io/hexpm/dt/phoenix_form_awesomplete.svg?color=blue "Hex downloads")


PhoenixFormAwesomplete is a [Phoenix form helper](https://hexdocs.pm/phoenix_html/Phoenix.HTML.Form.html) that utilizes Lea Verou's autocomplete / autosuggest / typeahead / inputsearch [Awesomplete widget](https://leaverou.github.io/awesomplete/index.html).

It comes with an AwesompleteUtil [javascript library](https://nico-amsterdam.github.io/awesomplete-util/index.html) which adds the following features:

- Dynamic remote data loading; based on what is typed-in it performs an ajax lookup.
- Allow HTML markup in the shown items. Show value with description. Optionally search in the description text.
- Show when there is an exact match.
- Show when there isn't a match.
- When there is an exact match show related data (supplied in the remote data) in other parts of the page.
- Select the highlighted item when tab key is used.

## Examples

[live examples](https://nico-amsterdam.github.io/awesomplete-util/phoenix.html) with code.

[![Run in Livebook](https://livebook.dev/badge/v1/blue.svg)](https://livebook.dev/run?url=https%3A%2F%2Fraw.githubusercontent.com%2Fnico-amsterdam%2Fphoenix_form_awesomplete%2Fmaster%2Fphoenix_form_awesomplete.livemd)

## Installation

[Installation instructions for Phoenix 1.7](
https://hexdocs.pm/phoenix_form_awesomplete/PhoenixFormAwesomplete.html#module-installation)
 integrated with esbuild assets management and using function components for HEEx templates and ~H sigils.

### Previous installation instructions

In your Phoenix project:

#### Add dependency

  1. Add `phoenix_form_awesomplete`to the list of dependencies in `mix.exs`:

```elixir
def deps do
  [
   {:phoenix_form_awesomplete, "~> 1.0"}
  ]
end
```

#### Download & compile

```sh
mix deps.get
mix compile
```

#### Add in web


Open lib/\<your context\>\_web.ex in the `html_helpers` function below the other import statements add:
```elixir
# Awesomplete autocomplete widget
import PhoenixFormAwesomplete
```

In lib/\<your context\>\_web/components/layouts/root.html.heex add inside the head element:

```html
<link rel="stylesheet" href="//nico-amsterdam.github.io/awesomplete-util/css/awesomplete.css">
<script src="//nico-amsterdam.github.io/awesomplete-util/js/awesomplete-v2020.min.js"></script>
<script src="//nico-amsterdam.github.io/awesomplete-util/js/awesomplete-util.min.js"></script>
<style>
  div.awesomplete {display: block}
  div.awesomplete ul li p {display: block; font-size: small; margin-left: 1em}
  div.awesomplete .awe-found {border: 2px solid green}
  .hide-not-found div.awesomplete .awe-not-found {border-color: lightblue}
  div.awesomplete .awe-not-found {border: 2px solid red}
  .awe-btn .caron {pointer-events: none}
</style>
```

The awesomplete.css and awesomplete.min.js files are copied from [Awesomplete](https://github.com/LeaVerou/awesomplete) and tested in combination with AwesompleteUtil. I recommend to make your own copies of these files. If you put them on github.io they will be served by [Fastly CDN](https://www.fastly.com). Do not forget to also copy the javascript sourcemaps ([awesomplete.min.js.map](https://nico-amsterdam.github.io/awesomplete-util/js/awesomplete.min.js.map) and [awesomplete-util.min.js.map](https://nico-amsterdam.github.io/awesomplete-util/js/awesomplete-util.min.js.map)).

Customize the above styling for your own needs. The CSS class 'awe-found' is put on the input control when the input exactly matches the value of an list item. The CSS class 'awe-not-found' is put on the input control when the list closes because there are no more matching items.

#### Use in your EEx or HEEx template

Example:

```html
<div>
  <label for="user_country" class="control-label">Country</label>
  <%= awesomplete(:user, :country, 
                  [class: "form-control"], 
                 %{ url: "https://restcountries.com/v2/all", 
                    loadall: true, 
                    prepop: true,
                    minChars: 1, 
                    maxItems: 8, 
                    value: "name",
                    nonce: @script_src_nonce
                 }) %>
</div>
```

## License

[MIT](LICENSE)

