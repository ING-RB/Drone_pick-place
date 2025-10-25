function url = getLoginFrameUrl(varargin)
% GETLOGINFRAMEURL  Gets the relative URL to the mw-login HTML file

% Copyright 2021-2024 The MathWorks, Inc.

p = inputParser();
p.KeepUnmatched = true;
p.PartialMatching = false;
p.addOptional("debug", false);
p.addOptional("external", false);
p.addOptional("channel", '');
p.parse(varargin{:});

url = "toolbox/matlab/login/web/";
if p.Results.debug
    url = url + "index-debug.html";
else
    url = url + "index.html";
end
pairs = containers.Map();
if p.Results.external % Only add if a non-default value was specified
    pairs('external') = p.Results.external;
end
if ~isempty(p.Results.channel) % Only add if specified
    pairs('channel') = p.Results.channel;
end

% Add other params, mw-login will deal with them accordingly
iAddKVPairsFromStruct(pairs, p.Unmatched);
if ~pairs.isempty
    url = url + '?' + iPairsToUrl(pairs);
end
end

function iAddKVPairsFromStruct(target, data, prefix)
paramNames = fieldnames(data);
for k = 1 : numel(paramNames)
    paramName = paramNames{k};
    paramValue = data.(paramName);
    if nargin > 2 && ~isempty(prefix)
        paramName = strcat(prefix,  '.',  paramName);
    end
    if isstruct(paramValue)
        iAddKVPairsFromStruct(target, paramValue, paramName);
    else
        target(paramName) = paramValue;
    end
end
end

function url = iPairsToUrl(map)
pairs = cell(map.length, 1);
keys = map.keys;
values = map.values;
for k = 1 : map.length
    pairs{k} = { keys{k}, values{k} };
end
allPairs = cellfun(@iPairToString, pairs);
url = strjoin(allPairs, "&");
end

function str = iPairToString(pair)
key = pair{1};
value = pair{2};
% Using `num2str` on any simple type is safe, it will behave as a ".toString()" method
str = string(strcat(urlencode(key), '=', urlencode(num2str(value))));
end
