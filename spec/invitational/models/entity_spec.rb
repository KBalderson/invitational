require 'spec_helper'
require 'invitational/services/service_helper'

describe Entity do
  Given {no_invitations_exist}

  Given(:user) { setup_user "test1@d-i.co" }
  Given(:entity) { setup_entity "Test entity 1"}

  context "relationships" do
    When {invite_user user, entity, :admin}

    Then {entity.admins.should include(user)}
  end

  context "inviting" do
    context "Users can be invited with a defined role" do
      When(:result) {entity.invite user, :admin}

      Then  {result.success.should be_true }
      And   {result.invitation.should_not be_nil}
      And   {result.invitation.invitable.should == entity}
      And   {result.invitation.user.should == user }
      And   {result.invitation.role.should == :admin}
      And   {result.invitation.claimed?.should be_true}
      end

    context "Users cannot be invited with a role that isn't defined on the entity" do
      When(:result) {entity.invite user, :client}

      Then  {result.should be_nil }
    end
  end

end
