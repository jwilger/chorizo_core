defmodule ChorizoCore.UserManagementTest do
  use ExUnit.Case, async: true

  import Mox

  doctest ChorizoCore.UserManagement

  alias ChorizoCore.{Entities.User, UserManagement}

  setup_all do
    defmock(ChorizoCore.UserManagementTest.MockAuth, for: ChorizoCore.Authorization)
    defmock(ChorizoCore.UserManagementTest.MockUsers,
            for: ChorizoCore.Repositories.API)
    {:ok, auth_mod: ChorizoCore.UserManagementTest.MockAuth,
          users_repo: ChorizoCore.UserManagementTest.MockUsers}
  end

  setup :verify_on_exit!

  defp create_user(user, as: as) do
    UserManagement.create_user(
      user, [as: as],
      ChorizoCore.UserManagementTest.MockUsers,
      ChorizoCore.UserManagementTest.MockAuth
    )
  end

  describe "create_user/4" do
    test "checks if the user is authorized to :manage_users",
    %{auth_mod: auth_mod, users_repo: users_repo} do
      users_repo
      |> stub(:insert, fn u -> {:ok, u} end)

      as = User.new(username: "bob")

      auth_mod
      |> expect(:authorized?, fn :manage_users, ^as, ^users_repo -> true end)

      create_user(User.new, as: as)
    end
  end

  describe "create_user/4 when user is authorized" do
    setup context do
      context[:auth_mod]
      |> stub(:authorized?, fn _, _, _ -> true end)

      context[:users_repo]
      |> stub(:insert, fn u -> {:ok, u} end)

      context
    end

    test "new user is inserted into the repository",
    %{users_repo: users_repo} do
      user = User.new(username: "bob")
      users_repo
      |> expect(:insert, fn ^user -> {:ok, user} end)
      create_user(user, as: User.new())
    end

    test "new user is returned" do
      user = User.new(username: "bob")
      {:ok, ^user} = create_user(user, as: User.new())
    end
  end

  describe "create_user/4 when user is not authorized" do
    setup context do
      context[:auth_mod]
      |> stub(:authorized?, fn _, _, _ -> false end)
      context
    end

    test "new user is not inserted into the repository" do
      # if it were, we would get a failure here about no expectation for
      # insert/1
      create_user(User.new(), as: User.new)
    end

    test ":not_authorized is returned" do
      assert :not_authorized = create_user(User.new(), as: User.new())
    end
  end
end
