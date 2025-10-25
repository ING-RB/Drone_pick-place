function isLatest = isLatestVersion(givenMinorVersion, givenMajorVersion)
%
 
%   Copyright 2018-2019 The MathWorks, Inc.
%   deprecated API. Use checkModelWithCurrentVersion instead.
%   this API is just for grandfathering purpose
    if ~exist('givenMajorVersion','var')
        isLatest = false;
        return;
    end
    if ~isequal(givenMajorVersion, version('-release'))
        isLatest = false;
        return;
    end
    [~,minorVersion] = Stateflow.App.Utils.getVersion();
    isLatest = minorVersion == givenMinorVersion; 
end
