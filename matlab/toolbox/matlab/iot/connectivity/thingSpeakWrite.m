function varargout = thingSpeakWrite( channelID, varargin )
%THINGSPEAKWRITE Write data to a ThingSpeak channel.
%
%   Syntax
%   ------
%
%   thingSpeakWrite(channelID, data, 'WriteKey', writeAPIKey)
%   thingSpeakWrite(__, Name, Value)
%   response = thingSpeakWrite(__)
%
%   Description
%   -----------
%
%   thingSpeakWrite(channelID, data, 'WriteKey', writeAPIKey) writes the 
%   data to the specified channel. The write API key is specified as a 
%   comma-separated pair consisting of 'WriteKey' and a character vector 
%   or string representing the channel write key.
%
%   thingSpeakWrite(__, Name, Value) uses additional options 
%   specified by one or more Name,Value pair arguments.
%
%   response = thingSpeakWrite(__) returns the response provided by the 
%   ThingSpeak server on successful completion of the write operation.
%
%   Input Arguments
%   ---------------
%
%   Name         Description                            Data Type
%   ----      ------------------                        ---------
%   channelID
%            Channel identification number.             positive integer
%
%
%   data
%            Data to be written to the fields in        numeric scalar or
%            a channel. Values can be specified         numeric array or
%            as either a scalar, numeric array,         cell array or table
%            cell array, table or timetable.            or timetable
%
%            If the specified value is a scalar,
%            and FIELDS parameter has not been
%            specified, then it is written to
%            Field1 of the specified channel.
%
%            If the specified value is a vector,
%            it can be a numeric vector or a 1-D
%            cell array. In this case the vector
%            can have a maximum of 8 elements.
%            Each consecutive value in the vector
%            will be written to a consecutive
%            field, starting with Field1, in the
%            specified channel.
%
%            If the specified value is a matrix or
%            table or timetable, then each row of
%            the specified data is assumed to
%            correspond to a single timestamp. For
%            data specified as a matrix the
%            timestamp associated with each row of
%            the matrix needs to be provided using
%            the TIMESTAMP parameter.
%            For data specified as a table,
%            timestamps have be provided as either the
%            first column of the table or using the
%            TIMESTAMP parameter.
%
%
%   Name-Value Pair Arguments
%   -------------------------
%
%   Name         Description                            Data Type
%   ----      ------------------                        ---------
%
%   Fields
%             Field indices in a channel to write       1x8 positive integers
%             data. The maximum vector size is 8 
%             elements.
%
%   Location
%             Write [Latitude, Longitude, Altitude]     1x3 numeric vector or
%             data to the channel feed. You can also    Nx3 array
%             specify just [Latitude, Longitude], if
%             Altitude information is not present.
%
%   Timestamp
%             Specify the timestamp of the datetime     datetime
%             value/s being written to the channel
%             feed.
%
%   Timeout
%             Specify the timeout (in seconds) for      positive number
%             connecting to the server and reading
%             data. Default value is 10 seconds.
%
%   Values
%             Values to be written to the channel       numeric scalar or
%             fields specified with the Fields          numeric array  or
%             parameter.                                cell array     or
%                                                       string         or
%                                                       table or timetable
%
%   WriteKey
%             Specify the write APIKey of the channel.  string
%
%
%   % Example 1
%   % ---------
%   % Write a value to Field1 of a channel. Change the channel ID to
%   % write data to your channel.
%   channelID = <Enter Channel ID>
%   writeKey  = <Enter Write API Key>
%   thingSpeakWrite(channelID, 2.3, 'WriteKey', writeKey);
%
%   % Example 2
%   % ---------
%   % Write numeric values to the first 4 consecutive fields [1, 2, 3, 4]
%   % of a channel. Change the channel ID to write data to your
%   % channel.
%   channelID = <Enter Channel ID>
%   writeKey  = <Enter Write API Key>
%   thingSpeakWrite(channelID, [2.3, 1.2, 3.2, 0.1], 'WriteKey', writeKey)
%
%   % Example 3
%   % ---------
%   % Write non-numeric data to the first 3 consecutive fields [1, 2, 3]
%   % of a channel. Change the channel ID to write data to your
%   % channel.
%   channelID = <Enter Channel ID>
%   writeKey  = <Enter Write API Key>
%   thingSpeakWrite(channelID, {2.3, 'on', 'good'}, 'WriteKey', writeKey)
%
%   % Example 4
%   % ---------
%   % Write values to non-consecutive fields, for e.g., [1, 4, 6] of a
%   % channel. Change the channel ID to write data to your channel.
%   channelID = <Enter Channel ID>
%   writeKey  = <Enter Write API Key>
%   thingSpeakWrite(channelID, {2.3, 'on', 'good'}, 'Fields', [1, 4, 6], 'WriteKey', writeKey)
%
%   % Example 5
%   % ---------
%   % Write latitude and longitude to the channel feed along with values to
%   % consecutive fields. Change the channel ID to write data to
%   % your channel.
%   channelID = <Enter Channel ID>
%   writeKey  = <Enter Write API Key>
%   thingSpeakWrite(17504, {2.3, 'on', 'good'}, 'Location', [-40, 23], 'WriteKey', writeKey)
%
%   % Example 6
%   % ---------
%   % Write latitude, longitude and altitude data to a channel without
%   % adding values to fields. Change the channel ID to write data to
%   % your channel.
%   channelID = <Enter Channel ID>
%   writeKey  = <Enter Write API Key>
%   thingSpeakWrite(17504, 'Location', [-40, 23, 3500], 'WriteKey', writeKey)
%
%   % Example 7
%   % ---------
%   % Write timestamp for the value being written to a channel. Timestamp
%   % provided is interpreted in local timezone.
%   channelID = <Enter Channel ID>
%   writeKey  = <Enter Write API Key>
%   tStamp = datetime('2/6/2015 9:27:12', 'InputFormat', 'MM/dd/yyyy HH:mm:ss')
%   thingSpeakWrite(17504, [2.3, 1.2, 3.2, 0.1], 'TimeStamp', tStamp, 'WriteKey', writeKey)
%
%   % Example 8
%   % ---------
%   % Write timestamp for the value being written to a channel. Timestamp
%   % provided is interpreted in local timezone.
%   channelID = <Enter Channel ID>
%   writeKey  = <Enter Write API Key>
%   tStamp = datetime('2/6/2015 9:27:12', 'InputFormat', 'MM/dd/yyyy HH:mm:ss')
%   thingSpeakWrite(17504, [2.3, 1.2, 3.2, 0.1], 'TimeStamp', tStamp, 'WriteKey', writeKey)
%
%   % Example 9
%   % ----------
%   % Write a matrix of values to your channel
%   % Generate Random Data
%   data = randi(10, 10, 3);
%
%   % Generate timestamps for the data
%   tStamps = datetime('now')-minutes(9):minutes(1):datetime('now');
%
%   channelID = <Enter Channel ID>
%   writeKey  = <Enter Write API Key>
%
%   % Write 10 values to each field of your channel along with timestamps
%   thingSpeakWrite(channelID, data, 'TimeStamp', tStamps, 'WriteKey', writeKey)
%
%   % Example 10
%   % ----------
%   % Write a table of values to your channel
%   % Generate Random Data
%   dataField1 = randi(10, 10, 1);
%   dataField2 = randi(10, 10, 1);
%   % Generate timestamps for the data
%   tStamps = [datetime('now')-minutes(9):minutes(1):datetime('now')]';
%
%   % Create table
%   dataTable = table(tStamps, dataField1, dataField2);
%   channelID = <Enter Channel ID>
%   writeKey  = <Enter Write API Key>
%
%   % Write 10 values to each field of your channel along with timestamps
%   thingSpeakWrite(channelID, dataTable, 'WriteKey', writeKey)
%
%   % Example 11
%   % ----------
%   % Write a timetable of values to your channel
%   % Generate Random Data
%   dataField1 = randi(10, 10, 1);
%   dataField2 = randi(10, 10, 1);
%   % Generate timestamps for the data
%   Timestamps = [datetime('now')-minutes(9):minutes(1):datetime('now')]';
%
%   % Create timetable
%   dataTimeTable = timetable(Timestamps, dataField1, dataField2);
%   channelID = <Enter Channel ID>
%   writeKey  = <Enter Write API Key>
%
%   % Write 10 values to each field of your channel along with timestamps
%   thingSpeakWrite(channelID, dataTimeTable, 'WriteKey', writeKey)

