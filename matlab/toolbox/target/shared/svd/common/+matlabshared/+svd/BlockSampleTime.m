classdef BlockSampleTime < handle
    %BlockSampleTime Sample time for Simulink blocks.
    
    % Copyright 2015-2023 The MathWorks, Inc.
    
    %#codegen
    
    properties (Abstract)
        %SampleTime Sample time
        SampleTime 
    end
    
    methods
        function obj = BlockSampleTime
            coder.allowpcode('plain');
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

