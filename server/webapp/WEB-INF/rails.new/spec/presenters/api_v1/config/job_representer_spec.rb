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

describe ApiV1::Config::JobRepresenter do
  it 'should render stage with hal representation' do
    presenter = ApiV1::Config::JobRepresenter.new(get_job_config)
    actual_json = presenter.to_hash(url_builder: UrlBuilder.new)

    expect(actual_json).to eq(job_hash)
  end

  it "should convert from document to JobConfig" do
    job_config = JobConfig.new

    ApiV1::Config::JobRepresenter.new(job_config).from_hash(job_hash)
    expected = get_job_config
    expect(job_config).to eq(expected)
    expect(job_config.tasks).to eq(expected.tasks)
    expect(job_config.artifactPlans).to eq(expected.artifactPlans)
    expect(job_config.artifactPlans.first.instance_of? ArtifactPlan).to eq(true)
    expect(job_config.artifactPlans.last.instance_of? TestArtifactPlan).to eq(true)
  end

  it "should map errors" do
    job_config = JobConfig.new
    plans = ArtifactPlans.new
    plans.add(ArtifactPlan.new(com.thoughtworks.go.domain.ArtifactType::unit, nil, "../foo"))
    job_config.setArtifactPlans(plans)
    job_config.setTasks(com.thoughtworks.go.config.Tasks.new(FetchTask.new(CaseInsensitiveString.new(""),CaseInsensitiveString.new(""), CaseInsensitiveString.new(""),nil, nil )))
    job_config.setTabs(com.thoughtworks.go.config.Tabs.new(com.thoughtworks.go.config.Tab.new("coverage#1", "/Jcoverage/index.html"), com.thoughtworks.go.config.Tab.new("coverage#1", "/Jcoverage/path.html")))

    job_config.validateTree(PipelineConfigSaveValidationContext.forChain(PipelineConfig.new, StageConfig.new, job_config))
    presenter = ApiV1::Config::JobRepresenter.new(job_config)
    actual_json = presenter.to_hash(url_builder: UrlBuilder.new)

    expect(actual_json).to eq(job_hash_with_errors(job_config))

  end

  def job_hash_with_errors job
    {
      name:                  "",
      run_on_all_agents:     false,
      run_instance_count:    nil,
      timeout:               nil,
      environment_variables: [],
      resources:             nil,
      tasks:                 [
                               {
                                 type:       "fetch",
                                 attributes: {pipeline: nil, stage: nil, job: nil, is_source_a_file: false, source: nil, destination: ""},
                                 errors:     {
                                   job:   ["Job is a required field."],
                                   src:   ["Should provide either srcdir or srcfile"],
                                   stage: ["Stage is a required field."]
                                 }
                               }
                             ],
      tabs:                  [
                               {
                                 name:   "coverage#1",
                                 path:   "/Jcoverage/index.html",
                                 errors: {
                                   name: ["Tab name 'coverage#1' is not unique.",
                                          "Tab name 'coverage#1' is invalid. This must be alphanumeric and can contain underscores and periods."
                                         ]
                                 }
                               },
                               {
                                 name:   "coverage#1",
                                 path:   "/Jcoverage/path.html",
                                 errors: {
                                   name: ["Tab name 'coverage#1' is not unique.",
                                          "Tab name 'coverage#1' is invalid. This must be alphanumeric and can contain underscores and periods."
                                         ]
                                 }
                               }
                             ],
      artifacts:             [
                               {
                                 source:      nil,
                                 destination: "../foo",
                                 type:        "test",
                                 errors:      {
                                   destination: ["Invalid destination path. Destination path should match the pattern "+ com.thoughtworks.go.config.validation.FilePathTypeValidator::PATH_PATTERN],
                                   source:      ["Job 'null' has an artifact with an empty source"]

                                 }
                               }
                             ],
      properties: nil,
      errors:                {
        name: ["Name is a required field"]
      }
    }
  end

  def get_job_config
    com.thoughtworks.go.helper.JobConfigMother.jobConfig()
  end

  def job_hash
    {
      name: "defaultJob",
      run_on_all_agents: false,
      run_instance_count: "3",
      timeout: "100",
      environment_variables: [
          {secure: true,name: "MULTIPLE_LINES", encrypted_value: get_job_config.variables.get(0).getEncryptedValue }, {secure: false,name: "COMPLEX", value: "This has very <complex> data" }
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
  end
end