% Copyright 2015-2018, The MathWorks Inc.

% Initialize the optionString array
optionString = {};

try
    % Check to ensure that atleast one input is provided
    narginchk(1, inf);
    
    % Validate channel ID specified by the user
    validateChannelID(channelID);
    
    % Depending on the NV pairs provided and number of feeds being written,
    % call the single value or batch values error parser
    [parsedInputs, batchflag] = inputArgParser(nargin, varargin);
    
    % Extract Fields, Values and Location parameter
    
    Fields = parsedInputs.Fields;
    Values = parsedInputs.Values;
    Location = parsedInputs.Locations;
    
    
    % Either Values or Location needs to be provided for the function to
    % work.
    % Check if Field input is scalar or vector and has values that are
    % positive integer values in [0, 8]. Also check if the 'values' input
    % is appropriate for the specified number of fields
    validateFields(Fields, Values)
    
    % If neither Values or Location is provided then generate an error
    if isempty(Values) && isempty(Location)
        throwAsCaller(MException(message...
            ('MATLAB:iot:thingSpeakConnectivity:missingData')));
    end
    
    % If an alternate URL (to a private ThingSpeak Server) is provided
    alternateURL = parsedInputs.URL;
    
    % Get the thingSpeak URL to use in this function
    url = getThingSpeakURL({'alternateURL', alternateURL, 'writeFlag', ...
        1, 'batchFlag', batchflag, 'channelID', channelID});
    
    % API 'Key' parameter
    [optionString] = validateAPIKey(parsedInputs.WriteKey, optionString);
    
    % Parse the data to build the json string
    TimeStamp = parsedInputs.Timestamps;
    
    optionString = dataParser(batchflag, Values, Fields, ...
        optionString, Location, TimeStamp);
    
    % Fetch the user defined timeout value and validate user provided value
    timeout = parsedInputs.Timeout;
    
    timeout = validateTimeOut(timeout, batchflag);
    
    % Figure out TimeZone for the user provided datetime values
    timeZone = '';
    if ~isempty(TimeStamp)
        timeZone = TimeStamp.TimeZone;
    end
    
    % If Batch values is provided as a table, or timetable, extract the
    % time from the first column to set the timezone.
    if istable(Values) || isa(Values, 'timetable')
        if istable(Values) && isdatetime(Values{:,1})
            timeStampFirst = Values{1,1};
            timeZone = timeStampFirst.TimeZone;
        elseif isa(Values, 'timetable')
            timeZone = Values.Properties.RowTimes.TimeZone;
        end
    elseif isa(Location, 'timetable')
        % If Location data is provided as a timeTable
        timeZone = Location.Properties.RowTimes.TimeZone;
    end
    
    % If user provided data doesnt have timezone info, then set to local
    if isempty(timeZone)
        TimeStamp = datetime;
        TimeStamp.TimeZone = 'local';
        timeZone = TimeStamp.TimeZone;
    end
    
    optionString(:, end+1:end+2) = {'timezone', timeZone};
    
    % Call to ThingSpeak API to write data from ThingSpeak.
    writeResponse = write2ThingSpeak(url, optionString, ...
        timeout, batchflag);
    
    % If user has provided a LHS
    if nargout == 1
        varargout{1} = writeResponse;
    end
    
catch writeErr
    % Catch any errors generated in the write process and return to user
    throwAsCaller(writeErr);
end

end

