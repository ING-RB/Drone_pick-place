classdef ControlSharedFactorySettings < matlab.settings.internal.FactorySettingsDefinition
    methods (Static)
        function createTree(shared)
            shared.addGroup('graphics','HasAdditionalSettings',true);
        end
        function u = createUpgraders()
            u = matlab.settings.SettingsFileUpgrader('v1');
        end
    end
end