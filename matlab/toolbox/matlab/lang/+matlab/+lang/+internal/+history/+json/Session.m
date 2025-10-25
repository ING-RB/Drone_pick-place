classdef Session < matlab.lang.internal.history.Session
    methods (Access=protected)
        function commands = extractCommands(sessions)
            arguments
                sessions (1,:) matlab.lang.internal.history.json.Session;
            end
            captureStamp   = capturePat("time_stamp", "chTimestamp", "\d+", ",");
            captureErrText = captureQuoted("errorText", "errorText", ",");
            captureID      = captureQuoted("id", "id", ",");
            captureError   = capturePat("error", "isError", "true", ",");
            captureBatch   = captureQuoted("batch", "positionInBatch", ",");
            captureRepeat  = capturePat("repeat", "repeat", "\d+", ",");
            captureCommand = captureQuoted("command", "value", "");
            jsonFields     = captureStamp + captureErrText + captureID + captureError + captureBatch + captureRepeat + captureCommand;

            commands = regexp([sessions.fullText], jsonFields, 'names');
            commands = removeFlags(commands);

            errors = string([commands.error]) == "true";
            batchStart = string([commands.batch]) == "start";
            if (any(errors & batchStart))
                errors = find(errors);
                batchStart = find(batchStart);
                batchEnd = find(string([commands.batch]) == "end");
                [~, batchErrors] = intersect(batchStart, errors);
                for i = batchErrors(:)'
                    [commands(batchStart(i):batchEnd(i)).error] = deal("true");
                end
            end
        end
    end

    methods (Access=protected, Static)
        function script = sanitize(script)
            script = replace(script, '\"', '"');
        end
    end
end

function s = removeFlags(s)
    if iscell(s)
        s = cellfun(@removeFlags, s, 'UniformOutput', false);
    else
        fields = fieldnames(s);
        fields(~endsWith(fields, '_flag')) = [];
        s = rmfield(s, fields);
    end
end

function pat = captureQuoted(field, name, tail)
    pat = sharedCapture(field, name, '(\\"|[^"])*', """", '"' + tail);
end

function pat = capturePat(field, name, pat, tail)
    pat = sharedCapture(field, name, pat, "", tail);
end

function pat = sharedCapture(field, name, pat, head, tail)
    flag = field + "_flag";
    intro = optional(capture(flag, '"' + name + '":' + head));
    main = capture(field, conditional(flag, pat));
    tail = conditional(flag, tail);
    pat = intro + main + tail;
end

function pat = capture(name, pat)
    pat = "(?<" + name + ">" + pat + ")";
end

function pat = optional(pat)
    pat = pat + "?";
end

function pat = conditional(condition, pat)
    pat = "(?(" + condition + ")" + pat + ")";
end

%   Copyright 2022-2023 The MathWorks, Inc.

