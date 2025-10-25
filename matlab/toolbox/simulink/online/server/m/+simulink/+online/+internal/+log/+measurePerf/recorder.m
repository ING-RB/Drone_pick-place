% recorder.m will make performance measurements for each job.

function recorder(conf, recordTime)

    % Read configurations, including time, version information and action
    % function. Also measurement information will be recorded.
    count = conf.testInfo.measurementsCount; % number of measurements
    testVersion = conf.testInfo.testVersion; % version of Simulink Online
    testComponent = "None"; % N/A means there is no test component by default. E.g. the originial version used as comparison.
    testInfo = conf.testInfo;

    if isfield(testInfo, 'testComponent')
        testComponent = conf.testInfo.testComponent;
    end

    % extract action function names from JSON
    % extract the action files to present working directory.
    % if there isn't one, use "doNothing" function as a placeholder.

    actionFields = ["action", "preAction", "exceptionAction", "postAction"];
    actionFunctionDict = containers.Map;

    for i = 1: length(actionFields)
        actionField = actionFields(i);
        if ~isfield(conf.actionFunctions, actionField)
            actionFunctionDict(actionField) = "simulink.online.internal.log.measurePerf.doNothing";
        else
            actionFunctionDict(actionField) = conf.actionFunctions.(actionField);

            actionFunctionPath = "actionFunctions/" + actionFunctionDict(actionField) + ".m";
            actionFunctionFile = dir(actionFunctionPath);
            if isempty(actionFunctionFile)
                error("no action function found!");
            end
        end
    end

    % add action functions to the current directory.
    addpath("actionFunctions");

    % time setup
    actionTime = conf.testInfo.actionTime; % unit: second, time period for the perfcounter to measure server/network time.

    % make a new directory to store data
    mkdir(fullfile("data/", testVersion + "-" + testComponent));
    mkdir(fullfile("data/" + testVersion + "-" + testComponent, recordTime));
    newPath = "data/" + testVersion + "-" + testComponent + "/" + recordTime;

    % perform the pre-action function
    eval(actionFunctionDict("preAction"));

    % Create a log file and insert setup information
    logFilePath = recordTime + "-" + testVersion + "-log" + ".txt"; % create a new log txt file
    logFile = fopen(logFilePath, "w");
    fprintf(logFile,'%12s %12s\n', testVersion, testComponent);
    systemTime = datestr(now,'HH:MM:SS.FFF');
    fprintf(logFile,'%12s %12s\n', 'System time is', systemTime);
    fprintf(logFile,'%12s %12s %12s\n','cmdTime','serverTime', 'networkTime');

    % Start the performance measurement and collect data
    serverTimeArray = zeros(count, 1);
    networkTimeArray = zeros(count, 1);

    for i = 1: count
        disp(i);
        actionFunction = actionFunctionDict("action");
        exceptionActionFunction = actionFunctionDict("exceptionAction");
        [cmdTime, serverTime, networkTime] = timeFunc(actionFunction, exceptionActionFunction, newPath, actionTime);
        serverTimeArray(i) = serverTime;
        networkTimeArray(i) = networkTime;
        fprintf(logFile, '%12.8f% 12.8f %12.8f\n', [cmdTime, serverTime, networkTime]);
    end

    fclose(logFile);

    % Record the means and standard devations of serverTime and networkTime
    % Put briefings into mainLog.txt

    % After one job (a batch of measurements) is done, recorder.m will calculate the mean value 
    % (and also the var value) of all measurements (their mean values) in this job, and write 
    % this value into mainLog.txt. In other words, mainLog.txt records the mean value of mean values 
    % of measurements.

    meanServerTime = mean(serverTimeArray);
    varServerTime = var(serverTimeArray);
    meanNetworkTime = mean(networkTimeArray);
    varNetworkTime = var(networkTimeArray);

    mainLogText = fopen('mainLog.txt', 'a+');
    fprintf(mainLogText, '%12s\t', recordTime);
    fprintf(mainLogText, '%12.8f\t %12.8f\t %12.8f\t %12.8f\n', [meanServerTime, varServerTime, meanNetworkTime, varNetworkTime]);
    fclose(mainLogText);

    % Use post action function and clear files.
    eval(actionFunctionDict("postAction"));
    movefile(logFilePath, newPath);

    % clear the action functions that are no longer useful.
    rmpath("configurations");

end

% Time function will record the command time, server time and network time for each measurement,
% and regulate the exception (time-out) case.
function [cmdTime, serverTime, networkTime] = timeFunc(action, exceptionAction, newPath, actionTime)

    % set logTime to be twice of user's estimated action Time
    logTime = 2*actionTime;
    % time to wait the perfcounter to generate JSON
    cacheTime = 2;
    redundantTime = 3;
    % logTime + cacheTime + redundantTime is the maximum time allowed for each measurement
    iterationTime = logTime + cacheTime + redundantTime;  

    % Set up a timer to prevent action function to go over time limit
    delayFuze = timer('TimerFcn', @(~,~)simulink.online.internal.log.measurePerf.fuzeHandler(exceptionAction), 'StartDelay', logTime + cacheTime);
    start(delayFuze);

    % start the perf counter. 
    simulink.online.internal.log.perf('duration', logTime);

    % perform the action function and record the command time.
    tic;
    eval(action);
    cmdTime = toc;

    % wait until this iteration is finished.
    pause(iterationTime);
    delete(delayFuze);

    file = dir('*.json');

    % analyze run-time data
    if ~isempty(file)
        try
            [n, ~, s] = simulink.online.internal.log.measurePerf.getPerfData(file.name);
            serverTime = s;
            networkTime = n;
            disp("serverTime ", serverTime);
            disp("networkTime ", networkTime)
        catch ex
            disp(ex);
        end
        movefile("*.json", newPath);
    end

end
    