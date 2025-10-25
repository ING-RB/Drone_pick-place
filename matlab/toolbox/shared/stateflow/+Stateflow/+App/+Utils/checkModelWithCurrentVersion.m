function out = checkModelWithCurrentVersion(givenMATLABVersion, givenSfVersion)
%

%   Copyright 2019 The MathWorks, Inc.
    
    %  0 - versions match
	% -1 - model saved in newer releases
	%  1 - model saved in previous releases
    out = 0;
    [currentMATLABVersion, currentSfVersion] = Stateflow.App.Utils.getVersion();
    if currentMATLABVersion > givenMATLABVersion || currentSfVersion > givenSfVersion
        out = 1;
    elseif currentMATLABVersion < givenMATLABVersion || currentSfVersion < givenSfVersion
        out = -1;
    end
end
