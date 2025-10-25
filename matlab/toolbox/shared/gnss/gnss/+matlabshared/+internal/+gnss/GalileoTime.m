classdef (Hidden) GalileoTime
%This function is for internal use only. It may be removed in the future.

%GALILEOTIME Internal class with methods for Galileo time calculations.

%   Copyright 2023 The MathWorks, Inc.

    methods (Static)
        function t = getLocalTime(galileoWeek, tow, tzone)
        %GETLOCALTIME Date and time as datetime object
        %   Inputs
        %       galileoWeek - Galileo week number
        %       tow         - Time of week in seconds
        %       tzone       - Time zone string
        %
        %   Outputs
        %       t          - Scalar datetime

            if (nargin < 3)
                tzone = '';
            end

            % Get Galileo start date
            galileoStart = ...
                matlabshared.internal.gnss.GalileoTime.getGalileoStartTime;

            % Get local time
            t = matlabshared.internal.gnss.GNSSTime.getLocalTime( ...
                galileoWeek, tow, tzone, galileoStart);
        end

        function [galileoWeek, tow] = getGalileoTime(t)
        %GETGALILEOTIME Galileo week number and time of week (tow) in 
        % seconds
        %   Inputs
        %       t           - Scalar datetime
        %   Outputs
        %       galileoWeek - Galileo week number
        %       tow         - Time of week in seconds

            % Get Galileo start date
            galileoStart = ...
                matlabshared.internal.gnss.GalileoTime.getGalileoStartTime;

            % Get week number and time of week
            [galileoWeek, tow] = ...
                    matlabshared.internal.gnss.GNSSTime.getGNSSTime( ...
                    t, galileoStart);
        end

        function galileoStart = getGalileoStartTime
        %GETGALILEOSTARTTIME Starting date of Galileo time
        %   This is the start date and time of Galileo constellation

            % The Galileo System Time start epoch is defined as 13 seconds
            % before midnight between 21st August and 22nd August 1999 i.e.
            % GST is equal to 13 seconds at 22nd August 1999 00:00:00 UTC
            % Taken from:
            % Section 5.1.2. of Galileo SiS Open Service Interface Control
            % Document. Accessed May 25, 2023. Available:
            % https://www.gsc-europa.eu/sites/default/files/sites/all/files/Galileo_OS_SIS_ICD_v2.0.pdf.
            galileoStart = datetime(1999, 8, 22, 0, 0, 0, ...
                                'TimeZone','UTCLeapSeconds') - seconds(13);
        end
    end
end
