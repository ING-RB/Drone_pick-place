function providers = registerMlappDiffNoGUIProviders(~)
%   Support returning report from visdiff command line without launching comparison tool GUI

%   Copyright 2022 The MathWorks, Inc.

    providers = appdesigner.internal.comparison.MlappDiffNoGUIProvider();
    
end