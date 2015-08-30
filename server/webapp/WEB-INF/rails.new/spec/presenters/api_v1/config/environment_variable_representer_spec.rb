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

describe ApiV1::Config::EnvironmentVariableRepresenter do
  it 'should render plain environment variable with hal representation' do
    presenter = ApiV1::Config::EnvironmentVariableRepresenter.new(get_plain_text_config)
    actual_json = presenter.to_hash(url_builder: UrlBuilder.new)
    expect(actual_json).to eq(get_plain_text_hash)
  end

  it 'should render secure environment variable with hal representation' do
    presenter = ApiV1::Config::EnvironmentVariableRepresenter.new(get_secure_config)
    actual_json = presenter.to_hash(url_builder: UrlBuilder.new)
    expect(actual_json).to eq(get_secure_hash)
  end

  it "should convert from secure hash with encrypted value to EnvironmentVariableConfig" do
    config = EnvironmentVariableConfig.new()
    presenter = ApiV1::Config::EnvironmentVariableRepresenter.new(config)
    presenter.from_hash(get_secure_hash)
    expect(config).to eq(get_secure_config)
  end

  it "should convert from secure hash with plain value to EnvironmentVariableConfig" do
    config = EnvironmentVariableConfig.new()
    presenter = ApiV1::Config::EnvironmentVariableRepresenter.new(config)
    presenter.from_hash(get_secure_hash_with_plain_text_value_for_put)
    expect(config).to eq(get_secure_config)
  end

  def get_secure_config
    EnvironmentVariableConfig.new(GoCipher.new, "secure", "confidential", true)
  end

  def get_plain_text_config
    EnvironmentVariableConfig.new(GoCipher.new, "plain", "plain", false)
  end

  def get_plain_text_hash
    {
        name: "plain",
        value: "plain",
        secure: false
    }
  end

  def get_secure_hash
    {
        secure: true,
        name: "secure",
        encrypted_value: GoCipher.new.encrypt("confidential")
    }
  end

  def get_secure_hash_with_plain_text_value_for_put
    {
        secure: true,
        name: "secure",
        value: "confidential"
    }
  end
end
