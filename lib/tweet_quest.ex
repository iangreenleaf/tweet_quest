defmodule TweetQuest do
  @moduledoc """
  Build and dispatch a Quest-style Twitter API request.

  Example:

      TweetQuest.client()
      |> consumer_credentials({"MY_CONSUMER_KEY", "MY_CONSUMER_SECRET"})
      |> client_credentials({"MY_OAUTH_TOKEN", "MY_OAUTH_SECRET"})
      |> request(:get, "favorites/list.json", opts)
      |> dispatch()
      |> wait_for_rate_limiting()
  """

  @default_q %Quest{
    dispatcher: HTTPoisonDispatcher,
    encoding: :json,
    params: [],
    payload: "",
    base_url: "https://api.twitter.com/1.1/",
    adapter_options: [recv_timeout: 20_000],
    destiny: "twitter"
  }

  def client(client_opts \\ []) do
    client_opts
    |> Enum.into(@default_q)
  end

  def consumer_credentials(quest, {consumer_key, consumer_secret}) do
    [appmeta: [app_credentials: %{consumer_key: consumer_key, consumer_secret: consumer_secret}]]
    |> Enum.into(quest)
  end

  def client_credentials(quest, {oauth_token, oauth_secret}) do
    [appmeta: [user_credentials: %{oauth_token: oauth_token, oauth_secret: oauth_secret}]]
    |> Enum.into(quest)
  end

  def request(quest, verb, path, params \\ []) do
    [verb: verb, path: path, params: params]
    |> Enum.into(quest)
  end

  def dispatch(quest) do
    quest
    |> normalize_params()
    |> auth_headers()
    |> Quest.dispatch()
  end

  def wait_for_rate_limiting({:ok, %{status_code: 429} = resp}) do
    {_, retry_epoch_str} = List.keyfind(resp[:headers], "x-rate-limit-reset", 0)

    wait_s = String.to_integer(retry_epoch_str) - DateTime.to_unix(DateTime.utc_now())

    Process.sleep(wait_s * 1000)

    dispatch(resp[:quest])
  end

  def wait_for_rate_limiting(resp), do: resp

  # Need to make sure we pass consistent params into the OAuth signing process
  defp normalize_params(quest) do
    quest
    |> Map.update(:params, [], &Enum.map(&1, fn {k, v} -> {to_string(k), to_string(v)} end))
  end

  # Signs the request on behalf of the user
  # https://developer.twitter.com/en/docs/authentication/oauth-1-0a/authorizing-a-request
  defp auth_headers(quest) do
    {:ok, %{consumer_key: _, consumer_secret: _} = consumer} =
      Keyword.fetch(quest.appmeta, :app_credentials)

    {:ok, %{oauth_token: token, oauth_secret: token_secret}} =
      Keyword.fetch(quest.appmeta, :user_credentials)

    credentials =
      Map.merge(consumer, %{token: token, token_secret: token_secret})
      |> OAuther.credentials()

    url = quest.dispatcher.url(quest)

    {headers, _params} =
      OAuther.sign(to_string(quest.verb), url, quest.params, credentials)
      |> OAuther.header()

    %{headers: [headers]} |> Enum.into(quest)
  end
end
