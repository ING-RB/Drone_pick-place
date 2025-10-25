classdef EquivalentCarbondioxide < handle
    %Base class for gas sensor modules

    %  Copyright 2023 The MathWorks, Inc.

    properties(Abstract, Access = protected, Constant)
        EquivalentCarbondioxideDataRegister; % output data register
    end

    properties(Access = protected)
        EquivalentCarbondioxideDataName = {'eCO2'};
    end

    methods(Abstract,Access = protected)
        data = readEquivalentCarbondioxideImpl(obj);
        initEquivalentCarbondioxideImpl(obj);
    end

    methods (Access = private, Static = true)
        function name = matlabCodegenRedirect(~)
            % During code generation, the current class will be replaced by
            % the following class
            name = 'matlabshared.sensors.coder.matlab.EquivalentCarbondioxide';
        end
    end

    methods(Access = public)
        function [data,timeStamp] = readEquivalentCarbondioxide(obj,varargin)
            %   Read one sample of eCO2 from gas sensor along with timestamp.
            %
            %   Syntax:
            %   [eCO2Readings,timestamp] = readEquivalentCarbondioxide(gasSensor);
            %
            %   Input Argument:
            %   gasSensor - Sensor object.
            %
            %   Output Argument:
            %   eCO2Readings - EquivalentCarbondioxide values
            %   read from sensor in units of ppm.
            %
            %   timestamp - the time at which MATLAB® receives eCO2 data,
            %   specified as a datetime.
            %
            try
                timeStamp = datetime('now','TimeZone','local','Format','d-MMM-y HH:mm:ss.SSS');
                if(isLocked(obj))
                    % if onDemand API is executed while streaming, flush
                    % all buffers and get latest data.
                    dataOut = readLatestFrame(obj);
                    data = dataOut.eCO2(end,:);
                    %Collect DDUX data for sensors (MATLAB). 
                    %The second argument determines the mode OnDemand /
                    %Streaming / OnDemandWhileStreaming
                    dataUpdateFunction(obj,matlabshared.sensors.internal.Mode.OnDemandWhileStreaming);
                else
                    [data,~,targetTime] = readEquivalentCarbondioxideImpl(obj,varargin{:});
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