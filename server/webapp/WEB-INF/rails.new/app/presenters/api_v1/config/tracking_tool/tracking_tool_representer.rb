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
    module TrackingTool
      class TrackingToolRepresenter < ApiV1::BaseRepresenter
        alias_method :tracking_tool, :represented
        property :type, exec_context: :decorator, skip_parse: true
        nested :attributes,
               decorator: lambda { |tracking_tool, *|
                  case tracking_tool.getClass.getName
                    when 'com.thoughtworks.go.config.MingleConfig'
                      MingleTrackingToolRepresenter
                    when 'com.thoughtworks.go.config.TrackingTool'
                      ExternalTrackingToolRepresenter
                    else
                      raise "Not implemented"
                  end
                }

        property :errors, exec_context: :decorator, decorator: ApiV1::Config::ErrorRepresenter, skip_parse: true, skip_render: lambda { |object, options| object.empty? }


        def errors
          mapped_errors = {}
          tracking_tool.errors.each do |key, value|
            mapped_errors[matching_error_key(key)] = value
          end
          mapped_errors
        end

        private

        def error_keys
          tool_class = case tracking_tool.getClass.getName
            when 'com.thoughtworks.go.config.MingleConfig'
              MingleTrackingToolRepresenter
            when 'com.thoughtworks.go.config.TrackingTool'
              ExternalTrackingToolRepresenter
          end

          tool_class.new(tracking_tool).error_keys
        end

        def matching_error_key key
          return error_keys[key] if error_keys[key]
          key
        end

        def type
          if tracking_tool.instance_of? com.thoughtworks.go.config.MingleConfig
            "mingle"
          elsif tracking_tool.instance_of? com.thoughtworks.go.config.TrackingTool
            "external"
          else
            raise "not implemented"
          end
        end
      end
    end
  end
end
