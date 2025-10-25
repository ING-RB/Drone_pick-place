function [url] = getThingSpeakURL(varargin)
% GETTHINGSPEAKURL validates the URL provided by the user to ensure that
% it is in the correct format for the thingSpeak connectivity functions
%
% INPUTS
% alternateURL -> Alternate URL to validate
% writeFlag    -> Flag to indicate if the function is being called by
%                 thingSpeakWrite
% batchFlag    -> Flag to indicate whether the data update is a single
%                 point or batch upload
% channelID    -> ID of the channel to be included in the URL

% Copyright 2015-2018, The MathWorks Inc.

parsedInputs = tsParseInputs(varargin{:});

baseURL =  'https://api.thingspeak.com';
url = '';
alternateURL = parsedInputs.alternateURL;
writeFlag    = parsedInputs.writeFlag;
batchFlag    = parsedInputs.batchFlag;
channelID    = parsedInputs.channelID;

% Pick up user provided url, if available. Else check for appdata
if ~isempty(alternateURL)
    baseURL = alternateURL;
else
    envURL = getappdata(0, 'MATLAB_ThingSpeak_Custom_URL');
    % If URL has been set as an environmental variable, then use that
    if ~isempty(envURL)
        baseURL = envURL;
    end
end

% Validate URL input
try
    % Convert to char vector for validation
    if isstring(baseURL)
        baseURL = char(baseURL);
    end
    validateattributes(baseURL, {'char'}, {'vector'});
catch    
    throwAsCaller(MException(message('MATLAB:iot:thingSpeakConnectivity:URLNotAString')));
end

% If user provided url has forward slash at the end remove it
if strcmpi(baseURL(end), '/')
    baseURL(end) = '';
end

% Ensure URL starts with http or https, so that we can add http if
% not
if (length(baseURL) >= length('http')) && ...
        ~strcmpi(baseURL(1:length('http')), 'http')
    if contains(baseURL, 'api.thingspeak.com')
        baseURL = sprintf('https://%s', baseURL);
    else
        baseURL = sprintf('http://%s', baseURL);
    end
end

if writeFlag == 1
    if ~batchFlag
        if ~isempty(alternateURL)
            % This is to use the old end-point
            url = sprintf('%s/update', baseURL);
        else
            % This is to use the new end-point
            url = sprintf('%s/channels/%d/feeds.json', baseURL, channelID);
        end
    else
        % This is to use the new end-point
        url = sprintf('%s/channels/%d/bulk_update.json', baseURL,...
            channelID);        
    end
end

if isempty(url)
    url = baseURL;
end

% Append forward slash as required
if url(end) ~= '/'
    url(end + 1) = '/';
end

end

function parsedInputs = tsParseInputs(inputArguments)
p = inputParser;
addParameter(p, 'alternateURL', []);    % fields to retrieve
addParameter(p, 'writeFlag', []);       % number of entries to retrieve (8000 max)
addParameter(p, 'batchFlag', []);       % days from now to include in feed
addParameter(p, 'channelID', []);       % minutes from now to include in feed
addParameter(p, 'errorIDPrefix', []);   % days from now to include in feed
addParameter(p, 'errormsgPrefix', '');  % APIKey for reading data from private channels

try
    p.parse(inputArguments{:});
catch
end

parsedInputs = p.Results;
end