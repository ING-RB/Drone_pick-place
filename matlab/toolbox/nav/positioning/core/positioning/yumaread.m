function data = yumaread(filename, varargin)
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
    if nargin > 1
        narginchk(3, 3);
        % Validate that second input argument is "GPSWeekEpoch"
        validatestring(varargin{1}, "GPSWeekEpoch", ...
                         "yumaread", "GPSWeekEpoch", 2);
        % Validate value of gpsWeekEpoch
        validatestring(varargin{2}, ...
            matlabshared.internal.gnss.getGPSWeekRolloverDates, ...
                         "yumaread", "GPSWeekEpoch value", 3);
    end

    % Get full file path
    fullfilename = which(filename);
    if isempty(fullfilename)
        fullfilename = char(filename);
    end

    % Parse the file
    try
        recordsTable = readYUMAAlmanac(fullfilename);
    catch ME
        rethrow(ME);
    end

    % Get number of rows before pruning
    numRowsBeforePrune = size(recordsTable,1);

    % Remove the rows with PRN number out of range
    gpsMinPRN = 1;
    gpsMaxPRN = 32;
    qzssMinPRN = 193;
    qzssMaxPRN = 202;
    recordsTable = recordsTable( ...
        (recordsTable.PRN >=gpsMinPRN  & recordsTable.PRN <=gpsMaxPRN)|...
        (recordsTable.PRN >=qzssMinPRN & recordsTable.PRN <=qzssMaxPRN),:);

    % Throw a warning about discarded data because of improper PRN number
    improperPRNNumber = numRowsBeforePrune - size(recordsTable,1);
    if improperPRNNumber >= 1
        coder.internal.warning( ...
        'nav_positioning:yumaread:invalidPRN', improperPRNNumber);
    end

    % Validate the data and throw warning for invalid data
    validateAndThrowWarning(recordsTable);

    % get number of GPS week rollovers
    numGPSWeekNumRollOvers = getNumGPSWeekNumRollOvers(varargin{:});

    % Get actual week number
    recordsTable.Week = recordsTable.Week + ...
           repmat(numGPSWeekNumRollOvers*1024,size(recordsTable.Week,1),1);

    % Get time for timetable
    time = matlabshared.internal.gnss.GNSSTime.getLocalTime( ...
                recordsTable.Week, recordsTable.TimeOfApplicability);

    % convert the table to time table
    data = table2timetable(recordsTable,'RowTimes',time);
end

function recordsTable = readYUMAAlmanac(fileName)
    % Extract contents of file as string
    filetext = fileread(fileName);

    % Split the file at delimiters. Get the number of elements per data
    % block
    [filetextSplit, ~, numElementsPerBlock] = ...
                        matlabshared.internal.gnss.strsplitCG(filetext);

    % Get the number of data blocks with 47 elements
    numProperDataBlocks = nnz(numElementsPerBlock(:) == 47);

    % Get number of data blocks discarded and throw a warning
    numDataBlocksDiscarded = size(numElementsPerBlock,1) ...
                                -numProperDataBlocks;
    improperDataBlocksFlags = numElementsPerBlock(:) == 47;
    if numDataBlocksDiscarded > 0
        coder.internal.warning( ...
            'nav_positioning:yumaread:improperDataBlocks', ...
            numDataBlocksDiscarded);
    end

    % Get initial index of each data block
    numElementsPerBlockCS = cumsum(numElementsPerBlock) - 47;

    % Check if all the valid blocks have valid field names
    allFileFieldNameIndices = numElementsPerBlockCS + getFieldNameIndices;
    fileFieldNames = getFileFieldNames;
    allFileFieldNameFlag = false(size(numElementsPerBlockCS,1),1);
    for i = 1:size(numElementsPerBlockCS,1)
        allFileFieldNameFlag(i) = ...
            strcmp([filetextSplit{allFileFieldNameIndices(i,:)}], ...
                    fileFieldNames);
    end
    % Get number of data blocks discarded because of improper field names
    % and throw a warning
    numDataBlocksDiscardedImproperFieldName = ...
        nnz(allFileFieldNameFlag - improperDataBlocksFlags < 0);
    if numDataBlocksDiscardedImproperFieldName > 0
        coder.internal.warning( ...
            'nav_positioning:yumaread:improperFieldName', ...
            numDataBlocksDiscardedImproperFieldName);
    end

    % Get number of proper data blocks
    properDataBlocksFlag = improperDataBlocksFlags & allFileFieldNameFlag;
    numProperDataBlocks = nnz(properDataBlocksFlag == 1);
    % Get indices of all proper data blocks
    allIndices = numElementsPerBlockCS(properDataBlocksFlag) + ...
                            getDataIndices;

    % Store the data in a table
    % Create an empty table
    fieldNames = getFieldNames();
    numFields  = numel(fieldNames);
    varTypes = repmat({'double'},1,numFields);
    recordsTable = table('Size', [numProperDataBlocks, numFields], ...
                         'VariableTypes', varTypes, ...
                         'VariableNames', fieldNames);

    % Populate table with data
    for i = 1:numProperDataBlocks
        for j = 1:numFields
            recordsTable.(fieldNames{j})(i) = ...
                real(str2double(filetextSplit{allIndices(i,j)}));
        end
    end
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

