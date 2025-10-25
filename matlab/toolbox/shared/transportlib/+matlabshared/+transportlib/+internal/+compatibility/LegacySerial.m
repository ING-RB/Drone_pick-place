classdef (Abstract, Hidden) LegacySerial < matlabshared.transportlib.internal.compatibility.LegacyBase & ...
                                           matlabshared.transportlib.internal.compatibility.LegacyBinaryMixin & ...
                                           matlabshared.transportlib.internal.compatibility.LegacyASCIIMixin & ...
                                           matlabshared.transportlib.internal.compatibility.LegacyBinblockMixin & ...
                                           matlabshared.transportlib.internal.compatibility.LegacyQueryMixin

    %LEGACYSERIAL Specific implementation of legacy serial support. The
    %serialport class must inherit from it in order to support legacy
    %operations.
    %
    %    This undocumented class may be removed in a future release.
    
    % Copyright 2021 The MathWorks, Inc.

    %#codegen

    properties (Hidden, SetAccess = private, Dependent)
        PinStatus 
    end

    %% Getters / Setters
    methods
        function value = get.PinStatus(obj)
            status = obj.getpinstatus;
            value.ClearToSend = matlab.lang.OnOffSwitchState(status.ClearToSend);
            value.DataSetReady = matlab.lang.OnOffSwitchState(status.DataSetReady);
            value.CarrierDetect = matlab.lang.OnOffSwitchState(status.CarrierDetect);
            value.RingIndicator = matlab.lang.OnOffSwitchState(status.RingIndicator);
        end
    end    

    methods
        %This dummy constructor is needed for codegen support
        function obj = LegacySerial
            coder.allowpcode('plain');
        end
    end
end