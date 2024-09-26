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

Explore and try these

[![examples](https://nico-amsterdam.github.io/awesomplete-util/svg/examples.svg)](https://nico-amsterdam.github.io/awesomplete-util/phoenix.html).


Fiddle with the code yourself: 

[![Run in Livebook](https://livebook.dev/badge/v1/black.svg)](https://livebook.dev/run?url=https%3A%2F%2Fraw.githubusercontent.com%2Fnico-amsterdam%2Fphoenix_form_awesomplete%2Fmaster%2Fphoenix_form_awesomplete.livemd).

## Installation

[Installation instructions for Phoenix 1.7 and newer](
https://hexdocs.pm/phoenix_form_awesomplete/PhoenixFormAwesomplete.html#module-installation)
 integrated with esbuild assets management and using function components for HEEx templates and ~H sigils.

## License

[MIT](LICENSE)

