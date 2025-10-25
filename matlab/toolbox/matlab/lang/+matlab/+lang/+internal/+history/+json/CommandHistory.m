classdef CommandHistory < matlab.lang.internal.history.CommandHistory
    methods
        function ch = CommandHistory(jsonData)
            arguments
                jsonData (1,1) string = matlab.lang.internal.history.json.getDefaultHistory;
            end
            ch.fullText = jsonData;
        end
    end

    methods (Access=protected)
        function sessionTexts = allSessionTexts(ch)
            arguments
                ch (1,1) matlab.lang.internal.history.json.CommandHistory;
            end
            sessionTexts = split(ch.fullText, '{"content":{"id":"');
            sessionTexts(1) = [];
        end
    end

    methods (Access=protected, Static)
        function sessions = createSessions(sessionTexts)
            arguments
                sessionTexts (1,:) string;
            end
            sessions = matlab.lang.internal.history.json.Session(sessionTexts);
        end

        function timestamps = getTimeStamps(sessionTexts)
            arguments
                sessionTexts (1,:) string;
            end
            timestamps = extractAfter(sessionTexts, '"chTimestamp":');
            timestamps = extractBefore(timestamps, ',"');
            timestamps = double(timestamps);
        end
    end
end

%   Copyright 2022-2024 The MathWorks, Inc.
