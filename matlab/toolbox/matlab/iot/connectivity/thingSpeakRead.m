function [outputData, timestamps, channelInfo, entryIDs] = thingSpeakRead( channelID, varargin )
%THINGSPEAKREAD Read data stored in a ThingSpeak channel.
%
%   Syntax
%   ------
%   data = thingSpeakRead(channelID)
%   data = thingSpeakRead(channelID,Name,Value)
%   data = thingSpeakRead(___,'ReadKey',readAPIKey)
%   [data,timestamps] = thingSpeakRead(___)
%   [data,timestamps,channelInfo] = thingSpeakRead(___) 
%   
%   Description
%   ------------
%   data = thingSpeakRead(channelID) reads the most recent data from
%   all fields of the specified public channel on ThingSpeak.com.
%
%   data = thingSpeakRead(channelID,Name,Value) uses additional options 
%   specified by one or more Name,Value pair arguments.
% 
%   data = thingSpeakRead(___,'ReadKey',readAPIKey) uses the ThingSpeak 
%   read API key stored in variable readAPIKey to read from a private
%   channel.
%
%   [data,timestamps] = thingSpeakRead(___) also returns timestamps from 
%   the specified channel on ThingSpeak.com and can include any of the 
%   input arguments in previous syntaxes.
%
%   [data,timestamps,channelInfo] = thingSpeakRead(___) also returns 
%   channel information.
%
%   The structure of the channel information is:
%                ChannelID: 12397
%                     Name: 'WeatherStation'
%              Description: 'MathWorks Weather Station, West Garage, Natick, MA 01760, USA'
%                 Latitude: 42.2997
%                Longitude: -71.3505
%                 Altitude: 60
%                  Created: [1x1 datetime]
%                  Updated: [1x1 datetime]
%                LastEntry: 188212
%        FieldDescriptions: {1x8 cell}
%                 FieldIDs: [1 2 3 4 5 6 7 8]
%                      URL: 'http://api.thingspeak.com/channels/12397/feed.json?'
%
%   Input Arguments
%   ---------------
%
%   Name         Description                             Data Type
%   ----    --------------------                         ---------
%   channelID
%           Channel identification number.               positive integer
%
%   Name-Value Pair Arguments
%   -------------------------
%
%   Name         Description                             Data Type
%   ----    --------------------                         ---------
%
%   DateRange
%           Range of data to return, specified as an     1x2 array of datetime
%           an array of values that have 
%           [startdate,enddate], in MATLAB datetime
%           values. The number of points returned is
%           always limited to a maximum of 8000 by the
%           ThingSpeak.com server. Adjust your ranges 
%           or make multiple calls if you need more 
%           than 8000 points of data.
%
%           DateRange cannot be used with:
%           - NumDays
%           - NumMinutes
%
%   Fields
%           Channel Field IDs to retrieve data from.     1x8 positive integer/s
%           You can specify up to 8 fields to read 
%           data from.
%
%   Location                                             logical
%           Positional information of data from the
%           channel. Location information includes 
%           latitude, longitude, and altitude.
%
%   NumDays
%           Number of 24 hour periods to retrieve from   positive integer
%           the present time. The number of points
%           returned is always limited to a maximum
%           of 8000 by the ThingSpeak.com server
%           and therefore if you hit the limit you may
%           wish to use DateRange instead.
%
%           NumDays cannot be used with:
%           - NumMinutes
%           - DateRange
%
%   NumMinutes
%           Number of minutes from the present time to   positive integer
%           retrieve data from. The number of points
%           returned is always limited to a maximum of
%           8000 by the ThingSpeak.com server and
%           therefore if you hit the limit you may wish
%           to use DateRange instead.
%
%           NumMinutes cannot be used with:
%           - NumDays
%           - DateRange
%
%   NumPoints
%           Number of data points to retrieve           positive integer
%           from the present moment. The number of
%           points returned is limited to a maximum
%           of 8000 by the ThingSpeak.com server.
%
%           NumPoints cannot be used with:
%           - DateRange
%           - NumDays
%           - NumMinutes
%
%   OutputFormat
%           Specify the class of the output data.        string
%           Valid values are: 'matrix' or 'table'
%           or 'timetable'.
%           If 'table' or 'timetable' is chosen,
%           the right hand side outputs become:
%           [ table, channelInfo ]
%           The table will contain the timestamps and
%           the data from the fields. If OutputFormat is
%           not specified, the default value is
%           'matrix'.
%
%   ReadKey
%           Specify the Read APIKey of the channel.      string
%           
%
%   Timeout                                              positive number
%          Specify the timeout (in seconds) for
%          connecting to the server and reading data.
%          Default value is 10 seconds.
%
%   % Example 1
%   % ---------
%   % Retrieve the most recent result for all fields of a
%   % public channel including the timestamp.
%   [data,time] = thingSpeakRead(12397)
%
%   % Example 2
%   % ---------
%   % Retrieve data for August 8, 2014 through August 12, 2014 for
%   % fields 1 and 4 of a public channel, including the timestamp, and
%   % channel information.
%   [data,time,channelInfo] = ...
%   thingSpeakRead(12397,'Fields',[1 4],'DateRange',[datetime('Aug 8, 2014'),...
%                  datetime('Aug 12, 2014')])
%
%   % Example 3
%   % ---------
%   % Retrieve last ten points of data from fields 1 and 4 of a public
%   % channel. Return the data and timestamps in a table, and include the
%   % channel information.
%   [data,channelInfo] = ...
%   thingSpeakRead(12397,'Fields',[1 4],'NumPoints',10,'OutputFormat','table')
%
%   % Example 4
%   % ---------
%   % Retrieve last ten points of data from fields 1 and 4 of a public
%   % channel. Return the data in a timetable, and include the channel
%   % information.
%
%   [data,channelInfo] = ...
%   thingSpeakRead(12397,'Fields',[1, 4],'NumPoints',10,'OutputFormat','timetable');
%
%   % Example 5
%   % ---------
%   % Retrieve last 5 minutes of data from fields 1 and 4 of a public
%   % channel. Return only the data and timestamps.
%   [data, time] = thingSpeakRead(12397, 'Fields', [1, 4], 'NumMinutes', 5)
%
%   % Example 6
%   % ---------
%   % Retrieve last 2 days of data from fields 1 and 4 of a public
%   % channel. Return only the data and timestamps.
%   [data, time] = thingSpeakRead(12397, 'Fields', [1, 4], 'NumDays', 2)
%
%   % Example 7
%   % ---------
%   % Retrieve the most recent result for all fields of a private channel.
%   channelID = <Enter Channel ID>
%   readKey   = <Enter Read API Key>
%   data = thingSpeakRead(channelID, 'ReadKey', readKey)
%
%   % Example 8
%   % ---------
%   % Retrieve latitude, longitude and altitude data along with the last
%   % 10 channel updates for all fields in a public channel and return the
%   % data as a table.
%   channelID = <Enter Channel ID>
%   data = thingSpeakRead(channelID, 'NumPoints', 10, 'Location', true, ...
%          'OutputFormat', 'table')
%
%   % Example 9
%   % ---------
%   % Set the timeout for reading 8000 data points from field 1 of a public
%   % channel.
%   data = thingSpeakRead(12397, 'Fields', 1, 'NumPoints', 8000, ...
%          'Timeout', 10)
%

