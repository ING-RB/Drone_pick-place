classdef DeviceAppletData <matlab.hwmgr.internal.data.DeviceLaunchableData
    %DEVICEAPPLETDATA Applet data specific to a Hardware Manager device

    % Copyright 2021-2024 The MathWorks, Inc.

    properties (SetAccess = private)
        %AppletClass
        %   Client app applet class inheriting from matlab.hwmgr.internal.AppletBase
        AppletClass
    end

    methods (Access = {?matlab.hwmgr.internal.data.DataFactory, ?matlab.unittest.TestCase})
        
        function obj = DeviceAppletData(appletClass, supportingAddOnBaseCodes, skipSupportingAddonInstallation, identifierReference)
            arguments
                appletClass (1, 1) string
                supportingAddOnBaseCodes (1, :) string = string.empty()
                skipSupportingAddonInstallation = dictionary(string.empty, logical.empty)
                identifierReference (1, 1) string = ""
            end
            
            % Initialize common properties via the superclass constructor
            obj@matlab.hwmgr.internal.data.DeviceLaunchableData(identifierReference, ...
                                                                supportingAddOnBaseCodes, ...
                                                                skipSupportingAddonInstallation);
            obj.AppletClass = appletClass;
        end
    end
end