function [MATLABVersion, SfVersion] = getVersion()
%

%   Copyright 2018-2019 The MathWorks, Inc.

    MATLABVersion = "R" + version('-release');
    
    SfVersion = Stateflow.internal.Version.toNumeric;
end
