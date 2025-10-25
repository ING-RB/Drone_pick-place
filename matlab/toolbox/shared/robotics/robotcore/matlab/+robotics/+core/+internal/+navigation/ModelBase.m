classdef ModelBase
    %This class is for internal use only. It may be removed in the future.

    %ModelBase provides generic interface for modeling equation of motions.
    %
    %   This class models a state-space based equation of motion, which could
    %   be linear or nonlinear.
    %   The model should be representable as:
    %   \dot{s} = f(s, u, e)
    %   s is a vector containing all the states
    %   u is a value class that contains all the commanded control inputs
    %   e is a value class that contains all the environmental/external
    %   parameters/inputs
    %   
    %   Example:
    %   
    %   Assume that MultirotorModel < ModelBase
    %
    %   >> dataType = 'double';
    %   >> model = MultirotorModel(dataType);
    %   >> s = state(model, 'object', dataType);
    %   >> s.WorldVelocity(:) = [1;1;1];
    %   >> u = control(model, 'object', dataType);
    %   >> u.Roll(:) = 1;
    %   >> e = environment(model, 'object', dataType);
    %   >> sdot = derivative(model, s.toVector(dataType), u, e);
    
    %   Copyright 2018-2024 The MathWorks, Inc.
    
    %#codegen
    
    properties (Abstract)
        %Configuration - serializable class that contains all the parameters needed for the motion model
        Configuration
    end
    
    properties (Abstract, SetAccess = private)
        %Model - read-only string that indicates the motion model type
        Model
    end
    
    properties
        %Name - string that represents the name/identification given to an instance of the motion model
        Name = "Unnamed"
    end
    
    methods (Abstract)
        %derivative - models the equation of motion for the motion model.
        %   The model is represented as \dot{s} = f(s, u, e)
        stateDerivative = derivative(obj, state, control, environment)
    end
    
    methods
        function obj = ModelBase(dataType, numInstances) %#ok<INUSD> due to removed validation
            %ModelBase constructor
            %   Constructor mandates the subclass to allow |dataType| as
            %   input. |dataType| must be 'double' or 'single'
            %   validatestring(dataType, {'double', 'single'}, 'navigation.ModelBase', dataType);
        end
    end
    
    methods
        function u = control(obj, outputFormat, dataType, numInstances)
            %control creates a container of the control inputs.
            %   The control inputs is of |outputFormat|, with all numerics
            %   belong to |dataType|. |outputFormat| could be 'vector',
            %   'struct' or 'object'. |dataType| could be 'double' or
            %   'single'
            uPrototype = controlImpl(obj, dataType, numInstances);
            u = obj.formatOutput(outputFormat, uPrototype, dataType, numInstances);
        end
        
        function s = state(obj, outputFormat, dataType, numInstances)
            %state creates a container of the state.
            %   The state is of |outputFormat|, with all numerics belong to
            %   |dataType|. |outputFormat| could be 'vector', 'struct' or
            %   'object'. |dataType| could be 'double' or 'single'
            sPrototype = stateImpl(obj, dataType, numInstances);
            s = obj.formatOutput(outputFormat, sPrototype, dataType, numInstances);
        end
        
        function e = environment(obj, outputFormat, dataType, numInstances)
            %environment creates a container of the environmental inputs.
            %   The environment inputs is of|outputFormat|, with all
            %   numerics belong to |dataType|. |outputFormat| could be
            %   'vector', 'struct' or 'object'.|dataType| could be 'double'
            %   or 'single'
            ePrototype = environmentImpl(obj, dataType, numInstances);
            e = obj.formatOutput(outputFormat, ePrototype, dataType, numInstances);
        end
    end
    
    methods (Abstract, Access = protected)
        %controlImpl creates a container of the control inputs
        %   Its values are of numeric type |dataType|
        u = controlImpl(obj, dataType, numInstances)
        
        %stateImpl creates a container of the states
        %   Its values are of numeric type |dataType|
        s = stateImpl(obj, dataType, numInstances)
        
        %environmentImpl creates a container of the environmental inputs
        %   Its values are of numeric type |dataType|
        e = environmentImpl(obj, dataType, numInstances)
    end
    
    methods (Access = private, Static)
        function out = formatOutput(outputFormat, input, dataType, numInstances)
            %formatOutput format the output according to |outputFormat|.
            %   The output contains numeric values based on the |input|
            %   container and |dataType|
            switch outputFormat
                case 'vector'
                    out = input.toVector(dataType, numInstances);
                case 'struct'
                    out = input.toStruct(dataType, numInstances);
                case 'object'
                    out = input.cast(dataType, numInstances);
            end
        end
    end
    
end
