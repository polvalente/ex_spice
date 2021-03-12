defmodule ExSpiceWeb.PageController do
  use ExSpiceWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
