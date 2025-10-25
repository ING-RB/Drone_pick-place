%YUMAREAD Read data from YUMA almanac file
%
%   DATA = YUMAREAD(FILENAME) reads data from the YUMA almanac file
%   specified by FILENAME, and returns the parameters of each associated
%   satellite as a timetable. The timetable has a row for each record and a
%   column for each parameter in that record. FILENAME is a string scalar
%   or character vector that specifies the name of the YUMA file. FILENAME
%   can include path and the file extension.
%
%   DATA = YUMAREAD(FILENAME, GPSWeekEpoch=t) specifies the reference date
%   from which the YUMA almanac file counts the GPS week number. The 
%   reference date is specified as one of these valid datetime strings that
%   coincide with the GPS week number rollover dates: "06-Jan-1980", 
%   "21-Aug-1999", or "06-Apr-2019". These dates occur every 1024 weeks, 
%   starting from January 6, 1980 at 00:00 (UTC). The default value is a
%   datetime string that coincides with the most recent GPS week number
%   rollover date before the current day.
%
%   The timetable has following fields:
%       Time                 - GPS Time, calculated using Week and
%                              TimeOfApplicability
%       PRN                  - Satellite Pseudorandom noise number
%       Health               - Satellite vehicle health code
%       Eccentricity         - Eccentricity
%       TimeOfApplicability  - Number of seconds since beginning of GPS
%                              week number
%       OrbitalInclination   - Inclination angle at reference time (rad)
%       RateOfRightAscen     - Rate of change in measurement of angle of
%                              right ascension (rad/s)
%       SQRTA                - Square root of semi-major axis (m^(1/2))
%       RightAscenAtWeek     - Geographic longitude of orbital plane at
%                              weekly epoch (rad)
%       ArgumentOfPerigee    - Angle from equator to perigee (rad)
%       MeanAnom             - Angle from position of satellite in its
%                              orbit relative to perigee (rad)
%       Af0                  - Satellite almanac zeroth-order clock
%                              correction term (s)
%       Af1                  - Satellite almanac first order clock
%                              correction term (s/s)
%       Week                 - GPS Week number, continuous, not mod(1024)
%
%   Example:
%
%       % Get the orbital parameters from a YUMA almanac file and specify
%       % the GPS Week Epoch
%       filename = "yumaAlmanac_2022-4-20.alm";
%       data = yumaread(filename, GPSWeekEpoch="06-Apr-2019");
%
%   References:
%   [1] IS-GPS-200 Navstar GPS Space Segment/Navigation User Interfaces, 
%       U.S. Coast Guard Navigation Center, Alexandria, VA, USA, May 21,
%       2021. Accessed September 20, 2022. [Online]. Available:
%       https://www.navcen.uscg.gov/sites/default/files/pdf/gps/IS_GPS_200M.pdf.
%
%   [2] ICD-GPS-240 Navstar GPS Control Segment to User Support Community
%       Interface, U.S. Coast Guard Navigation Center, Alexandria, VA, USA,
%       May 21, 2021. Accessed September 20, 2022. [Online]. Available:
%       https://www.navcen.uscg.gov/sites/default/files/pdf/gps/ICD_GPS_240D.pdf.
%
%   [3] GPS almanac archives, U.S. Coast Guard Navigation Center,
%       Alexandria, VA, USA. Accessed September 20, 2022. Available:
%       https://www.navcen.uscg.gov/archives.
%
%   [4] Quasi-Zenith Satellite System(QZSS). "Satellite Positioning,
%       Navigation and Timing Service." Accessed September 20, 2022.
%       Available:
%       https://qzss.go.jp/en/technical/download/pdf/ps-is-qzss/is-qzss-pnt-004.pdf.
%
%   [5] QZSS almanac archives, Quasi-Zenith Satellite System(QZSS). 
%       "QZSS (Quasi-Zenith Satellite System) - Cabinet Office (Japan);"
%       Accessed September 20, 2022. Available:
%       https://sys.qzss.go.jp/dod/en/archives/pnt.html.
%
%   See also semread, rinexread, gnssconstellation

 
%   Copyright 2022-2023 The MathWorks, Inc.

