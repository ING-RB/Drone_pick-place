classdef (StrictDefaults) StateVector2Struct < matlab.System
    %This class is for internal use only. It may be removed in the future.

    %StateVector2Struct translates vectorized states of motion model into
    % struct format and output as bus in Simulink
    
    %   Copyright 2018-2024 The MathWorks, Inc.

    %#codegen
    
    properties(Nontunable)
        %OutputBusName - Name of the output Simulink.Bus type
        OutputBusName = 0
        
        %ModelType - Motion model type
        ModelType = 0
        
        %DataType - Output type for the elements in Simulink.Bus
        DataType = 0

        %NumInstances - Number of instances of the guidance model.
        NumInstances = 1;
    end
    
    properties(Access = private)
        %OutputTemplate - the template used for serializing the states from
        %vector to struct
        OutputTemplate
    end
    
    methods
        function out = copy(obj)
            %copy implements deep copy
            out = robotics.core.internal.system.navigation.StateVector2Struct;
            out.OutputBusName = obj.OutputBusName;
            out.ModelType = obj.ModelType;
            out.DataType = obj.DataType;
            out.NumInstances = obj.NumInstances;
            out.OutputTemplate = obj.OutputTemplate;
        end
    end
    
    methods (Access=?matlab.unittest.TestCase)
        function outputTemplate = getOutputTemplate(obj)
            %getOutputTemplate provide access to private methods for
            %testing
            outputTemplate = obj.OutputTemplate;
        end
    end
    
    methods (Access=protected)
        
        function setupImpl(obj)
            %setupImpl constructs the state template used for serialization
            
            obj.reset();
            
        end

        function resetImpl(obj)
            %resetImpl initialize / reset discrete-state properties
            
            model = robotics.core.internal.navigation.ModelFactory.getMotionModel(obj.ModelType, obj.DataType, obj.NumInstances);
            obj.OutputTemplate = state(model, 'object', obj.DataType, obj.NumInstances);
        end
        
        function out = stepImpl(obj, s)          
            %stepImpl translates input vector to a struct defined by
            %OutputTemplate
            
            outObject = obj.OutputTemplate.fromVector(s, obj.DataType, obj.NumInstances);
            out = outObject.toStruct(obj.DataType, obj.NumInstances);
            
        end
        
        function out = getOutputSizeImpl(~)
            %getOutputSizeImpl output is a Simulink.Bus type
            out = [1 1];
        end
        
        function out = isOutputComplexImpl(~)
            %isOutputComplexImpl output is a Simulink.Bus type
            out = false;
        end
        
        function out = getOutputDataTypeImpl(obj)
            %getOutputDataTypeImpl output is a Simulink.Bus type with given name
            out = obj.OutputBusName;
        end
        
        function out = isOutputFixedSizeImpl(~)
            %isOutputFixedSizeImpl output is fixed sized
            out = true;
        end
        
    end
end
