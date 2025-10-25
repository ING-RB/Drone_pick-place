classdef Session < matlab.lang.internal.history.Session
    methods (Access=protected)
        function commands = extractCommands(sessions)
            arguments
                sessions (1,:) matlab.lang.internal.history.xml.Session;
            end
            captureStamp  = captureAnnotation("time_stamp",     "\w+");
            captureBatch  = captureAnnotation("batch",          "\d+");
            captureError  = captureAnnotation("error",          "true");
            captureTime   = captureAnnotation("execution_time", "\d+");
            captureRepeat = captureAnnotation("repeat",         "\d+");
            annotations   = captureStamp + captureBatch + captureError + captureTime + captureRepeat;

            captureCommand = capture("command", ".*?");

            commandExpression = "<command" + annotations + ">" + captureCommand + "</command>";

            commands = regexp([sessions.fullText], commandExpression, 'names');
            commands = removeFlags(commands);
        end
    end

    methods (Access=protected, Static)
        function script = sanitize(script)
            script = replace(script, ["&lt;", "&gt;", "&amp;"], ["<", ">", "&"]);
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

function pat = captureAnnotation(name, pat)
    flag = name + "_flag";
    intro = optional(capture(flag, " " + name + '="'));
    main = capture(name, conditional(flag, pat));
    tail = conditional(flag, '"');
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
