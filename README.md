# TweetQuest

More documentation coming soon.

For now, here's a usage example:

```elixir
{:ok, %{"oauth_token" => token}} =
  TweetQuest.OAuth.request_token("http://my-app.com/callback")

{:ok, authorize_url} = TweetQuest.OAuth.authorize_url(token)

# Send the user to `authorize_url`...

# When a user is returned to your callback endpoint:

{:ok, %{"oauth_token" => token, "oauth_token_secret" => secret}} =
  TweetQuest.OAuth.access_token(oauth_token, oauth_verifier)

{:ok, %{body: twitter_user}} =
  TweetQuest.verify_credentials(token, secret, include_email: true)

{:ok, %{body: favs}} =
  TweetQuest.client()
  |> consumer_credentials({"MY_CONSUMER_KEY", "MY_CONSUMER_SECRET"})
  |> client_credentials({token, secret})
  |> request(:get, "favorites/list.json", opts)
  |> dispatch()
  |> wait_for_rate_limiting()
```

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `tweet_quest` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:tweet_quest, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/tweet_quest](https://hexdocs.pm/tweet_quest).

