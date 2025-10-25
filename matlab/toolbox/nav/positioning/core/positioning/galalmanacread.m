function data = galalmanacread(filename, nvArgs)
%

% Copyright 2023 The MathWorks, Inc.

    arguments
        filename {mustBeNonempty,mustBeTextScalar, checkFilename(filename)}
        nvArgs.IssueDate datetime {mustBeScalarOrEmpty} = NaT
    end

    % Get full file path
    fullfilename = which(filename);
    if isempty(fullfilename)
        fullfilename = char(filename);
    end

    % Parse the file
    try
        recordsTable = xml2table(fullfilename, nvArgs.IssueDate);
    catch ME
        rethrow(ME);
    end

    % Get number of rows before pruning
    numRowsBeforePrune = size(recordsTable,1);

    % Remove the rows with SVID out of range
    % SVID = 0 is used to indicate unused almanac entries in almanac
    % data. Values higher than 36 are reserved for future use.
    % Taken from:
    % Section 5.1.91. of Galileo SiS Open Service Interface Control
    % Document. Accessed January 25, 2023. Available:
    % https://www.gsc-europa.eu/sites/default/files/sites/all/files/Galileo_OS_SIS_ICD_v2.0.pdf.
    galMinSVID = 1;
    galMaxSVID = 36;

    recordsTable = recordsTable(recordsTable.SVID >= galMinSVID & ...
                                recordsTable.SVID <= galMaxSVID,:);

    % Throw a warning about discarded data because of improper SVID
    improperSVIDNumber = numRowsBeforePrune - size(recordsTable,1);
    if improperSVIDNumber >= 1
        coder.internal.warning( ...
        'nav_positioning:galalmanacread:invalidSVID',improperSVIDNumber);
    end

    % Validate the data and throw warning for invalid data
    validateAndThrowWarning(recordsTable);

    % Get time for timetable
    time = matlabshared.internal.gnss.GalileoTime.getLocalTime( ...
                                    recordsTable.wna, recordsTable.t0a);

    % convert the table to time table
    data = table2timetable(recordsTable,'RowTimes',time);
end

function checkFilename(filename)
% Check the file extension
    [~,~,fileExtension] = fileparts(filename);

    if ~strcmpi(fileExtension, '.xml')
        error(message('nav_positioning:galalmanacread:invalidFileType', ...
            fileExtension));
    end

    % Check if the file exists
    fid = fopen(filename, 'r');

    if fid == -1
        error(message('nav_positioning:galalmanacread:fileOpenFailed', ...
            filename));
    end
    fclose(fid);
end

function recordsTable = xml2table(fileName, issueDate)
    % Parse the xmlfile
    xmlStruct = readstruct(fileName);

    % Check the read file for IssueDate and Almanac data
    checkDataAvailability(xmlStruct, issueDate);

    % Get datetime string from the file and convert it to datetime
    % object if user has not provided that
    if isnat(issueDate)
        % Get datetime string from the file
        datetimeString = xmlStruct.header.GAL_header.issueDate;
        % Convert issue date to datetime object
        time = datetime(datetimeString, 'InputFormat', ...
                    'uuuu-MM-dd''T''HH:mm:ss.SSSZ','TimeZone','UTC');
    else
        % User provided datetime object is the time to be used
        time = issueDate;
    end

    % Check valid field names and sub field names in the data
    [missingDataArray, allFieldFlag] = checkValidFieldNames(xmlStruct);

    % Get expected number of elements in each block
    expNumElementsPerBlock = numel(getFieldNames);
    % Count number of fields for each satellite
    numElementsPerBlock = sum(missingDataArray,2);
    sixteenElemsDataBlocksFlag = ...
                    (numElementsPerBlock(:) == expNumElementsPerBlock);

    % Get number of data blocks with expected number of elements
    numProperDataBlocks = ...
                    nnz(numElementsPerBlock(:) == expNumElementsPerBlock);

    % Get number of data blocks discarded and throw a warning
    numDataBlocksDiscardedLessElems = ...
                    size(numElementsPerBlock,1) - numProperDataBlocks;
    improperDataBlocksFlags = ...
                    numElementsPerBlock(:) == expNumElementsPerBlock;
    if numDataBlocksDiscardedLessElems > 0
        coder.internal.warning( ...
            'nav_positioning:galalmanacread:improperDataBlocks', ...
            numDataBlocksDiscardedLessElems);
    end

    % Get number of data blocks discarded because of improper field
    % names and throw a warning
    numDataBlocksDiscardedImproperFieldName = ...
        nnz(allFieldFlag - improperDataBlocksFlags < 0);
    if numDataBlocksDiscardedImproperFieldName > 0
        coder.internal.warning( ...
            'nav_positioning:galalmanacread:improperFieldName', ...
            numDataBlocksDiscardedImproperFieldName);
    end

    % Get number of proper data blocks
    properDataBlocksFlag = sixteenElemsDataBlocksFlag & allFieldFlag;

    % Store the data in a table
    recordsTable = createTableFromStruct(xmlStruct, properDataBlocksFlag);

    % Calculate actual week number from the issue date
    galWeek = matlabshared.internal.gnss.GalileoTime.getGalileoTime(time);

    % Check if mod(4) of computed week number is equal to actual wna or not
    % and throw warning about that
    wnaRange = 4;
    if any(recordsTable.wna ~= mod(galWeek,wnaRange))
        coder.internal.warning( ...
            'nav_positioning:galalmanacread:weeksMismatch');
    end

    % Replace wna with actual week number
    recordsTable.wna = repmat(galWeek, size(recordsTable,1),1);