%% Helper functions
function validateFields(Fields, Values)
% VALIDATEFIELDS validates the fields name value provided by the user. This
% also checks the values provided to ensure that the dimensions are in
% agreement

if ~isempty(Fields)
    try
        validateattributes(Fields, {'numeric'}, {'positive', 'integer',...
            'vector', '>', 0, '<', 9});
        
        % Check that all values are unique
        uniqueVals = unique(Fields);
        if numel(uniqueVals) ~= numel(Fields)
            throwAsCaller(MException(message...
                ('MATLAB:iot:thingSpeakConnectivity:nonUniqueFields')));
        end
    catch
        throwAsCaller(MException(message...
            ('MATLAB:iot:thingSpeakConnectivity:invalidFields')));
    end
    
    % Check if Values parameter is specified
    
    if isempty(Values) && ~isempty(Fields)
        throwAsCaller(MException(message...
            ('MATLAB:iot:thingSpeakConnectivity:missingValuesInput')));
    end
end
end

function [optionString] = validateAPIKey(apiKey, optionString)
% VALIDATEAPIKEY handles the Read API Key provided by the user

if isempty(apiKey)
    throwAsCaller(MException(message...
        ('MATLAB:iot:thingSpeakConnectivity:missingAuthentication')));
else
    if isstring(apiKey)
        apiKey = char(apiKey);
    end
    
    try
        validateattributes(apiKey, {'char'}, {'vector'});
    catch
        throwAsCaller(MException(message...
            ('MATLAB:iot:thingSpeakConnectivity:invalidWriteAPIKey')));
    end
    
    if contains(apiKey, ' ')
        throwAsCaller(MException(message...
            ('MATLAB:iot:thingSpeakConnectivity:invalidWriteAPIKeySpace')));
    end
    optionString(1, end+1:end+2) = {'key', apiKey};
end
end

function timeout = validateTimeOut(timeout, batchflag)
% VALIDATETIMEOUT validates the value provided for the TimeOut name input
% argument. It also selects default if not provided by user.

if ~isempty(timeout)
    try
        validateattributes(timeout, {'numeric'}, {'finite', 'nonnan',...
            'nonzero'})
    catch
        throwAsCaller(MException(message...
            ('MATLAB:iot:thingSpeakConnectivity:invalidTimeout')));
    end
else
    if batchflag
        % setting default timeout to a large value for batch upload
        timeout = 1000;
    else
        % setting default timeout to 10 seconds for single row upload
        timeout = 10;
    end
end

end

function validateTimeTable(Values)

timestamps = Values.Properties.RowTimes;
if isduration(timestamps)
    throwAsCaller(MException(message...
        ('MATLAB:iot:thingSpeakConnectivity:timetableIncorrectTime')));
end
end

function validateChannelID(channelID)
% VALIDATECHANNELID validates the channelID provided by the user

try
    validateattributes(channelID,{'numeric'},{'scalar', 'nonempty', ...
        'integer', 'positive'})
catch
    throwAsCaller(MException(message...
        ('MATLAB:iot:thingSpeakConnectivity:invalidChannelID')));
end

end


function [parsedInputs, batchflag] = inputArgParser(numInpts, inputArgs)
% TSNUMINPUTSWITCHER handles the different combinations of input Name-Value
% pairs provided by a user

% If only 1 input is provided
if numInpts <2
    throwAsCaller(MException(message...
        ('MATLAB:iot:thingSpeakConnectivity:missingData')));
elseif numInpts==2 % If channel ID and values to be written are provided
    inputArguments = {'Values', inputArgs{1}};
else % If more than two inputs are provided
    % If numInpts is greater than 2 then the second input has to be either
    % the data or a supported Name-Value pair
    
    secondInput = inputArgs{1};
    
    % If the second input is data, then it has to be a numeric scalar, or
    % vector - mwArray or cell array
    
    % Check if it is a single number or array and numeric or table but not
    % a struct, or or categorial or object or any other MATLAB datatype
    if ischar(secondInput)||(isstring(secondInput)&&isscalar(secondInput))
        inputArguments = inputArgs;
    elseif (isscalar(secondInput)...
            && isnumeric(secondInput)...
            || isvector(secondInput)...
            || istable(secondInput)...
            || (size(secondInput, 1) > 1))...
            && (~ischar(secondInput)...
            && ~isstruct(secondInput)...
            && ~iscategorical(secondInput))
        % Put the data in second Input as values into input Arguments
        inputArguments = [{'Values', secondInput}, inputArgs(2:end)];
    else
        throwAsCaller(MException(message...
            ('MATLAB:iot:thingSpeakConnectivity:unrecognizedParameter')));
    end
end

% If additional inputs are provided parse the inputs and assign them to the
% parsedInputs structure
try
    parsedInputs = parseInputs(inputArguments);
catch e
    throwAsCaller(e);
end

numRowsValues = size(parsedInputs.Values, 1);
numRowsLocation = size(parsedInputs.Locations, 1);
numRowsTimestamps = size(parsedInputs.Timestamps, 1);

% All three of these need to have the same number of rows
% Default is single timestamp update

batchflag = 0;
if numRowsValues > 1 || numRowsLocation > 1 || numRowsTimestamps > 1
    batchflag = 1;
end
end

function optionString = dataParser(batchflag, Values, Fields,...
    optionString, Location, TimeStamp)
% DATAPARSING validates and converts the data provided by the user for
% both the single and batch feed update scenarios.

