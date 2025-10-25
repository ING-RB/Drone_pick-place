function [data,title] = semread(filename, varargin)
%SEMREAD Read data from SEM almanac file
%
%   [DATA, TITLE] = SEMREAD(FILENAME) reads a SEM almanac file specified by
%   FILENAME and returns a timetable with a row for each record and a
%   column for each entry in that record and almanac title. The timetable
%   contains the parameters of each satellite read from the SEM almanac 
%   file associated with time data. FILENAME is a character vector or
%   string scalar that specifies the name of the SEM file. FILENAME can
%   include path extension.
%
%   [DATA, TITLE] = SEMREAD(FILENAME, GPSWeekEpoch=t) additionally takes
%   reference date from which the GPS week number defined in the SEM
%   almanac file is counted. Valid values are datetime strings
%   that coincide with the GPS week number rollover dates. These dates
%   occur every 1024 weeks, starting from 6 January 1980 00:00 UTC. The
%   value of GPSWeekEpoch must be "06-Jan-1980", "21-Aug-1999", or
%   "06-Apr-2019". The default value is a datetime string that coincides
%   with the latest GPS week number rollover date that occurs before the
%   current day.
%
%   The timetable has following fields:
%       Time                              - GPS Time, calculated using
%                                           GPSWeekNumber and
%                                           GPSTimeOfApplicability
%       GPSWeekNumber                     - GPS Week number, continuous,
%                                           not mod(1024)
%       GPSTimeOfApplicability            - Number of seconds since
%                                           beginning of GPS week number
%       PRNNumber                         - Satellite Pseudorandom noise
%                                           number
%       SVN                               - Space vehicle reference number
%       AverageURANumber                  - Average URA number of satellite
%       Eccentricity                      - Eccentricity
%       InclinationOffset                 - Inclination angle offset from
%                                           54 degrees (semicircles)
%       RateOfRightAscension              - Rate of change in measurement
%                                           of angle of right ascension
%                                           (semicircles/s)
%       SqrtOfSemiMajorAxis               - Square root of semi-major axis
%                                           (m^(1/2))
%       GeographicLongitudeOfOrbitalPlane - Geographic longitude of
%                                           orbital plane at weekly epoch
%                                           (semicircles)
%       ArgumentOfPerigee                 - Angle from equator to perigee
%                                           (semicircles)
%       MeanAnomaly                       - Angle from position of
%                                           satellite in its orbit relative
%                                           to perigee (semicircles)
%       ZerothOrderClockCorrection        - Satellite almanac zeroth-order
%                                           clock correction term (sec)
%       FirstOrderClockCorrection         - Satellite almanac first order
%                                           clock correction term (sec/sec)
%       SatelliteHealth                   - Satellite vehicle health data
%       SatelliteConfiguration            - Satellite vehicle configuration
%
%   Example:
%
%       % Get the orbital parameters from a SEM almanac file and specify
%       % the GPS Week Epoch
%       filename = "semalmanac_2022-1-18.al3";
%       [data, title] = semread(filename, GPSWeekEpoch="06-Apr-2019");
%
%   References:
%   [1] IS-GPS-200 Navstar GPS Space Segment/Navigation User Interfaces, 
%       U.S. Coast Guard Navigation Center, Alexandria, VA, USA, May 21,
%       2021. Accessed on: May. 6, 2022. [Online]. Available:
%       https://www.navcen.uscg.gov/sites/default/files/pdf/gps/IS_GPS_200M.pdf.
%
%   [2] ICD-GPS-240 Navstar GPS Control Segment to User Support Community
%       Interface, U.S. Coast Guard Navigation Center, Alexandria, VA, USA,
%       May 21, 2021. Accessed on: May. 6, 2022. [Online]. Available:
%       https://www.navcen.uscg.gov/sites/default/files/pdf/gps/ICD_GPS_240D.pdf.
%
%   [3] Almanac archives, U.S. Coast Guard Navigation Center, Alexandria,
%       VA, USA. Accessed on: May. 6, 2022. [Online]. Available:
%       https://www.navcen.uscg.gov/archives.
% 
%   See also rinexread, gnssconstellation

%   Copyright 2022-2023 The MathWorks, Inc.

    if nargin > 1
        narginchk(3, 3);
        % Validate that second input argument is "GPSWeekEpoch"
        validatestring(varargin{1}, "GPSWeekEpoch", ...
                         "semread", "GPSWeekEpoch", 2);
        % Validate value of gpsWeekEpoch
        validatestring(varargin{2}, ...
            matlabshared.internal.gnss.getGPSWeekRolloverDates, ...
                         "semread", "GPSWeekEpoch value", 3);
    end

    % Get full file path
    fullfilename = which(filename);
    if isempty(fullfilename)
        fullfilename = char(filename);
    end

    % Parse the file
    try
        [title,gpsWeekNum,gpsTimeOfApplicability,~,recordsTable] = ...
            matlabshared.internal.gnss.readSEMAlmanac(fullfilename);
    catch ME
        rethrow(ME);
    end

    % get number of GPS week rollovers
    numGPSWeekNumRollOvers = getNumGPSWeekNumRollOvers(varargin{:});

    % Get actual week number
    gpsWeekNum = gpsWeekNum + (numGPSWeekNumRollOvers*1024);

    % Get time for timetable
    time = matlabshared.internal.gnss.GNSSTime.getLocalTime(gpsWeekNum, ...
                                                gpsTimeOfApplicability);
    timeVec = repmat(time, size(recordsTable,1),1);

    % GPSWeekNum and GPSTimeOfApplicability table
    table1 = table(repmat(gpsWeekNum,size(recordsTable,1),1), ...
                   repmat(gpsTimeOfApplicability,size(recordsTable,1),1),...
                   'VariableNames', ...
                   {'GPSWeekNumber', 'GPSTimeOfApplicability'});

    % concatenate both the tables
    cumulativeTable = [table1, recordsTable];
    % convert the combined table to time table
    data = table2timetable(cumulativeTable,'RowTimes',timeVec);
end

function numGPSWeekNumRollOvers = getNumGPSWeekNumRollOvers(varargin)
% get number of GPS week rollovers

    numGPSWeekNumRollOvers = 0; %#ok<NASGU>
    if nargin == 2 && ~(varargin{2} == "")
        % Convert the string to datetime object
        gpsWeekNumEpoch = datetime(varargin{2}, ...
                                    'InputFormat', 'dd-MMM-yyyy', ...
                                    'Locale', 'en_US');
        % Get number of rollovers with reference to specified Epoch
        numGPSWeekNumRollOvers = ceil(...
                matlabshared.internal.gnss.GNSSTime.getGPSWeekRollOvers( ...
                gpsWeekNumEpoch));
    else
        % Get number of rollovers from the current date
        numGPSWeekNumRollOvers = floor(...
                matlabshared.internal.gnss.GNSSTime.getGPSWeekRollOvers());
    end
end
