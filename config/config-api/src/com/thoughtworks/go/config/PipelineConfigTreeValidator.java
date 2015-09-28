package com.thoughtworks.go.config;

import com.rits.cloning.Cloner;
import com.thoughtworks.go.config.materials.dependency.DependencyMaterialConfig;
import com.thoughtworks.go.domain.Task;
import com.thoughtworks.go.domain.materials.MaterialConfig;
import com.thoughtworks.go.util.DFSCycleDetector;
import com.thoughtworks.go.util.Node;
import com.thoughtworks.go.util.PipelineDependencyState;

import java.util.List;

public class PipelineConfigTreeValidator {
    private final PipelineConfig pipelineConfig;

    public PipelineConfigTreeValidator(PipelineConfig pipelineConfig) {
        this.pipelineConfig = pipelineConfig;
    }

    public boolean validate(PipelineConfigSaveValidationContext validationContext) {
        pipelineConfig.validate(validationContext);

        validateDependencies(validationContext);
        if (pipelineConfig.isEmpty() && !pipelineConfig.hasTemplate()) {
            pipelineConfig.addError("stages", "A pipeline must have at least one stage");
        }
        if (!pipelineConfig.isEmpty() && pipelineConfig.hasTemplate()) {
            pipelineConfig.addError("stages", String.format("Cannot add stages to pipeline '%s' which already references template '%s'", pipelineConfig.name(), pipelineConfig.getTemplateName()));
            pipelineConfig.addError("template", String.format("Cannot set template '%s' on pipeline '%s' because it already has stages defined", pipelineConfig.getTemplateName(), pipelineConfig.name()));
        }
        boolean isValid = pipelineConfig.errors().isEmpty();
        if (pipelineConfig.hasTemplate() && !validationContext.doesTemplateExist(pipelineConfig.getTemplateName())) {
            pipelineConfig.addError("template", String.format("Template '%s' does not exist", pipelineConfig.getTemplateName()));
        }
        PipelineConfigSaveValidationContext contextForChildren = validationContext.withParent(pipelineConfig);

        for (StageConfig stageConfig : pipelineConfig.getStages()) {
            isValid = stageConfig.validateTree(contextForChildren) && isValid;
        }
        validateCyclicDependencies(validationContext);
        isValid = pipelineConfig.materialConfigs().validateTree(contextForChildren) && isValid;
        isValid = pipelineConfig.getParams().validateTree(contextForChildren) && isValid;
        isValid = pipelineConfig.getVariables().validateTree(contextForChildren) && isValid;
        if (pipelineConfig.getTrackingTool() != null)
            isValid = pipelineConfig.getTrackingTool().validateTree(contextForChildren) && isValid;
        if (pipelineConfig.getMingleConfig() != null)
            isValid = pipelineConfig.getMingleConfig().validateTree(contextForChildren) && isValid;
        if (pipelineConfig.getTimer() != null)
            isValid = pipelineConfig.getTimer().validateTree(contextForChildren) && isValid;
        return isValid;
    }

    private void validateCyclicDependencies(PipelineConfigSaveValidationContext validationContext) {
        final DFSCycleDetector dfsCycleDetector = new DFSCycleDetector();
        try {
            dfsCycleDetector.topoSort(pipelineConfig.name(), new PipelineConfigValidationContextDependencyState(pipelineConfig, validationContext));
        } catch (Exception e) {
            pipelineConfig.materialConfigs().addError("base", e.getMessage());
        }
    }

    private void validateDependencies(PipelineConfigSaveValidationContext validationContext) {
        for (CaseInsensitiveString selected : validationContext.getPipelinesWithDependencyMaterials()) {
            if (selected.equals(pipelineConfig.name())) continue;
            PipelineConfig selectedPipeline = validationContext.getPipelineConfigByName(selected);
            validateDependencyMaterialsForDownstreams(validationContext, selected, selectedPipeline);
            validateFetchTasksForOtherPipelines(validationContext, selectedPipeline);
        }
    }

    private void validateDependencyMaterialsForDownstreams(PipelineConfigSaveValidationContext validationContext, CaseInsensitiveString selected, PipelineConfig downstreamPipeline) {
        Node dependenciesOfSelectedPipeline = validationContext.getDependencyMaterialsFor(selected);
        for (Node.DependencyNode dependencyNode : dependenciesOfSelectedPipeline.getDependencies()) {
            if (dependencyNode.getPipelineName().equals(pipelineConfig.name())) {
                for (MaterialConfig materialConfig : downstreamPipeline.materialConfigs()) {
                    if (materialConfig instanceof DependencyMaterialConfig) {
                        DependencyMaterialConfig dependencyMaterialConfig = new Cloner().deepClone((DependencyMaterialConfig) materialConfig);
                        dependencyMaterialConfig.validate(validationContext.withParent(downstreamPipeline));
                        List<String> allErrors = dependencyMaterialConfig.errors().getAll();
                        for (String error : allErrors) {
                            pipelineConfig.errors().add("base", String.format("%s, it is being referred to from pipeline '%s'", error, selected));
                        }
                    }
                }
            }
        }
    }

    private void validateFetchTasksForOtherPipelines(PipelineConfigSaveValidationContext validationContext, PipelineConfig downstreamPipeline) {
        for (StageConfig stageConfig : downstreamPipeline.getStages()) {
            for (JobConfig jobConfig : stageConfig.getJobs()) {
                for (Task task : jobConfig.getTasks()) {
                    if (task instanceof FetchTask) {
                        FetchTask fetchTask = new Cloner().deepClone((FetchTask) task);
                        fetchTask.validateTask(validationContext.withParent(downstreamPipeline).withParent(stageConfig).withParent(jobConfig));
                        List<String> allErrors = fetchTask.errors().getAll();
                        for (String error : allErrors) {
                            pipelineConfig.errors().add("base", error);
                        }
                    }
                }
            }
        }
    }

    private class PipelineConfigValidationContextDependencyState implements PipelineDependencyState {
        private PipelineConfig pipelineConfig;
        private PipelineConfigSaveValidationContext validationContext;

        public PipelineConfigValidationContextDependencyState(PipelineConfig pipelineConfig, PipelineConfigSaveValidationContext validationContext) {
            this.pipelineConfig = pipelineConfig;
            this.validationContext = validationContext;
        }

        @Override
        public boolean hasPipeline(CaseInsensitiveString key) {
            return validationContext.getPipelineConfigByName(key) != null;
        }

        @Override
        public Node getDependencyMaterials(CaseInsensitiveString pipelineName) {
            if (pipelineConfig.name().equals(pipelineName))
                return pipelineConfig.getDependenciesAsNode();
            return validationContext.getDependencyMaterialsFor(pipelineName);
        }
    }

}