% Single timestamp update
if (batchflag == 0)
    % Check if Values is empty
    if ~isempty(Values)
        % Check if size of Values = size of Fields
        numElemsValues = numel(Values);
        
        % If fields is specified
        if ~isempty(Fields)
            numElemsFields = numel(Fields);
            
            if numElemsFields ~= numElemsValues
                throwAsCaller(MException(message...
                    ('MATLAB:iot:thingSpeakConnectivity:invalidParamWithValues')));
            end
        end
        
        % Check the number of elements in Values
        if istable(Values)
            if numElemsValues > 9
                throwAsCaller(MException(message...
                    ('MATLAB:iot:thingSpeakConnectivity:tooManyValues')));
            end
        elseif istimetable(Values)
            %Timetable is covered because timestamps
            % are rownames and are not counted as variables.
            if numElemsValues > 8
                throwAsCaller(MException(message...
                    ('MATLAB:iot:thingSpeakConnectivity:tooManyValuesTimeTable')));
            end
        else
            % For arrays
            if numElemsValues > 8
                throwAsCaller(MException(message...
                    ('MATLAB:iot:thingSpeakConnectivity:tooManyValues')));
            end
        end
        
        try
            % Attempt to parse all the inputs provided by the user
            optionString = valuesParser(Values, optionString, Fields);
        catch optionStringErr
            % If any errors are generated, then generate an throw the error
            % generated by the valueParsing function
            throwAsCaller(optionStringErr);
        end
        
    end
    
    % Check the Locations Input
    if ~isempty(Location)
        try
            validateattributes(Location, {'numeric', 'tabular'},...
                {'vector'});
        catch
            throwAsCaller(MException(message...
                ('MATLAB:iot:thingSpeakConnectivity:invalidParamWithLocation')));
        end
        LocationSet = {'latitude', 'longitude', 'elevation'};
        nLoc = numel(Location);
        
        if istable(Location) || isa(Location, 'timetable')
            if isa(Location, 'timetable')
                if ~isempty(TimeStamp)
                    throwAsCaller(MException(message...
                        ('MATLAB:iot:thingSpeakConnectivity:multipleTStampsLT')));
                elseif (istable(Values) && isdatetime(Values{1, 1})) || ...
                        (isa(Values, 'timetable') && ...
                        isdatetime(Values.Properties.RowTimes(1)))
                    throwAsCaller(MException(message...
                        ('MATLAB:iot:thingSpeakConnectivity:multipleTStampsLV')));
                end
            end
            
            TimeStamp = Location.Properties.RowTimes(1);
            Location = Location{1, :};
        end
        
        for iLoc = 1:nLoc
            optionString(:, end+1:end+2) = {LocationSet{iLoc}, ...
                num2str(Location(iLoc), 16)};
        end
        
    end
    
    % Timestamp parameter
    
    if ~isempty(TimeStamp)
        try
            validateattributes(TimeStamp, {'datetime'}, {'scalar'})
            tsYear   = year(TimeStamp);
            tsMonth  = month(TimeStamp);
            tsDay    = day(TimeStamp);
            tsHour   = hour(TimeStamp);
            tsMinute = minute(TimeStamp);
            tsSecond = second(TimeStamp);
            
            if isempty(tsYear)   || ...
                    isempty(tsMonth) || ...
                    isempty(tsDay)   || ...
                    isempty(tsHour)  || ...
                    isempty(tsMinute)|| ...
                    isempty(tsSecond)
                throwAsCaller(MException(message...
                    ('MATLAB:iot:thingSpeakConnectivity:invalidTimeFormat')));
            end
            
            dateString = datestr(sprintf('%d-%d-%d %d:%d:%d', tsYear,...
                tsMonth, tsDay, tsHour, tsMinute, fix(tsSecond)),...
                'yyyy-mm-dd HH:MM:SS');
            
            optionString(:, end+1:end+2) = {'created_at', dateString};
        catch
            throwAsCaller(MException(message...
                ('MATLAB:iot:thingSpeakConnectivity:invalidTimeFormat')));
        end
    end
else
    %  Batch Upload parameters
    try
        [Values, TimeStamp] = validateBatchUploadParams(Values, ...
            TimeStamp, Location, Fields);
    catch batchUploadErr
        throwAsCaller(batchUploadErr)
    end
    
    optionString = batchValueParser(Values, Location, ...
        TimeStamp, optionString, Fields);
end

end

function optionString = valuesParser(secondInput, optionString, varargin)
% VALUESPARSING validates VALUES input and generates the required http
% request string required to write the data to ThingSpeak. It handles all
% supported datatypes and combinations of inputs. It also covers single
% feed and batch feed writes.

% If num inputs to valuesParsing function is greater than 3 then Fields
% parameter is provided as input. Else assume that Fields input is not
% provided.
if nargin > 2
    Fields = varargin{1};
else
    % If Fields input is not provided write data to consecutive fields
    % starting with the first
    Fields = 1:size(secondInput, 2);
end

% Error for incorrect data
% If Values is provided as a string or structure
if ischar(secondInput) ...
        || isstruct(secondInput)
    throwAsCaller(MException(message...
        ('MATLAB:iot:thingSpeakConnectivity:incorrectInputsWithValues')));
end

% If the data is provided as a table
if istable(secondInput) || isa(secondInput, 'timetable')
    optionString = tableMatrixDataParser(secondInput, optionString, ...
        varargin);
elseif iscell(secondInput)
    % If data is provided as a cell array
    optionString = cellArrayDataParser(secondInput, Fields, ...
        optionString);
else
    % Data can be scalar, vector or array
    if isscalar(secondInput)
        iField = 1;
        if ~isempty(Fields)
            iField = Fields(1);
        end
        
        if isstring(secondInput)
            optionString(1, end+1:end+2) = {sprintf('field%d', iField), ...
                secondInput};
        elseif ~isnan(secondInput)
            % If the value is NaN then the data point is not written.
            % This will be stored as a null value on ThingSpeak.
            optionString(1, end+1:end+2) = {sprintf('field%d', iField), ...
                num2str(secondInput, 16)};
        end
    elseif isvector(secondInput)
        % Data is provided as a vector
        % For each element of the vector
        for iData = 1:numel(secondInput)
            % If fields is not specified, then assume that data needs to be
            % written to consecutive fields starting with field1.
            if isempty(Fields)
                iField = iData;
            else
                iField = Fields(iData);
            end
            
            if isstring(secondInput(iData))
                optionString(1, end+1:end+2) = {sprintf('field%d', ...
                    iField), secondInput(iData)};
            elseif ~isnan(secondInput(iData))
                % If the value is NaN then the data point is not written.
                % This will be stored as a null value on ThingSpeak.
                optionString(1, end+1:end+2) = {sprintf('field%d', ...
                    iField), num2str(secondInput(iData), 16)};
            end
        end
    else % if data is an array
        optionString = tableMatrixDataParser(secondInput, optionString, ...
            varargin);
    end
