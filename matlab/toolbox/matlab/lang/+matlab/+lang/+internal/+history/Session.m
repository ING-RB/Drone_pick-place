classdef Session
    properties (Access=protected)
        fullText (1,1) string;
    end

    methods
        function s = Session(fullText)
            arguments
                fullText (1,:) string;
            end
            s = repmat(s, size(fullText));

            for i = 1:numel(fullText)
                s(i).fullText = fullText(i);
            end
        end

        function b = containsVariable(sessions, variables)
            arguments
                sessions  (1,:) matlab.lang.internal.history.Session;
                variables (1,:) string;
            end
            b = contains([sessions.fullText], letterBoundary + variables + alphanumericBoundary);
        end

        function commands = getCommands(session)
            arguments
                session (1,1) matlab.lang.internal.history.Session;
            end
            commands = session.extractCommands;
            commands = [commands.command];
        end

        function [script, lineNos, lastLine] = convertToScript(session)
            arguments
                session (1,1) matlab.lang.internal.history.Session;
            end
            commands = session.extractCommands;
            lastLine = numel(commands);
            lineNos = num2cell(1:lastLine);
            [commands.lineNo] = lineNos{:};
            commands(string([commands.error]) == "true") = [];

            if ~isempty(commands)
                repeats = double([commands.repeat]);
                repeats(ismissing(repeats)) = 1;
                commands = arrayfun(@(s,n)repmat(s, 1, n), commands, repeats, 'UniformOutput', false);
                commands = [commands{:}];
            end

            if isempty(commands)
                script = strings(0);
            else
                script = session.sanitize([commands.command]);
            end
            lineNos = [commands.lineNo];
        end
    end

    methods (Abstract, Access=protected)
        commands = extractCommands(sessions);
    end

    methods (Abstract, Access=protected, Static)
        script = sanitize(script);
    end
end

%   Copyright 2022-2024 The MathWorks, Inc.
