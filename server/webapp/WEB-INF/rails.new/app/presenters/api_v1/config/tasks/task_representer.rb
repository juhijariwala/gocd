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
  module Config
    module Tasks
      class TaskRepresenter < ApiV1::BaseRepresenter
        alias_method :task, :represented
        property :type, exec_context: :decorator, skip_parse: true

        nested :attributes,
                 decorator: lambda { |task, *|
                   if task.instance_of? PluggableTask
                     PluggableTaskRepresenter
                   else
                     case task.getTaskType()
                       when ExecTask::TYPE
                         ExecTaskRepresenter
                       when AntTask::TYPE
                         AntTaskRepresenter
                       when NantTask::TYPE
                         NantTaskRepresenter
                       when RakeTask::TYPE
                         RakeTaskRepresenter
                       when FetchTask::TYPE
                         FetchTaskRepresenter
                       else
                         raise "not implemented"
                     end
                   end
                 }
        property :errors, decorator: ApiV1::Config::ErrorRepresenter, skip_parse: true, skip_render: lambda { |object, options| object.empty? }

        def type
          return "pluggable_task" if task.instance_of? PluggableTask
          task.getTaskType
        end

        def task_attributes
          task
        end

        def task_attributes=(value)
          @represented = value
        end

      end
    end
  end
end

