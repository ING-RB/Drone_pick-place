classdef (Abstract, Hidden) LegacyUDPDatagram < matlabshared.transportlib.internal.compatibility.LegacyUDPCommon 
    %LEGACYUDPDATAGRAM Specific implementation of legacy udp (datagram
    %mode) support. The udpport.datagram.UDPPort class must inherit from it
    %in order to support legacy operations.
    %
    %    This undocumented class may be removed in a future release.    

    % Copyright 2021 The MathWorks, Inc.

    %#codegen

    properties (Hidden, Dependent)
        DatagramReceivedFcn function_handle
    end

    methods
        function value = get.DatagramReceivedFcn(obj)
            value = obj.DatagramsAvailableFcn;
        end

        function set.DatagramReceivedFcn(obj, callbackFcn)
            obj.configureCallback("datagram", 1, callbackFcn)
        end        
    end

    methods
        %This dummy constructor is needed for codegen support
        function obj = LegacyUDPDatagram
            coder.allowpcode('plain');
            obj.DatagramTerminateMode = 'on';
        end
    end

    methods (Access = protected)
        function data = readHook(obj, ~, precision)
            % numRead parameter is ignored (for legacy udp datagram
            % support): always read a single datagram back, irrespective of
            % the number of elements requested.
            data = read(obj, 1, precision);
        end

        function dataOut = convertReadDataHook(~, dataIn)
            % UDP produces a datagram, not a primitive datatype (no need
            % for any conversion)
            dataOut = dataIn;
        end

        function out = packageReadDataHook(~, data, numRead, warningstr, numRows, numCols)
            % A non-empty warning is a result of receiving empty data
            if ~isempty(warningstr)
                out = {data, numRead, warningstr, '', []};
                return
            end

            datagramAddress = convertStringsToChars(data.SenderAddress);
            datagramPort = data.SenderPort;
            
            dataOut = reshape(data.Data', numRows, numCols);
            out = {dataOut, numel(dataOut), warningstr, datagramAddress, datagramPort};
        end        
    end    
end

