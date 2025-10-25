classdef (Abstract) FactorySettingsDefinition
%

%   Copyright 2021-2022 The MathWorks, Inc.

    methods(Static, Abstract)
        createTree(additional)
        up = createUpgraders()
    end
end

