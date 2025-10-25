classdef (Hidden) NISysCfg
    %NISYSCFG Utilities that use NI SysCfg to list available devices

    % Copyright 2022-2024 The MathWorks, Inc.

    properties (Constant)
        % SupportedHardwareTypes: Expert names for managing (NI) modular
        % instruments.
        %
        % PackageNames: Corresponding installation packages required if the
        % specified hardware is not detected.
        SupportedHardwareTypes = ["ni-vst", "daqmx", "ni-visa", "ni-rio", "niflexrio2"]
        PackageNames = ["NI-RFSG", "DAQ", "VISA", "NI-RIO", "NI-FLEXRIO2"]
        SupportedTypesToPackageName = dictionary(instrument.internal.NISysCfg.SupportedHardwareTypes, instrument.internal.NISysCfg.PackageNames)
    end

    methods (Static)
       function syscfg = getSystemConfig(expertName)

            arguments
                expertName (1, 1) string {validateSysConfigTypes(expertName)} = "ni-vst"
            end

            if ispc
                mh = mexhost;
                try
                    syscfg = feval(mh, 'mexsyscfg', expertName);
                catch ex
                    switch ex.identifier
                        case 'MATLAB:mex:MexHostCrashed'
                            id = "instrument:qcinstrument:unableToDetectExpertName";
                            me = MException(message(id, upper(expertName), instrument.internal.NISysCfg.SupportedTypesToPackageName(expertName)));
                        otherwise
                            me = ex;
                    end

                    throw(me);
                end
            else
                syscfg = struct.empty;
            end
       end

        function resources = listNIRIOResources(expertName)

            arguments
                expertName (1, 1) string {validateSysConfigTypes(expertName)} = "ni-vst"
            end

            sp = instrument.internal.NISysCfg.getSystemConfig(expertName);
            if ~isempty(sp)
                resources = [sp.Alias];
                if isempty(resources)
                    resources = string.empty;
                end
            else
                resources = string.empty;
            end
        end
    end
end


function validateSysConfigTypes(type)
    mustBeMember(type, instrument.internal.NISysCfg.SupportedHardwareTypes);
end

