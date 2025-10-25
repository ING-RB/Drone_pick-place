function log(type, varargin)
    % The function can get the log from front-end and write the struct into a
    % json file.
    % Inputs:
    %     type: currently only takes 'perf'
    %     duration: a integer representing the duration in seconds

    % Copyright 2021 The MathWorks, Inc.

    % Parse input
    defaultDuration = 30;
    expectedTypes = {'perf'};

    p = inputParser;
    addRequired(p, 'type', @(x) any(validatestring(x, expectedTypes)));
    addParameter(p, 'duration', defaultDuration, @(x) isnumeric(x) && isscalar(x) && (x > 0));
    parse(p, type, varargin{:});

    duration = p.Results.duration;
    type = p.Results.type;
    % check if there is one running
    if logging(type)
        return;
    end
    logging(type, true);

    % Start logging
    % Handler function when the front-end send back message
    id = message.subscribe('/simulinkonline/log', @(msg)handleLog(msg));
    subscriptionId(type, id);

    % Setup timer
    t = timer;
    t.StartDelay = duration;
    t.ExecutionMode = 'singleShot';
    t.TimerFcn = @(~, ~)endLogging(type);
    t.StopFcn = @(t,~) delete(t);

    startLogging(type);
    start(t);
end

%% Helper functions
function isLogging = logging(type, value)
    persistent runningLog;
    if nargin == 2
        runningLog.(type) = value;
    end

    if isfield(runningLog, type)
        isLogging = runningLog.(type);
    else
        isLogging = false;
    end

end

function id = subscriptionId(type, value)
    persistent logSubId;
    if nargin == 2
        logSubId.(type) = value;
    end

    if isfield(logSubId, type)
        id = logSubId.(type);
    else
        id = '';
    end
end

function handleLog(msg)
    type = msg.type;
    event = msg.event;
    data = msg.data;

    filePath = getFilePath(type);

    switch event
        case 'log'
        writeToDrive(filePath, data);
        otherwise
        error("Invalid event " + event);
    end

    resetLogging(type);
end

function startLogging(type)
    message.publish('/simulinkonline/log', createServerLogMsg(type, 'start'));
end

function endLogging(type)
    message.publish('/simulinkonline/log', createServerLogMsg(type, 'end'));
end

function resetLogging(type)
    logging(type, false);
    message.unsubscribe(subscriptionId(type));
    subscriptionId(type, '');
end

function msg = createServerLogMsg(type, event)
    msg = struct('type', type, 'event', event);
end

function writeToDrive(filePath, msg)
    %writestruct(msg, filePath);
    if isempty(fieldnames(msg))
        return
    end
    txt = jsonencode(msg);
    fid = fopen(filePath,'wt');
    fprintf(fid, txt);
    fclose(fid);
end

function filePath = getFilePath(type)
    timeStamp = getTimeStamp();
    filePath = ['so-' type '-' timeStamp '.json'];
end

function timeStamp = getTimeStamp()
    timeStamp = char(datetime('now'));
    timeStamp = strrep(timeStamp, ':', '-');
    timeStamp = strrep(timeStamp, ' ', '-');
end
