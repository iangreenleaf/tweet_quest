# TweetQuest

TweetQuest is a Twitter client inspired by Greg Vaughn's [Quest](https://github.com/gvaughn/quest) pattern.
It's a proof of concept for now, so while it does work, it's a use-at-your-own-risk sort of thing.

One of the cool insights of the Quest pattern is that HTTP requests can be modeled in a functional way as data structures that are incrementally transformed before being executed.
This library extends that concept with useful helpers specific to the Twitter API that allow requests to be constructed in a modular fashion.
The request logic can also easily be customized or extended by the addition of your own transformation functions that perform whatever operations you like on the quest object, before or after dispatch.

Please note that this library's Quest object varies in a couple small ways from the canonical one.
Also, you should not assume that this interface is 100% stable yet, because again, proof of concept.

## Usage example

To acquire a user access token from the 3-legged OAuth flow:

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
```

Once you have authorization, you can make requests to any API endpoint.
Note how each of these functions can be added or removed depending on what functionality you want the request to exhibit.


```elixir
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
