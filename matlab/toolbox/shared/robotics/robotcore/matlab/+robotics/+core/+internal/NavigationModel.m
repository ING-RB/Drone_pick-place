classdef NavigationModel < handle
    %This class is for internal use only. It may be removed in the future.
    
    %NavigationModel describes a kinematic/dynamic system using
    %state space representation.
    %   NavigationModel encapsulates a linear/nonlinear state
    %   space model. It provides the compatible input/output interface for
    %   such model and allows user to reconfigure the model's
    %   configurations. User may simulate different robot motions in
    %   discrete or continuous settings with different integration solvers
    %   by integrating the time derivative of states computed by this model
    %
    %   model = robotics.core.internal.NavigationModel(MODELTYPE,
    %   DATATYPE) creates a motion model based on MODELTYPE specification,
    %   with input/output/configuration value typed according to DATATYPE.
    %   Accepted MODELTYPE includes "MultirotorGuidance" and
    %   "FixedWingGuidance". Accepted DATATYPE includes "double" and
    %   "single"
    %
    %   NavigationModel properties:
    %      Configuration - Motion model control and physical parameters
    %      DataType      - Interface and configuration value data type
    %      ModelType     - Motion model definition type 
    %      Name          - Motion model instance name
    %
    %   NavigationModel methods:
    %      control       - Provide control interface template 
    %      copy          - Create a copy of motion model instance 
    %      derivative    - Compute time derivative of the state based on model's equation of motion
    %      environment   - Provide environment interface template 
    %      state         - Provide state interface template
    %
    %   Example:
    %
    %      % construct a Multirotor motion model with double precision interface and computation type 
    %
    %      model = robotics.core.internal.NavigationModel('MultirotorGuidance', 'double');
    %
    %      % set state world XYZ coordinates 
    %      s = state(model);
    %      s(1:3) = [3;2;1];
    %
    %      % set control command Roll and Thrust 
    %      u = control(model); 
    %      u.Roll = 1; 
    %      u.Thrust = 1;
    %
    %      % create environment setting e = model.environment;
    %
    %      % compute time derivative of the state given current state, control and environment
    %      sdot = derivative(model, s, u, e);
    %
    %      % perform simulation using ODE45 integration 
    %      simOut = ode45(@(~,x)derivative(model,x,u,e), [0 1], s);
    
    %   Copyright 2018-2024 The MathWorks, Inc.
    
    %#codegen
    
    properties (Dependent)
        %Name - Motion model instance name
        Name
        
        %Configuration - Motion model control and physical parameters
        Configuration
    end
    
    properties (SetAccess = private, Dependent)
        %ModelType - Motion model definition type
        ModelType
        
        %DataType - Interface and configuration value data type
        DataType
   end

   properties (Access = {?robotics.core.internal.NavigationModel, ?matlab.unittest.TestCase})
        %ModelContainer - internal implementation of motion models
        ModelContainer
        
        %ControlTemplate - internal template of motion model control inputs
        ControlTemplate
        
        %EnvironmentTemplate -internal template of motion model environment
        %inputs
        EnvironmentTemplate
        
        %StateTemplate - internal template of motion model states
        StateTemplate
        
        %ConfigurationTemplate - internal template of motion model
        %configuration
        ConfigurationTemplate
    end
    
    methods
        function obj = NavigationModel(modelType, dataType)
            %NavigationModel Construct motion model
            
            narginchk(1,2);
            
            % validate input modelType
            % output from extrinsic function is later const folded, so it works in both mex and dll
            coder.extrinsic('fields');
            modelList = robotics.core.internal.navigation.ModelListSingleton.getInstance().Models;
            modelType = coder.const(validatestring(modelType, ...
                fields(modelList)', ...
                'robotics.core.internal.NavigationModel', 'modelType'));
            
            if nargin == 1
                % setup default value for optional input dataType
                dataType = 'double';
            else
                % validate input dataType
                dataType = coder.const(validatestring(dataType, {'double', 'single'}, ...
                    'robotics.core.internal.NavigationModel', 'dataType'));
            end

            % The number of instances is by default set to as 1, as
            % we are supporting just single instance implementation for
            % now.
        
            numInstances = 1;
            % default constructor is required for system object
            obj.ModelContainer = robotics.core.internal.system.navigation.ModelContainer(modelType, dataType, numInstances);
            
            obj.ControlTemplate = control(obj.ModelContainer.ModelImpl, 'struct', obj.DataType, numInstances);
            obj.EnvironmentTemplate = environment(obj.ModelContainer.ModelImpl, 'struct', obj.DataType, numInstances);
            obj.StateTemplate = state(obj.ModelContainer.ModelImpl, 'vector', obj.DataType, numInstances);
            obj.ConfigurationTemplate = obj.ModelContainer.ModelImpl.Configuration.toStruct(obj.DataType, numInstances);
        end
    end
    
    methods
        function stateDerivative = derivative(obj, stateVector, controlStruct, environmentStruct)
            %derivative Compute time derivative of the state based on
            %model's equation of motion
            %   STATEDERIVATIVE = derivative(OBJ, STATEVECTOR,
            %   CONTROLSTRUCT, ENVIRONMENTSTRUCT) expects state as vector
            %   of the same size and type as obj.state; control as struct
            %   of the same field format as obj.control; and environment as
            %   struct of the same field format as obj.environment.
            
            % Perform input validation
            validateattributes(stateVector, {obj.DataType}, ...
                {'size', size(obj.StateTemplate)}, 'NavigationModel.derivative', 'stateVector');
            validateattributes(controlStruct, {'struct'}, ...
                {'scalar'}, 'NavigationModel.derivative', 'controlStruct');
            validateattributes(environmentStruct, {'struct'}, ...
                {'scalar'}, 'NavigationModel.derivative', 'environmentStruct');
            
            numInstances = 1;
            % Compute state derivative using model implementation
            stateDerivative = obj.ModelContainer.ModelImpl.derivative(...
                numInstances, stateVector, controlStruct, environmentStruct);
        end
        
        function u = control(obj)
            %control Provide control interface template
            %   U = control(OBJ) returns a struct as the control interface
            %   template with supported field names. The struct field
            %   values are initialized with compatible size and data type.
            u = obj.ControlTemplate;
        end
        
        function s = state(obj)
            %state Provide state interface template
            %   S = state(OBJ) returns a vector as the state interface
            %   template with supported field names. The vector is
            %   initialized with correct size and data type
            s = obj.StateTemplate;
        end
        
        function e = environment(obj)
            %environment Provide environment interface template
            %   E = environment(OBJ) returns a struct as the environment
            %   interface template with supported field names. The struct
            %   field values are initialized with compatible size and data
            %   type.
            e = obj.EnvironmentTemplate;
        end
        
        function newObj = copy(obj)
            %copy Create a copy of motion model instance
            %   NEWOBJ = copy(OBJ) returns a deep copy of the
            %   NavigationModel object with same properties
            newObj = getModelWithDefaultConfiguration(obj);
            newObj.Name = obj.Name;
            newObj.Configuration = obj.Configuration;
        end
    end
    
    methods
        function p = get.Name(obj)
            %getter for model instance name
            p = obj.ModelContainer.Name;
        end
        
        function set.Name(obj, p)
            %setter for model instance name
            obj.ModelContainer.Name = p;
        end
        
        function p = get.Configuration(obj)
            %getter for model configuration
            p = obj.ModelContainer.Configuration;
        end
        
        function set.Configuration(obj, config)
            %setter for model configuration
            robotics.internal.validation.validateStructAgainstTemplate(config, obj.ConfigurationTemplate, 'Configuration', 'config');
            obj.ModelContainer.Configuration = config;
        end
    end
    
    methods
        function p = get.ModelType(obj)
            %getter for model type
            p = obj.ModelContainer.ModelType;
        end
        
        function p = get.DataType(obj)
            %getter for model type
            p = obj.ModelContainer.DataType;
        end

    end
    
    methods (Access=protected)
        function model = getModelWithDefaultConfiguration(obj)
            %getModelWithDefaultConfiguration create a navigation model of
            %same model type and data type

            model = robotics.core.internal.NavigationModel(obj.ModelType, obj.DataType);
        end
    end
    
end

