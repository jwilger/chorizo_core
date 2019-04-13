defmodule Chorizo.WebApp.Resolvers.UserTest do
  use Chorizo.WebApp.ConnCase

  alias Chorizo.WebApp.Resolvers.User

  import Mox

  setup :verify_on_exit!

  describe "create_user/2" do
    test "calls Accounts.create_user/2 with a User struct created from the supplied arguments" do
      Chorizo.Accounts.Mock
      |> expect(:create_user, fn %Chorizo.Accounts.VO.User{} = user ->
        {:ok, %Chorizo.Accounts.VO.User{
          id: "e93c98b2-628f-4617-a159-14b492156c9f",
          email_address: user.email_address
        }}
      end)

      User.create_user(%{email_address: "nobody@example.com", password: "foobarbaz"}, %{})
    end

    test "returns the user data and a JWT for the user when successful" do
      Chorizo.Accounts.Mock
      |> expect(:create_user, fn user ->
        {:ok, %Chorizo.Accounts.VO.User{
          id: "e93c98b2-628f-4617-a159-14b492156c9f",
          email_address: user.email_address
        }}
      end)

      {:ok, %{user: user, jwt: jwt}} =
        User.create_user(%{email_address: "nobody@example.com", password: "foo"}, %{})

      assert user.id == "e93c98b2-628f-4617-a159-14b492156c9f"
      assert user.email_address == "nobody@example.com"

      {:ok, user_data} = Chorizo.WebApp.verify_jwt(jwt, max_age: 1)

      assert user_data.id == user.id
    end

    test "returns the {:error, messages} tuple when an error occurs" do
      Chorizo.Accounts.Mock
      |> expect(:create_user, fn _ ->
        {:error, ["Something happened"]}
      end)

      assert {:error, ["Something happened"]} == 
        User.create_user(%{email_address: "nobody@example.com", password: "foobarbaz"}, %{})
    end
  end
end