function fieldNames = getFieldNames()
    % The field names in YUMA almanac file
    fieldNames = {'PRN', ...
                  'Health', ...
                  'Eccentricity', ...
                  'TimeOfApplicability', ...
                  'OrbitalInclination', ...
                  'RateOfRightAscen', ...
                  'SQRTA', ...
                  'RightAscenAtWeek', ...
                  'ArgumentOfPerigee', ...
                  'MeanAnom', ...
                  'Af0', ...
                  'Af1', ...
                  'Week'};
end

function fileFieldNames = getFileFieldNames()
    fileFieldNames = "ID:Health:Eccentricity:TimeofApplicability(s):" + ...
                     "OrbitalInclination(rad):RateofRightAscen(r/s):" + ...
                     "SQRT(A)(m1/2):RightAscenatWeek(rad):" + ...
                     "ArgumentofPerigee(rad):MeanAnom(rad):" + ...
                     "Af0(s):Af1(s/s):week:";
end

function dataIndices = getDataIndices()
    % Indices in a data block where data is available
    dataIndices = [9 11 13 17 20 25 29 34 38 41 43 45 47];
end

function fieldNameIndices = getFieldNameIndices()
    % Indices in a data block where data is available
    fieldNameIndices = [8 10 12 14 15 16 18 19 21 22 23 24 26 27 28 ...
        30 31 32 33 35 36 37 39 40 42 44 46];
end

function validateAndThrowWarning(records)
    invalidDataArray = getIndicesInvalidData(records);
    throwWarning(invalidDataArray);
end

function invalidDataArray = getIndicesInvalidData(records)
    % Get field names
    varNames = getFieldNames();
    % Initialize flag arrays
    invalidDataArray = zeros(size(records));

    % Check and update flag for each field
    for idx = 1:numel(varNames)
        % Check if values of individual field is invalid or not, and
        % update the flag in the array
        if (idx == 1 || idx == 2 || idx == 13)
            invalidDataArray(:,idx) = isnan(records.(varNames{idx})) | ...
                isinf(records.(varNames{idx})) | ...
                ~(mod(records.(varNames{idx}),1) == 0);
        else
            invalidDataArray(:,idx) = isnan(records.(varNames{idx})) | ...
                isinf(records.(varNames{idx}));
        end
    end

    % Replace the first column with PRN number
    invalidDataArray(:,1) = records.PRN;
end

function throwWarning(invalidDataArray)
    % Get field names
    fieldNames = getFieldNames();
    indices = 2:13;
    % Check and throw warning for each PRN number
    for count = 1:size(invalidDataArray,1)
        % Get invalid data indices
        invalidIndices = indices(invalidDataArray(count,2:end) == 1);

        % Throw warning for invalid data
        if size(invalidIndices,2) == 1
            strInvalid = fieldNames{invalidIndices};
            coder.internal.warning( ...
                'nav_positioning:yumaread:invalidData', ...
                strInvalid, invalidDataArray(count,1));
        elseif size(invalidIndices,2) > 1
            strInvalid = '';
            for k = 1:size(invalidIndices,2)-1
                strInvalid = [strInvalid, ...
                        fieldNames{invalidIndices(k)}, ',']; %#ok<AGROW>
            end
            strInvalid = [strInvalid, ...
                        fieldNames{invalidIndices(k+1)}]; %#ok<AGROW>

            coder.internal.warning( ...
                'nav_positioning:yumaread:invalidData', ...
                strInvalid, invalidDataArray(count,1));
        end
    end
end