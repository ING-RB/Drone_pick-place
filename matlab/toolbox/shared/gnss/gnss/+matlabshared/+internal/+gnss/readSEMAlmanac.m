function [almanacTitle, gpsWeekNum, gpsTimeOfApplicability, ...
          recordsStruct, recordsTable] = readSEMAlmanac(fileName)
%readSEMAlmanac Read SEM almanac file
%   Reserved for MathWorks internal use only.
%
%   [almanacTitle, gpsWeekNum, gpsTimeOfApplicability, recordsStruct, ...
%     recordsTable] = matlabshared.internal.gnss.readSEMAlmanac(fileName)
%
%   Input Argument:
%   fileName               - ASCII-formatted SEM almanac file
%
%   Output Arguments:
%   almanacTitle           - Descriptive name for Almanac in file as string
%                            scalar
%   gpsWeekNum             - Almanac reference week number for all almanac
%                            data in file
%                            Note: The value lies between 0 and 1023 and it
%                            is modulus of 1024.
%   gpsTimeOfApplicability - Number of seconds since beginning of almanac
%                            reference week
%   recordsStruct          - Parameters of each satellite defined in SEM
%                            almanac as structure
%   recordsTable           - Parameters of each satellite defined in SEM
%                            almanac as table
%
%   Parameters of each satellite:
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

%   Refer to Section 40.4, Table 40-II on page 3 in this document for the
%   definition of the SEM almanac parameters:
%   https://navcen.uscg.gov/pdf/gps/ICD_GPS_240D.pdf

%   Copyright 2021-2022 The MathWorks, Inc.

%#codegen

    % Check that user has provided 1 input argument i.e., the filename
    narginchk(1,1);

    % Extract contents of file as string
    filetext = fileread(fileName);

    % Split the file at delimiters. Get the number of elements per line
    % and per data block
    [filetextSplit, numElementsPerLine, numElementsPerBlock] = ...
                matlabshared.internal.gnss.strsplitCG(filetext);

    % Error out if header doesn't have 3 elements, title can be omitted,
    % but other 3 data are absolutely required
    coder.internal.errorIf( ...
        numElementsPerBlock(1) ~= 3 && numElementsPerBlock(1) ~= 4, ...
        'shared_gnss:readSEMAlmanac:invalidHeader');

    % Get number of records
    numRecords = real(str2double(filetextSplit{1}));
    % Validate the number of records
    validateattributes(numRecords, {'double'}, ...
                       {'scalar', 'real', 'integer', '>=',0, '<=',32}, ...
                       'readSEMAlmanac', 'Number of records');

    % Throw a warning if number of records doesn't match the number of data
    % blocks
    if numRecords ~= size(numElementsPerBlock,1)-1
        coder.internal.warning( ...
            'shared_gnss:readSEMAlmanac:numRecordsDataBlockMismatch');
    end

    % Check if title is available, if not, throw a warning
    if numElementsPerLine(1) == 2
        almanacTitle = filetextSplit{2};
    else
        almanacTitle = '';
        coder.internal.warning('shared_gnss:readSEMAlmanac:noTitle');
    end

    % Get GPS Week number
    gpsWeekNum = real(str2double(filetextSplit{numElementsPerBlock(1)-1}));
    % Validate GPS Week number
    validateattributes(gpsWeekNum, {'double'}, ...
                       {'scalar', 'real', 'integer', '>=',0, '<=',1023},...
                       'readSEMAlmanac', 'GPS Week Number');

    % Get GPS time of applicability
    gpsTimeOfApplicability = ...
        real(str2double(filetextSplit{numElementsPerBlock(1)}));
    % Validate GPS time of applicability
    validateattributes(gpsTimeOfApplicability, {'double'}, ...
                    {'scalar', 'real', 'integer', '>=',0, '<=',602112}, ...
                    'readSEMAlmanac', 'GPS Time of Applicability');

    % Get the data blocks with 14 elements
    idxRecordsToPopulate = find(numElementsPerBlock(2:end) == 14);
    numProperDataBlocks = numel(idxRecordsToPopulate);

    % Get number of data blocks discarded and throw a warning
    numDataBlocksDiscarded = size(numElementsPerBlock,1) -1 ...
                                -numProperDataBlocks;
    if numDataBlocksDiscarded > 0
        coder.internal.warning( ...
            'shared_gnss:readSEMAlmanac:improperDataBlocks', ...
            numDataBlocksDiscarded);
    end

    % Store the data in a table
    fieldNames = getFieldNames();
    numFields  = numel(fieldNames);
    varTypes = repmat({'double'},1,numFields);
    recordsTable = table('Size', [numProperDataBlocks, numFields], ...
                         'VariableTypes', varTypes, ...
                         'VariableNames', fieldNames);
    for i = 1:numProperDataBlocks
        for j = 1:numFields
            index = sum(numElementsPerBlock(1:idxRecordsToPopulate(i))) +j;
            recordsTable.(fieldNames{j})(i) = ...
                real(str2double(filetextSplit{index}));
        end
    end

    % Get number of rows before pruning
    numRowsBeforePrune = size(recordsTable,1);

    % Remove the rows with PRN number out of range
    recordsTable = recordsTable ...
        (recordsTable.PRNNumber >= 1 & recordsTable.PRNNumber <= 32,:);

    % Throw a warning about discarded data because of improper PRN number
    improperPRNNumber = numRowsBeforePrune - size(recordsTable,1);
    if improperPRNNumber >= 1
        coder.internal.warning( ...
        'shared_gnss:readSEMAlmanac:invalidPRN', improperPRNNumber);
    end

    % convert to struct
    recordsStruct = table2struct(recordsTable);

    % Validate the data and throw warning for invalid and out of range data
    validateAndThrowWarning(recordsTable);
