##########################################################################
# Copyright 2016 ThoughtWorks, Inc.
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
describe ApiV2::Config::Materials::PluggableScmMaterialRepresenter do

  describe :pluggable do
    before :each do
      @go_config = BasicCruiseConfig.new

    end
    it "should represent a pluggable scm material" do
      pluggable_scm_material = MaterialConfigsMother.pluggableSCMMaterialConfig()

      config_property1 = ConfigurationPropertyMother.create("key1",true,"val1")
      config_property2= ConfigurationPropertyMother.create("key2",false,"val2")

      pluggable_scm_material.getSCMConfig.getConfiguration.add(config_property1)
      pluggable_scm_material.getSCMConfig.getConfiguration.add(config_property2)
      presenter              = ApiV2::Config::Materials::MaterialRepresenter.prepare(pluggable_scm_material)
      actual_json            = presenter.to_hash(url_builder: UrlBuilder.new)
      expect(actual_json).to eq(pluggable_scm_material_hash)
    end

    it "should deserialize" do
      pluggable_scm_material = MaterialConfigsMother.pluggableSCMMaterialConfig()

      config_property1 = ConfigurationPropertyMother.create("key1",true,"val1")
      config_property2= ConfigurationPropertyMother.create("key2",false,"val2")

      pluggable_scm_material.getSCMConfig.getConfiguration.add(config_property1)
      pluggable_scm_material.getSCMConfig.getConfiguration.add(config_property2)
      scm = pluggable_scm_material.getSCMConfig

      presenter           = ApiV2::Config::Materials::MaterialRepresenter.new(PluggableSCMMaterialConfig.new)
      deserialized_object = presenter.from_hash(pluggable_scm_material_hash)
      expect(deserialized_object.getScmId).to eq("scm-id")
      expect(deserialized_object.getSCMConfig).to eq(scm)
      expect(deserialized_object.getFolder).to eq("des-folder")
      expect(deserialized_object.filter.getStringForDisplay).to eq("**/*.html,**/foobar/")
    end

    it "should deserialize pluggable scm material with nulls" do
      presenter           = ApiV2::Config::Materials::MaterialRepresenter.new(PluggableSCMMaterialConfig.new)
      deserialized_object = presenter.from_hash({
                                                  type:       "plugin",
                                                  attributes: {
                                                    ref: nil,
                                                    scm_config:  {
                                                      id:                   nil,
                                                      name:                 nil,
                                                      auto_update:          true,
                                                      plugin_configuration: {
                                                        id:      "plugin",
                                                        version: "1.0"
                                                      },
                                                      configuration: [
                                                                              {
                                                                                key:   "key1",
                                                                                encrypted_value: GoCipher.new.encrypt("val1")
                                                                              },
                                                                              {
                                                                                key:   "key2",
                                                                                value: "val2"
                                                                              }
                                                                            ]
                                                    },
                                                    destination: nil
                                                  }
                                                })
      expect(deserialized_object.name.to_s).to eq("")
      expect(deserialized_object.getScmId).to be_nil
      expect(deserialized_object.getFolder).to be_nil
      # expect(ReflectionUtil::getField(deserialized_object, "filter")).to be_nil
    end

    it "should render errors" do
      pluggable_scm_material = PluggableSCMMaterialConfig.new(CaseInsensitiveString.new(''), nil, '/dest', nil)
      material_configs       = MaterialConfigs.new(pluggable_scm_material);
      material_configs.validateTree(PipelineConfigSaveValidationContext.forChain(true, "group", PipelineConfig.new()))

      presenter              = ApiV2::Config::Materials::MaterialRepresenter.new(material_configs.first())
      actual_json            = presenter.to_hash(url_builder: UrlBuilder.new)
      expected_material_hash = expected_material_hash_with_errors
      expect(actual_json).to eq(expected_material_hash)
    end

    def pluggable_scm_material_hash
      {
        type:       "plugin",
        attributes: {
          ref: "scm-id",
          scm_config:  {
            id:                   "scm-id",
            name:                 "scm-scm-id",
            auto_update:          true,
            plugin_configuration: {
              id:      "plugin",
              version: "1.0"
            },
            configuration: [
                             {
                               key:   "key1",
                               encrypted_value: GoCipher.new.encrypt("val1")
                             },
                             {
                               key:   "key2",
                               value: "val2"
                             }
                           ]
          },
          filter:      {
            ignore: [
                      "**/*.html",
                      "**/foobar/"
                    ]
          },
          destination: "des-folder"
        }
      }
    end

    def expected_material_hash_with_errors
      {
        type:       "plugin",
        attributes: {
          ref:         nil,
          filter:      nil,
          destination: "/dest"
        },
        errors:     {
          destination: ["Dest folder '/dest' is not valid. It must be a sub-directory of the working folder."],
          ref:         ["Please select a SCM"]
        }
      }
    end

  end
end
