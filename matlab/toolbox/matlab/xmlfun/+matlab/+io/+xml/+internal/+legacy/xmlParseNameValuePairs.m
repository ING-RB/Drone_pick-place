function parsedNameValuePairs = xmlParseNameValuePairs(nameValuePairs)
% 

% Copyright 2022-2024 The MathWorks, Inc.

% Since xmlread allows arbitrary values to be passed in via varargin,
% we don't allow case insensitivity or partial matching of name-value
% pairs to reduce the space of possible incompatibilities to a minimum.

parsedNameValuePairs.AllowDoctype = true;

for ii = 1:2:length(nameValuePairs)
    if ischar(nameValuePairs{ii})
        name = nameValuePairs{ii};
        if strcmp(name, 'AllowDoctype')
            if ii < length(nameValuePairs)
                value = nameValuePairs{ii + 1};
                validateattributes(value, {'logical'}, {'scalar'}, 'xmlread', 'AllowDoctype');
                parsedNameValuePairs.AllowDoctype = value;
            end
        end
    end
end

end