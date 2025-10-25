classdef AddOnData
    %ADDONDATA AddOn data required by Hardware Manager app

    % Copyright 2021-2022 The MathWorks, Inc.

    properties (SetAccess = private)
        %BaseCode
        %   Base code of the AddOn
        BaseCode

        %FullName
        %   Full marketing name of the AddOn
        FullName

        %RequiredAddOnBaseCodes
        %   Base code of all upstream AddOn dependencies
        RequiredAddOnBaseCodes

        %AsyncioDevicePlugin
        %   Client enumerator asycio device plugin dll path
        AsyncioDevicePlugin

        %AsyncioConverterPlugin
        %   Client enumerator asycio converter plugin dll path (optional)
        AsyncioConverterPlugin

        %ClientEnumeratorAddOnSwitch
        %   Base code of the AddOn whose installation status determines
        %   whether the client enumertor or device provider is used. If no
        %   value is provided, the "BaseCode" of this AddOn is used.
        %   Example: if value is VN, then this client
        %   enumerator is disabled when VNT toolbox is installed.
        ClientEnumeratorAddOnSwitch
    end

    methods (Access = {?matlab.hwmgr.internal.data.DataFactory, ?matlab.unittest.TestCase})
        function obj = AddOnData(baseCode, fullName, requiredAddOnBaseCodes, nameValueArgs)
            arguments
                baseCode (1, 1) string
                fullName (1, 1) string
                requiredAddOnBaseCodes (1, :) string = string.empty();
                nameValueArgs.AsyncioDevicePlugin (1, :) string = string.empty()
                nameValueArgs.AsyncioConverterPlugin (1, :) string = string.empty()
                nameValueArgs.ClientEnumeratorAddOnSwitch (1, :) string = string.empty()
            end

            % All basecodes must be upper case.
            obj.BaseCode = upper(baseCode);
            obj.FullName = fullName;
            obj.RequiredAddOnBaseCodes = upper(requiredAddOnBaseCodes);
            obj.AsyncioDevicePlugin = nameValueArgs.AsyncioDevicePlugin;
            obj.AsyncioConverterPlugin = nameValueArgs.AsyncioConverterPlugin;
            obj.ClientEnumeratorAddOnSwitch = nameValueArgs.ClientEnumeratorAddOnSwitch;
        end
    end
end