end

end

function optionString = tableMatrixDataParser(secondInput, ...
    optionString, inputArgs)
% TABLEMATRIXDATAPARSER converts input data into json string for api call
% to ThingSpeak

% If input is provided as a table or timetable
if (istable(secondInput) || isa(secondInput, 'timetable')) &&...
        size(secondInput, 1) == 1
    
    % Check the size of the input table
    if istable(secondInput) && (size(secondInput, 2) > 9)
        throwAsCaller(MException(message...
            ('MATLAB:iot:thingSpeakConnectivity:tooManyColumnsTable')));
        % Check the size of the input timetable
    elseif isa(secondInput, 'timetable')
        % Convert timetable to table
        secondInput = timetable2table(secondInput);
        if (size(secondInput, 2) > 9)
            throwAsCaller(MException(message...
                ('MATLAB:iot:thingSpeakConnectivity:tooManyColumnsTimeTable')));
        end
    end
    
    % Check if first column is datetime
    firstVariable = secondInput{1,1};
    
    % If the firstvariable is datetime
    if isdatetime(firstVariable)
        % assign the datetime value to optionString
        optionString(1, end+1:end+2) = {'created_at', ...
            datestr(firstVariable, 31)};
        optionString = valuesParser(table2cell(...
            secondInput(1, 2:end)), optionString, inputArgs{:});
    else
        %datetime can be provided as a separate input parameter
        if size(secondInput, 2) > 8
            throwAsCaller(MException(message...
                ('MATLAB:iot:thingSpeakConnectivity:tooManyColumnsTable')));
        end
        optionString = valuesParser(table2cell(...
            secondInput(1, 1:end)), optionString, inputArgs{:});
    end
else % If data is provided as an array
    validateBatchUploadParams(secondInput, [], [], []);
    optionString = batchValueParser(secondInput, [], [], {}, []);
end
end

function optionString = cellArrayDataParser(secondInput, Fields,...
    optionString)

% For each element of secondInput
for iCell = 1:numel(secondInput)
    try
        % Attempt to convert each element of the cell to a Matrix.
        % If the value is a nested cell then cell2mat function will
        % generate an error which we catch.
        fieldData = cell2mat(secondInput(iCell));
    catch
        throwAsCaller(MException(message...
            ('MATLAB:iot:thingSpeakConnectivity:invalidCellArray')));
    end
    
    % Assign iField to iCell unless Fields is provided by the user
    iField = iCell;
    if ~isempty(Fields)
        iField = Fields(iCell);
    end
    
    % If the value is either an empty string or NaN then skip field
    if ~isempty(fieldData)
        if ~isnan(fieldData)
            % If the value is NaN then the data point is not written.
            % This will be stored as a null value on ThingSpeak.
            optionString(1, end+1:end+2) = {sprintf('field%d', iField), ...
                num2str(fieldData, 16)};
        end
    end
end

end

function [Values, TimeStamp] = validateBatchUploadParams(Values, ...
    TimeStamp, Location, Fields)
% BATCHUPLOADERRORCHECKING validates all the data inputs from the user -
% Timestamps, values, location, fields. Separate subfunctions are called
% for each.

% Flag to check if timestamps are provided as a part of BatchValues
tStampProvided = 0;

% Check the validity of the batch data the user is looking to upload to
% ThingSpeak
[tStampProvided, Values] = validateBatchValues(Values, Fields, ...
    TimeStamp, tStampProvided);

% Check the timestamps provided by the user for the batch upload
validateBatchTimeStamp(TimeStamp, Values, tStampProvided, Location);

% Check the Locations Input for the batch upload
TimeStamp = validateBatchLocation(Location, Values, TimeStamp);

end

function optionString = batchValueParser(BatchValues, BatchLocations, ...
    BatchTimestamps, optionString, Fields)
% BATCHVALUEPARSER handles the data from user for performing a batch
% update. The result is the JSON string equivalent of the data provided by
% the user that can be provided to the http POST request.

% Store the number of fields worth of data in the table without
% timestamps
numFields = size(BatchValues, 2);

% If BatchValues is a table
if istable(BatchValues)
    % If BatchTimestamps is empty, then it is a part of the BatchValues
    % Table
    if isempty(BatchTimestamps)
        % Convert timestamps to datestr
        BatchValues.(BatchValues.Properties.VariableNames{1}) ...
            = (datestr(BatchValues{:,1}, 31));
        % Store the number of fields worth of data in the table with
        % timestamps - decrease by 1 since table contains timestamps as
        % well
        numFields = numFields-1;
    else
        % In this case, we need to append the timestamps to the first
        % column of the table
        batchTime = table(datestr(BatchTimestamps, 31));
        batchTime.Properties.VariableNames{1} = 'created_at';
        BatchValues = [batchTime, BatchValues];
    end
elseif isnumeric(BatchValues)
    % BatchValues is an array
    % Convert array to table first
    BatchValues = array2table(BatchValues);
    
    % We need to append the timestamps to the first
    % column of the table
    batchTime = table(datestr(BatchTimestamps, 31));
    batchTime.Properties.VariableNames{1} = 'created_at';
    BatchValues = [batchTime, BatchValues];
else
    % If Batcharrays was not provided and only locations was provided
    
    % Check if BatchTimestamps is not a table, convert to table
    if ~istable(BatchTimestamps) && ~isempty(BatchTimestamps)
        batchTime = table(datestr(BatchTimestamps, 31));
    end
end

% if fields is empty
if isempty(Fields)
    Fields = 1:numFields;
end

variableNames = {'latitude', 'longitude', 'elevation'};

