function trailingPeriodsAndWhitespaces(paths)
%trailingPeriodsAndWhitespaces    Error when paths end in periods or
%   whitespace

%   Copyright 2019-2020 The MathWorks, Inc.
    if numel(paths) > 2 && any(strcmp(paths(end),{'.',' '}))
        error(message('MATLAB:datastoreio:pathlookup:fileNotFound',paths));
    end
end