end

function checkDataAvailability(xmlStruct, issueDate)
% Check xmlStruct for IssueDate and Almanac data

    % Throw an error if IssueDate is not present in the file and user
    % has not passed it either
    coder.internal.errorIf( ...
        ~((isfield(xmlStruct, 'header') && ...
          isfield(xmlStruct.header, 'GAL_header') && ...
          isfield(xmlStruct.header.GAL_header,'issueDate') && ...
          xmlStruct.header.GAL_header.issueDate ~= "") || ...
         ~isnat(issueDate)), ...
        'nav_positioning:galalmanacread:noIssueDate');

    % Throw an error if field 'body' is not present in the read struct
    coder.internal.errorIf(~(isfield(xmlStruct,'body') && ...
        isfield(xmlStruct.body, 'Almanacs') && ...
        isfield(xmlStruct.body.Almanacs, 'svAlmanac')), ...
        'nav_positioning:galalmanacread:noBody');
end

function fieldNames = getFieldNames()
    % The field names in XML almanac file
    fieldNames = {'SVID', ...
                  'aSqRoot', ...
                  'ecc', ...
                  'deltai', ...
                  'omega0', ...
                  'omegaDot', ...
                  'w', ...
                  'm0', ...
                  'af0', ...
                  'af1', ...
                  'iod', ...
                  't0a', ...
                  'wna', ...
                  'statusE5a', ...
                  'statusE5b', ...
                  'statusE1B'};
end

function bodyFieldNames = getBodyFieldNames()
    % The field names in the almanac body
    bodyFieldNames = {'SVID', ...
                      'almanac', ...
                      'svFNavSignalStatus', ...
                      'svINavSignalStatus'};
end

function bodySubField = getBodySubField()
    % The sub field names in the almanac body
    bodySubField = {{'aSqRoot'; ...
                  'ecc'; ...
                  'deltai'; ...
                  'omega0'; ...
                  'omegaDot'; ...
                  'w'; ...
                  'm0'; ...
                  'af0'; ...
                  'af1'; ...
                  'iod'; ...
                  't0a'; ...
                  'wna'}, ...
                  {'statusE5a'}, ...
                  {'statusE5b'; 'statusE1B'}};
end

function [SVIDIdx, wnaIdx, statusE5aIdx, ...
                statusE5bIdx, statusE1BIdx] = getIndexIntValues()
%getIndexIntValues Index of fields which are expected to be integers
    SVIDIdx      = 1;
    wnaIdx       = 13;
    statusE5aIdx = 14;
    statusE5bIdx = 15;
    statusE1BIdx = 16;
end

