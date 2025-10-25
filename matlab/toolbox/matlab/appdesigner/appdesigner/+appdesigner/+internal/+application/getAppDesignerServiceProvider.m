function serviceProvider = getAppDesignerServiceProvider()
% Accesses singleton AppDesignerServiceProvider

% Copyright 2020 The MathWorks, Inc.
    
persistent localServiceProvider;
if isempty(localServiceProvider) || ~isvalid(localServiceProvider) 
    localServiceProvider = appdesigner.internal.application.AppDesignerServiceProvider;
end

serviceProvider = localServiceProvider;

mlock;
end

