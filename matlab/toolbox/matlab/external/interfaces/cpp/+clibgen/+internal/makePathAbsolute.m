function paths = makePathAbsolute(paths)
% MAKEPATHABSOLUTE converts the relative path as input to absolute paths.
% No validation on the input is performed.
% If an entry in the input list does not exist, a empty string is returned.

%   Copyright 2024 The MathWorks, Inc.

arguments
    paths (1,:) string
end

% normalized input path to absolute path
for ind = 1:length(paths)
    [status,attrib] = fileattrib(paths(ind));
    if status == 0
        % path does not exist go to the next entry
        % no validation is performed.
        paths(ind)="";
    else
        paths(ind) = string(attrib.Name);
    end
end

end
