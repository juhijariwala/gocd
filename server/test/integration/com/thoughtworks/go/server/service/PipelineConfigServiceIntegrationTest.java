package com.thoughtworks.go.server.service;

import com.thoughtworks.go.config.*;
import com.thoughtworks.go.config.materials.MaterialConfigs;
import com.thoughtworks.go.config.materials.git.GitMaterialConfig;
import com.thoughtworks.go.config.registry.ConfigElementImplementationRegistry;
import com.thoughtworks.go.domain.ConfigErrors;
import com.thoughtworks.go.domain.config.Admin;
import com.thoughtworks.go.helper.GoConfigMother;
import com.thoughtworks.go.metrics.service.MetricsProbeService;
import com.thoughtworks.go.presentation.TriStateSelection;
import com.thoughtworks.go.security.GoCipher;
import com.thoughtworks.go.server.dao.DatabaseAccessHelper;
import com.thoughtworks.go.server.domain.Username;
import com.thoughtworks.go.server.service.result.HttpLocalizedOperationResult;
import com.thoughtworks.go.service.ConfigRepository;
import com.thoughtworks.go.util.*;
import com.thoughtworks.go.util.command.CommandLine;
import com.thoughtworks.go.util.command.InMemoryStreamConsumer;
import org.eclipse.jgit.api.errors.GitAPIException;
import org.junit.After;
import org.junit.Before;
import org.junit.Ignore;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.test.context.ContextConfiguration;
import org.springframework.test.context.junit4.SpringJUnit4ClassRunner;
import sun.misc.Perf;

import java.io.ByteArrayOutputStream;
import java.io.File;
import java.lang.management.ManagementFactory;
import java.util.*;
import java.util.concurrent.ConcurrentHashMap;

import static com.thoughtworks.go.util.TestUtils.contains;
import static com.thoughtworks.go.util.command.ProcessOutputStreamConsumer.inMemoryConsumer;
import static org.hamcrest.core.Is.is;
import static org.hamcrest.core.IsNot.not;
import static org.hamcrest.core.IsNull.nullValue;
import static org.junit.Assert.*;

@RunWith(SpringJUnit4ClassRunner.class)
@ContextConfiguration(locations = {
        "classpath:WEB-INF/applicationContext-global.xml",
        "classpath:WEB-INF/applicationContext-dataLocalAccess.xml",
        "classpath:WEB-INF/applicationContext-acegi-security.xml"
})

public class PipelineConfigServiceIntegrationTest {
    static {
        new SystemEnvironment().setProperty(GoConstants.USE_COMPRESSED_JAVASCRIPT, "false");
    }

    @Autowired
    private PipelineConfigService pipelineConfigService;
    @Autowired
    private GoConfigService goConfigService;
    @Autowired
    private GoConfigDao goConfigDao;
    @Autowired
    private DatabaseAccessHelper dbHelper;
    @Autowired
    private ConfigRepository configRepository;
    @Autowired
    private ConfigCache configCache;
    @Autowired
    private ConfigElementImplementationRegistry registry;
    @Autowired
    private MetricsProbeService metricsProbeService;

    private GoConfigFileHelper configHelper;
    private PipelineConfig pipelineConfig;
    private Username user;
    private String headCommitBeforeUpdate;
    private HttpLocalizedOperationResult result;
    private String groupName = "jumbo";

    @Before
    public void setup() throws Exception {
        configHelper = new GoConfigFileHelper();
        dbHelper.onSetUp();
        configHelper.usingCruiseConfigDao(goConfigDao).initializeConfigFile();
        configHelper.onSetUp();
        goConfigService.forceNotifyListeners();
        user = new Username(new CaseInsensitiveString("current"));
        pipelineConfig = GoConfigMother.createPipelineConfigWithMaterialConfig(UUID.randomUUID().toString(), new GitMaterialConfig("FOO"));
        goConfigService.addPipeline(pipelineConfig, groupName);
        GoCipher goCipher = new GoCipher();
        goConfigService.updateServerConfig(new MailHost(goCipher), new LdapConfig(goCipher), new PasswordFileConfig("path"), false, goConfigService.configFileMd5(), "artifacts", null, null, "0", null, null, "foo");
        UpdateConfigCommand command = goConfigService.modifyAdminPrivilegesCommand(Arrays.asList(user.getUsername().toString()), new TriStateSelection(Admin.GO_SYSTEM_ADMIN, TriStateSelection.Action.add));
        goConfigService.updateConfig(command);
        result = new HttpLocalizedOperationResult();
        headCommitBeforeUpdate = configRepository.getCurrentRevCommit().name();
    }

    @After
    public void tearDown() throws Exception {
        configHelper.onTearDown();
        dbHelper.onTearDown();
    }

