# PhoenixFormAwesomplete

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

## Installation

In your Phoenix project:

### Add dependency

  1. Add `phoenix_form_awesomplete`to the list of dependencies in`mix.exs:

    ```elixir
    def deps do
      [{:phoenix_form_awesomplete, "~> 0.1"}]
    end
    ```

### Download & compile

```sh
mix deps.get
mix compile
```

### Add in web


Open web/web.ex (phoenix <= 1.2) or lib/\<your context\>\_web.ex (phoenix >= 1.3), in the 'view' function below the other import statements add:
```elixir
# Awesomplete autocomplete widget
import PhoenixFormAwesomplete
```

In web/templates/layout/app.html.eex (phoenix <= 1.2),

or lib/\<your context\>\_web/templates/layout/app.html.eex (phoenix >= 1.3) add:

```html
<link rel="stylesheet" href="//nico-amsterdam.github.io/awesomplete-util/css/awesomplete.css">
<script src="//nico-amsterdam.github.io/awesomplete-util/js/awesomplete.min.js"></script>
<script src="//nico-amsterdam.github.io/awesomplete-util/js/awesomplete-util.min.js"></script>
<style>
  div.awesomplete {display: block}

  div.awesomplete ul li p {display: block; font-size: small; margin-left: 1em}

  div.awesomplete .awe-found {border: 2px solid green}
  
  .hide-not-found div.awesomplete .awe-not-found {border-color: lightblue}
  
  div.awesomplete .awe-not-found {border: 2px solid red}
</style>
```

The awesomplete.css and awesomplete.min.js files are copied from [Awesomplete](https://github.com/LeaVerou/awesomplete) and tested in combination with AwesompleteUtil. I recommend to make your own copies of these files. If you put them on github.io they will be served by [Fastly CDN](https://www.fastly.com). Do not forget to also copy the javascript sourcemaps ([awesomplete.min.js.map](https://nico-amsterdam.github.io/awesomplete-util/js/awesomplete.min.js.map) and [awesomplete-util.min.js.map](https://nico-amsterdam.github.io/awesomplete-util/js/awesomplete-util.min.js.map)).

Customize the above styling for your own needs. The CSS class 'awe-found' is put on the input control when the input exactly matches the value of an list item. The CSS class 'awe-not-found' is put on the input control when the list closes because there are no more matching items.

### Use in your EEx template

Example:

```html
<div class="form-group row">
  <%= label(:user, :country, "Country", class: "control-label col-sm-2") %>
  <div class="col-sm-10">
      <%= awesomplete(:user, :country, 
                      [class: "form-control"], 
                      [ url: "https://restcountries.eu/rest/v1/all", 
                        loadall: true, 
                        prepop: true,
                        minChars: 1, 
                        maxItems: 8, 
                        value: "name"
                      ]) %>
  </div>
</div>
```

## License

[MIT](LICENSE)

