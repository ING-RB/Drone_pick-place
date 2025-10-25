classdef (Abstract, Hidden) LegacyBluetooth < matlabshared.transportlib.internal.compatibility.LegacyBase & ...
                                              matlabshared.transportlib.internal.compatibility.LegacyBinaryMixin & ...
                                              matlabshared.transportlib.internal.compatibility.LegacyASCIIMixin
                                              % LegacyBinblockMixin not supported
                                              % LegacyQueryMixin not supported
    %LEGACYBLUETOOTH Specific implementation of legacy Bluetooth support.
    %The bluetooth class must inherit from it in order to support legacy
    %operations.
    %
    %    This undocumented class may be removed in a future release.
    
    % Copyright 2021 The MathWorks, Inc.

    %#codegen

    properties (Hidden, SetAccess = private, Dependent)
        RemoteID
        RemoteName
    end

    %% Getters / Setters
    methods
        function value = get.RemoteID(obj)
            % Refers to bluetooth's "Address"
            value = obj.Address;
        end

        function value = get.RemoteName(obj)
            % Refers to bluetooth's "Name"
            value = obj.Name;
        end
    end

    methods
        %This dummy constructor is needed for codegen support
        function obj = LegacyBluetooth
            coder.allowpcode('plain');
        end
    end

    methods (Access = protected)
        function timeout = getFscanfMinTimeout(obj)
            % minimum timeout for bluetooth is 1 second
            timeout = 1;
        end
    end  
end