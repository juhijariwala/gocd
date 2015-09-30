##########################################################################
# Copyright 2015 ThoughtWorks, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
##########################################################################

require 'spec_helper'

describe ApiV1::Config::ApprovalRepresenter do
  it 'renders approval with hal representation' do
    approval = get_approval
    presenter = ApiV1::Config::ApprovalRepresenter.new(approval)
    actual_json = presenter.to_hash(url_builder: UrlBuilder.new)
    expect(actual_json).to eq(approval_hash)
  end

  it 'should convert basic hash to Approval object' do
    approval = Approval.new()

    ApiV1::Config::StageRepresenter.new(approval).from_hash(approval_hash)
    expect(approval).to eq(get_approval)
  end


  it "should render error" do
    approval = Approval.new()
    approval.setType("junk")

    approval.validateTree(PipelineConfigSaveValidationContext.forChain([]))
    presenter = ApiV1::Config::ApprovalRepresenter.new(approval)
    actual_json = presenter.to_hash(url_builder: UrlBuilder.new)
    expect(actual_json).to eq(approval_hash_with_errors)
  end

  def approval_hash
    {
      type: "manual",
      authorization: {
        roles: ["role1", "role2"],
        users: ["user1", "user2"]
      }
    }
  end

  def get_approval
    admins      = [
      AdminRole.new(CaseInsensitiveString.new("role1")), AdminRole.new(CaseInsensitiveString.new("role2")),
      AdminUser.new(CaseInsensitiveString.new("user1")), AdminUser.new(CaseInsensitiveString.new("user2"))].to_java(com.thoughtworks.go.domain.config.Admin)
    auth_config = AuthConfig.new(admins)

    approval = Approval.new(auth_config)
  end

  def approval_hash_with_errors
    {
      type: "junk",
      authorization: {},
      errors: {
        type: ["You have defined approval type as 'junk'. Approval can only be of the type 'manual' or 'success'."]
      }
    }
  end
end