% If BatchLocations has been provided
if ~isempty(BatchLocations)
    % Check if it is a table
    if ~istable(BatchLocations) && ~isa(BatchLocations, 'timetable')
        BatchLocations = array2table(BatchLocations);
    elseif isa(BatchLocations, 'timetable')
        batchTime = table(datestr(BatchLocations.Properties.RowTimes, 31));
        BatchLocations = array2table(BatchLocations.Variables);
    end
    
    % Update the columns names to the format required for batch update
    for i = 1:size(BatchLocations, 2)
        BatchLocations.Properties.VariableNames{i} = variableNames{i};
    end
    
    % if batchvalues is empty
    if isempty(BatchValues)
        % Append timestamps to batchLocations
        batchData = [batchTime, BatchLocations];
    else
        batchData = [BatchValues, BatchLocations];
    end
else
    batchData = BatchValues;
end

% change the first variable name to created_at
batchData.Properties.VariableNames{1} = 'created_at';
for i=1:numFields
    batchData.Properties.VariableNames{i+1} = sprintf('mwTSField%d',...
        Fields(i));
end

for i=1:numFields
    batchData.Properties.VariableNames{i+1} = sprintf('field%d',...
        Fields(i));
end

d_struct = table2struct(batchData);
d_json = jsonencode(d_struct);

% Fields in the middle of the list have commas
expression1 = '"field(\w+)":NaN,';
% Fields that are at the end of the list do not have trailing
% commas but have them at the beginning that need to be removed
expression2 = ',"field(\w+)":NaN';
replace='';

% Location data with NaN
expression3 = '"latitude":NaN,';
expression4 = '"longitude":NaN,';
expression5 = '"elevation":NaN,';
expression6 = '"longitude":NaN';
expression7 = '"elevation":NaN';
% Replacing all NaNs - remove the associated field as well
d_json = regexprep(d_json,expression1,replace);
d_json = regexprep(d_json,expression2,replace);
d_json = regexprep(d_json,expression3,replace);
d_json = regexprep(d_json,expression4,replace);
d_json = regexprep(d_json,expression5,replace);
d_json = regexprep(d_json,expression6,replace);
d_json = regexprep(d_json,expression7,replace);

% If the user provided data has only NaN values, then d_json will have no
% data. In this case, we do not need to write to ThingSpeak

if writeFieldMask(d_json)
    optionString(1, end+1:end+2) = {'feeds', jsondecode(d_json)};
else
    throwAsCaller(MException(message...
        ('MATLAB:iot:thingSpeakConnectivity:emptyData')));
    
end

end


function output = writeFieldMask(d_json)
% Check for fields:
f1 = ~contains(d_json, 'field1');
f2 = ~contains(d_json, 'field2');
f3 = ~contains(d_json, 'field3');
f4 = ~contains(d_json, 'field4');
f5 = ~contains(d_json, 'field5');
f6 = ~contains(d_json, 'field6');
f7 = ~contains(d_json, 'field7');
f8 = ~contains(d_json, 'field8');
f9 = ~contains(d_json, 'latitude');
f10 = ~contains(d_json, 'longitude');
f11 = ~contains(d_json, 'elevation');

output = ~(f1 && f2 && f3 && f4 && f5 && f6 && f7 && f8 && f9 && ...
    f10 && f11);
end

function [tStampProvided, Values] = validateBatchValues(Values, ...
    Fields, TimeStamp, tStampProvided)
% BATCHVALUESVALIDATE checks if the batch data provided by the user
% satisfies all the required dimension, datatype and interdependeny
% requirements. This function does not format the data to JSON string.
% The function also converts data provided as timetable to a table.

% Check if Fields is empty
if ~isempty(Values)
    
    
    % Check if data is in the required format
    if ~isnumeric(Values) && ~isa(Values, 'tabular') &&...
            ~isstring(Values)
        throwAsCaller(MException(message...
            ('MATLAB:iot:thingSpeakConnectivity:invalidParamWithBatchValues')));
    end
    
    numElemsFields = numel(Fields);
    numColumnsValues = size(Values, 2);
    
    %     If Array, check if number of columns is greater than 8
    if isnumeric(Values)
        if size(Values, 2) > 8
            throwAsCaller(MException(message...
                ('MATLAB:iot:thingSpeakConnectivity:tooManyColumnsArray')));
        end
        
        % Check for fields conformance
        % Check if size of Values = size of Fields
        
        if (numElemsFields ~= numColumnsValues) && (numElemsFields ~=0)
            throwAsCaller(MException(message...
                ('MATLAB:iot:thingSpeakConnectivity:invalidParamSizeWithBatchValuesFields')));
        end
        
    elseif istable(Values) || isa(Values, 'timetable')
        % If Table, check if the first column is datetime. If first column
        % is datetime then check that the number of columns is less than
        % 10, else check if number of columns is less than 9
        
        % Check to see if MATLAB version is 9.1 or later because timetable
        % is available only starting R2016b (v9.1)
        
        % If values was input as timetable, then convert to table.
        ttFlag = istimetable(Values);
        if ttFlag
            validateTimeTable(Values);
            Values = timetable2table(Values);
            % Changing the first variable name to 'Timestamps' for
            % consistency
            Values.Properties.VariableNames{1} = 'Timestamps';
        end
        
        tStampProvided = isdatetime(Values{:,1});
        
        %         Find the number of columns in the table
        numVars = size(Values, 2);
        
        %         If first column is datetime then a max of 9 variables is
        %         allowed in the table. Else only 8 variables are allowed.
        if (numVars > 9 && tStampProvided) || ...
                (numVars > 8 && ~tStampProvided)
            if ttFlag
                throwAsCaller(MException(message...
                    ('MATLAB:iot:thingSpeakConnectivity:tooManyColumnsTimeTable')));
            else
                throwAsCaller(MException(message...
                    ('MATLAB:iot:thingSpeakConnectivity:tooManyColumnsTable')));
            end
        end
        
        % Check if the user provided timestamps in both the Values
        % table and in the timestamps input
        if tStampProvided && ~isempty(TimeStamp)
            throwAsCaller(MException(message...
                ('MATLAB:iot:thingSpeakConnectivity:multipleTStamps')));
        end
        
        if tStampProvided
            % If timestamp provided in the table
            % Check for fields conformance
            % Check if size of Values = size of Fields
            
            if (numElemsFields+1 ~= numColumnsValues) && (numElemsFields ~=0)
                throwAsCaller(MException(message...
                    ('MATLAB:iot:thingSpeakConnectivity:invalidParamSizeWithBatchValuesFields')));
            end
        else
            % If timestamp provided using Timestamp parameter
            % Check for fields conformance
            % Check if size of Values = size of Fields
            
            if (numElemsFields ~= numColumnsValues) && (numElemsFields ~=0)
                throwAsCaller(MException(message...
                    ('MATLAB:iot:thingSpeakConnectivity:invalidParamSizeWithBatchValuesFields')));
            end
        end
    end
    
    % If number of rows is not equal
    if (size(Values, 1) ~= length(TimeStamp)) && ~isempty(TimeStamp)
        throwAsCaller(MException(message...
            ('MATLAB:iot:thingSpeakConnectivity:unequalNumTimestamps')));
    end
