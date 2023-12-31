defmodule CloudflareAccessEx do
  @moduledoc """
    This library aims to simplify the process of sitting an application behind Cloudflare Access.

    By default, this library starts its own supervision tree. The root application will read Application
    config to determine which Cloudflare Access domains to retrieve JWKs from. These keys can then be used
    to verify the application tokens sent by Cloudflare Access when your application is accessed.

    The [Cloudflare docs](https://developers.cloudflare.com/cloudflare-one/identity/authorization-cookie/application-token/)
    provide more information.

    The library also provides a Plug (see `CloudflareAccessEx.Plug`) that can be used to to extract and
    verify tokens from requests.

    Usage:

    1. Add `cloudflare_access_ex` to your list of dependencies in `mix.exs`. Note that the
       `:runtime` option can be used to disable Jwks polling in selected environments (i.e. `:test` and `:dev`)

           def deps do
             [
               {:cloudflare_access_ex, "~> 0.1", runtime: Mix.env() not in [:test, :dev]}
             ]
           end

       If you wish to startup the application manually, you can opt out of the runtime dependency and start the
       supervisor manually:

           def deps do
             [
               {:cloudflare_access_ex, "~> 0.1", runtime: false}
             ]
           end

       in your application module:

           CloudflareAccessEx.Supervisor.start_link(... TODO ...)

    2. Get the audience tag from the Cloudflare Access dashboard for your application.
       [Instruction here](https://developers.cloudflare.com/cloudflare-one/identity/authorization-cookie/validating-json/#get-your-aud-tag).

    3. Configure the application:

           config :cloudflare_access_ex, :my_cfa_app,
               domain: "example.cloudflareaccess.com"
               # this is the audience tag retrieved on step 2
               audience: "a8d3b7..."

       Multiple applications can be configured by adding more keys to the `:cloudflare_access_ex` config. i.e.

           config :cloudflare_access_ex, :my_cfa_app,
               domain: "example.cloudflareaccess.com"
               audience: "a8d3b7..."

           config :cloudflare_access_ex, :my_other_cfa_app,
               domain: "example.cloudflareaccess.com"
               audience: "7309b8..."

       There will only be one process that fetches Jwks keys for each domain. It's also possible to consolidate the
       duplicate configuration for the domain string like so:

           config :cloudflare_access_ex, :example,
               domain: "example.cloudflareaccess.com"

           config :cloudflare_access_ex, :my_cfa_app,
               domain: :example, audience: "a8d3b7..."

           config :cloudflare_access_ex, :my_other_cfa_app,
               domain: :example, audience: "7309b8..."

    4. Verify tokens either using `CloudflareAccessEx.Plug` (this will return 403 for invalid tokens by default):

           plug CloudflareAccessEx.Plug, cfa_app: :my_cfa_app

       or using `CloudflareAccessEx.ApplicationTokenVerifier` directly if you need even more control:

           alias CloudflareAccessEx.{ApplicationTokenVerifier, Principal}

           verifier = ApplicationTokenVerifier.create(:my_cfa_app)
           {:ok, principal} = conn |> ApplicationTokenVerifier.verify(verifier)

           case principal do
             %Principal{type: :anonymous} -> # do something
             %Principal{type: :authenticated, user_id: _, email: _}} -> # do something else
           end
  """
end
