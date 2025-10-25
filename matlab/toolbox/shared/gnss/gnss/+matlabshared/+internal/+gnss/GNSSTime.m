classdef (Hidden) GNSSTime
%This function is for internal use only. It may be removed in the future.

%GNSSTIME Internal class with methods for GNSS time calculations.

%   Copyright 2021-2023 The MathWorks, Inc.

%#codegen

    methods (Static)
        function t = getLocalTime(gnssWeek, tow, tzone, gnssStartTime)
        %GETLOCALTIME Date and time as datetime object
        %   Inputs
        %       gnssWeek      - GNSS week number
        %       tow           - Time of week in seconds
        %       tzone         - Time zone string
        %       gnssStartTime - Starting date of constellation time
        %
        %   Outputs
        %       t             - Scalar datetime

            if (nargin <= 3)
                gnssStartTime = ...
                    matlabshared.internal.gnss.GNSSTime.getGPSStartTime;
            end

            if (nargin == 2)
                tzone = '';
            end

            secondsPerWeek = getSecondsPerWeek;
            t = gnssStartTime + seconds((gnssWeek * secondsPerWeek) + tow);

            t.TimeZone = 'UTC';
            t.TimeZone = tzone;
        end

        function [gnssWeek, tow] = getGNSSTime(t, gnssStartTime)
        %GETGNSSTIME GNSS week number and time of week (tow) in seconds
        %   Inputs
        %       t             - Scalar datetime
        %       gnssStartTime - Starting date of constellation time
        %   Outputs
        %       gnssWeek      - GNSS week number
        %       tow           - Time of week in seconds

            if nargin <= 1
                gnssStartTime = ...
                    matlabshared.internal.gnss.GNSSTime.getGPSStartTime;
            end

            if nargin == 0
                t = datetime('now', 'TimeZone', 'UTCLeapSeconds');
            end
            if isempty(t.TimeZone)
                t.TimeZone = 'UTC';
            end
            t.TimeZone = 'UTCLeapSeconds';

            % Time from GPS start time.
            dateDiff = seconds(t - gnssStartTime);
            secondsPerWeek = getSecondsPerWeek;
            gnssWeek = floor(dateDiff / secondsPerWeek);
            tow = dateDiff - (gnssWeek * secondsPerWeek);
        end

        function [gnssWeek, tow] = getGPSTime(t)
        %GETGPSTIME GPS week number and time of week (tow) in seconds

        % g2960357

            [gnssWeek, tow] = ...
                matlabshared.internal.gnss.GNSSTime.getGNSSTime(t);
        end

        function numGPSWeekRollOvers = getGPSWeekRollOvers(referenceDate)
        %GETGPSWEEKROLLOVERS Number of GPS week roll overs relative to
        % GPS start time
        %   Inputs
        %       referenceDate       - Reference date, specified as a
        %                             datetime object, up to which the
        %                             number of GPS week rollover is to be
        %                             calculated with respect to the GPS
        %                             start time. The function assumes
        %                             current date as the reference date if
        %                             no input is given.
        %   Outputs
        %       numGPSWeekRollOvers - Number of GPS week rollovers

        %   Note: No validation is done in this function.
        %   Any input validation should be done in a function or object
        %   that uses this function.

            if nargin < 1
                referenceDate = ...
                    datetime('today', 'TimeZone', 'UTCLeapSeconds');
            end
            if isempty(referenceDate.TimeZone)
                referenceDate.TimeZone = 'UTC';
            end
            referenceDate.TimeZone = 'UTCLeapSeconds';

            gpsStart = matlabshared.internal.gnss.GNSSTime.getGPSStartTime;

            numGPSWeekRollOvers = days(referenceDate - gpsStart)/7/1024;
        end

        function gpsStart = getGPSStartTime
        %GETGPSSTARTTIME Starting date of GPS time
        %   This is the start date and time of GPS constellation.
        
            gpsStart = datetime(1980, 1, 6, 0, 0, 0, ...
                                'TimeZone', 'UTCLeapSeconds');
        end
    end
end


function secondsPerWeek = getSecondsPerWeek
%GETSECONDSPERWEEK Number of seconds in a week

    secondsPerWeek = 604800;
end
