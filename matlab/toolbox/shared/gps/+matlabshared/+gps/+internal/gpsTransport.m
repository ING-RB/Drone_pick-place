classdef(Sealed,Hidden) gpsTransport < matlab.System
    %GPSTRANSPORT is used for creating a transport layer interface for GPS 
    
    % Copyright 2020-2021 The MathWorks, Inc.
    
    properties(Access = private)
        TransportObject = [];
        TimeForFirstRMCSet = 0;
        TimeForSecondRMCSet = 0;
        CallingObj;
        RawData = [];
        ResetAfterSetup = 0;
    end
    
    properties (Access = public, Hidden)
        UpdateRate;
    end
    
    methods
        function obj = gpsTransport(connectionObj,callingObj)
            try
                obj.CallingObj = callingObj;
                if isa(connectionObj, 'internal.Serialport') || isa(connectionObj,'gpsTest.mock.serialObject')
                    obj.TransportObject  =  connectionObj;
                    callingObj.BaudRate = obj.TransportObject.BaudRate;
                else
                    if ischar(connectionObj)||isstring(connectionObj)
                        if contains(string(connectionObj), serialportlist,'IgnoreCase',true)
                            obj.TransportObject  = serialport(connectionObj,callingObj.BaudRate);
                        else
                            error(message('shared_gps:general:InvalidPort'));
                        end
                    else
                        error(message('shared_gps:general:InvalidPort'));
                    end
                end
                callingObj.SerialPort = obj.TransportObject.Port;
            catch ME
                obj.TransportObject  = [];
                throwAsCaller(ME);
            end
        end
    end
    
    methods(Access = protected)
        function obj = setupImpl(obj)
            validateGpsData(obj);
            obj.CallingObj.UpdateRate = obj.UpdateRate;
            obj.ResetAfterSetup = 1;
        end
        
        function varargout = stepImpl(obj)
            varargout{1} = [obj.RawData,readData(obj)];
            obj.RawData = [];
        end
        
        function resetImpl(obj)
            if obj.ResetAfterSetup == 1
                obj.ResetAfterSetup = 0;
            else
                flush(obj.TransportObject);
            end
        end
        
        function releaseImpl(~)
        end
    end
    
    methods(Hidden)
        function showProperties(obj)
            fprintf('                         SerialPort: %s\t\n',obj.TransportObject.Port);
            fprintf('                           BaudRate: %d (bits/s)\n\n',obj.TransportObject.BaudRate);
        end
        
        function writeBytes(obj,configmsg)
            if(obj.isLocked ~= 1)
                obj.TransportObject.write(configmsg,'uint8');
            else
                try
                    error(message('shared_gps:general:UnableToConfigure'));
                catch ME
                    throwAsCaller(ME);
                end
            end
        end
    end
    
    methods( Access = private)
        
        function validateGpsData(obj)
            % The function checks if the data read from serial Device has
            % required NMEA sentences.
            flush(obj.TransportObject);
            [rawData,unparsedData] = getGpsFrame(obj);
            if(~contains(rawData,"RMC") || ~contains(rawData,"GGA") || ~contains(rawData,"GSA"))
                error(message('shared_gps:general:InvalidGPSData'));
            else
                obj.RawData = unparsedData;
            end
        end
        
        function data = readData(obj)
            data = [];
            bytesAvailable = obj.TransportObject.NumBytesAvailable;
            if(bytesAvailable>0)
                data = read(obj.TransportObject,bytesAvailable,'char');
            end
        end
        
        function [rawData,unParsedData] = getGpsFrame(obj)
            idx = [];
            rawData = '';
            unParsedData = [];
            timeout = 5;
            timeForFirstRMC = 0;
            ts = tic;
            while(numel(idx)<2 && toc(ts)< timeout)
                data =  readData(obj);
                if ~isempty(data)
                    unParsedData = [unParsedData,data];
                    idx = strfind(unParsedData,"RMC");
                    if(numel(idx) == 1 && obj.TimeForFirstRMCSet == 0)
                        % time is taken here to get an approximate value of
                        % Update Rate during construction.
                        timeForFirstRMC = toc(ts);
                        obj.TimeForFirstRMCSet = 1;
                    elseif(numel(idx) == 2 && obj.TimeForSecondRMCSet == 0)
                        timeForSecondRMC = toc(ts);
                        obj.TimeForSecondRMCSet = 1;
                        obj.UpdateRate = 1/(timeForSecondRMC-timeForFirstRMC);
                    end
                end
            end
            obj.TimeForFirstRMCSet = 0;
            obj.TimeForSecondRMCSet = 0;
            % check only between two RMC
            if numel(idx)>= 2
                rawData = unParsedData(idx(1):idx(2));
            end
        end
    end
end
