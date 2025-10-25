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