% Copyright 2015-2018 The MathWorks, Inc.

% Default read parameters
% Timeout
timeOut = 10;
% Enable location 
locationEnable = 0;
% NumPoints 
numPoints = [];
% Output Format
tabularOutput = 0;

% Fields to read from
channelFields = [];

optionString = {};

try    
    % Ensure that atleast one input is specified
    narginchk(1, inf);

    % Validate channel ID specified by the user
    validateChannelID(channelID);

    url = getThingSpeakURL({'alternateURL', ''});
 
    url = validateFields([], url, channelID);
    
    %% Validate additional inputs, if provided

    if nargin>1
    % If additional inputs are provided, check to ensure second parameter
    % is a "Name"
    inputArguments = validateAdditionalInputs(varargin);
    
    % Parse the additional inputs
    parsedInputs = parseInputs(inputArguments);
    
    % If an alternate URL (to a private ThingSpeak Server) is provided    
    % Get the thingSpeak URL to use in this function
    url = getThingSpeakURL({'alternateURL', parsedInputs.URL});
    
    % 'Fields' parameters
    channelFields = parsedInputs.Fields;
    [url, channelFields] = validateFields(channelFields, url, channelID);
 
    % Check the keys
    [optionString] = validateAPIKey(parsedInputs.ReadKey, optionString);
    
    % 'NumPoints' parameter validation
    numPoints = parsedInputs.NumPoints;
    optionString = validateNumPoints(numPoints, optionString);
    
    
    % 'NumDays' parameter validation
    numDays = parsedInputs.NumDays;
    optionString = validateNumDays(numDays, optionString);
    
    % 'NumMinutes' parameter validation
    numMinutes = parsedInputs.NumMinutes;
    optionString = validateNumMinutes(numMinutes, optionString);
    
    % 'DateRange' parameter validation
    dateRange = parsedInputs.DateRange;
    optionString = validateDateRange(dateRange, optionString);
    
    % Define default behavior
    if  isempty(numPoints) && isempty(numDays)...
            && isempty(dateRange) && isempty(numMinutes)
        optionString(1, end+1:end+2) = {'results', 1};
    end
    
    % Ensure that if 'numPoints' is specified then 'NumMinutes', 'NumDays'
    % and 'DateRange' are not specified
    validateNumPointsCombo(numPoints, dateRange, numDays, numMinutes);
    
    % Ensure that 'DateRange' and 'NumMinutes' are not specified along with
    % 'NumDays'
    validateNumDaysCombo(numDays, dateRange, numMinutes)
    
    % Ensure that 'DateRange' and 'NumDays' are not specified along with
    % 'NumMinutes'
    validateNumMinutesCombo(numMinutes, dateRange, numDays)
    
    % 'Location' parameter validation
    [locationEnable, optionString] = validateLocationEnable...
        (parsedInputs.Locations, optionString);
    
    % 'Timeout' parameter validation
    timeOut = validateTimeOut(parsedInputs.Timeout);
    
    % 'OutputFormat' parameter validation
    tabularOutput = validateOutputFormat(parsedInputs.OutputFormat);

    else
        % Create a default optionString
        optionString = {'results', 1};
    end
    %%
    options = weboptions;
    options.Timeout = timeOut;
    options.ContentType = 'json';
    
