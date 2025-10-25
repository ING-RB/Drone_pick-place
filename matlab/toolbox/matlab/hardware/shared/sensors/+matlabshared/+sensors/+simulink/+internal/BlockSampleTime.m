classdef BlockSampleTime < handle
    %BlockSampleTime Sample time for Simulink blocks.
    
    % Copyright 2021 The MathWorks, Inc.
    
    %#codegen
    
    properties
        %SampleTime Sample time
        SampleTime = -1;
    end
    
    methods
        function obj = BlockSampleTime
            coder.allowpcode('plain');
        end
    end
    
    methods
        function set.SampleTime(obj,newTime)
            coder.extrinsic('error');
            coder.extrinsic('message');
            if (isLocked(obj) && obj.SampleTime ~= newTime)
                error(message('matlab_sensors:general:SampleTimeNonTunable'))
            end
            newTime = matlabshared.sensors.simulink.internal.validateSampleTime(newTime);
            obj.SampleTime = newTime;
        end
    end
    
    methods (Access=protected)
        function st = getSampleTimeImpl(obj)
          if isequal(obj.SampleTime, -1) || isequal(obj.SampleTime, [-1, 0])
            st = matlab.system.SampleTimeSpecification('Type', 'Inherited');
          elseif isequal(obj.SampleTime, [0, 1])
            st = matlab.system.SampleTimeSpecification('Type', 'Fixed In Minor Step');
          else
            if numel(obj.SampleTime) == 1
              sampleTime = obj.SampleTime;
              offset = 0;
            else
              sampleTime = obj.SampleTime(1);
              offset = obj.SampleTime(2);
            end
            st = matlab.system.SampleTimeSpecification('Type', 'Discrete', ...
              'SampleTime', sampleTime, 'Offset', offset);
          end
        end
    end
end

