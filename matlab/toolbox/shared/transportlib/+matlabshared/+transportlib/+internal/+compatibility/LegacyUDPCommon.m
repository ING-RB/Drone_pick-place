classdef (Abstract, Hidden) LegacyUDPCommon < matlabshared.transportlib.internal.compatibility.LegacyBase & ...
                                              matlabshared.transportlib.internal.compatibility.LegacyBinaryMixin
    % LEGACYUDPCOMMON Common properties for Legacy UDP classes
    %
    %    This undocumented class may be removed in a future release.

    % Copyright 2021 The MathWorks, Inc.
    
    %#codegen

    properties (Hidden)
        RemoteHost = '127.0.0.1'
        RemotePort =  9090
    end

    properties (Hidden, SetAccess = protected)
        DatagramTerminateMode
    end    

    methods
        %This dummy constructor is needed for codegen support
        function obj = LegacyUDPCommon
            coder.allowpcode('plain');
        end
    end

    methods (Access = protected)
        function writeHook(obj, data, precision)
            write(obj, data, precision, obj.RemoteHost, obj.RemotePort);
        end
    end
end

