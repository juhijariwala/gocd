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
import static org.junit.Assert.assertThat;

@RunWith(SpringJUnit4ClassRunner.class)
@ContextConfiguration(locations = {
        "classpath:WEB-INF/applicationContext-global.xml",
        "classpath:WEB-INF/applicationContext-dataLocalAccess.xml",
        "classpath:WEB-INF/applicationContext-acegi-security.xml"
})

public class PipelineConfigServicePerformanceTest {
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

    private GoConfigFileHelper configHelper;
    @Before
    public void setup() throws Exception {
        configHelper = new GoConfigFileHelper();
        dbHelper.onSetUp();
        configHelper.usingCruiseConfigDao(goConfigDao).initializeConfigFile();
        configHelper.onSetUp();
        goConfigService.forceNotifyListeners();
    }

    @After
    public void tearDown() throws Exception {
        configHelper.onTearDown();
        dbHelper.onTearDown();
    }

    @Test
    @Ignore
    public void performanceTest() throws Exception {
        File dumpDir = FileUtil.createTempFolder("perf-pipelineapi-test");
        FileUtil.deleteDirectoryNoisily(dumpDir);
        dumpDir.mkdirs();
        final HttpLocalizedOperationResult result = new HttpLocalizedOperationResult();
        final Username user = new Username(new CaseInsensitiveString("admin"));
        final int numberOfRequests = 100;
        createPipelines(numberOfRequests);
        System.out.println("Tests start now!");
        final ConcurrentHashMap<Integer, Boolean> results = new ConcurrentHashMap<>();
        ArrayList<Thread> ts = new ArrayList<>();
        for (int i = 0; i < numberOfRequests; i++) {
            final int finalI = i;
            Thread t = new Thread(new Runnable() {
                @Override
                public void run() {
                    PipelineConfig pipelineConfig = goConfigService.getConfigForEditing().pipelineConfigByName(new CaseInsensitiveString("pipeline" + finalI));
                    pipelineConfig.add(new StageConfig(new CaseInsensitiveString("additional_stage"), new JobConfigs(new JobConfig(new CaseInsensitiveString("addtn_job")))));
                    PerfTimer updateTimer = PerfTimer.start("Saving pipelineConfig : " + pipelineConfig.name());
                    pipelineConfigService.updatePipelineConfig(user, pipelineConfig, result);
                    updateTimer.stop();
                    results.put(finalI, result.isSuccessful());
                    if (!result.isSuccessful()) {
                        System.err.println(result.toString());
                        System.err.println("Errors on pipeline" + finalI + " are : " + ListUtil.join(getAllErrors(pipelineConfig)));
                    }
                }
            }, "Thread" + i);
            ts.add(t);
        }
        for (Thread t : ts) {
            Thread.sleep(1000 * (new Random().nextInt(3) + 1));
            t.start();
        }
        for (Thread t : ts) {
            int i = ts.indexOf(t);
            if (i == (numberOfRequests - 1)) {
//                takeHeapDump(dumpDir, i);
            }
            t.join();
        }
        Boolean finalResult = true;
        for (Integer threadId : results.keySet()) {
            finalResult = results.get(threadId) && finalResult;
        }
        assertThat(finalResult, is(true));
    }

    private void takeHeapDump(File dumpDir, int i) {
        InMemoryStreamConsumer outputStreamConsumer = inMemoryConsumer();
        CommandLine commandLine = CommandLine.createCommandLine("jmap").withArgs("-J-d64", String.format("-dump:format=b,file=%s/%s.hprof", dumpDir.getAbsoluteFile(), i), ManagementFactory.getRuntimeMXBean().getName().split("@")[0]);
        System.out.println(commandLine.describe());
        int exitCode = commandLine.run(outputStreamConsumer, "thread" + i);
        System.out.println(outputStreamConsumer.getAllOutput());
        assertThat(exitCode, is(0));
        System.out.println(String.format("Heap dump available at %s", dumpDir.getAbsolutePath()));
    }

    private static abstract class ErrorCollectingHandler implements GoConfigGraphWalker.Handler {
        private final List<ConfigErrors> allErrors;

        public ErrorCollectingHandler(List<ConfigErrors> allErrors) {
            this.allErrors = allErrors;
        }

        public void handle(Validatable validatable, ValidationContext context) {
            handleValidation(validatable, context);
            ConfigErrors configErrors = validatable.errors();

            if (!configErrors.isEmpty()) {
                allErrors.add(configErrors);
            }
        }

        public abstract void handleValidation(Validatable validatable, ValidationContext context);
    }


    private List<ConfigErrors> getAllErrors(Validatable v) {
        final List<ConfigErrors> allErrors = new ArrayList<ConfigErrors>();
        new GoConfigGraphWalker(v).walk(new ErrorCollectingHandler(allErrors) {
            @Override
            public void handleValidation(Validatable validatable, ValidationContext context) {
                // do nothing here
            }
        });
        return allErrors;
    }


    private void createPipelines(Integer count) throws Exception {
        String groupName = "jumbo";
//        String configFile = "<FULL PATH TO YOUR CONFIG FILE>";
        String configFile = "/Users/jsingh/Downloads/ancestry-cruise-config.xml";
        String xml = FileUtil.readContentFromFile(new File(configFile));
        goConfigService.fileSaver(false).saveConfig(xml, goConfigService.getConfigForEditing().getMd5());
        System.out.println(String.format("Total number of pipelines in this config: %s", goConfigService.getConfigForEditing().allPipelines().size()));
        if (goConfigService.getConfigForEditing().hasPipelineGroup(groupName)) {
            ((BasicPipelineConfigs) goConfigService.getConfigForEditing().findGroup(groupName)).clear();
        }
        final CruiseConfig configForEditing = goConfigService.getConfigForEditing();
        for (int i = 0; i < count; i++) {
            JobConfig jobConfig = new JobConfig(new CaseInsensitiveString("job"));
            StageConfig stageConfig = new StageConfig(new CaseInsensitiveString("stage"), new JobConfigs(jobConfig));
            PipelineConfig pipelineConfig = new PipelineConfig(new CaseInsensitiveString("pipeline" + i), new MaterialConfigs(new GitMaterialConfig("FOO")), stageConfig);
            configForEditing.addPipeline(groupName, pipelineConfig);
        }

        goConfigService.updateConfig(new UpdateConfigCommand() {
            @Override
            public CruiseConfig update(CruiseConfig cruiseConfig) throws Exception {
                return configForEditing;
            }
        });
    }
}