classdef (Abstract, Hidden) LegacyTcpclient < matlabshared.transportlib.internal.compatibility.LegacyBase & ...
                                              matlabshared.transportlib.internal.compatibility.LegacyBinaryMixin & ...
                                              matlabshared.transportlib.internal.compatibility.LegacyASCIIMixin & ...
                                              matlabshared.transportlib.internal.compatibility.LegacyBinblockMixin & ...
                                              matlabshared.transportlib.internal.compatibility.LegacyQueryMixin
    %LEGACYTCPCLIENT Specific implementation of legacy tcp (client)
    %support. The tcpclient class must inherit from it in order to support
    %legacy operations.
    %
    %    This undocumented class may be removed in a future release.    

    % Copyright 2021 The MathWorks, Inc.

    %#codegen

    properties (Hidden, SetAccess = private, Dependent)
        RemoteHost 
        RemotePort

        % TransferDelay - refers to EnableTransferDelay
        TransferDelay matlab.lang.OnOffSwitchState
    end

    %% Getters / Setters
    methods
        function value = get.RemoteHost(obj)
            % Refers to tcpclient's "Address"
            value = obj.Address;
        end

        function value = get.RemotePort(obj)
            % Refers to tcpclient's "Port"
            value = obj.Port;
        end

        function value = get.TransferDelay(obj)
            value = matlab.lang.OnOffSwitchState(obj.EnableTransferDelay);
        end
    end

    methods
        %This dummy constructor is needed for codegen support
        function obj = LegacyTcpclient
            coder.allowpcode('plain');
        end
    end
end