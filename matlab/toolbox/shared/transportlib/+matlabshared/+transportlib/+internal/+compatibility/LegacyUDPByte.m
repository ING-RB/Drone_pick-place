classdef (Abstract, Hidden) LegacyUDPByte < matlabshared.transportlib.internal.compatibility.LegacyUDPCommon & ...
                                            matlabshared.transportlib.internal.compatibility.LegacyASCIIMixin
    %LEGACYUDPBYTE Specific implementation of legacy udp (byte mode)
    %support. The udpport.byte.UDPPort class must inherit from it in order
    %to support legacy operations.
    %
    %    This undocumented class may be removed in a future release.  

    % Copyright 2021 The MathWorks, Inc.

    %#codegen
    methods
        %This dummy constructor is needed for codegen support
        function obj = LegacyUDPByte
            coder.allowpcode('plain');
            obj.DatagramTerminateMode = 'off';
        end
    end

    methods (Access = protected)
        % Binary

        function out = packageReadDataHook(obj, data, numRead, warningstr, numRows, numCols)
            data = reshape(data, numRows, numCols);
            out = {data, numRead, warningstr, obj.RemoteHost, obj.RemotePort};
        end
 
        % ASCII
        function out = packageScanDataHook(obj, outputData, outputCount, outputMessage)
            out = {outputData, outputCount, outputMessage, obj.RemoteHost, obj.RemotePort};
        end
    end
end