function [missingDataArray, allFieldFlag] = ...
                                        checkValidFieldNames(xmlStruct)
    % Get number of data blocks in the read data
    numDataBlocks = numel(xmlStruct.body.Almanacs.svAlmanac);

    % Get the field names in the body
    bodyFieldNames = getBodyFieldNames();
    % Get the sub field names in the body
    bodySubField = getBodySubField;
    % Get number of body fields
    numBodyFields = numel(bodyFieldNames);

    % Create an numberOfDataBlocks-by-numberOfBodyFields array for
    % storing number of elements in each body field
    missingDataArray = ones(numDataBlocks, numBodyFields);
    % Create n-by-1 vector for storing flag for valid field names
    allFieldFlag = ones(numDataBlocks,1);

    % Store the number of elements available in each body field and
    % Check if all the valid blocks have valid field names
    for i = 1:numDataBlocks
        for j = 2:numBodyFields
            missingDataArray(i,j) = numel(fieldnames(xmlStruct ...
                .body.Almanacs.svAlmanac(i).(bodyFieldNames{j})));
            fieldToCheck = fieldnames( ...
                xmlStruct.body.Almanacs.svAlmanac(i).(bodyFieldNames{j}));
            allFieldFlag(i) = allFieldFlag(i) && ...
                              isequal(fieldToCheck, bodySubField{j-1});
        end
    end
end

function recordsTable = createTableFromStruct(xmlStruct, ...
                                              properDataBlocksFlag)
    % Store the data in a table
    % Create an empty table
    fieldNames = getFieldNames();
    numFields  = numel(fieldNames);
    varTypes = repmat({'double'},1,numFields);
    recordsTable = table( ...
                    'Size', [nnz(properDataBlocksFlag == 1),numFields], ...
                    'VariableTypes', varTypes, ...
                    'VariableNames', fieldNames);

    % Get indices of almanac sub field in the Body
    almanacSubFieldIndexStart = 2;
    almanacSubFieldIndexEnd = 13;

    % Get indices of data blocks that have proper data
    indices = (1:numel(xmlStruct.body.Almanacs.svAlmanac))';
    indicesToUse = indices(properDataBlocksFlag);

    % Populate table with data
    for i = 1:numel(indicesToUse)
        idx = indicesToUse(i);
        % Populate Satellite ID
        recordsTable.SVID(i) = xmlStruct.body.Almanacs.svAlmanac(idx).SVID;
        % Populate other almanac data
        for j = almanacSubFieldIndexStart:almanacSubFieldIndexEnd
            recordsTable.(fieldNames{j})(i) = xmlStruct.body.Almanacs ...
                .svAlmanac(idx).almanac.(fieldNames{j});
        end
        % Populate statusE5a
        recordsTable.statusE5a(i) = xmlStruct.body.Almanacs ...
                .svAlmanac(idx).svFNavSignalStatus.statusE5a;
        % Populate statusE5b and statusE1B
        recordsTable.statusE5b(i) = xmlStruct.body.Almanacs ...
                .svAlmanac(idx).svINavSignalStatus.statusE5b;
        % Populate statusE1B
        recordsTable.statusE1B(i) = xmlStruct.body.Almanacs ...
                .svAlmanac(idx).svINavSignalStatus.statusE1B;
    end
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
    % Get index of fields which are expected to be integers
    [SVIDIdx, wnaIdx, statusE5aIdx, ...
                statusE5bIdx, statusE1BIdx] = getIndexIntValues();

    % Check and update flag for each field
    for idx = 1:numel(varNames)
        % Check if values of individual field is invalid or not, and
        % update the flag in the array
        if(idx == SVIDIdx || idx == wnaIdx || idx == statusE5aIdx || ...
                idx == statusE5bIdx || idx == statusE1BIdx)
            invalidDataArray(:,idx) = isnan(records.(varNames{idx}))|...
                isinf(records.(varNames{idx})) | ...
                ~(mod(records.(varNames{idx}),1) == 0);
        else        % all other almanac data
            invalidDataArray(:,idx) = isnan(records.(varNames{idx}))|...
                isinf(records.(varNames{idx}));
        end
    end

    % Replace the first column with SVID
    invalidDataArray(:,1) = records.SVID;
end

function throwWarning(invalidDataArray)
    % Get field names
    fieldNames = getFieldNames();
    % Get indices of data
    dataStartIndexAfterSVID = 2;
    indices = dataStartIndexAfterSVID:numel(fieldNames);
    % Check and throw warning for each PRN number
    for count = 1:size(invalidDataArray,1)
        % Get invalid data indices
        invalidIndices = indices( ...
                invalidDataArray(count,dataStartIndexAfterSVID:end) == 1);

        % Throw warning for invalid data
        if size(invalidIndices,2) == 1
            strInvalid = fieldNames{invalidIndices};
            coder.internal.warning( ...
                'nav_positioning:galalmanacread:invalidData', ...
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
                'nav_positioning:galalmanacread:invalidData', ...
                strInvalid, invalidDataArray(count,1));
        end
    end
end