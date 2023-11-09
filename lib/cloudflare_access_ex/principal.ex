defmodule CloudflareAccessEx.Principal do
  @moduledoc """
  Defines the `Principal` struct for representing the principal identity of a user coming through Cloudflare Access.

  A `Principal` can either represent an anonymous user or a user that has logged in through an identity provider (IdP).
  The struct differentiates between these two states with the `:type` field, which can be `:anonymous` for users without
  a user ID or email, or `:authenticated` for users who have been verified and have these attributes.
  """
  @enforce_keys [:type]
  defstruct [:type, user_id: nil, email: nil]

  @type anonymous_principal :: %__MODULE__{
          type: :anonymous,
          user_id: nil,
          email: nil
        }

  @type authenticated_principal :: %__MODULE__{
          type: :authenticated,
          user_id: String.t(),
          email: String.t()
        }

  @type t :: anonymous_principal() | authenticated_principal()

  @doc """
  Creates a `Principal` struct for an anonymous user.

  ## Examples

      iex> CloudflareAccessEx.Principal.anonymous()
      %CloudflareAccessEx.Principal{type: :anonymous, user_id: nil, email: nil}
  """
  @spec anonymous() :: anonymous_principal()
  def anonymous do
    %__MODULE__{
      type: :anonymous
    }
  end

  @doc """
  Creates a `Principal` struct for an authenticated user with the provided `user_id` and `email`.

  ## Parameters

  - `user_id`: The user ID from the IdP.
  - `email`: The email address associated with the user.

  ## Examples

      iex> CloudflareAccessEx.Principal.authenticated("user123", "user@example.com")
      %CloudflareAccessEx.Principal{
        type: :authenticated,
        user_id: "user123",
        email: "user@example.com"
      }
  """
  @spec authenticated(String.t(), String.t()) :: authenticated_principal()
  def authenticated(user_id, email) do
    %__MODULE__{
      type: :authenticated,
      user_id: user_id,
      email: email
    }
  end
end