    @Test
    public void shouldSavePipelineConfig() throws GitAPIException {
        GoConfigHolder goConfigHolderBeforeUpdate = goConfigDao.loadConfigHolder();

        pipelineConfig.add(new StageConfig(new CaseInsensitiveString("additional_stage"), new JobConfigs(new JobConfig(new CaseInsensitiveString("addtn_job")))));
        pipelineConfigService.updatePipelineConfig(user, pipelineConfig, result);

        assertThat(result.toString(), result.isSuccessful(), is(true));
        assertThat(goConfigDao.loadConfigHolder(), is(not(goConfigHolderBeforeUpdate)));
        StageConfig newlyAddedStage = goConfigDao.loadForEditing().getPipelineConfigByName(pipelineConfig.name()).getStage(new CaseInsensitiveString("additional_stage"));
        assertThat(newlyAddedStage, is(not(nullValue())));
        assertThat(newlyAddedStage.getJobs().isEmpty(), is(false));
        assertThat(newlyAddedStage.getJobs().first().name().toString(), is("addtn_job"));
        assertThat(configRepository.getCurrentRevCommit().name(), is(not(headCommitBeforeUpdate)));
        assertThat(configRepository.getCurrentRevision().getUsername(), is(user.getDisplayName()));
    }

    @Test
    public void shouldNotSavePipelineConfigInCaseOfValidationErrors() throws GitAPIException {
        GoConfigHolder goConfigHolder = goConfigDao.loadConfigHolder();
        pipelineConfig.setLabelTemplate("LABEL");
        pipelineConfigService.updatePipelineConfig(user, pipelineConfig, result);

        assertThat(result.toString(), result.isSuccessful(), is(false));
        assertThat(pipelineConfig.errors().on(PipelineConfig.LABEL_TEMPLATE), contains("Invalid label"));
        assertThat(configRepository.getCurrentRevCommit().name(), is(headCommitBeforeUpdate));
        assertThat(goConfigDao.loadConfigHolder().configForEdit, is(goConfigHolder.configForEdit));
        assertThat(goConfigDao.loadConfigHolder().config, is(goConfigHolder.config));
    }

    @Test
    public void shouldNotSavePipelineWhenPreprocessingFails() throws Exception {
        CaseInsensitiveString templateName = new CaseInsensitiveString("template_with_param");
        saveTemplateWithParamToConfig(templateName);

        GoConfigHolder goConfigHolder = goConfigDao.loadConfigHolder();
        pipelineConfig.clear();
        pipelineConfig.setTemplateName(templateName);
        pipelineConfigService.updatePipelineConfig(user, pipelineConfig, result);

        assertThat(result.toString(), result.isSuccessful(), is(false));
        assertThat(result.toString(), result.toString().contains("Parameter 'SOME_PARAM' is not defined"), is(true));
        assertThat(configRepository.getCurrentRevCommit().name(), is(headCommitBeforeUpdate));
        assertThat(goConfigDao.loadConfigHolder().configForEdit, is(goConfigHolder.configForEdit));
        assertThat(goConfigDao.loadConfigHolder().config, is(goConfigHolder.config));
    }

    @Test
    public void shouldCheckForUserPermissionBeforeUpdatingPipelineConfig() throws Exception {
        CaseInsensitiveString templateName = new CaseInsensitiveString("template_with_param");
        saveTemplateWithParamToConfig(templateName);

        GoConfigHolder goConfigHolderBeforeUpdate = goConfigDao.loadConfigHolder();
        pipelineConfigService.updatePipelineConfig(new Username(new CaseInsensitiveString("unauthorized_user")), pipelineConfig, result);

        assertThat(result.toString(), result.isSuccessful(), is(false));
        assertThat(result.toString(), result.httpCode(), is(401));
        assertThat(result.toString(), result.toString().contains("UNAUTHORIZED_TO_EDIT_PIPELINE"), is(true));
        assertThat(configRepository.getCurrentRevCommit().name(), is(headCommitBeforeUpdate));
        assertThat(goConfigDao.loadConfigHolder().configForEdit, is(goConfigHolderBeforeUpdate.configForEdit));
        assertThat(goConfigDao.loadConfigHolder().config, is(goConfigHolderBeforeUpdate.config));
    }

    private void saveTemplateWithParamToConfig(CaseInsensitiveString templateName) throws Exception {
        JobConfig jobConfig = new JobConfig(new CaseInsensitiveString("job"));
        ExecTask task = new ExecTask();
        task.setCommand("ls");
        jobConfig.addTask(task);
        jobConfig.addVariable("ENV_VAR", "#{SOME_PARAM}");
        final PipelineTemplateConfig template = new PipelineTemplateConfig(templateName, new StageConfig(new CaseInsensitiveString("stage"), new JobConfigs(jobConfig)));
        CruiseConfig cruiseConfig = goConfigDao.loadConfigHolder().configForEdit;
        cruiseConfig.addTemplate(template);
        ByteArrayOutputStream buffer = new ByteArrayOutputStream();
        new MagicalGoConfigXmlWriter(configCache, registry, metricsProbeService).write(cruiseConfig, buffer, false);
    }
}