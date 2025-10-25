function [location, filePattern] = splitWriteLocation(location)
%SPLITWRITELOCATION Split an input location into the path and file pattern.
%
%   [LOCATION, FILEPATTERN] = SPLITWRITELOCATION(LOCATION) tries to
%   separate out the path from a file pattern if specified. File patterns
%   must include a *, otherwise the input string will be treated as a
%   location.
%
%   Examples:
%   >> [l,p] = splitWriteLocation("foo/data_*.txt")
%   l = "foo"
%   p = "data_*.txt"

%   Copyright 2018 The MathWorks, Inc.

% If first input includes a file pattern, split the location and the
% pattern.
if matlab.internal.datatypes.isScalarText(location)
    if contains(location, "*")
        [location, filePattern, ext] = fileparts(location);
        filePattern = strcat(filePattern, ext);
        
        if contains(location, "*")
            % Wildcards are not allowed in the path!
            error(message("MATLAB:bigdata:write:WildcardInPath"))
        end
        
        if numel(strfind(filePattern, "*")) ~= 1
            error(message("MATLAB:bigdata:write:TooManyWildcards"))
        end
    else
        filePattern = "";
    end
    
    if strlength(location)==0
        error(message("MATLAB:bigdata:write:EmptyLocation"))
    end
else
    % Location was not text
    error(message("MATLAB:bigdata:write:BadLocation"))
end