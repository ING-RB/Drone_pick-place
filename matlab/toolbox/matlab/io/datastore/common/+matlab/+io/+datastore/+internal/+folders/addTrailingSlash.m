function folders = addTrailingSlash(folders)
%   Adds a trailing slash to any input folder names that don't already have
%   one. This function expects a list of fully resolved folder names as input.

%   Copyright 2019 The MathWorks, Inc.

    % Get the IRI status of all folders at once.
    if ~isempty(folders)
        isIriResults = matlab.io.internal.vfs.validators.isIRI(folders);
    end

    % Iterate over all folders and ensure that they have a trailing slash.
    for index = 1:numel(folders)
        if isIriResults(index)
            separator = '/';
        else
            separator = filesep;
        end
        
        if ~endsWith(folders{index}, separator)
            folders{index} = [folders{index} separator];
        end
    end
end
