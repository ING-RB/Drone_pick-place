function obj = instance()
%

%   Copyright 2024 The MathWorks, Inc.

    persistent localUniqueInstance;
    if isempty(localUniqueInstance)
        obj = appdesigner.internal.service.AppManagementService();
        localUniqueInstance = obj;
    else
        obj = localUniqueInstance;
    end
end
