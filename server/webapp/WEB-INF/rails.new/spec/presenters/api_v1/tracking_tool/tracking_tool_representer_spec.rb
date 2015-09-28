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

describe ApiV1::Config::TrackingTool::TrackingToolRepresenter do
  describe :external_tool do
    it 'renders external tracking tool with hal representation' do

      external_tracking_tool= TrackingTool.new("link", "regex")
      presenter             = ApiV1::Config::TrackingTool::TrackingToolRepresenter.new(external_tracking_tool)
      actual_json           = presenter.to_hash(url_builder: UrlBuilder.new)
      expect(actual_json).to eq(external_tracking_tool_hash)
    end

    it "should deserialize" do
      presenter           = ApiV1::Config::TrackingTool::TrackingToolRepresenter.new(TrackingTool.new)
      deserialized_object = presenter.from_hash(external_tracking_tool_hash)
      expected            = TrackingTool.new("link", "regex")
      expect(deserialized_object).to eq(expected)
    end

    it "should render validation errors" do
      tracking_tool= TrackingTool.new
      tracking_tool.validateTree(nil)

      presenter           = ApiV1::Config::TrackingTool::TrackingToolRepresenter.new(tracking_tool)
      actual_json         = presenter.to_hash(url_builder: UrlBuilder.new)
      expect(actual_json).to eq(external_tracking_tool_with_errors_hash)
    end
  end

  describe :mingle do
    it 'renders mingle tracking tool with hal representation' do

      mingle_tracking_tool= MingleConfig.new("http://mingle.example.com", "my_project", "status > 'In Dev'")
      presenter           = ApiV1::Config::TrackingTool::TrackingToolRepresenter.new(mingle_tracking_tool)
      actual_json         = presenter.to_hash(url_builder: UrlBuilder.new)
      expect(actual_json).to eq(mingle_tracking_tool_hash)
    end

    it "should deserialize" do
      presenter           = ApiV1::Config::TrackingTool::TrackingToolRepresenter.new(MingleConfig.new)
      deserialized_object = presenter.from_hash(mingle_tracking_tool_hash)
      expected            = MingleConfig.new("http://mingle.example.com", "my_project", "status > 'In Dev'")
      expect(deserialized_object).to eq(expected)
    end

    it "should render validation errors" do
      mingle_tracking_tool= MingleConfig.new("http://mingle.example.com", "my_project", "status > 'In Dev'")
      mingle_tracking_tool.validateTree(nil)

      presenter           = ApiV1::Config::TrackingTool::TrackingToolRepresenter.new(mingle_tracking_tool)
      actual_json         = presenter.to_hash(url_builder: UrlBuilder.new)
      expect(actual_json).to eq(mingle_tracking_tool_with_errors_hash)
    end
  end


  def external_tracking_tool_hash
    {
      type:       "external",
      attributes: {
        link:  "link",
        regex: "regex"
      }
    }
  end

  def external_tracking_tool_with_errors_hash
    {
      type:       "external",
      attributes: {
        link:  "",
        regex: ""
      },
        errors: {
          link: [
            "Link should be populated",
            "Link must be a URL containing '${ID}'. Go will replace the string '${ID}' with the first matched group from the regex at run-time."
          ],
          regex: ["Regex should be populated"]
        }
    }
  end

  def mingle_tracking_tool_hash
    {
      type:       "mingle",
      attributes: {
        base_url:            "http://mingle.example.com",
        project_identifier:  "my_project",
        mql_grouping_conditions: "status > 'In Dev'"
      }
    }
  end

  def mingle_tracking_tool_with_errors_hash
    {
      type:       "mingle",
      attributes: {
        base_url:            "http://mingle.example.com",
        project_identifier:  "my_project",
        mql_grouping_conditions: "status > 'In Dev'"
      },
      errors: {
        base_url: ["Should be a URL starting with https://"]
      }
    }
  end
end