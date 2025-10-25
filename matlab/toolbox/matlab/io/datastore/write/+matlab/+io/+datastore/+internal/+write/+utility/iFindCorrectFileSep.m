function sep = iFindCorrectFileSep(location)
%iFindCorrectFileSep    Find the filesep based on the stored fileseparator
%   found from the folder name of the first file.

%   Copyright 2023 The MathWorks, Inc.
    sep = filesep;
    location = convertStringsToChars(location);
    if ispc && ~isempty(location)
        ind = find(location == '/' | location == '\', 1, 'first');
        if ~isempty(ind)
            sep = location(ind);
        end
    end
end