catch preReadErr    
    throwAsCaller(preReadErr);
end


%% Request for data from the ThingSpeak Server
try
    % HTTP Get method to fetch data from ThingSpeak channel    
    jsonData = webread(url, optionString{:}, options);
catch e
    switch e.identifier
        case 'MATLAB:webservices:HTTP400StatusCodeError'
            % incorrect or missing API key -            
            throwAsCaller(MException(...
                message('MATLAB:iot:thingSpeakConnectivity:incorrectKey')));
        case 'MATLAB:webservices:HTTP404StatusCodeError' % bad channel ID -
            throwAsCaller(MException(message...
        ('MATLAB:iot:thingSpeakConnectivity:invalidChannelID')));
        case 'MATLAB:webservices:Timeout' % bad port         
            throwAsCaller(MException(message...
        ('MATLAB:iot:thingSpeakConnectivity:connectionTimeOut')));
        case 'MATLAB:webservices:UnknownHost' % bad hostname or IP
            r = url;
            [~, r] = strtok(r, '/');
            [t, ~] = strtok(r, '/');            
            throwAsCaller(MException(message...
        ('MATLAB:iot:thingSpeakConnectivity:unknownHost', t)));
        otherwise
            throwAsCaller(e);
    end
end

%% Output parsing

% Parse server response
try
    [channelInfo, channelColumnNames] = validateServerResponse(jsonData,...
        url);
    
    % Assign the channel info. Use channelInfo instead of field info to
    % cover cases where field is yet to be populated.
    
    fieldIndx = find(cell2mat(cellfun(@(x) ~isempty(x), ...
        (strfind(channelColumnNames, 'field')), 'UniformOutput', false)));
    
    if ~isempty(fieldIndx)
        for i = 1:numel(fieldIndx)
            colName = jsonData.channel.(channelColumnNames{fieldIndx(i)});
            % Additional checks to ensure that channel field names are not
            % set to Latitude, Longitude or Altitude when 'Locations'
            % parameter is set to true in thingSpeakRead(). If true then
            % convert column name to <>_Field
            if locationEnable && (strcmpi(colName, 'Latitude') ...
                    || strcmpi(colName, 'Longitude') ...
                    || strcmpi(colName, 'Altitude'))
                colName = sprintf('%s_Field', colName);
            end
            channelInfo.FieldDescriptions{end+1} = colName;
            channelInfo.FieldIDs(end+1) = ...
                str2double(channelColumnNames{fieldIndx(i)}...
                (length('field')+1:end));
        end
    end
    
    % Parse feeds data    
    [feedColumnNames, dataTable, indexSet, strIndx] = ...
        parseFeedsData(jsonData, channelFields, channelInfo, ...
        locationEnable);
    
    if isempty(dataTable)
        createdAt = [];
    else
        createdAt = dataTable.created_at;
    end
    
    [feedColumnNames, timestamps, dataTable] = ...
        parseTableData(jsonData, indexSet, feedColumnNames, createdAt,...
        dataTable);
    
    
    [data, channelInfo, entryIDs] = processChannelData(dataTable, ...
        channelInfo, feedColumnNames, strIndx, timestamps, ...
        channelFields);
    
    
    % Check if the requested number of points was returned
    if ~isempty(numPoints)
        [numPointsRead, ~] = size(data);
        if numPointsRead ~= numPoints
            tsIssueWarning(...
                'MATLAB:iot:thingSpeakConnectivity:numPointsUnmet', numPoints, ...
                size(data, 1));
        end
    end
    
    % Returning data in the order that the user requested
    % If the requested outputFormat is table
    % Only if parsedInputs.Fields is not empty
    
    if exist('parsedInputs', 'var')
       channelFields = parsedInputs.Fields; 
    end
    
    [outputData, timestamps, channelInfo] = outputDataFormat(...
        channelFields, data, channelInfo, ...
        locationEnable, tabularOutput, strIndx);
    
catch postReadErr
    throwAsCaller(postReadErr);
end

end

%% Helper Functions

