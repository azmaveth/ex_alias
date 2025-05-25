defmodule ExAlias.Error do
  @moduledoc """
  Error handling utilities for ExAlias.
  """

  @doc """
  Create a validation error tuple.

  ## Parameters
  - `field` - The field that failed validation
  - `message` - Human-readable error message

  ## Returns
  Error tuple in the format `{:error, {:validation_error, {field, message}}}`

  ## Examples

      iex> ExAlias.Error.validation_error(:name, "cannot be empty")
      {:error, {:validation_error, {:name, "cannot be empty"}}}
  """
  @spec validation_error(atom(), binary()) :: {:error, {:validation_error, {atom(), binary()}}}
  def validation_error(field, message) when is_atom(field) and is_binary(message) do
    {:error, {:validation_error, {field, message}}}
  end
end