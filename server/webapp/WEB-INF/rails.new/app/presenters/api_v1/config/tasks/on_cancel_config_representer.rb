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
      class OnCancelConfigRepresenter < ApiV1::BaseRepresenter
        alias_method :on_cancel_config, :represented

        def from_hash(hash, options={})
          task = case hash['type']
                          when ExecTask::TYPE
                            ExecTask.new
                          when AntTask::TYPE
                            AntTask.new
                          when NantTask::TYPE
                            NantTask.new
                          when RakeTask::TYPE
                            RakeTask.new
                          when FetchTask::TYPE
                            FetchTask.new
                          when "pluggable_task"
                            PluggableTask.new
                          else
                            raise UnprocessableEntity, "Invalid Task type: #{hash['type']||hash[:type]}.It can be one of '{pluggable_task, exec, Ant, nant, rake, fetch}'"
                        end
          representer = TaskRepresenter.new(task)
          representer.from_hash(hash, options)
          com.thoughtworks.go.config.OnCancelConfig.new(representer.represented)
        end

        def to_hash(*options)
          return nil if @represented.getTask.getTaskType.eql?("killallchildprocess")
          TaskRepresenter.new(@represented.getTask).to_hash(url_builder: UrlBuilder.new)
        end
      end
    end
  end
end




