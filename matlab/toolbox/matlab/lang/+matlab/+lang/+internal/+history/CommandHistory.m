classdef CommandHistory
    properties (Access=protected)
        fullText (1,1) string;
    end

    methods (Static)
        function ch = create
            if ~desktop('-inuse')
                error(message('MATLAB:internal:lasso:DesktopRequired'));
            elseif feature('webui')
                ch = matlab.lang.internal.history.json.CommandHistory;
            else
                ch = matlab.lang.internal.history.xml.CommandHistory;
            end
        end
    end

    methods
        function sessions = getSessions(ch, count)
            arguments
                ch    (1,1) matlab.lang.internal.history.CommandHistory;
                count (1,1) double = inf;
            end
            sessionText = ch.allSessionTexts;
            sessionCount = min(numel(sessionText), count);
            sessionText = flip(sessionText)';
            sessionText = sessionText(1:sessionCount);
            sessions = ch.createSessions(sessionText);
        end

        function session = getSessionByTimestamp(ch, timestamp)
            arguments
                ch        (1,1) matlab.lang.internal.history.CommandHistory;
                timestamp (1,1) datetime;
            end
            sessionTexts = ch.allSessionTexts;
            sessionStamps = ch.getTimeStamps(sessionTexts);
            noStamp = ismissing(sessionStamps);
            sessionTexts(noStamp) = [];
            sessionStamps(noStamp) = [];
            stamps = datetime(sessionStamps, 'ConvertFrom', 'posixtime');
            sessionIdx = find(stamps <= timestamp, 1, 'last');

            if isempty(sessionIdx)
                sessionText = "";
            else
                sessionText = sessionTexts(sessionIdx);
            end
            session = ch.createSessions(sessionText);
        end
    end

    methods (Abstract, Access=protected)
        sessionTexts = allSessionTexts(ch);
    end

    methods (Abstract, Access=protected, Static)
        sessions = createSessions(sessionTexts);
        timestamps = getTimeStamps(sessionTexts);
    end
end

%   Copyright 2022-2024 The MathWorks, Inc.
