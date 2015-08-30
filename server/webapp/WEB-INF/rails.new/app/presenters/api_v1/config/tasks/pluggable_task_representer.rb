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
      class PluggableTaskRepresenter < ApiV1::Config::Tasks::BaseTaskRepresenter
        alias_method :pluggable_task, :represented

        property :plugin_configuration, decorator: PluginConfigurationRepresenter, class: PluginConfiguration
        collection :configuration, exec_context: :decorator, decorator: PluginConfigurationPropertyRepresenter,:parse_strategy => lambda { |fragment, i, options|
                                   task_config = PluggableTaskConfigStore.store().preferenceFor(pluggable_task.plugin_configuration.getId()).getConfig()
                                   #TODO: review handleSecureValueConfiguration

                                   property_definition = task_config.get(fragment[:key])
                                   #TODO: handle property_definition being nil
                                   if (configuration.getProperty(fragment[:key]).nil?)
                                     configuration.addNewConfiguration(fragment[:key], property_definition.getOption(com.thoughtworks.go.plugin.api.config.Property::SECURE))
                                   end
                                   config_property = configuration.getProperty(fragment[:key])
                                   config_property.setConfigurationValue(ConfigurationValue.new(fragment[:value]))
                                   config_property.handleSecureValueConfiguration(property_definition.getOption(com.thoughtworks.go.plugin.api.config.Property::SECURE))
                                   config_property
                                 }


        def configuration
          pluggable_task.getConfiguration()
        end

        def configurationfoo=(hash)
          task_config = PluggableTaskConfigStore.store().preferenceFor(pluggable_task.plugin_configuration.getId()).getConfig()
          #TODO: review handleSecureValueConfiguration

          hash.each do |property|
            property_definition = task_config.get(property[:key])
            #TODO: handle property_definition being nil
            if (pluggable_task.getConfiguration().getProperty(property[:key]).nil?)
              pluggable_task.getConfiguration().addNewConfiguration(property[:key], property_definition.getOption(com.thoughtworks.go.plugin.api.config.Property::SECURE))
            end
            config_property = pluggable_task.getConfiguration().getProperty(property[:key])
            config_property.setConfigurationValue(ConfigurationValue.new(property[:value]))
            config_property.handleSecureValueConfiguration(property_definition.getOption(com.thoughtworks.go.plugin.api.config.Property::SECURE))
          end
        end
      end
    end
  end
end