end
end

function validateBatchTimeStamp(TimeStamp, Values, tStampProvided,...
    Location)
% BATCHTIMESTAMPVALIDATE checks if the batch timestamps provided by the
% user satisfies all the required dimension and interdependeny
% requirements.

if ~isempty(TimeStamp)
    
    %Ensure that only one column of data is provided
    if ~isvector(TimeStamp)
        throwAsCaller(MException(message...
            ('MATLAB:iot:thingSpeakConnectivity:tooManyColsTimeStamps')));
    end
    
    try
        if istable(TimeStamp)
            % Extract the timestamps into an array
            TimeStamp = table2array(TimeStamp);
        end
        
        validateattributes(TimeStamp, {'datetime'}, {'vector'})
        tsYear   = year(TimeStamp);
        tsMonth  = month(TimeStamp);
        tsDay    = day(TimeStamp);
        tsHour   = hour(TimeStamp);
        tsMinute = minute(TimeStamp);
        tsSecond = second(TimeStamp);
        
        if isempty(tsYear)   || ...
                isempty(tsMonth) || ...
                isempty(tsDay)   || ...
                isempty(tsHour)  || ...
                isempty(tsMinute)|| ...
                isempty(tsSecond)
            throwAsCaller(MException(message...
                ('MATLAB:iot:thingSpeakConnectivity:invalidTimeFormat')));
        end
    catch
        throwAsCaller(MException(message...
            ('MATLAB:iot:thingSpeakConnectivity:invalidTimeFormat')));
    end
elseif ~isempty(Values)
    % If Values is an array then timestamps have to be provided
    if isnumeric(Values) && ~isa(Location, 'timetable')
        throwAsCaller(MException(message...
            ('MATLAB:iot:thingSpeakConnectivity:missingArrayBatchTimestamps')));
    end
    
    % If Values is a table and if timestamps have not been provided as
    % the first column or using Location
    if ~tStampProvided && ~isa(Values, 'timetable') && ...
            ~isa(Location, 'timetable')
        throwAsCaller(MException(message...
            ('MATLAB:iot:thingSpeakConnectivity:missingTableBatchTimestamps')));
    end
end
end

function TimestampFin = validateBatchLocation(Location, Values, ...
    TimeStamp)
% VALIDATEBATCHLOCATION checks if the batch timestamps provided by the
% user satisfies all the required dimension and interdependeny
% requirements.


if ~isempty(Location)
    try
        % size, datatypes, double array (not cell array)
        validateattributes(Location, {'numeric', 'tabular'}, {'3d'});
    catch
        throwAsCaller(MException(message...
            ('MATLAB:iot:thingSpeakConnectivity:invalidParamWithBatchLocation')));
    end
    
    if isa(Location, 'timetable')
        if ~isempty(TimeStamp)
            throwAsCaller(MException(message...
                ('MATLAB:iot:thingSpeakConnectivity:multipleTimeBatchLocation')));
        end
        
        
        if isa(Values, 'timetable') || (istable(Values) &&...
                isdatetime(Values{:,1}))
            throwAsCaller(MException(message...
                ('MATLAB:iot:thingSpeakConnectivity:multipleTimeBatchLocation')));
        end
        
        TimeStamp = Location.Properties.RowTimes;
    end
    
    % If too many columns are provided for location input or if the number
    % of rows do not match that of TimeStamps or Values
    isBatchLocSizeOk = 0;
    if ~isempty(Values)
        isBatchLocSizeOk = isequal(size(Location, 1), size(Values, 1));
    end
    
    if ~isempty(TimeStamp)
        isBatchLocSizeOk = isequal(size(Location, 1), ...
            size(TimeStamp, 1)) + isBatchLocSizeOk;
    end
    
    % If either more than 3 columns have been specified or the number of
    % rows of Location input do not match that of Values or
    % Timestamps then generate an error
    if ~isBatchLocSizeOk
        throwAsCaller(MException(message...
            ('MATLAB:iot:thingSpeakConnectivity:badSizeBatchLocation')));
    end
    
    if (size(Location, 2) < 2)
        throwAsCaller(MException(message...
            ('MATLAB:iot:thingSpeakConnectivity:incompleteBatchLocation')));
    end
    
    if (size(Location, 2) > 3)
        throwAsCaller(MException(message...
            ('MATLAB:iot:thingSpeakConnectivity:badSizeBatchLocation')));
    end
end
TimestampFin = TimeStamp;
end

function [writeResponse] = parseWriteReturn(writeResponse)
% TSPARSEWRITERETURN parses the returned JSON to a format similar to that
% used by channelInfo on ThingSpeakRead

% Remove status field since we do not allow user to write Status
writeResponse = rmfield(writeResponse, 'status');

