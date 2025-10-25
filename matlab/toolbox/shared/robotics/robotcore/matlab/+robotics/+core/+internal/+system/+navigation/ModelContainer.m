classdef ModelContainer < matlab.System
    %This class is for internal use only. It may be removed in the future.
    
    %ModelContainer describes a kinematic/dynamic system using
    %state space representation.
    %
    %   The motivation for this class to utilize non-tunable property
    %   setting in matlab.System to enable code-generation
    %
    %   ModelContainer encapsulates a motion model base object.
    %   It contains the NON-TUNABLE data type property, which is necessary
    %   for code generation process.
    %
    %   This class is not directly exposed to the user due to the
    %   complexity involved with MATLAB.System object:
    %       Setup-step scheme is not suitable for user workflow.
    %       Mandatory default constructor doesn't have clear definition
    %
    %   model = robotics.core.internal.system.navigation.ModelContainer()
    %   creates a Multirotor motion model with double precision values used
    %   in input/output/configuration.
    %
    %   model =
    %   robotics.core.internal.system.navigation.ModelContainer(MODELTYPE,
    %   DATATYPE) creates a motion model based on MODELTYPE specification,
    %   with input/output/configuration value typed according to DATATYPE.
    %   Accepted MODELTYPE includes "MultirotorGuidance" and
    %   "FixedWingGuidance". Accepted DATATYPE includes "double" and
    %   "single"
    
    %   Copyright 2018-2024 The MathWorks, Inc.
    
    %#codegen
    
    properties (Dependent)
        %Name - Motion model instance name
        Name
        
        %Configuration - Motion model control and physical parameters
        Configuration
    end
    
    properties
        %ModelImpl - internal implementation of motion models
        ModelImpl
    end
    
    % Non-tunable property requires matlab.System superclass
    properties (SetAccess = private, Nontunable)
        %DataType - Interface and configuration value data type
        %   Non-tunable property is a must to enable code generation
        DataType
        
        %ModelType - Motion model definition type
        ModelType

        %NumInstances - Total number of instances of the model
        %NumInstances
    end
    
    methods
        function obj = ModelContainer(modelType, dataType, numInstances)
            %ModelContainer Construct motion model
            
            if nargin == 0
                % setup default value for optional input modelType
                modelType = 'MultirotorGuidance';
            end
            
            if nargin <= 1
                % setup default value for optional input dataType
                dataType = 'double';                
            end

            if nargin <= 2
                % setup default value for optional input numInstances
                numInstances = 1;
            end
            
            obj.ModelImpl = robotics.core.internal.navigation.ModelFactory.getMotionModel(modelType, dataType, numInstances);
            obj.ModelType = coder.const(char(modelType));
            obj.DataType = coder.const(dataType);
            %obj.NumInstances = coder.const(numInstances);
        end
    end
    
    methods
        function p = get.Name(obj)
            %getter for model instance name
            p = obj.ModelImpl.Name;
        end
        
        function set.Name(obj, p)
            %setter for model instance name
            obj.ModelImpl.Name = p;
        end
        
        function p = get.Configuration(obj)
            %getter for model configuration
            p = obj.ModelImpl.Configuration.toStruct(obj.DataType, 1);
        end
        
        function set.Configuration(obj, config)
            %setter for model configuration
            obj.ModelImpl.Configuration = obj.ModelImpl.Configuration.fromStruct(config, obj.DataType, 1);
        end
    end
    
    methods(Access = protected)
        function loadObjectImpl(obj,s,wasLocked)
            % Set properties in object obj to values in structure s
            
            % Set private and protected properties
            obj.ModelImpl = s.ModelImpl;
            obj.DataType = s.DataType;
            obj.ModelType = s.ModelType;
            %obj.NumInstances = s.NumInstances;
            loadObjectImpl@matlab.System(obj,s,wasLocked);
        end
        
        function s = saveObjectImpl(obj)
            % Set properties in structure s to values in object obj
            
            s = saveObjectImpl@matlab.System(obj);
            
            % Set private and protected properties
            s.ModelImpl = obj.ModelImpl;
            s.DataType = obj.DataType;
            s.ModelType = obj.ModelType;
            %s.NumInstances = obj.NumInstances;
        end
    end
end