function tsIssueWarning(id, varargin)
% TSISSUEWARNING generates warnings without displaying backtrace
warning off backtrace;
warning(message(id, varargin{:}));
warning on backtrace;
end

function w = tsIsPositiveInteger(value)
% TSISPOSITIVEINTEGER Checks if input is a positive integer

try
    validateattributes(value,{'numeric'},{'scalar', 'nonempty', ...
        'integer','finite', '>', 0})
    w = 1;
catch
    w = 0;
end

end

function validateChannelID(channelID)
% CHANNELIDCHECK validates the channelID provided by the user

if ~tsIsPositiveInteger(channelID)
    throwAsCaller(MException(message...
        ('MATLAB:iot:thingSpeakConnectivity:invalidChannelID')));
end

end

function inputArguments = validateAdditionalInputs(addInputArgs)
% ADDITIONALINPUTCHECK manages the input arguments when Name-value pairs
% are specified

if ~isempty(addInputArgs)
    % The first additional input has to be a string (parameter name)
    if ~ischar(addInputArgs{1}) && ~isstring(addInputArgs{1})
        throwAsCaller(MException(...
            message('MATLAB:iot:thingSpeakConnectivity:invalidSecondParam')));
    else
        inputArguments = addInputArgs;
    end
else % Only channel ID has been provided
    inputArguments = {};
end
end

function [url, channelFields] = validateFields(channelFields, url,...
    channelID)
% VALIDATEFIELDS validates the fields name value provided by the user.

if ~isempty(channelFields)
    try
        validateattributes(channelFields, {'numeric'}, {'integer',...
            'row', 'positive', '<', 9});
    catch
        throwAsCaller(MException(...
            message('MATLAB:iot:thingSpeakConnectivity:invalidFields')));
    end
    
    channelFieldsUnique = unique(channelFields); % sort and remove dupes
    if length(channelFieldsUnique) ~= length(channelFields)
        throwAsCaller(MException(...
            message('MATLAB:iot:thingSpeakConnectivity:nonUniqueFields')));
    else
        channelFields = channelFieldsUnique;
    end
    
    if isscalar(channelFields)
        % Retrieve a single field
        url = sprintf('%schannels/%d/field/%d.json?', url, ...
            channelID, channelFields);
    else
        % Retrieve all fields and then subsref prune them for the user
        url = sprintf('%schannels/%d/feed.json?', url, channelID);
    end
else
    % Retrieve all fields for the user
    url = sprintf('%schannels/%d/feed.json?', url, channelID);
end

end

function optionString = validateAPIKey(apiKey, optionString)
% VALIDATEAPIKEY handles the Read API Key provided by the user

if ~isempty(apiKey)
    if isstring(apiKey)
        apiKey = char(apiKey);
    end
    
    try
        validateattributes(apiKey, {'char'}, {'vector'});
    catch
        throwAsCaller(MException(...
            message('MATLAB:iot:thingSpeakConnectivity:invalidReadAPIKey')));
    end
    
    if contains(apiKey, ' ')
        throwAsCaller(MException(...   
        message('MATLAB:iot:thingSpeakConnectivity:invalidReadAPIKeySpace')));
    end
    
    optionString(1, end+1:end+2) = {'key', apiKey};
end
end

function optionString = validateNumPoints(numPoints, optionString)
% VALIDATENUMPOINTS validates the value provided for NumPoints input

if ~isempty(numPoints)
    if tsIsPositiveInteger(numPoints) && numPoints < 8001
        optionString(1, end+1:end+2) = {'results', numPoints};
    else
        throwAsCaller(MException(...
            message('MATLAB:iot:thingSpeakConnectivity:invalidNumPoints')));
    end
end
end

function optionString = validateNumDays(numDays, optionString)
% VALIDATENUMDAYS validates the value provided for NumDays input

if ~isempty(numDays)
    if tsIsPositiveInteger(numDays)
        optionString(1, end+1:end+2) = {'days', numDays};
    else
        throwAsCaller(MException(...
            message('MATLAB:iot:thingSpeakConnectivity:invalidNumDays')));
    end
end
end

function optionString = validateNumMinutes(numMinutes, optionString)
% VALIDATENUMMINUTES validates the value provided for NumMinutes input

if ~isempty(numMinutes)
    if tsIsPositiveInteger(numMinutes)
        optionString(1, end+1:end+2) = {'minutes', numMinutes};
    else
        throwAsCaller(MException(...
            message('MATLAB:iot:thingSpeakConnectivity:invalidNumMinutes')));
    end
end
end

function optionString = validateDateRange(dateRange, optionString)
% VALIDATEDATERANGE validates the value provided for DateRange input

