function absPath = resolveRelativeLocation(location)
%

%   Copyright 2024 The MathWorks, Inc.

    P = matlab.io.internal.filesystem.Path(location);
    if P.absolute()
        absPath = location;
    else
        S = matlab.io.internal.filesystem.resolvePath(location, ResolveSymbolicLinks=false);
        absPath = S.ResolvedPath;
    end
end
