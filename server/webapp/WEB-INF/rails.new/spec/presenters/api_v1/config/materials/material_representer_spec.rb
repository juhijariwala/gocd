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

describe ApiV1::Config::Materials::MaterialRepresenter do
  describe :git do
    it "should represent a git material" do
      presenter = ApiV1::Config::Materials::MaterialRepresenter.prepare(MaterialConfigsMother.gitMaterialConfig())
      actual_json = presenter.to_hash(url_builder: UrlBuilder.new)
      expect(actual_json).to eq(git_material_hash)
    end

    it "should deserialize" do
      presenter = ApiV1::Config::Materials::MaterialRepresenter.new(GitMaterialConfig.new)
      deserialized_object = presenter.from_hash(git_material_hash)
      expected = MaterialConfigsMother.gitMaterialConfig()
      expect(deserialized_object.autoUpdate).to eq(expected.autoUpdate)
      expect(deserialized_object.name).to eq(expected.name)
      expect(deserialized_object).to eq(expected)
    end
  end

  describe :svn do
    it "should represent a svn material" do
      presenter = ApiV1::Config::Materials::MaterialRepresenter.prepare(MaterialConfigsMother.svnMaterialConfig())
      actual_json = presenter.to_hash(url_builder: UrlBuilder.new)
      expect(actual_json).to eq(svn_material_hash)
    end

    it "should deserialize" do
      presenter = ApiV1::Config::Materials::MaterialRepresenter.new(SvnMaterialConfig.new)
      deserialized_object = presenter.from_hash(svn_material_hash)
      expected = MaterialConfigsMother.svnMaterialConfig()
      expect(deserialized_object.autoUpdate).to eq(expected.autoUpdate)
      expect(deserialized_object.name).to eq(expected.name)
      expect(deserialized_object).to eq(expected)
    end
  end

    describe :hg do
      it "should represent a hg material" do
        presenter   = ApiV1::Config::Materials::MaterialRepresenter.prepare(MaterialConfigsMother.hgMaterialConfigFull())
        actual_json = presenter.to_hash(url_builder: UrlBuilder.new)
        expect(actual_json).to eq(hg_material_hash)
      end

    it "should deserialize" do
      presenter = ApiV1::Config::Materials::MaterialRepresenter.new(HgMaterialConfig.new)
      deserialized_object = presenter.from_hash(hg_material_hash)
      expected = MaterialConfigsMother.hgMaterialConfigFull()
      expect(deserialized_object.autoUpdate).to eq(expected.autoUpdate)
      expect(deserialized_object.name).to eq(expected.name)
      expect(deserialized_object).to eq(expected)
    end
  end

  describe :tfs do
    it "should represent a tfs material" do
      presenter   = ApiV1::Config::Materials::MaterialRepresenter.prepare(MaterialConfigsMother.tfsMaterialConfig())
      actual_json = presenter.to_hash(url_builder: UrlBuilder.new)
      expect(actual_json).to eq(tfs_material_hash)
    end

    it "should deserialize" do
      presenter = ApiV1::Config::Materials::MaterialRepresenter.new(TfsMaterialConfig.new)
      deserialized_object = presenter.from_hash(tfs_material_hash)
      expected = MaterialConfigsMother.tfsMaterialConfig()
      expect(deserialized_object.autoUpdate).to eq(expected.autoUpdate)
      expect(deserialized_object.name).to eq(expected.name)
      expect(deserialized_object).to eq(expected)
    end
  end

  describe :p4 do
    it "should represent a p4 material" do
      presenter   = ApiV1::Config::Materials::MaterialRepresenter.prepare(MaterialConfigsMother.p4MaterialConfigFull())
      actual_json = presenter.to_hash(url_builder: UrlBuilder.new)
      expect(actual_json).to eq(p4_material_hash)
    end

    it "should deserialize" do
      presenter = ApiV1::Config::Materials::MaterialRepresenter.new(P4MaterialConfig.new)
      deserialized_object = presenter.from_hash(p4_material_hash)
      expected = MaterialConfigsMother.p4MaterialConfigFull()
      expect(deserialized_object.autoUpdate).to eq(expected.autoUpdate)
      expect(deserialized_object.name).to eq(expected.name)
      expect(deserialized_object).to eq(expected)
    end

  end

  describe :package do
    it "should represent a package material" do
      presenter   = ApiV1::Config::Materials::MaterialRepresenter.prepare(MaterialConfigsMother.packageMaterialConfig())
      actual_json = presenter.to_hash(url_builder: UrlBuilder.new)
      expect(actual_json).to eq(package_material_hash)
    end

    it "should deserialize" do
      presenter = ApiV1::Config::Materials::MaterialRepresenter.prepare(PackageMaterialConfig.new)
      deserialized_object = presenter.from_hash(package_material_hash)
      expected = MaterialConfigsMother.package_material_config()
      expect(deserialized_object.getPackageId).to eq(expected.getPackageId)
    end
  end

  describe :dependency do
    it "should represent a dependency material" do
      dependency_material = MaterialConfigsMother.dependencyMaterialConfig()
      dependency_material.setName(CaseInsensitiveString.new("dep-material"))

      presenter   = ApiV1::Config::Materials::MaterialRepresenter.prepare(dependency_material)
      actual_json = presenter.to_hash(url_builder: UrlBuilder.new)
      expect(actual_json).to eq(dependency_material_hash)
    end

    it "should deserialize" do
      presenter = ApiV1::Config::Materials::MaterialRepresenter.new(DependencyMaterialConfig.new)
      deserialized_object = presenter.from_hash(dependency_material_hash)
      expected = MaterialConfigsMother.dependencyMaterialConfig()
      expected.setName(CaseInsensitiveString.new("dep-material"))
      expect(deserialized_object.autoUpdate).to eq(expected.autoUpdate)
      expect(deserialized_object.name.to_s).to eq(expected.name.to_s)
      expect(deserialized_object).to eq(expected)
    end
  end

  describe "pluggable scm material" do
    it "should represent a pluggable scm material" do
      pluggable_scm_material = MaterialConfigsMother.pluggableSCMMaterialConfig()
      presenter              = ApiV1::Config::Materials::MaterialRepresenter.prepare(pluggable_scm_material)
      actual_json            = presenter.to_hash(url_builder: UrlBuilder.new)
      expect(actual_json).to eq(pluggable_scm_material_hash)
    end

    it "should deserialize" do
      presenter = ApiV1::Config::Materials::MaterialRepresenter.new(PluggableSCMMaterialConfig.new)
      deserialized_object = presenter.from_hash(pluggable_scm_material_hash)
      expected = MaterialConfigsMother.pluggableSCMMaterialConfig()
      expect(deserialized_object.getScmId).to eq("scm-id")
    end

  end

  def pluggable_scm_material_hash
    {
      type:       PluggableSCMMaterialConfig::TYPE,
      attributes: {
        ref:         "scm-id",
        filter:      {
          ignore: [
                    "**/*.html",
                    "**/foobar/"
                  ]
        },
        name:        "scm-scm-id",
        auto_update: true
      }
    }
  end

  def dependency_material_hash
    {
      type:       DependencyMaterialConfig::TYPE,
      attributes: {
        pipeline:    "pipeline-name",
        stage:       "stage-name",
        name:        "dep-material",
        auto_update: true
      }
    }
  end

  def package_material_hash
    {
      type:       PackageMaterialConfig::TYPE,
      attributes: {
        ref:         "p-id",
        name:        "repo-name:package-name",
        auto_update: true
      }
    }
  end

  def p4_material_hash
    {
      type:       P4MaterialConfig::TYPE,
      attributes: {
        destination:        "dest-folder",
        filter:             {
          ignore: [
                    "**/*.html",
                    "**/foobar/"
                  ]
        },
        port:               "host:9876",
        username:           "user",
        encrypted_password: GoCipher.new.encrypt("password"),
        use_tickets:        true,
        view:               "view",
        name:               "p4-material",
        auto_update:        true
      }
    }
  end

  def tfs_material_hash
    {
      type:       TfsMaterialConfig::TYPE,
      attributes: {
        url:                "http://10.4.4.101:8080/tfs/Sample",
        destination:        "dest-folder",
        filter:             {
          ignore: [
                    "**/*.html",
                    "**/foobar/"
                  ]
        },
        domain:             "some_domain",
        username:           "loser",
        encrypted_password: com.thoughtworks.go.security.GoCipher.new.encrypt("passwd"),
        project_path:       "walk_this_path",
        name:               "tfs-material",
        auto_update:        true
      }
    }
  end

  def hg_material_hash
    {
      type:       HgMaterialConfig::TYPE,
      attributes: {
        url:         "http://user:pass@domain/path##branch",
        destination: "dest-folder",
        filter:      {
          ignore: [
                    "**/*.html",
                    "**/foobar/"
                  ]
        },
        name:        "hg-material",
        auto_update: true
      }
    }
  end

  def git_material_hash
    {
      type:       GitMaterialConfig::TYPE,
      attributes: {
        url:              "http://user:password@funk.com/blank",
        destination:      "destination",
        filter:           {
          ignore: [
                    "**/*.html",
                    "**/foobar/"
                  ]
        },
        branch:           "branch",
        submodule_folder: "sub_module_folder",
        name:             "AwesomeGitMaterial",
        auto_update:      false
      }
    }
  end

  def svn_material_hash
    {
      type:       SvnMaterialConfig::TYPE,
      attributes: {
        url:             "url",
        destination:     "svnDir",
        filter:          {
          ignore: [
                    "*.doc"
                  ]
        },
        name:            "svn-material",
        auto_update:     false,
        check_externals: true,
        username:        "user",
        encrypted_password: GoCipher.new.encrypt("pass"),

      }
    }
  end
end
