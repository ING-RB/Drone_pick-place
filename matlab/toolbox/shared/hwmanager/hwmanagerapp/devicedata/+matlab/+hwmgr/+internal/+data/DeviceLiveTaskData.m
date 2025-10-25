classdef DeviceLiveTaskData < matlab.hwmgr.internal.data.DeviceLaunchableData
    %DEVICELIVETASKDATA Live task data specific to a Hardware Manager device

    % Copyright 2022-2024 The MathWorks, Inc.

    properties (SetAccess = private)
        %LIVETASKDISPLAYNAME
        %   Live task display name used as an identification for live task
        LiveTaskDisplayName
    end

    methods (Access = {?matlab.hwmgr.internal.data.DataFactory, ?matlab.unittest.TestCase})

        function obj = DeviceLiveTaskData(liveTaskDisplayName, supportingAddOnBaseCodes, skipSupportingAddonInstallation, identifierReference)
            arguments
                liveTaskDisplayName (1, 1) string
                supportingAddOnBaseCodes (1, :) string = string.empty()
                skipSupportingAddonInstallation = dictionary(string.empty, logical.empty)
                identifierReference (1, 1) string =  ""
            end

            % Initialize common properties via the superclass constructor
            obj@matlab.hwmgr.internal.data.DeviceLaunchableData(identifierReference, ...
                                                                supportingAddOnBaseCodes, ...
                                                                skipSupportingAddonInstallation);
            obj.LiveTaskDisplayName = liveTaskDisplayName;
        end
    end
end