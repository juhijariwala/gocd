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

describe ApiV1::Config::StageRepresenter do
  it 'should render stage with hal representation' do
    presenter = ApiV1::Config::StageRepresenter.new(get_stage_config)
    actual_json = presenter.to_hash(url_builder: UrlBuilder.new)

    expect(actual_json).to eq(stage_hash)
  end

  it "should convert from document to StageConfig" do
    stage_config = StageConfig.new

    ApiV1::Config::StageRepresenter.new(stage_config).from_hash(stage_hash)

    expected = get_stage_config
    expect(stage_config).to eq(expected)
  end

  it "should render errors" do
    stage_config = StageConfigMother.stageConfigWithEnvironmentVariable("stage#1")
    stage_config.getJobs().get(0).setTasks(com.thoughtworks.go.config.Tasks.new(FetchTask.new(CaseInsensitiveString.new(""),CaseInsensitiveString.new(""), CaseInsensitiveString.new(""),nil, nil )))
    stage_config.validateTree(com.thoughtworks.go.config.PipelineConfigSaveValidationContext::forChain([]))
    presenter = ApiV1::Config::StageRepresenter.new(stage_config)
    actual_json = presenter.to_hash(url_builder: UrlBuilder.new)

    expect(actual_json).to eq(stage_hash_with_errors)
  end

  def get_stage_config
    StageConfigMother.stageConfigWithEnvironmentVariable("stage1")
  end

  def stage_hash
    {
      name: "stage1",
      fetch_materials: true,
      clean_working_directory: false,
      never_cleanup_artifacts: false,
      approval: {
        type: "success",
        authorization: {}
      },
      environment_variables: [
        {
          secure: true,
          name: "MULTIPLE_LINES",
          encrypted_value:  get_stage_config.variables.get(0).getEncryptedValue
        },
        {
          secure: false,
          name: "COMPLEX",
          value: "This has very <complex> data"
        }
      ],
      jobs: [
          {
              name: "defaultJob",
              run_on_all_agents: false,
              run_instance_count: "3",
              timeout: "100",
              environment_variables: [
                  {secure: true,name: "MULTIPLE_LINES", encrypted_value: get_stage_config.getJobs.get(0).variables.get(0).getEncryptedValue}, {secure: false,name: "COMPLEX", value: "This has very <complex> data"}
              ],
              resources: [
                  "Linux",
                  "Java"
              ],
              tasks: [
                  {type: "ant", attributes: {working_dir: "working-directory", build_file: "build-file", target: "target"}}
              ],
              tabs: [
                  {
                      name: "coverage",
                      path: "Jcoverage/index.html"
                  },
                  {
                      name: "something",
                      path: "something/path.html"
                  }
              ],
              artifacts: [
                           {
                             source: "target/dist.jar",
                             destination: "pkg",
                             type: "build"
                           },
                           {
                             source: nil,
                             destination: "testoutput",
                             type: "test"
                           }
                         ],
              properties: [
                  {
                      name: "coverage.class",
                      source: "target/emma/coverage.xml",
                      xpath: "substring-before(//report/data/all/coverage[starts-with(@type,'class')]/@value, '%')"
                  }
              ]
          }
      ]
    }
  end

  def stage_hash_with_errors
    {
      name: "stage#1",
      fetch_materials: true,
      clean_working_directory: false,
      never_cleanup_artifacts: false,
      approval: {
        type: "success",
        authorization: {}
      },
      environment_variables: [
        {
          secure: true,
          name: "MULTIPLE_LINES",
          encrypted_value:  get_stage_config.variables.get(0).getEncryptedValue
        },
        {
          secure: false,
          name: "COMPLEX",
          value: "This has very <complex> data"
        }
      ],
      jobs: [
          {
              name: "defaultJob",
              run_on_all_agents: false,
              run_instance_count: "3",
              timeout: "100",
              environment_variables: [
                  {secure: true,name: "MULTIPLE_LINES", encrypted_value: get_stage_config.getJobs.get(0).variables.get(0).getEncryptedValue}, {secure: false,name: "COMPLEX", value: "This has very <complex> data"}
              ],
              resources: [
                  "Linux",
                  "Java"
              ],
              tasks: [
                  {
                      type: "fetch",
                      attributes: {pipeline: nil, stage: nil, job: nil, is_source_a_file: false, source: nil, destination: ""},
                      errors: {
                        job: ["Job is a required field."],
                        src: ["Should provide either srcdir or srcfile"],
                        stage: ["Stage is a required field."]
                      }
                  }
              ],
              tabs: [
                  {
                      name: "coverage",
                      path: "Jcoverage/index.html"
                  },
                  {
                      name: "something",
                      path: "something/path.html"
                  }
              ],
              artifacts: [
                           {
                             source: "target/dist.jar",
                             destination: "pkg",
                             type: "build"
                           },
                           {
                             source: nil,
                             destination: "testoutput",
                             type: "test",
                             errors: {source: ["Job 'defaultJob' has an artifact with an empty source"]}
                           }
                         ],
              properties: [
                  {
                      name: "coverage.class",
                      source: "target/emma/coverage.xml",
                      xpath: "substring-before(//report/data/all/coverage[starts-with(@type,'class')]/@value, '%')"
                  }
              ]
          }
      ],
      errors: {
        name: ["Invalid stage name 'stage#1'. This must be alphanumeric and can contain underscores and periods (however, it cannot start with a period). The maximum allowed length is 255 characters."]
      }
    }
  end
end