end

function validateAndThrowWarning(records)
    invalidDataArray = getIndicesInvalidData(records);
    throwWarning(invalidDataArray);
end

function flagDataArray = getIndicesInvalidData(records)
    % Get field names
    varNames = getFieldNames();
    % Initialize flag arrays
    invalidDataArray = zeros(size(records));
    outOfRangeDataArray = zeros(size(records));
    % Get minimum and maximum value of each field
    minMaxValues = getMinMaxValues();
    % Check and update flag for each field
    for idx = 1:numel(varNames)
        % Check if values of individual field is out of range or not, and
        % update the flag in the array
        outOfRangeDataArray(:,idx) = ...
            ~((records.(varNames{idx}) >= minMaxValues(idx,1)) & ...
              (records.(varNames{idx}) <= minMaxValues(idx,2)));

        % Check if values of individual field is invalid or not, and
        % update the flag in the array
        if (idx == 1 || idx == 2 || idx == 3 || idx == 13 || idx == 14)
            invalidDataArray(:,idx) = isnan(records.(varNames{idx})) | ...
                isinf(records.(varNames{idx})) | ...
                ~(mod(records.(varNames{idx}),1) == 0);
        else
            invalidDataArray(:,idx) = isnan(records.(varNames{idx})) | ...
                isinf(records.(varNames{idx}));
        end
    end
    % Get a cumulative flag array
    flagDataArray = outOfRangeDataArray + invalidDataArray * 2;
    % Replace the first column with PRN number
    flagDataArray(:,1) = records.PRNNumber;
    % Extract only the rows with invalid data
    flagDataArray = flagDataArray(any(flagDataArray(:,2:end),2),:);
end

function throwWarning(invalidDataArray)
    % Get field names
    fieldNames = getFieldNames();
    indices = 2:14;
    % Check and throw warning for each PRN number
    for count = 1:size(invalidDataArray,1)
        % Get invalid data indices
        invalidIndices = indices(invalidDataArray(count,2:end) > 1);
        % Get out of range data indices
        outOfRangeIndices = indices(invalidDataArray(count,2:end) == 1);

        % Throw warning for invalid data
        if size(invalidIndices,2) == 1
            strInvalid = fieldNames{invalidIndices};
            coder.internal.warning( ...
                'shared_gnss:readSEMAlmanac:invalidData', ...
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
                'shared_gnss:readSEMAlmanac:invalidData', ...
                strInvalid, invalidDataArray(count,1));
        end

        % Throw warning for out of range data
        if size(outOfRangeIndices,2) == 1
            strOutOfRange = fieldNames{outOfRangeIndices};
            coder.internal.warning( ...
                'shared_gnss:readSEMAlmanac:outOfRangeData', ...
                strOutOfRange, invalidDataArray(count,1));
        elseif size(outOfRangeIndices,2) > 1
            strOutOfRange = '';
            for k = 1:size(outOfRangeIndices,2)-1
                strOutOfRange = [strOutOfRange, ...
                        fieldNames{outOfRangeIndices(k)}, ',']; %#ok<AGROW>
            end
            strOutOfRange = [strOutOfRange, ...
                        fieldNames{outOfRangeIndices(k+1)}]; %#ok<AGROW>
            coder.internal.warning( ...
                'shared_gnss:readSEMAlmanac:outOfRangeData', ...
                strOutOfRange, invalidDataArray(count,1));
        end
    end
end

function fieldNames = getFieldNames()
    % The field names in SEM almanac file
    fieldNames = {'PRNNumber', ...
                  'SVN', ...
                  'AverageURANumber', ...
                  'Eccentricity', ...
                  'InclinationOffset', ...
                  'RateOfRightAscension', ...
                  'SqrtOfSemiMajorAxis', ...
                  'GeographicLongitudeOfOrbitalPlane', ...
                  'ArgumentOfPerigee', ...
                  'MeanAnomaly', ...
                  'ZerothOrderClockCorrection', ...
                  'FirstOrderClockCorrection', ...
                  'SatelliteHealth', ...
                  'SatelliteConfiguration'};
end

function minMaxValues = getMinMaxValues()
    % minimum and maximum valued of all the field in SEM almanac file
    minMaxValues = [ 1, 32; ...
                     0, 255; ...
                     0, 15; ...
                     0, 3.125e-2; ...
                     -6.25e-2, 6.25e-2; ...
                     -1.1921e-7, 1.1921e-7; ...
                     0, 8192; ...
                     -1, 1; ...
                     -1, 1; ...
                     -1, 1; ...
                     -9.7657e-4, 9.7657e-4; ...
                     -3.7253e-9, 3.7253e-9; ...
                     0, 63; ...
                     0, 15];
end
