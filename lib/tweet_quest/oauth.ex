defmodule TweetQuest.OAuth do
  @moduledoc """
  Helpers for 3-legged OAuth with Twitter.

  Expects the consumer key and secret to be set in config:

      config :tweet_quest,
        consumer_credentials: {"MY_CONSUMER_KEY", "MY_CONSUMER_SECRET"}

  Usage:

      {:ok, %{"oauth_token" => token}} =
        TweetQuest.OAuth.request_token("http://my-app.com/callback")

      {:ok, authorize_url} = TweetQuest.OAuth.authorize_url(token)

      # Send the user to `authorize_url`...

      # When a user is returned to your callback endpoint:

      {:ok, %{"oauth_token" => token, "oauth_token_secret" => secret}} =
        TweetQuest.OAuth.access_token(oauth_token, oauth_verifier)

      {:ok, %{body: twitter_user}} =
        TweetQuest.verify_credentials(token, secret, include_email: true)
  """

  import TweetQuest

  # https://developer.twitter.com/en/docs/authentication/api-reference/request_token
  def request_token(oauth_callback, opts \\ []) do
    client(base_url: "https://api.twitter.com/")
    |> consumer_credentials(Elixir.Application.get_env(:tweet_quest, :consumer_credentials))
    |> client_credentials({"", ""})
    |> request(:post, "oauth/request_token", [{:oauth_callback, oauth_callback} | opts])
    |> dispatch()
    |> wait_for_rate_limiting()
    |> url_decode()
    |> case do
      {:ok,
       %{
         status_code: 200,
         body:
           %{
             "oauth_callback_confirmed" => "true",
             "oauth_token" => _,
             "oauth_token_secret" => _
           } = body
       }} ->
        {:ok, body}

      {_, response} ->
        {:error, response}
    end
  end

  # https://developer.twitter.com/en/docs/authentication/api-reference/authorize
  def authorize_url(oauth_token, opts \\ []) do
    {:ok,
     %Elixir.URI{
       scheme: "https",
       host: "api.twitter.com",
       path: "/oauth/authorize",
       query: Enum.into(opts, %{oauth_token: oauth_token}) |> Elixir.URI.encode_query()
     }
     |> Elixir.URI.to_string()}
  end

  # https://developer.twitter.com/en/docs/authentication/api-reference/access_token
  def access_token(oauth_token, oauth_verifier) do
    client(base_url: "https://api.twitter.com/")
    |> consumer_credentials(Elixir.Application.get_env(:tweet_quest, :consumer_credentials))
    |> client_credentials({oauth_token, ""})
    |> request(:post, "oauth/access_token",
      oauth_token: oauth_token,
      oauth_verifier: oauth_verifier
    )
    |> dispatch()
    |> wait_for_rate_limiting()
    |> url_decode()
    |> case do
      {:ok,
       %{
         status_code: 200,
         body:
           %{
             "oauth_token" => _,
             "oauth_token_secret" => _
           } = body
       }} ->
        {:ok, body}

      {_, response} ->
        {:error, response}
    end
  end

  # https://developer.twitter.com/en/docs/twitter-api/v1/accounts-and-users/manage-account-settings/api-reference/get-account-verify_credentials
  def verify_credentials(token, secret, opts \\ []) do
    client()
    |> consumer_credentials(Elixir.Application.get_env(:tweet_quest, :consumer_credentials))
    |> client_credentials({token, secret})
    |> request(:get, "account/verify_credentials.json", opts)
    |> dispatch()
    |> wait_for_rate_limiting()
  end

  defp url_decode({:ok, resp}) do
    {:ok, %{resp | body: URI.decode_query(resp.body)}}
  end

  defp url_decode(any), do: any
end
