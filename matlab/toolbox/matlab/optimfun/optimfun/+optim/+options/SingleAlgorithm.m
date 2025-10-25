classdef (Abstract) SingleAlgorithm < optim.options.SolverOptions
%

%SingleAlgorithm Options for Optimization Toolbox solvers with only one
%                algorithm
%
%   SingleAlgorithm is an abstract class representing a set of options for
%   an Optimization Toolbox solver, where the solver only has one
%   algorithm. You cannot create instances of this class directly. You must
%   create an instance of a derived class such optim.options.Fgoalattain.
%
%   See also OPTIM.OPTIONS.SOLVEROPTIONS

%   Copyright 2012-2024 The MathWorks, Inc.

    % Constructor
    methods (Hidden)
        function obj = SingleAlgorithm(varargin)
%SINGLEALGORITHM Construct a new SingleAlgorithm object
%
%   OPTS = OPTIM.OPTIONS.SINGLEALGORITHM creates a set of options with each
%   option set to its default value.
%
%   OPTS = OPTIM.OPTIONS.SINGLEALGORITHM(PARAM, VAL, ...) creates a set of
%   options with the named parameters altered with the specified values.
%
%   OPTS = OPTIM.OPTIONS.SINGLEALGORITHM(OLDOPTS, PARAM, VAL, ...) creates
%   a copy of OLDOPTS with the named parameters altered with the specified
%   value

            % Call the superclass constructor
            obj = obj@optim.options.SolverOptions(varargin{:});
               
        end
    end
    
    methods (Hidden, Access = protected)
              
        function algOptions = getDisplayOptions(obj)
%GETDISPLAYOPTIONS Get the options to be displayed
%
%   ALGOPTIONS = GETDISPLAYOPTIONS(OBJ) returns a cell array of options to
%   be displayed. For solver objects that inherit from SingleAlgorithm, all
%   options are displayed.
            
            algOptions = properties(obj);
        end
        
    end
    
    methods (Hidden)
        function OptionsStruct = extractCustomOptionsStructure(obj)
%EXTRACTCUSTOMOPTIONSSTRUCTURE Extract options structure from OptionsStore
%
%   OPTIONSSTRUCT = EXTRACTCUSTOMOPTIONSSTRUCTURE(OBJ) extracts a plain
%   structure containing the options from obj.OptionsStore. The solver
%   calls convertForSolver, which in turn calls this method to obtain a
%   plain options structure.
            
            % Replace any special strings in the options object
            obj = replaceSpecialStrings(obj);

            % Extract the main options structure
            OptionsStruct = obj.OptionsStore.Options;
            
        end
    end
    
    methods (Hidden, Access = private)
        
        function numSetByUser = numDisplayOptionsSetByUser(obj)
%NUMDISPLAYOPTIONSSETBYUSER Return number of display options set by user
%
%   NUMSETBYUSER = NUMDISPLAYOPTIONSSETBYUSER(OBJ) returns the number of
%   display options that have been set by the user.
            
            % Get names of all the properties for the current algorithm.
            % This is the same as the options that are displayed.
            allOptions = properties(obj);
            
            % Determine the number of these properties that are set by the
            % user
            numSetByUser = 0;
            for i = 1:length(allOptions)
                if obj.OptionsStore.SetByUser.(optim.options.OptionAliasStore.getAlias(allOptions{i}, obj.SolverName, obj.OptionsStore.Options))
                    numSetByUser = numSetByUser + 1;
                end
            end
        end
        
    end
   
    
    % Public informal interface methods
    methods
        
        function obj = resetoptions(obj, name)
%RESETOPTIONS Reset optimization options
%
%   OPTS = RESETOPTIONS(OPTS,'option') resets the specified option back to
%   its default value.
%
%   OPTS = RESETOPTIONS(OPTS,OPTIONS) resets more than one option at a time
%   when OPTIONS is a cell array of strings.  
%
%   See also OPTIMOPTIONS.             

            % Validate the option names passed by the user
            name = validateResetOptions(obj, name);
            
            % Loop through each option and reset to default
            for i = 1:numel(name)
                OptionStoredName = optim.options.OptionAliasStore.getAlias(name{i}, obj.SolverName, obj.OptionsStore.Options);
                obj.OptionsStore.SetByUser.(OptionStoredName) = false;
                obj.OptionsStore.Options.(OptionStoredName) = ...
                    obj.OptionsStore.Defaults.(OptionStoredName);
            end
            
        end
        
    end    
    
end
