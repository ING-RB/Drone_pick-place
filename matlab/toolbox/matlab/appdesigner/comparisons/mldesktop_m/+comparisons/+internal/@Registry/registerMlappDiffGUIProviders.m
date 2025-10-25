function providers = registerMlappDiffGUIProviders(~)
%   Support launching comparison tool GUI from visdiff command line

%   Copyright 2021-2022 The MathWorks, Inc.

    providers = appdesigner.internal.comparison.MlappDiffGUIProvider();

end
