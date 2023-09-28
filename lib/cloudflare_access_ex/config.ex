defmodule CloudflareAccessEx.Config do
  @moduledoc """
  Utility functions for processing the configuration of the library.
  """

  @spec get_issuer(String.t()) :: String.t()
  @doc """
  Get the issuer URL for a domain. By default, just the domain name is provided, but it
  is also possible to provide a full URL. This function will ensure that the issuer URL
  is a full URL.
  """
  def get_issuer(domain) do
    if String.match?(domain, ~r/^https?\:\/\//) do
      domain
    else
      "https://#{domain}"
    end
  end

  @spec resolve_domain(atom() | String.t()) :: String.t()
  @doc """
  Given a domain atom or string, return the domain string.

  If the domain is an atom, it will be looked up in the application config.
  """
  def resolve_domain(domain) when is_atom(domain) do
    resolved_domain =
      Application.get_env(:cloudflare_access_ex, domain, [])
      |> Keyword.get(:domain) ||
        throw(
          "Attempting to get domain name for :cloudflare_access_ex, #{inspect(domain)} but no :domain key found in config"
        )

    if is_binary(resolved_domain) do
      resolved_domain
    else
      throw(
        "Domain configuration #{inspect(domain)} refers to #{inspect(resolved_domain)} which is not a string"
      )
    end
  end

  def resolve_domain(domain) when is_binary(domain),
    do: domain

  def resolve_domain(domain),
    do: throw("Invalid domain name: #{inspect(domain)}")

  @spec get_domain_strings :: list(String.t())
  @doc """
  Return all domain names in all keys under :cloudflare_access_ex.
  """
  def get_domain_strings() do
    Application.get_all_env(:cloudflare_access_ex)
    |> get_domain_strings()
  end

  defp get_domain_strings(config) do
    config
    |> Enum.map(fn
      {_, configs} when is_list(configs) ->
        Keyword.get(configs, :domain)

      _ ->
        nil
    end)
    |> Enum.filter(&is_binary/1)
    |> Enum.uniq()
  end
end
