defmodule JidoLiveDashboard.Case do
  @moduledoc """
  Base test case for JidoLiveDashboard tests.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      import JidoLiveDashboard.Case
    end
  end

  setup _tags do
    :ok
  end
end
