classdef (Abstract) IFeatureLaunchable < handle
    % Abstract base interface class for FeatureLaunchable implementations.

    % Copyright 2024 The MathWorks, Inc.

    methods (Abstract, Access = {?matlab.hwmgr.internal.IFeatureLaunchable, ?matlab.hwmgr.internal.FeatureLauncher, ?matlab.unittest.TestCase})
        launch(obj)
    end

     methods (Static)

        function deviceLaunchableData = getDeviceLaunchableData(identifier, hwmgrDevice)
             % Given the identifier, iterate through each feature category to find the device launchable data.
            deviceLaunchableData = [];

            if isempty(hwmgrDevice)
                return;
            end

            % Retrieve the list of feature categories
            categories = string(enumeration('matlab.hwmgr.internal.data.FeatureCategory'));

            for i = 1:length(categories)
                propertyName = "Device" + categories(i) + "Data";
                if (isprop(hwmgrDevice,propertyName))
                    deviceData =  hwmgrDevice.(propertyName);

                    % Find the device data that matches the specified identifier
                    index = find(arrayfun(@(x) ismember(x.IdentifierReference, identifier), deviceData));

                    if ~isempty(index)
                        deviceLaunchableData = deviceData(index);
                        return;
                    end
                end
            end
        end
    end
end
