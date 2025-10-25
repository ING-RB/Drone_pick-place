function initCaches()
% Initialize all caches, including those in the private directory.
% Allows external applications to reset caches. 

%   Copyright 2013-2020 The MathWorks, Inc.

    matlab.depfun.internal.cacheWhich();
    matlab.depfun.internal.cacheExist();
    matlab.depfun.internal.cacheEdge();
    matlab.depfun.internal.cacheIsExcluded();
    matlab.depfun.internal.cacheIsExpected();
    getPrivateFiles();
    matlab.depfun.internal.MatlabSymbol.initClasses();
end
