function configFile = getConfigFile()
%getConfigFile return the config file for code compatibility report
%   This config file contains only syntax error and compatibility issues.

%   Copyright 2022 The MathWorks, Inc.
    configFile = fullfile(matlabroot, "toolbox", "matlab", "codeanalysis", "reports", "analysis", "ccrConfig.json");
end