if ~isempty(dateRange)
    try
        validateattributes(dateRange, {'datetime'}, {'row', 'size', [1,2]});
    catch
        throwAsCaller(MException(...
            message('MATLAB:iot:thingSpeakConnectivity:invalidDateRange')));
    end
    
    startDate = dateRange(1);
    endDate = dateRange(2);
    
    if startDate >= endDate
         throwAsCaller(MException(...
            message('MATLAB:iot:thingSpeakConnectivity:badStartEnd')));
    end
    
    if isempty(startDate.TimeZone)
        startDate.TimeZone = 'local';
    end
    
    if isempty(endDate.TimeZone)
        endDate.TimeZone = 'local';
    end
    
    
    if ~strcmpi(startDate.TimeZone, endDate.TimeZone)
        throwAsCaller(MException(...
            message('MATLAB:iot:thingSpeakConnectivity:timeZonesDontMatch')));
    end
    % Convert timezones to UTC
    startDate.TimeZone = 'UTC';
    endDate.TimeZone = 'UTC';
    
    startDatestr = datestr(startDate, 31);
    endDatestr   = datestr(endDate, 31);
    
    optionString(1, end+1:end+2) = {'start', startDatestr};
    optionString(1, end+1:end+2) = {'end', endDatestr};
    
end
end

function validateNumPointsCombo(numPoints, dateRange, numDays, numMinutes)
% NUMPOINTSCOMBOCHECK ensures that numpoints isn't specified with either
% daterange, numdays or numminutes
if ~isempty(numPoints)
    if ~isempty(dateRange)
        throwAsCaller(MException(...
            message('MATLAB:iot:thingSpeakConnectivity:invalidParamDateRangeWithNumPoints')));
    elseif ~isempty(numDays)
        throwAsCaller(MException(...
            message('MATLAB:iot:thingSpeakConnectivity:invalidParamNumDaysWithNumPoints')));
    elseif ~isempty(numMinutes)
        throwAsCaller(MException(...
            message('MATLAB:iot:thingSpeakConnectivity:invalidParamNumMinsWithNumPoints')));
    end
end
end

function validateNumDaysCombo(numDays, dateRange, numMinutes)
% DATERANGECOMBOCHECK ensures that dateRange isnt specified with numDays or
% numMinutes

if ~isempty(numDays)
    if ~isempty(dateRange)
        if ~isempty(dateRange)
            throwAsCaller(MException(...
            message('MATLAB:iot:thingSpeakConnectivity:invalidParamDateRangeWithNumDays')));
        elseif ~isempty(numMinutes)
            throwAsCaller(MException(...
            message('MATLAB:iot:thingSpeakConnectivity:invalidParamNumMinsWithNumDays')));
        end       
    end
end

end

function validateNumMinutesCombo(numMinutes, dateRange, numDays)
% NUMMINUTESCHECK ensures that numMinutes is not specified with either
% dateRange, or numDays

if ~isempty(numMinutes)
    if ~isempty(dateRange) || ~isempty(numDays)
        if ~isempty(dateRange)          
            throwAsCaller(MException(...
            message('MATLAB:iot:thingSpeakConnectivity:invalidParamDateRangeWithNumMinutes')));
        elseif ~isempty(numDays)            
            throwAsCaller(MException(...
            message('MATLAB:iot:thingSpeakConnectivity:invalidParamNumDaysWithNumMinutes')));
        end        
    end
end
end

function [locationEnable, optionString] = ...
    validateLocationEnable(locationEnable, optionString)
% Validate the input to location enable named parameter

if ~isempty(locationEnable)
    try
        validateattributes(locationEnable, {'logical', 'double'}, ...
            {'binary'});
    catch
        throwAsCaller(MException(...
            message('MATLAB:iot:thingSpeakConnectivity:invalidLocation')));
    end
    
    if true(locationEnable)
        optionString(1, end+1:end+2) = {'location', 'true'};
    end
else
    locationEnable = 0;
end

end

function timeOut = validateTimeOut(timeOut)
% VALIDATETIMEOUT validates the value specified by the user for timeout
if ~isempty(timeOut)
    try
        validateattributes(timeOut, {'double'}, {'positive', 'finite'});
    catch
         throwAsCaller(MException(...
            message('MATLAB:iot:thingSpeakConnectivity:invalidTimeout')));
    end
else
    timeOut = 10;
end

end

function tabularOutput = validateOutputFormat(outputFormat)
% VALIDATEOUTPUTFORMAT validates the value specified for OUTPUTFORMAT
% Set default value of tabularOutput to be 0 - matrix

tabularOutput = 0;

if isempty(outputFormat) && ischar(outputFormat)
    return;
end

try
    validateattributes(outputFormat, {'char', 'string'}, {'row'});
    
catch
    throwAsCaller(MException(...
        message('MATLAB:iot:thingSpeakConnectivity:invalidOutputFormat')));
end

outputFormat = char(outputFormat);

switch lower(outputFormat)
    case {'m', 'ma', 'mat', 'matr', 'matri', 'matrix'}
        tabularOutput = 0;
    case {'ta', 'tab', 'tabl', 'table'}
        tabularOutput = 1;
    case {'ti', 'tim', 'time', 'timet', 'timeta', 'timetab', ...
            'timetabl', 'timetable'}
        tabularOutput = 2;
    otherwise
        throwAsCaller(MException(...
            message('MATLAB:iot:thingSpeakConnectivity:invalidOutputFormat')));
