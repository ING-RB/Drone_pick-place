classdef TotalVolatileOrganicCompounds < handle
    %Base class for gas sensor modules

    %  Copyright 2023 The MathWorks, Inc.

    properties(Abstract, Access = protected, Constant)
        TVOCDataRegister; % output data register
    end

    properties(Access = protected)
        TotalVolatileOrganicCompoundsDataName = {'eTVOC'};
    end

    methods(Abstract,Access = protected)
        data = readTotalVolatileOrganicCompoundsImpl(obj);
        initTotalVolatileOrganicCompoundsImpl(obj);
    end

    methods (Access = private, Static = true)
        function name = matlabCodegenRedirect(~)
            % During code generation, the current class will be replaced by
            % the following class
            name = 'matlabshared.sensors.coder.matlab.TotalVolatileOrganicCompounds';
        end
    end

    methods(Access = public)
        function [data,timeStamp] = readTotalVolatileOrganicCompounds(obj,varargin)
            %   Read one sample of eTVOC from gas sensor along with timestamp.
            %
            %   Syntax:
            %   [eTVOCReadings,timestamp] = readTotalVolatileOrganicCompounds(imu);
            %
            %   Input Argument:
            %   gasSensor - Sensor object.
            %
            %   Output Argument:
            %   TotalVolatileOrganicCompoundsReadings - eTVOC values
            %   read from sensor in units of ppb.
            %
            %   timestamp - the time at which MATLAB® receives TotalVolatileOrganicCompounds data,
            %   specified as a datetime.
            %
            try
                timeStamp = datetime('now','TimeZone','local','Format','d-MMM-y HH:mm:ss.SSS');
                if(isLocked(obj))
                    % if onDemand API is executed while streaming, flush
                    % all buffers and get latest data.
                    dataOut = readLatestFrame(obj);
                    data = dataOut.eTVOC(end,:);
                    %Collect DDUX data for sensors (MATLAB). 
                    %The second argument determines the mode OnDemand /
                    %Streaming / OnDemandWhileStreaming
                    dataUpdateFunction(obj,matlabshared.sensors.internal.Mode.OnDemandWhileStreaming); 
                else
                    [data,~,targetTime] = readTotalVolatileOrganicCompoundsImpl(obj,varargin{:});
                    % Target time will only be returned for streaming case,
                    % Use target time in such instances
                    if ~isempty(targetTime)
                        timeStamp = targetTime;
                    else
                        %Collect DDUX data for sensors (MATLAB). 
                    	%The second argument determines the mode OnDemand /
                        %Streaming / OnDemandWhileStreaming
                        dataUpdateFunction(obj,matlabshared.sensors.internal.Mode.OnDemand);
                    end
                end
            catch ME
                throwAsCaller(ME);
            end
        end
    end
end