% Main function.
function start(jsonFile)

    % start.m will read jobs in configuration.json and
    % execute them one by one. 
    [~, ~, ext] = fileparts(jsonFile);

    if ext ~= ".json"
        error("wrong configuration file format");
    end

    confFile = fileread(jsonFile);
    rawJSON = jsondecode(confFile);
    jobs = rawJSON.jobs;

    jobLength = length(jobs);

    % System time information, UTC time
    nd = datetime("now", "TimeZone", "UTC");
    recordTime = datestr(nd, "yyyymmddHHMMSS");

    jobMap = containers.Map;

    % Go over the job list.
    for idx = 1:jobLength
        conf = jobs(idx);
        jobName = conf.testInfo.testName;
        if isKey(jobMap, jobName) && jobMap(jobName) == 1
            error("Two jobs cannot have same name!");
        end
        jobMap(jobName) = 1;
        simulink.online.internal.log.measurePerf.recorder(conf, recordTime);
    end
    
end