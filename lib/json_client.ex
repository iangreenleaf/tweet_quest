defmodule JSONClient do
  use HTTPoison.Base

  def process_request_body(""), do: ""

  def process_request_body(body) do
    body |> Jason.encode!()
  end

  def process_response_body(""), do: ""

  def process_response_body(body) do
    case Jason.decode(body) do
      {:ok, json} -> json
      {:error, _} -> body
    end
  end
end
