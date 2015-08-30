/*************************GO-LICENSE-START*********************************
 * Copyright 2014 ThoughtWorks, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *************************GO-LICENSE-END***********************************/



package com.thoughtworks.go.config;

import com.thoughtworks.go.config.materials.MaterialConfigs;
import com.thoughtworks.go.domain.PipelineGroups;
import com.thoughtworks.go.domain.materials.MaterialConfig;
import com.thoughtworks.go.util.Node;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.Hashtable;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

public class PipelineConfigurationCache {
    private PipelineConfigMap pipelineConfigHashMap;
    private MaterialConfigFingerprintMap materialConfigsFingerprintMap;

    private static PipelineConfigurationCache pipelineConfigurationCache = new PipelineConfigurationCache();
    private CruiseConfig cruiseConfig;
    private  Hashtable<CaseInsensitiveString, Node> dependencies;

    private PipelineConfigurationCache() {
    }

    public static PipelineConfigurationCache getInstance() {
        return pipelineConfigurationCache;
    }

    public void onConfigChange(CruiseConfig cruiseConfig) {
        this.cruiseConfig = cruiseConfig;
        pipelineConfigHashMap = null;
        materialConfigsFingerprintMap = null;
        dependencies = null;
    }

    public MaterialConfigs getMatchingMaterialsFromConfig(String fingerprint) {
        initMaterialConfigMap();
        return materialConfigsFingerprintMap.get(fingerprint);
    }

    private void initMaterialConfigMap() {
        if (materialConfigsFingerprintMap == null) {
            materialConfigsFingerprintMap = new MaterialConfigFingerprintMap(cruiseConfig);
        }
    }

    public PipelineConfig getPipelineConfig(String pipelineName) {
        initPipelineConfigMap();
        return pipelineConfigHashMap.getPipelineConfig(pipelineName);
    }

    private void initPipelineConfigMap() {
        if (pipelineConfigHashMap == null) {
            pipelineConfigHashMap = new PipelineConfigMap(cruiseConfig);
        }
    }

    public PipelineConfigs getPipelineGroup(String pipelineName) {
        return cruiseConfig.findGroup(getPipelineGroupNameFor(pipelineName));
    }

    public String getPipelineGroupNameFor(String pipelineName) {
        initPipelineConfigMap();
        return pipelineConfigHashMap.getGroupName(pipelineName);
    }

    public void onPipelineConfigChange(PipelineConfig pipelineConfig, String group) {
        initPipelineConfigMap();
        initMaterialConfigMap();
        initDependencies();
        dependencies.put(pipelineConfig.name(), pipelineConfig.getDependenciesAsNode());
        pipelineConfigHashMap.update(pipelineConfig, group);
        materialConfigsFingerprintMap.update(pipelineConfig);
    }

    public SecurityConfig getServerSecurityConfig() {
        return cruiseConfig.server().security();
    }

    public Node getDependencyMaterialsFor(CaseInsensitiveString pipelineName) {
        initPipelineConfigMap();
        initDependencies();
        return dependencies.get(pipelineName) != null? dependencies.get(pipelineName): new Node(new ArrayList<CaseInsensitiveString>());
    }

    private void initDependencies() {
        if(dependencies == null){
            dependencies = new Hashtable<>();
            for (CaseInsensitiveString pipeline : pipelineConfigHashMap.map.keySet()) {
                dependencies.put(pipeline, pipelineConfigHashMap.getPipelineConfig(pipeline.toString()).getDependenciesAsNode());
            }
        }
    }

    private class PipelineConfigMap {
        private Map<CaseInsensitiveString, HashMap> map = new ConcurrentHashMap<>();

        public PipelineConfigMap(CruiseConfig cruiseConfig) {
            PipelineGroups groups = cruiseConfig.getGroups();
            for (PipelineConfigs group : groups) {
                for (PipelineConfig pipelineConfig : group) {
                    updatePipelineData(pipelineConfig, group.getGroup());
                }
            }
        }

        private void updatePipelineData(PipelineConfig pipelineConfig, String groupName) {
            HashMap pipelineMetadata = new HashMap();
            pipelineMetadata.put("group", groupName);
            pipelineMetadata.put("pipeline", pipelineConfig);
            this.map.put(pipelineConfig.name(), pipelineMetadata);
        }

        public PipelineConfig getPipelineConfig(String pipelineName) {
            if (map.containsKey(new CaseInsensitiveString(pipelineName)))
                return (PipelineConfig) map.get(new CaseInsensitiveString(pipelineName)).get("pipeline");
            return null;
        }

        public String getGroupName(String pipelineName) {
            return (String) map.get(new CaseInsensitiveString(pipelineName)).get("group");
        }

        public void update(PipelineConfig pipelineConfig, String group) {
            updatePipelineData(pipelineConfig, group);
        }
    }

    private class MaterialConfigFingerprintMap {
        private Map<String, MaterialConfigs> map = new ConcurrentHashMap<>();
        private Map<String, MaterialConfigs> pipelineMaterialMap = new ConcurrentHashMap<>();

        public MaterialConfigFingerprintMap(CruiseConfig cruiseConfig) {
            for (PipelineConfigs group : cruiseConfig.getGroups()) {
                for (PipelineConfig pipelineConfig : group) {
                    for (MaterialConfig material : pipelineConfig.materialConfigs()) {
                        String fingerprint = material.getFingerprint();
                        if (!map.containsKey(fingerprint)) {
                            map.put(fingerprint, new MaterialConfigs());
                        }
                        map.get(fingerprint).add(material);

                        if (!pipelineMaterialMap.containsKey(pipelineConfig.name().toString())) {
                            pipelineMaterialMap.put(pipelineConfig.name().toString(), new MaterialConfigs());
                        }
                        pipelineMaterialMap.get(pipelineConfig.name().toString()).add(material);
                    }
                }
            }
        }

        public void update(PipelineConfig pipelineConfig) {
            MaterialConfigs knownMaterialsForPipeline = pipelineMaterialMap.get(pipelineConfig.name().toString());
            MaterialConfigs currentMaterials = pipelineConfig.materialConfigs();
            if(knownMaterialsForPipeline!=null){
                for (MaterialConfig old : knownMaterialsForPipeline) {
                    map.get(old.getFingerprint()).remove(old);
                }
            }
            for (MaterialConfig currentMaterial : currentMaterials) {
                if (!map.containsKey(currentMaterial.getFingerprint())) {
                    map.put(currentMaterial.getFingerprint(), new MaterialConfigs());
                }
                map.get(currentMaterial.getFingerprint()).add(currentMaterial);
            }
            pipelineMaterialMap.put(pipelineConfig.name().toString(), currentMaterials);
        }

        public MaterialConfigs get(String fingerprint) {
            return map.get(fingerprint);
        }
    }

}