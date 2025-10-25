classdef (Abstract, Hidden) LegacyTcpserver < matlabshared.transportlib.internal.compatibility.LegacyBase & ...
                                              matlabshared.transportlib.internal.compatibility.LegacyBinaryMixin & ...
                                              matlabshared.transportlib.internal.compatibility.LegacyASCIIMixin & ...
                                              matlabshared.transportlib.internal.compatibility.LegacyBinblockMixin
                                              % LegacyQueryMixin not supported
    %LEGACYTCPSERVER Specific implementation of legacy tcp (server)
    %support. The tcpserver class must inherit from it in order to support
    %legacy operations.
    %
    %    This undocumented class may be removed in a future release.    
    
    % Copyright 2021 The MathWorks, Inc.

    %#codegen

    properties (Hidden, SetAccess = private, Dependent)
        RemoteHost 
        RemotePort

        LocalHost
        LocalPort
    end

    %% Getters / Setters
    methods
        function value = get.RemoteHost(obj)
            % Refers to tcpserver's "ClientAddress"
            value = obj.ClientAddress;
        end

        function value = get.RemotePort(obj)
            % Refers to tcpserver's "ClientPort"
            value = obj.ClientPort;
        end

        function value = get.LocalHost(obj)
            % Refers to tcpserver's "ServerAddress"
            value = obj.ServerAddress;
        end

        function value = get.LocalPort(obj)
            % Refers to tcpserver's "ServerPort"
            value = obj.ServerPort;
        end
    end

    methods
        %This dummy constructor is needed for codegen support
        function obj = LegacyTcpserver
            coder.allowpcode('plain');
        end
    end

    methods (Access = protected)
        function fopenHook(obj)
            while ~obj.Connected
                pause(0.1)
            end
        end
    end    
end