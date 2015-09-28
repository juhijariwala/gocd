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

describe ApiV1::Config::Tasks::TaskRepresenter do
  include TaskMother

  describe "exec task" do
    before(:each) do
      @task      = with_run_if(RunIfConfig::PASSED, with_run_if(RunIfConfig::FAILED, simple_exec_task_with_args_list))
      @presenter = ApiV1::Config::Tasks::TaskRepresenter.new(@task)
    end

    it 'should render exec task with hal representation' do
      actual_json = @presenter.to_hash(url_builder: UrlBuilder.new)
      expect(actual_json).to eq(exec_task_hash)
    end

    it 'should render exec task with and on-cancel task hal representation' do
      @task.setCancelTask(simple_exec_task_with_args_list)
      actual_json = @presenter.to_hash(url_builder: UrlBuilder.new)
      expect(actual_json).to eq(exec_task_hash_with_on_cancel)
    end

    it "should convert hash to ExecTask" do
      presenter = ApiV1::Config::Tasks::TaskRepresenter.new(ExecTask.new)
      presenter.from_hash(exec_task_hash)
      expect(presenter.represented).to eq(@task)
    end
  end


  describe :ant do
    before(:each) do
      @ant = with_run_if(RunIfConfig::PASSED, with_run_if(RunIfConfig::FAILED, ant_task("build.xml", "package", "hero/ka/directory")))
    end

    it 'should render ant task with hal representation' do
      presenter   = ApiV1::Config::Tasks::TaskRepresenter.new(@ant)
      actual_json = presenter.to_hash(url_builder: UrlBuilder.new)
      expect(actual_json).to eq(ant_task_hash)
    end

    it "should convert hash to AntTask" do
      presenter = ApiV1::Config::Tasks::TaskRepresenter.new(AntTask.new)
      presenter.from_hash(ant_task_hash)
      expect(presenter.represented).to eq(@ant)
    end
  end

  describe :nant do
    before(:each) do
      @nant = with_run_if(RunIfConfig::PASSED, with_run_if(RunIfConfig::FAILED, nant_task("build.xml", "package", "hero/ka/directory")))
    end
    it 'should render nant task with hal representation' do
      presenter   = ApiV1::Config::Tasks::TaskRepresenter.new(@nant)
      actual_json = presenter.to_hash(url_builder: UrlBuilder.new)
      expect(actual_json).to eq(nant_task_hash)
    end

    it "should convert hash to NantTask" do
      presenter = ApiV1::Config::Tasks::TaskRepresenter.new(NantTask.new)
      presenter.from_hash(nant_task_hash)
      expect(presenter.represented).to eq(@nant)
    end

  end

  describe :rake do
    before(:each) do
      @rake = with_run_if(RunIfConfig::PASSED, with_run_if(RunIfConfig::FAILED, rake_task("build.xml", "package", "hero/ka/directory")))
    end
    it 'should render rake task with hal representation' do

      presenter   = ApiV1::Config::Tasks::TaskRepresenter.new(@rake)
      actual_json = presenter.to_hash(url_builder: UrlBuilder.new)
      expect(actual_json).to eq(rake_task_hash)
    end
    it "should convert hash to RakeTask" do
      presenter = ApiV1::Config::Tasks::TaskRepresenter.new(RakeTask.new)
      presenter.from_hash(rake_task_hash)
      expect(presenter.represented).to eq(@rake)
    end

  end

  describe :fetch do
    before(:each) do
      @fetch = with_run_if(RunIfConfig::PASSED, with_run_if(RunIfConfig::FAILED, fetch_task()))
    end
    it 'should render fetch task with hal representation' do
      presenter   = ApiV1::Config::Tasks::TaskRepresenter.new(@fetch)
      actual_json = presenter.to_hash(url_builder: UrlBuilder.new)
      expect(actual_json).to eq(fetch_task_hash)
    end
    it "should convert hash to FetchTask" do
      presenter = ApiV1::Config::Tasks::TaskRepresenter.new(FetchTask.new)
      presenter.from_hash(fetch_task_hash)
      expect(presenter.represented).to eq(@fetch)
    end

    it "should represent errors" do
      fetch_task = FetchTask.new(CaseInsensitiveString.new(""), CaseInsensitiveString.new(""), CaseInsensitiveString.new(""), nil, nil)
      validation_context = double("ValidationContext")
      validation_context.stub(:isWithinPipelines).and_return(false)
      fetch_task.validateTree(validation_context)

      presenter   = ApiV1::Config::Tasks::TaskRepresenter.new(fetch_task)
      actual_json = presenter.to_hash(url_builder: UrlBuilder.new)
      expect(actual_json).to eq(errors_hash)
    end

    def errors_hash
      {
          type: "fetch",
          attributes: {pipeline: nil, stage: nil, job: nil, is_source_a_file: false, source: nil, destination: ""},
          errors: {
          job: ["Job is a required field."],
          src: ["Should provide either srcdir or srcfile"],
          stage: ["Stage is a required field."]
      }
      }
    end
  end

  describe :pluggable do
    before(:each) do
      config          = [ConfigurationProperty.new(ConfigurationKey.new("simple_key"), ConfigurationValue.new("value")), ConfigurationProperty.new(ConfigurationKey.new("secure_key"), EncryptedConfigurationValue.new("encrypted"))]
      @pluggable_task = with_run_if(RunIfConfig::PASSED, with_run_if(RunIfConfig::FAILED, simple_task_plugin_with_on_cancel_config("curl", config)))
      @pluggable_task.setCancelTask(simple_exec_task_with_args_list)
    end

    it 'should render pluggable task with hal representation' do

      presenter   = ApiV1::Config::Tasks::TaskRepresenter.new(@pluggable_task)
      actual_json = presenter.to_hash(url_builder: UrlBuilder.new)
      expect(actual_json).to eq(pluggable_task_hash)
    end

    it "should convert hash to PluggableTask" do
      store           = double("PluggableTaskConfigStore")
      simple_property = TaskConfigProperty.new("simple_key", nil)
      secure_property = TaskConfigProperty.new("secure_key", nil).with(com.thoughtworks.go.plugin.api.config.Property::SECURE, true)

      task = TaskMother::StubTask.new
      task.config.add(simple_property)
      task.config.add(secure_property)
      task_preference = TaskPreference.new(task)
      store.stub(:preferenceFor).with(anything).and_return(task_preference)
      PluggableTaskConfigStore.stub(:store).and_return(store)

      foo       = PluggableTask.new
      presenter = ApiV1::Config::Tasks::TaskRepresenter.new(foo)
      presenter.from_hash(pluggable_task_hash_for_put)
      expect(presenter.represented.configuration.get(0)).to eq(@pluggable_task.configuration.get(0))
      expect(presenter.represented.configuration.get(1).getConfigurationKey.name).to eq(@pluggable_task.configuration.get(1).getConfigurationKey.name)
      expect(presenter.represented.configuration.get(1).getEncryptedValue.value).to eq(GoCipher.new.encrypt("unencrypted_value"))
      expect(presenter.represented.getPluginConfiguration).to eq(@pluggable_task.getPluginConfiguration)
      expect(presenter.represented.getConditions).to eq(@pluggable_task.getConditions)
      expect(presenter.represented.onCancelConfig.getTask).to eq(@pluggable_task.onCancelConfig.getTask)
      expect(presenter.represented.onCancelConfig).to eq(@pluggable_task.onCancelConfig)
    end
  end

  def pluggable_task_hash_for_put
    {
      type:       "pluggable_task",
      attributes: {
        run_if:               ["failed", "passed"],
        on_cancel:            {
          type:       "exec",
          attributes: {
            command:     "ls",
            arguments:   [
                           "-l",
                           "-a"
                         ],
            working_dir: "hero/ka/directory"
          }
        },
        run_if:               ["failed", "passed"],
        plugin_configuration: {
          id:      "curl",
          version: "1.0"
        },
        configuration:        [
                                {
                                  key:   "simple_key",
                                  value: "value"
                                },
                                {
                                  key:   "secure_key",
                                  value: "unencrypted_value"
                                }
                              ]
      }
    }
  end

  def pluggable_task_hash
    {
      type:       "pluggable_task",
      attributes: {
        run_if:               ["failed", "passed"],
        on_cancel:            {
          type:       "exec",
          attributes: {
            command:     "ls",
            arguments:   [
                           "-l",
                           "-a"
                         ],
            working_dir: "hero/ka/directory"
          }
        },
        plugin_configuration: {
          id:      "curl",
          version: "1.0"
        },
        configuration:        [
                                {
                                  key:   "simple_key",
                                  value: "value"
                                },
                                {
                                  key:             "secure_key",
                                  encrypted_value: "****"
                                }
                              ]
      }
    }
  end

  def fetch_task_hash
    {
      type:       "fetch",
      attributes: {
        run_if:           ["failed", "passed"],
        on_cancel:        {
          type:       "exec",
          attributes: {
            command:     "echo",
            args:        "'failing'",
            working_dir: "oncancel_working_dir"
          }
        },
        pipeline:         "pipeline",
        stage:            "stage",
        job:              "job",
        source:           "src",
        is_source_a_file: true,
        destination:      "dest"
      }
    }
  end

  def rake_task_hash
    {
      type:       "rake",
      attributes: {
        run_if:      ["failed", "passed"],
        build_file:  "build.xml",
        target:      "package",
        working_dir: "hero/ka/directory",
      }
    }
  end

  def nant_task_hash
    {
      type:       "nant",
      attributes: {
        run_if:      ["failed", "passed"],
        build_file:  "build.xml",
        target:      "package",
        working_dir: "hero/ka/directory",
        nant_path:   nil
      }
    }
  end

  def ant_task_hash
    {
      type:       "ant",
      attributes: {
        run_if:      ["failed", "passed"],
        working_dir: "hero/ka/directory",
        build_file:  "build.xml",
        target:      "package"

      }
    }
  end

  def exec_task_hash
    {
      type:       "exec",
      attributes: {
        run_if:      ["failed", "passed"],
        command:     "ls",
        arguments:   [
                       "-l",
                       "-a"
                     ],
        working_dir: "hero/ka/directory"
      }
    }
  end

  def exec_task_hash_with_on_cancel
    {
      type:       "exec",
      attributes: {
        run_if:      ["failed", "passed"],
        on_cancel:   {
          type:       "exec",
          attributes: {
            command:     "ls",
            arguments:   [
                           "-l",
                           "-a"
                         ],
            working_dir: "hero/ka/directory"
          }
        },
        command:     "ls",
        arguments:   [
                       "-l",
                       "-a"
                     ],
        working_dir: "hero/ka/directory"
      }
    }
  end
end