end

end

function validateFieldAvailability(channelFields, channelInfo)
% Handles requests for fields that are not enabled on ThingSpeak
if ~isempty(channelFields) && ...
        ~isempty(setdiff(channelFields, channelInfo.FieldIDs))
      throwAsCaller(MException(...
            message('MATLAB:iot:thingSpeakConnectivity:invalidFieldBounds')));
end

end

function parsedInputs = parseInputs(inputArguments)
% PARSEINPUTS - Parse Name Value inputs provided by user

p = inputParser;
p.CaseSensitive = false;
p.PartialMatching = true;
addParameter(p, 'Fields', []); 
addParameter(p, 'NumPoints', []); 
addParameter(p, 'NumDays', []); % Previous days, from now, to include
addParameter(p, 'NumMinutes', []); % Previous minutes, from now, to include
addParameter(p, 'DateRange', []);  
addParameter(p, 'ReadKey', ''); 
addParameter(p, 'Locations', false); % Read location data - boolean 
addParameter(p, 'Timeout', 10);     % Timeout for webread function
addParameter(p, 'OutputFormat', ''); % output data class: array,table, etc.
addParameter(p, 'URL', '');         

try
    p.parse(inputArguments{:});
catch e
    switch e.identifier
        case 'MATLAB:InputParser:ParamMustBeChar'
            % could be: (6417,'Field',1,'NumPoints')
            throwAsCaller(MException(...
                message('MATLAB:iot:thingSpeakConnectivity:missingValue')));
        otherwise            
            throwAsCaller(e);
    end
end
parsedInputs = p.Results;
end

function [channelInfo, channelColumnNames] = ...
    validateServerResponse(jsonData, url)
% SERVERRESPONSECHECK checks ThingSpeak server response to ensure all the
% expected fields are returned.

% If the returned data does not contain the expected fields, generate an
% error
if isempty(jsonData) || ~isfield(jsonData, 'channel') || ...
        ~isfield(jsonData, 'feeds')   
    throwAsCaller(MException(...
            message('MATLAB:iot:thingSpeakConnectivity:improperJSON')));
end

% Parse the channel information provided by the ThingSpeak Server
try
    channelInfo = parseChannelInfo(jsonData);
    % Assign url to channelInfo structure
    channelInfo.URL = url;
catch    
    throwAsCaller(MException(...
            message('MATLAB:iot:thingSpeakConnectivity:unableToParseChannelInfo')));
end

% Find the field names defined in the ThingSpeak channel
channelColumnNames = fieldnames(jsonData.channel);

end

function channelInfo = parseChannelInfo(jsonData)
% PARSECHANNELINFO - Parse channel info from structure returned by webread()

channelInfo.ChannelID = jsonData.channel.id;
channelInfo.Name = jsonData.channel.name;

if isfield(jsonData.channel, 'description')
    channelInfo.Description = jsonData.channel.description;
else
    channelInfo.Description = '';
end
if isfield(jsonData.channel, 'latitude')
    channelInfo.Latitude = str2double(jsonData.channel.latitude);
else
    channelInfo.Latitude = [];
end
if isfield(jsonData.channel, 'longitude')
    channelInfo.Longitude = str2double(jsonData.channel.longitude);
else
    channelInfo.Longitude = [];
end
if isfield(jsonData.channel, 'elevation')
    channelInfo.Altitude = str2double(jsonData.channel.elevation);
else
    channelInfo.Altitude = [];
end

channelInfo.Created =  datetime(jsonData.channel.created_at, ...
    'InputFormat', 'yyyy-MM-dd''T''HH:mm:ss''Z''', 'TimeZone', ...
    'UTC');
channelInfo.Created.TimeZone = 'local';

channelInfo.Updated =  datetime(jsonData.channel.updated_at, ...
    'InputFormat', 'yyyy-MM-dd''T''HH:mm:ss''Z''', 'TimeZone',...
    'UTC');
channelInfo.Updated.TimeZone = 'local';

channelInfo.LastEntryID = jsonData.channel.last_entry_id;
channelInfo.FieldDescriptions = {};
channelInfo.FieldIDs = [];
end

function [feedColumnNames, dataTable, indexSet, strIndx] = ...
    parseFeedsData(jsonData, channelFields, channelInfo, location)
% PARSEFEEDSDATA converts the raw JSON data from ThingSpeak to a table with
% the appropriate Variable names

feedColumnNames = {};
dataTable = table();

% Identify the field names returned by ThingSpeak server
if ~isempty(jsonData.feeds)
    feedColumnNames = fieldnames(jsonData.feeds);
end

