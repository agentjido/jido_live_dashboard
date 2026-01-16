defmodule JidoLiveDashboardTest do
  use ExUnit.Case

  doctest JidoLiveDashboard

  describe "version" do
    test "returns the version string" do
      assert is_binary(JidoLiveDashboard.version())
      assert String.match?(JidoLiveDashboard.version(), ~r/^\d+\.\d+\.\d+/)
    end
  end
end
