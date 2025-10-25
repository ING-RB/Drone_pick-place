classdef CommandHistory < matlab.lang.internal.history.CommandHistory
    methods
        function ch = CommandHistory(file)
            arguments
                file (1,1) string = getDefaultFolder;
            end
            ch.fullText = string(fileread(file));
        end
    end

    methods (Access=protected)
        function sessionTexts = allSessionTexts(ch)
            arguments
                ch (1,1) matlab.lang.internal.history.xml.CommandHistory;
            end
            sessionTexts = ch.fullText.extractBetween('<session>', '</session>');
        end
    end

    methods (Access=protected, Static)
        function sessions = createSessions(sessionTexts)
            arguments
                sessionTexts (1,:) string;
            end
            sessions = matlab.lang.internal.history.xml.Session(sessionTexts);
        end

        function timestamps = getTimeStamps(sessionTexts)
            arguments
                sessionTexts (1,:) string;
            end
            stringStamps = extractAfter(sessionTexts, '<command time_stamp="');
            stringStamps = extractBefore(stringStamps, '"');
            timestamps = nan(size(stringStamps));
            hasStamp = ~ismissing(stringStamps);
            timestamps(hasStamp) = hex2dec(stringStamps(hasStamp))/1000;
        end
    end
end

function folder = getDefaultFolder
    folder = fullfile(prefdir, 'History.xml');
end

%   Copyright 2022-2024 The MathWorks, Inc.