% Create a table from the json data structure returned by webread()
% Even if the requested outputFormat is timetable, there is no builtin
% function for struct2timetable conversion. Therefore, we will continue to
% use struct2table and handle the data as a table.
if ~isempty(jsonData.feeds)
    dataTable = struct2table(jsonData.feeds, 'AsArray', true);
end

indexSet = [];

% Trim the Field description and ID to only those that are requested
if ~isempty(channelFields) && numel(channelFields) > 1
    indexSet = setdiff(channelInfo.FieldIDs, channelFields);
end

% If the requested field of data is not available on the specified
% ThingSpeak channel, generate an error

validateFieldAvailability(channelFields, channelInfo);

if isempty(channelFields)
    channelFields = channelInfo.FieldIDs;
end

% Check for string datatype in each column of the table (i.e., for each
% field of data)
if location
    strIndx = zeros(1, numel(channelFields)+3);
else
    strIndx = zeros(1, numel(channelFields));
end

% For each field, check if the data is numeric. If only numeric data
% (including null values) are found then convert the column to double
% datatype, else return the data as strings. For each field only
% homogeneous data is supported, i.e., all data elements in a field must be
% numeric (null values included) for conversion to double datatype.
if ~isempty(dataTable)
    for i = 1:numel(channelFields)
        if numel(channelFields) > 1
            % Extract the column of interest from the table
            columnData = dataTable.(['field' num2str(channelFields(i))]);
        else
            columnData = dataTable{:, 3};
        end
        
        % Convert columnData to a cell array - this is required by the
        % cellfun() call below
        
        if ~iscell(columnData)
            columnData = {columnData};
        end
        
                
        % Check for data that is numeric: 123, 1.123, 1e343, []. If any row
        % of the column doesnt satisfy one of the three numeric
        % requirements, then data in that column is returned as char
        % instead of numeric.
        
        % regexp doesnt accept empty numeric arrays: [], returned by
        % webread. This is generated when thingSpeak returns a null. For
        % regexp to accept the empty array input, converting it to a char
        % vector in a cell.
        columnData(cellfun(@(x) isempty(x) && isnumeric(x), columnData))...
            = {'[]'};

        % Check if the char vector only contains digits or an empty array
        numberCheck = ~cellfun(@(x) isempty(x), ...
            regexp(columnData, '^\s*(-?)[0-9]+\s*$|\[\]'));

        % Check if the char vector contains numbers in exponential format
        exponentialCheck = ~cellfun(@(x) isempty(x), ...
            regexp(columnData, '^\s*(-?)[0-9]+e[0-9]+\s*$'));

        % Check if the char vector contains decimal digits
        decimalPointCheck = ~cellfun(@(x) isempty(x), ...
            regexp(columnData, '^\s*(-?)[0-9]+\.[0-9]+\s*$'));
        
        if sum(numberCheck | exponentialCheck | decimalPointCheck) < ...
                size(columnData, 1)
            strIndx(i) = i;
        end

    end
end
end


function [feedColumnNames, timestamps, dataTable] = parseTableData...
    (jsonData, indexSet, feedColumnNames, created_at, dataTable)
% PARSETABLEDATA selects the Fields provided by user from dataTable and
% feedColumnNames

if ~isempty(jsonData.feeds)
    for iIndx = 1:numel(indexSet)
        eval(sprintf('dataTable.field%d = [];', (indexSet(iIndx))));
    end
    
    for iCIndx = 1:numel(indexSet)
        fieldName = sprintf('field%d', indexSet(iCIndx));
        feedColumnNames(strcmp(feedColumnNames, fieldName)) = [];
    end
    
    % Convert timestamps to datetime with the appropriate local timezone
    % and format
    timestamps = datetime(created_at, 'InputFormat',...
        'yyyy-MM-dd''T''HH:mm:ss''Z''', 'TimeZone', 'UTC');
    
    timestamps.TimeZone = 'local';
else
    timestamps = [];
end

end

function [data, channelInfo, entryIDs] = processChannelData...
    (dataTable, channelInfo, feedColumnNames, strIndx,...
    timestamps, channelFields)
