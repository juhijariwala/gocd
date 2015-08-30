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

module ApiV1
  class Config::JobRepresenter < ApiV1::BaseRepresenter
    alias_method :job, :represented

    property :name, exec_context: :decorator
    property :run_on_all_agents, exec_context: :decorator
    property :run_instance_count, skip_nil: true
    property :timeout, skip_nil: true
    collection :environment_variables, exec_context: :decorator, decorator: ApiV1::Config::EnvironmentVariableRepresenter, class: com.thoughtworks.go.config.EnvironmentVariableConfig, skip_nil: true, render_empty: false
    collection :resources, exec_context: :decorator, skip_nil: true, render_empty: false
    collection :tasks, exec_context: :decorator, decorator: ApiV1::Config::Tasks::TaskRepresenter, skip_nil: true, render_empty: false,
            class: lambda { |hash, *|
                case hash[:type] || hash['type']
                  when "pluggable_task"
                    PluggableTask
                  when ExecTask::TYPE
                    ExecTask
                  when AntTask::TYPE
                    AntTask
                  when NantTask::TYPE
                    NantTask
                  when RakeTask::TYPE
                    RakeTask
                  when FetchTask::TYPE
                    FetchTask
                  else
                    raise "not implemented"
                end
            }

    collection :tabs, exec_context: :decorator, decorator: TabConfigRepresenter, class: com.thoughtworks.go.config.Tab, skip_nil: true, render_empty: false
    collection :artifacts, exec_context: :decorator, decorator: ApiV1::Config::ArtifactRepresenter,skip_nil: true, render_empty: false,
        class: lambda { |hash, *|
          case hash['type'] || hash[:type]
            when "build"
              com.thoughtworks.go.config.ArtifactPlan
            when "test"
              com.thoughtworks.go.config.TestArtifactPlan
            else
              raise "Not implemented"
          end
        }

    collection :properties, exec_context: :decorator, decorator: ApiV1::Config::PropertyConfigRepresenter, class: com.thoughtworks.go.config.ArtifactPropertiesGenerator, skip_nil: true, render_empty: false
    property :errors, decorator: ApiV1::Config::ErrorRepresenter, skip_parse: true, skip_render: lambda { |object, options| object.empty? }

    def name
      job.name().to_s
    end

    def name=(value)
      job.setName(value)
    end

    def run_on_all_agents
      job.isRunOnAllAgents()
    end

    def run_on_all_agents=(value)
      job.setRunOnAllAgents(value)
    end

    def artifacts
      job.artifactPlans()
    end

    def artifacts=(value)
      artifact_plans=ArtifactPlans.new()
      value.each {|artifact| artifact_plans.add(artifact)}
      job.setArtifactPlans(artifact_plans)
    end

    def environment_variables
      job.getVariables()
    end
    def environment_variables=(array_of_variables)
      job.setVariables(EnvironmentVariablesConfig.new(array_of_variables))
    end

    def resources
      job.resources().map { |resource| resource.getName() }
    end

    def resources=(value)
      value.each {|resource| job.resources.add(com.thoughtworks.go.config.Resource.new(resource))}
    end

    def tasks
      job.getTasks
    end

    def tasks=(value)
      job.setTasks(com.thoughtworks.go.config.Tasks.new(value.to_java(Task)))
    end

    def tabs
      job.getTabs
    end

    def tabs=(value)
      job.setTabs(com.thoughtworks.go.config.Tabs.new(value.to_java(com.thoughtworks.go.config.Tab)))
    end

    def properties
      job.getProperties
    end

    def properties=(value)
      job.setProperties(com.thoughtworks.go.config.ArtifactPropertiesGenerators.new(value.to_java(com.thoughtworks.go.config.ArtifactPropertiesGenerator)))
    end
  end
end