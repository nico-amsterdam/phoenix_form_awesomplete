defmodule PhoenixFormAwesomplete.HookComponent do

  @moduledoc """
  Provides function components for the Awesomplete component,
  for autocomplete functionality.
  Uses a hook for the javascript code.
  Usable inside and outside LiveView.
  """

  use Phoenix.Component

  @doc """
  Provide functionality like PhoenixFormAwesomplete.awesomplete_script via client hook.
  """
  attr :id, :string
  attr :forField, :any, required: true, doc: "Phoenix.HTML.FormField struct or field name."
  attr :forForm, :any, doc: "Phoenix.HTML.Form struct or form name. Not needed when FormField is used."
  attr :nonce, :any, doc: "In liveview the nonce will be ignored."
  attr :rest, :global,
    include: ~w(ajax assign autoFirst combobox container convertInput convertResponse data debounce descr descrSearch filter item label list listLabel loadall limit maxItems minChars multiple prepop replace sort statusNoResults statusTypeXChar statusXResults url urlEnd value),
    doc: "the options for awesomplete_script."
  def autocomplete(%{forField: %Phoenix.HTML.FormField{}} = assigns) do
    assigns = assign_new(assigns, :id, fn -> assigns.forField.id <> "-autocomplete" end)
    ~H"""
    <span id={@id} phx-hook="Autocomplete" class="hidden" forField={@forField.id} {@rest} ></span>
    """
  end

  def autocomplete(assigns) do
    for_id = Phoenix.HTML.Form.input_id(assigns.forForm, assigns.forField)
    assigns = 
      assigns
      |> assign(:forField, %{id: for_id})
      |> assign_new(:id, fn -> for_id <> "-autocomplete" end)
    ~H"""
    <span id={@id} phx-hook="Autocomplete" class="hidden" forField={@forField.id} {@rest} ></span>
    """
  end

  defp copy2id_default_id(for_id, target) do
    "awe-" <> for_id <> "-2id" <> String.replace(target, ~r/\W/, "")
  end

  @doc """
  Provide functionality like PhoenixFormAwesomplete.copy_value_to_id via client hook.
  """
  attr :id, :string
  attr :field, :any, required: true, doc: "Phoenix.HTML.FormField struct or field name."
  attr :form, :any, doc: "Phoenix.HTML.Form struct or form name. Not needed when FormField is used."
  attr :target, :any, required: true, doc: "target: css selector, for example: #capital."
  attr :nonce, :any, doc: "In liveview the nonce will be ignored."
  attr :rest, :global,
    include: ~w(dataField),
    doc: "dataField: Optional, dataField to be copied, for example: capital."
  def copy_value_to_id(%{field: %Phoenix.HTML.FormField{}} = assigns) do
    assigns =
      assigns
      |> assign_new(:id, fn -> copy2id_default_id(assigns.field.id, assigns.target) end)
    ~H"""
    <span id={@id} phx-hook="AutocompleteCopyValueToId" class="hidden" field={@field.id} target={@target} {@rest} ></span>
    """
  end

  def copy_value_to_id(%{form: _form, field: _field} = assigns) do
    for_id = Phoenix.HTML.Form.input_id(assigns.form, assigns.field)
    assigns = 
      assigns
      |> assign(:field, %{id: for_id})
      |> assign_new(:id, fn -> copy2id_default_id(for_id, assigns.target) end)
    ~H"""
    <span id={@id} phx-hook="AutocompleteCopyValueToId" class="hidden" field={@field.id} target={@target} {@rest} ></span>
    """
  end

  @doc """
  Provide functionality like PhoenixFormAwesomplete.copy_value_to_field via client hook.
  """
  attr :id, :string
  attr :sourceField, :any, required: true, doc: "Phoenix.HTML.FormField struct."
  attr :targetField, :any, required: true, doc: "Phoenix.HTML.FormField struct."
  attr :nonce, :any, doc: "In liveview the nonce will be ignored."
  attr :rest, :global,
    include: ~w(dataField),
    doc: "dataField: Optional, dataField to be copied, for example: capital."
  def copy_value_to_field(%{sourceField: %Phoenix.HTML.FormField{}, targetField: %Phoenix.HTML.FormField{}} = assigns) do
    assigns =
      assigns
      |> assign_new(:id, fn -> "awe-" <> assigns.sourceField.id <> "-2fld-" <> assigns.targetField.id end)
    ~H"""
    <span id={@id} phx-hook="AutocompleteCopyValueToId" class="hidden" field={@sourceField.id} targetField={@targetField.id} {@rest} ></span>
    """
  end

  @doc """
  Transfer ownership of the DOM from LiveView to custom javascript code after the initial rendering.
  Another way to set phx-update="ignore" without scattering this phx attribute in the templates.
  """
  attr :id, :string, required: true 
  attr :rest, :global
  slot :inner_block
  def release_dom(assigns) do
    ~H"""
    <span id={@id} phx-update="ignore" {@rest} ><%= render_slot(@inner_block) %></span>
    """
  end

end