% PROCESSCHANNELDATA processes the data returned from ThingSpeak into the
% outputformat requested by the user.
entryIDs = [];
% If no data was returned from the channel
if ~isempty(dataTable)
    % Output is a table or timetable - handle the data as a table till the
    % end.
    % For each column of the table
    for iCol = 1:numel(feedColumnNames)-2
        % If the column contains only numeric data
        if (strIndx(iCol) == 0)
            dataTable.(feedColumnNames{iCol+2}) = ...
                str2double(dataTable.(feedColumnNames{iCol+2}));
        else % If the column contains non-numeric data
            % The input to cellfun needs to be a cell array. Therefore
            % converting to cell array if required.
            if ~iscell(dataTable.(feedColumnNames{iCol+2}))
                dataTable.(feedColumnNames{iCol+2}) = ...
                    {dataTable.(feedColumnNames{iCol+2})};
            end
            
            dataTable.(feedColumnNames{iCol+2}) = cellfun(@char, ...
                dataTable.(feedColumnNames{iCol+2}), ...
                'UniformOutput', false);
        end
    end
    
    % If 'entry_id' field exists, delete it as it is not part of the output
    if sum(ismember(dataTable.Properties.VariableNames, 'entry_id'))
        entryIDs = dataTable.entry_id;
        dataTable.entry_id = [];
    end
    
    % Assign the table to the output variable
    data = dataTable;
    % Assign timestamps as datatime format to the table
    data.created_at = timestamps;
    
    % Create the appropriate column headings
    newFieldDescriptions = matlab.lang.makeValidName(...
        channelInfo.FieldDescriptions, 'ReplacementStyle', 'delete');
    newFieldDescriptions = ...
        matlab.lang.makeUniqueStrings(newFieldDescriptions);
    data.Properties.VariableNames{1} = 'Timestamps';
    
    % If the user does not specify a Field, then ensure all returned Fields
    % have the appropriate column headings
    if isempty(channelFields)
        channelFields = channelInfo.FieldIDs;
    end
    
    for iCol = 1:numel(channelFields)
        fieldIndx = channelFields(iCol);
        data.Properties.VariableNames{iCol+1} = ...
            newFieldDescriptions{channelInfo.FieldIDs == fieldIndx};
    end
else
    % create an empty table
    data = table();
end
end

function [outputData, timestamps, channelInfo] = ...
    outputDataFormat(Fields, dataTable, channelInfo, ...
    locationEnable, tabularOutput, strIndx)
% OUTPUTDATAFORMAT solely focuses on conversion of datatype to the one
% requested by the user.
dataTemp = []; %#ok<NASGU>
outputData = [];
% If the user has specified Fields value then arrange the columns in the
% same order as that specified by the user
if ~isempty(dataTable)
    dataTable.Timestamps.TimeZone = '';
    dataTemp = dataTable;
    if ~isempty(Fields)
        outputDataColNames = dataTemp.Properties.VariableNames;
        for colIndx = 2:numel(outputDataColNames)
            dataTemp.Properties.VariableNames{colIndx} = ...
                [outputDataColNames{colIndx}, '__x'];
        end
        
        % for each element of the requested fields, find the correct field
        % name.
        for fieldIDIndex = 1:numel(Fields)
            dataTemp(:, fieldIDIndex+1) = ...
                dataTable(:, matlab.lang.makeValidName(...
                channelInfo.FieldDescriptions{channelInfo.FieldIDs ...
                == Fields(fieldIDIndex)}, 'ReplacementStyle', 'delete'));
            dataTemp.Properties.VariableNames{fieldIDIndex+1} = ...
                matlab.lang.makeValidName(...
                channelInfo.FieldDescriptions{channelInfo.FieldIDs...
                == Fields(fieldIDIndex)}, 'ReplacementStyle', 'delete');
        end
    end
    
    if ~isempty(dataTemp)
        if locationEnable
            % If location data is requested, and if the outputFormat
            % parameter is set to table, then change the column names to
            % have uppercase for first letter. If the outputFormat
            % parameter is set to Array then don't do anything more.
            
            dataTemp.Properties.VariableNames{end} = 'Altitude';
            dataTemp.Properties.VariableNames{end-1} = 'Longitude';
            dataTemp.Properties.VariableNames{end-2} = 'Latitude';
        end
        
        dataTable = dataTemp;
        clear dataTemp;
    end
    
else
    if tabularOutput == 0
        timestamps = [];
    elseif tabularOutput == 1
        % If table output was requested
        outputData = table();
        timestamps = channelInfo;
        channelInfo = [];
    elseif tabularOutput == 2
        % If table output was requested
        outputData = timetable();
        timestamps = channelInfo;
        channelInfo = [];
    end
    return;
end

if tabularOutput == 0
    % Output is a double array
    % Assign each column of the table to a column of the array
    
    % If non-numeric data is requested as a double array, generate a
    % warning
    if sum(strIndx) ~= 0
        tsIssueWarning('MATLAB:iot:thingSpeakConnectivity:nonNumericDataFound');
    end
    
    % Assign each column of the table to a column of the array
    % Cannot use table2array() since columns might have heterogenous
    % datatypes.
    for iCol = 2:size(dataTable, 2)
        if isnumeric(dataTable.(iCol))
            outputData(:, end+1) = dataTable.(iCol); %#ok<AGROW>
        else
            outputData(:, end+1) = str2double(dataTable.(iCol)); %#ok<AGROW>
        end
    end
    
    timestamps = dataTable.Timestamps;
    timestamps.TimeZone = '';
elseif tabularOutput == 1
    outputData = dataTable;
    timestamps = channelInfo;
    channelInfo = [];
elseif tabularOutput == 2
    outputData = table2timetable(dataTable);
    timestamps = channelInfo;
    channelInfo = [];
end
end