% Change the field name 'channel_id' to ChannelID
writeResponse.channelID = writeResponse.channel_id;
writeResponse = rmfield(writeResponse, 'channel_id');

% Change 'created_at' to Created
writeResponse.created = datetime(writeResponse.created_at,...
    'InputFormat', 'yyyy-MM-dd''T''HH:mm:ssZ', 'TimeZone', 'local');
writeResponse = rmfield(writeResponse, 'created_at');

% Change 'entry_id' to LastEntryID
writeResponse.lastEntryID = writeResponse.entry_id;
writeResponse = rmfield(writeResponse, 'entry_id');

% Identify all the field names in the response
fields = fieldnames(writeResponse);

% Format the response to match the format (names) used by ThingSpeakRead
for ifieldNames = 1:numel(fields)
    fieldName = fields{ifieldNames};
    fieldName(1) = upper(fieldName(1));
    writeResponse.(fieldName) = writeResponse.(fields{ifieldNames});
    writeResponse = rmfield(writeResponse, fields{ifieldNames});
end

% Change 'elevation' to Altitude
writeResponse.Altitude = writeResponse.Elevation;
writeResponse = rmfield(writeResponse, 'Elevation');
end

function parsedInputs = parseInputs(inputArguments)
% TSPARSEINPUTS parses the Name-value pairs specified by the user

% Create an input parser object and set PartialMatching to be true and case
% sensitivity to be false.
p = inputParser;
p.PartialMatching = true;
p.CaseSensitive = false;

% Single Point Upload
addParameter(p, 'WriteKey', ''); % Write API Key
addParameter(p, 'Fields', '');   % Fields to read data from
addParameter(p, 'Values', '');   % Values to write to Fields
addParameter(p, 'Locations', ''); % [Lat, Long, Altitude] information
addParameter(p, 'URL', '');      % Custom ThingSpeak Server install
addParameter(p, 'Timestamps', ''); % Timestamps as a separate NV pair
addParameter(p, 'Timeout', ''); % Timeout to use for the web connection

try
    % Parse the input arguments
    p.parse(inputArguments{:});
catch e
    throwAsCaller(e);
end
parsedInputs = p.Results;
end

function writeResponse = write2ThingSpeak(url,...
    optionString, timeout, batchflag)
% WRITE2THINGSPEAK writes data to ThingSpeak and handles the server
% response.

% Post the user provided data to the specified ThingSpeak Channel
try
    % Timeout for WEBWRITE is set using the weboptions function.
    options = weboptions('Timeout', timeout);
    
    % This needs to be set if data provided to webwrite is a json
    % string.
    options.MediaType = 'application/json';
    
    if batchflag
        options.ContentType = 'raw';
        optionString{1} = 'write_api_key';
        optionString{3} = 'updates';        
    end
    
    % Create a structure from the cell array
    for numOptionStr = 0:(numel(optionString)/2-1)
        optionIndx = [2 * numOptionStr + 1, 2 * numOptionStr + 2];
        optionStringStruct.(optionString{optionIndx(1)}) =...
            optionString{optionIndx(2)};
    end
    
    % Convert the structure to a json string (using the structure has
    % the same performance as the cell array)
    optionStringJSON = jsonencode(optionStringStruct);
    
    % Write data to the specified thingSpeak channel
    writeResponse = webwrite(url, optionStringJSON, options);
    
    if batchflag
        writeResponse = writeResponse';
    end
    
    if isempty(writeResponse)
        throwAsCaller(MException(message...
            ('MATLAB:iot:thingSpeakConnectivity:invalidServerResponse')));
    elseif (contains(url, '/update') && ...
            strcmp(strtrim(writeResponse), '0'))
        throwAsCaller(MException(message...
            ('MATLAB:iot:thingSpeakConnectivity:updateErrorResponse')));
    elseif isstruct(writeResponse)
        % Call Function to parse channel data and return fields in the same
        % format as that returned by THINGSPEAKREAD
        writeResponse = parseWriteReturn(writeResponse);
    end
catch e
    % We are only expecting 401 and 429 error codes to be returned from the
    % server. 401 pertains to authentication failure and 429 pertains to
    % too many requests in 15 seconds. Further, 401 is expected to swallow
    % 404 errors because authentication is required by default to perform a
    % write to channel. If the channel doesnt exist then the user will not
    % have the correct apiKey
    switch e.identifier
        case {'MATLAB:urlread:ConnectionFailed'}
            throwAsCaller(MException(message...
                ('MATLAB:iot:thingSpeakConnectivity:urlReadFailed')));
        case {'MATLAB:webservices:HTTP401StatusCodeError'}
            % incorrect or missing API key -
            throwAsCaller(MException(message...
                ('MATLAB:iot:thingSpeakConnectivity:incorrectAPIKey')));
        case {'MATLAB:urlread:Timeout' , 'MATLAB:webservices:Timeout'}
            % Timeout
            throwAsCaller(MException(message...
                ('MATLAB:iot:thingSpeakConnectivity:connectionTimeOut')));
        case {'MATLAB:urlread:UnknownHost', ...
                'MATLAB:webservices:UnknownHost'}
            % bad hostname or IP
            r = url;
            [~, r] = strtok(r, '/');
            [t, ~] = strtok(r, '/');
            throwAsCaller(MException(message...
                ('MATLAB:iot:thingSpeakConnectivity:unknownHost', t)));
        case 'MATLAB:webservices:HTTP429StatusCodeError'
            % sending data too often
            throwAsCaller(MException(message...
                ('MATLAB:iot:thingSpeakConnectivity:toomanyRequests')));
        case 'MATLAB:webservices:HTTP404StatusCodeError'
            % requested resource not found
            throwAsCaller(MException(message...
                ('MATLAB:iot:thingSpeakConnectivity:resourceNotFound')));
        case 'MATLAB:webservices:HTTP400StatusCodeError'
            throwAsCaller(MException(message...
                ('MATLAB:iot:thingSpeakConnectivity:unsupportedURL')));
        otherwise
            throwAsCaller(e);
    end
end

end