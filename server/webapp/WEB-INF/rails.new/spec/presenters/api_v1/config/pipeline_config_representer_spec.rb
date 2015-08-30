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

describe ApiV1::Config::PipelineConfigRepresenter do
  it 'renders a pipeline with hal representation' do
    presenter   = ApiV1::Config::PipelineConfigRepresenter.new(get_pipeline_config)
    actual_json = presenter.to_hash(url_builder: UrlBuilder.new)

    expect(actual_json).to have_links(:self, :find, :doc)
    expect(actual_json).to have_link(:self).with_url('http://test.host/api/admin/pipelines/wunderbar')
    expect(actual_json).to have_link(:find).with_url('http://test.host/api/admin/pipelines/:name')
    expect(actual_json).to have_link(:doc).with_url('http://api.go.cd/#pipeline_config')
    actual_json.delete(:_links)
    expect(actual_json).to eq(pipeline_hash)
  end

  it "should convert from full blown document to PipelineConfig" do
    pipeline_config = PipelineConfig.new

    ApiV1::Config::PipelineConfigRepresenter.new(pipeline_config).from_hash(pipeline_hash)
    expect(pipeline_config).to eq(get_pipeline_config)
  end

  it "should convert from minimal json to PipelineConfig" do
    pipeline_config = PipelineConfig.new

    ApiV1::Config::PipelineConfigRepresenter.new(pipeline_config).from_hash(pipeline_hash_basic)
    expect(pipeline_config.name.to_s).to eq("wunderbar")
    expect(pipeline_config.getParams.isEmpty).to eq(true)
    expect(pipeline_config.variables.isEmpty).to eq(true)
  end

  it "should render errors" do
    pipeline_config  = PipelineConfig.new(CaseInsensitiveString.new("wunderbar"), "", "", true, nil, ArrayList.new)
    pipeline_config.validateTree(com.thoughtworks.go.config.PipelineConfigSaveValidationContext::forChain(pipeline_config))

    presenter   = ApiV1::Config::PipelineConfigRepresenter.new(pipeline_config)
    actual_json = presenter.to_hash(url_builder: UrlBuilder.new)
    actual_json.delete(:_links)
    expect(actual_json).to eq(expected_hash_with_errors)
  end

  it "should render errors on nested objects" do
    pipeline_config  = get_invalid_pipeline_config
    PipelineConfigurationCache::getInstance().onConfigChange(BasicCruiseConfig.new(BasicPipelineConfigs.new(get_pipeline_config)));
    pipeline_config.validateTree(com.thoughtworks.go.config.PipelineConfigSaveValidationContext::forChain(pipeline_config))

    presenter   = ApiV1::Config::PipelineConfigRepresenter.new(pipeline_config)
    actual_json = presenter.to_hash(url_builder: UrlBuilder.new)
    actual_json.delete(:_links)
    expect(actual_json).to eq(expected_hash_with_nested_errors)
  end

  def expected_hash_with_errors
    {
        label_template:          "",
        enable_pipeline_locking: false,
        name:                    "wunderbar",
        materials:               [],
        stages:                  [],
        timer:                   {spec: "", only_on_changes: true, errors: {spec: ["Invalid cron syntax"]}},
        errors: {
           materials: ["A pipeline must have at least one material"],
           labelTemplate: ["Invalid label. Label should be composed of alphanumeric text, it should contain the builder number as ${COUNT}, can contain a material revision as ${<material-name>} of ${<material-name>[:<number>]}, or use params as \#{<param-name>}."],
           stages: ["A pipeline must have at least one stage"]
        }
    }
  end

  def expected_hash_with_nested_errors
    {
        label_template:          "foo-1.0.${COUNT}-${svn}",
        enable_pipeline_locking: false,
        name:                    "wunderbar",
        params: [
          {
              name: nil, value: "echo",
              errors: {
                name: [
                  "Parameter cannot have an empty name for pipeline 'wunderbar'.",
                  "Invalid parameter name 'null'. This must be alphanumeric and can contain underscores and periods (however, it cannot start with a period). The maximum allowed length is 255 characters."
                ]
              }
          }
        ],
        materials: [
          {
              type: "SvnMaterial", attributes: {url: "http://some/svn/url", destination: "svnDir", filter: nil, name: "http___some_svn_url", auto_update: true, check_externals: false, username: nil}
          },
          {
              type: "GitMaterial", attributes: {url: nil, destination: nil, filter: nil, name: nil, auto_update: true, branch: "master", submodule_folder: nil},
              errors: {folder: ["Destination directory is required when specifying multiple scm materials"], url: ["URL cannot be blank"]}
          }
        ],
        stages:  [{name: "stage1", fetch_materials: true, clean_working_directory: false, never_cleanup_artifacts: false, approval: {type: "success", authorization: {}}, jobs: []}],
        timer: {spec: "0 0 22 ? * MON-FRI", only_on_changes: true},
        tracking_tool: {
          type: "external", attributes: {link: "", regex: ""},
          errors: {
            link: ["Link should be populated", "Link must be a URL containing '${ID}'. Go will replace the string '${ID}' with the first matched group from the regex at run-time."],
            regex: ["Regex should be populated"]
          }
        },
        errors: {
           labelTemplate: ["You have defined a label template in pipeline wunderbar that refers to a material called svn, but no material with this name is defined."]
        }
    }
  end

  def get_invalid_pipeline_config
    material_configs = MaterialConfigsMother.defaultMaterialConfigs()
    git = GitMaterialConfig.new
    git.setFolder(nil);
    material_configs.add(git);

    pipeline_config  = PipelineConfig.new(CaseInsensitiveString.new("wunderbar"), "foo-1.0.${COUNT}-${svn}", "0 0 22 ? * MON-FRI", true, material_configs, ArrayList.new)
    pipeline_config.addParam(ParamConfig.new(nil, "echo"))
    pipeline_config.add(StageConfigMother.stageConfig("stage1"))
    pipeline_config.setTrackingTool(TrackingTool.new())
    pipeline_config
  end

  def get_pipeline_config
    material_configs = MaterialConfigsMother.defaultMaterialConfigs()
    pipeline_config  = PipelineConfig.new(CaseInsensitiveString.new("wunderbar"), "foo-1.0.${COUNT}-${svn}", "0 0 22 ? * MON-FRI", true, material_configs, ArrayList.new)
    pipeline_config.setVariables(EnvironmentVariablesConfigMother.environmentVariables())
    pipeline_config.addParam(ParamConfig.new("COMMAND", "echo"))
    pipeline_config.addParam(ParamConfig.new("WORKING_DIR", "/repo/branch"))
    pipeline_config.add(StageConfigMother.stageConfigWithEnvironmentVariable("stage1"))
    pipeline_config.setTrackingTool(TrackingTool.new("link", "regex"))
    pipeline_config
  end

  def pipeline_hash
    {
      label_template:          "foo-1.0.${COUNT}-${svn}",
      enable_pipeline_locking: false,
      name:                    "wunderbar",
      params:                  get_pipeline_config.getParams().collect { |j| ApiV1::Config::ParamRepresenter.new(j).to_hash(url_builder: UrlBuilder.new) },
      environment_variables:   get_pipeline_config.variables().collect { |j| ApiV1::Config::EnvironmentVariableRepresenter.new(j).to_hash(url_builder: UrlBuilder.new) },
      materials:               get_pipeline_config.materialConfigs().collect { |j| ApiV1::Config::Materials::MaterialRepresenter.new(j).to_hash(url_builder: UrlBuilder.new) },
      stages:                  get_pipeline_config.getStages().collect { |j| ApiV1::Config::StageRepresenter.new(j).to_hash(url_builder: UrlBuilder.new) },
      tracking_tool:           ApiV1::Config::TrackingTool::TrackingToolRepresenter.new(get_pipeline_config.getTrackingTool).to_hash(url_builder: UrlBuilder.new),
      timer:                   ApiV1::Config::TimerRepresenter.new(get_pipeline_config.getTimer).to_hash(url_builder: UrlBuilder.new)
    }
  end

  def pipeline_hash_basic
{
    label_template: "foo-1.0.${COUNT}-${svn}",
    enable_pipeline_locking: false,
    name: "wunderbar",
    materials: [
        {
            type: "SvnMaterial",
            attributes: {
                url: "http://some/svn/url",
                destination: "svnDir",
                check_externals: false
            },
            name: "http___some_svn_url",
            auto_update: true
        }
    ],
    stages: [
        {
            name: "stage1",
            fetch_materials: true,
            clean_working_directory: false,
            never_cleanup_artifacts: false,
            jobs: [
                {
                    name: "defaultJob",
                    tasks: [
                        {
                            type: "ant",
                            attributes: {
                                working_dir: "working-directory",
                                build_file: "build-file",
                                target: "target"
                            }
                        }
                    ]
                }
            ]
        }
    ],
}
  end


end
