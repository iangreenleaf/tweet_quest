defmodule TweetQuestTest do
  use ExUnit.Case, async: true

  import TweetQuest

  doctest TweetQuest

  setup do
    bypass = Bypass.open()
    Process.put(:bypass_twitter_port, bypass.port)

    base_url =
      %URI{port: bypass.port, host: "localhost", scheme: "http", path: "/1.1/"} |> URI.to_string()

    {:ok, bypass: bypass, bypass_options: %{base_url: base_url}}
  end

  describe "with authorized user" do
    setup do
      {:ok, credentials: [{"TEST_KEY", "TEST_SECRET"}, {"abcd1234", "9999999a"}]}
    end

    test "sends authorization headers", %{
      bypass: bypass,
      bypass_options: bypass_options,
      credentials: [consumer, client]
    } do
      Bypass.expect_once(bypass, "GET", "/1.1/favorites/list.json", fn conn ->
        assert conn.req_headers
               |> Enum.any?(fn {header, value} ->
                 header == "authorization" and
                   value =~
                     ~r/OAuth oauth_signature=".*", oauth_consumer_key="TEST_KEY", oauth_nonce=".*", oauth_signature_method="HMAC-SHA1", oauth_timestamp=".*", oauth_version="1.0", oauth_token="abcd1234"/
               end)

        Plug.Conn.resp(conn, 200, ~s<[]>)
      end)

      client(bypass_options)
      |> client_credentials(client)
      |> consumer_credentials(consumer)
      |> request(:get, "favorites/list.json")
      |> dispatch()
    end

    test "sends params in query string", %{
      bypass: bypass,
      bypass_options: bypass_options,
      credentials: [consumer, client]
    } do
      Bypass.expect_once(bypass, "GET", "/1.1/statuses/show.json", fn conn ->
        assert conn.params == %{"id" => "210462857140252672"}
        Plug.Conn.resp(conn, 200, File.read!("test/fixtures/status_show_response.json"))
      end)

      client(bypass_options)
      |> client_credentials(client)
      |> consumer_credentials(consumer)
      |> request(:get, "statuses/show.json", [{"id", "210462857140252672"}])
      |> dispatch()
    end

    test "converts params to strings", %{
      bypass: bypass,
      bypass_options: bypass_options,
      credentials: [consumer, client]
    } do
      Bypass.expect_once(bypass, "GET", "/1.1/statuses/show.json", fn conn ->
        assert conn.params == %{"id" => "210462857140252672"}
        Plug.Conn.resp(conn, 200, File.read!("test/fixtures/status_show_response.json"))
      end)

      client(bypass_options)
      |> client_credentials(client)
      |> consumer_credentials(consumer)
      |> request(:get, "statuses/show.json", [{"id", 210_462_857_140_252_672}])
      |> dispatch()
    end

    test "handles params as keyword list", %{
      bypass: bypass,
      bypass_options: bypass_options,
      credentials: [consumer, client]
    } do
      Bypass.expect_once(bypass, "GET", "/1.1/statuses/show.json", fn conn ->
        assert conn.params == %{"id" => "210462857140252672"}
        Plug.Conn.resp(conn, 200, File.read!("test/fixtures/status_show_response.json"))
      end)

      client(bypass_options)
      |> client_credentials(client)
      |> consumer_credentials(consumer)
      |> request(:get, "statuses/show.json", id: 210_462_857_140_252_672)
      |> dispatch()
    end

    test "converts response body JSON", %{
      bypass: bypass,
      bypass_options: bypass_options,
      credentials: [consumer, client]
    } do
      Bypass.expect_once(bypass, "GET", "/1.1/statuses/show/210462857140252672.json", fn conn ->
        Plug.Conn.resp(conn, 200, File.read!("test/fixtures/status_show_response.json"))
      end)

      {:ok, response} =
        client(bypass_options)
        |> client_credentials(client)
        |> consumer_credentials(consumer)
        |> request(:get, "statuses/show/210462857140252672.json")
        |> dispatch()

      assert %{"id" => 210_462_857_140_252_670, "user" => %{}, "text" => _} = response.body
    end
  end

  describe "when rate limited" do
    setup do
      {:ok, credentials: [{"TEST_KEY", "TEST_SECRET"}, {"abcd1234", "9999999a"}]}
    end

    test "returns rate limit response if not retried", %{
      bypass: bypass,
      bypass_options: bypass_options,
      credentials: [consumer, client]
    } do
      Bypass.expect(bypass, "GET", "/1.1/favorites/list.json", fn conn ->
        conn
        |> Plug.Conn.put_resp_header("x-rate-limit-limit", "75")
        |> Plug.Conn.put_resp_header("x-rate-limit-remaining", "0")
        |> Plug.Conn.put_resp_header("x-rate-limit-reset", "0")
        |> Plug.Conn.resp(429, ~s<{"errors": [{"code": 88, "message": "Rate limit exceeded"}]}>)
      end)

      assert {:ok, %{status_code: 429}} =
               client(bypass_options)
               |> client_credentials(client)
               |> consumer_credentials(consumer)
               |> request(:get, "favorites/list.json")
               |> dispatch()
    end

    test "waits and retries", %{
      bypass: bypass,
      bypass_options: bypass_options,
      credentials: [consumer, client]
    } do
      {:ok, agent} = Agent.start_link(fn -> 0 end)

      Bypass.expect(bypass, "GET", "/1.1/favorites/list.json", fn conn ->
        case Agent.get_and_update(agent, fn step_no -> {step_no + 1, step_no + 1} end) do
          1 ->
            allow_at = DateTime.utc_now() |> DateTime.add(1, :second) |> DateTime.to_unix()

            conn
            |> Plug.Conn.put_resp_header("x-rate-limit-limit", "75")
            |> Plug.Conn.put_resp_header("x-rate-limit-remaining", "0")
            |> Plug.Conn.put_resp_header("x-rate-limit-reset", to_string(allow_at))
            |> Plug.Conn.resp(
              429,
              ~s<{"errors": [{"code": 88, "message": "Rate limit exceeded"}]}>
            )

          2 ->
            Plug.Conn.resp(conn, 200, ~s<[]>)
        end
      end)

      assert {:ok, %{status_code: 200, body: []}} =
               client(bypass_options)
               |> client_credentials(client)
               |> consumer_credentials(consumer)
               |> request(:get, "favorites/list.json")
               |> dispatch()
               |> wait_for_rate_limiting()

      assert Agent.get(agent, fn i -> i end) == 2
    end
  end
end
