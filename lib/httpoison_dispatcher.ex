defmodule HTTPoisonDispatcher do
  def dispatch(%Quest{encoding: :json} = q) do
    options = [{:params, q.params} | q.adapter_options]

    case JSONClient.request(q.verb, url(q), q.payload, q.headers, options) do
      {:ok, resp} ->
        {:ok,
         resp
         |> Map.take([:status_code, :headers, :body])
         |> Map.put(:quest, q)}

      {:error, e} ->
        {:error, e}
    end
  end

  def dispatch(%Quest{encoding: :urlencoded} = q) do
    options = [{:params, q.params} | q.adapter_options]

    case HTTPoison.request(q.verb, url(q), q.payload, q.headers, options) do
      {:ok, resp} ->
        {:ok,
         resp
         |> Map.take([:status_code, :headers, :body])
         |> Map.put(:quest, q)}

      {:error, e} ->
        {:error, e}
    end
  end

  def url(%Quest{} = q) do
    URI.merge(q.base_url, q.path) |> URI.to_string()
  end
end
