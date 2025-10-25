classdef (Sealed) Fminsearch < optim.options.SingleAlgorithm
%

%Fminsearch Options for FMINSEARCH
%
%   The OPTIM.OPTIONS.FMINSEARCH class allows the user to create a set of
%   options for the FMINSEARCH solver. For a list of options that can be
%   set, see the documentation for FMINSEARCH.
%
%   OPTS = OPTIM.OPTIONS.FMINSEARCH creates a set of options for
%   FMINSEARCH with the options set to their default values.
%
%   OPTS = OPTIM.OPTIONS.FMINSEARCH(PARAM, VAL, ...) creates a set of
%   options for FMINSEARCH with the named parameters altered with the
%   specified values.
%
%   OPTS = OPTIM.OPTIONS.FMINSEARCH(OLDOPTS, PARAM, VAL, ...) creates a
%   copy of OLDOPTS with the named parameters altered with the specified
%   values.
%
%   See also OPTIM.OPTIONS.SINGLEALGORITHM, OPTIM.OPTIONS.SOLVEROPTIONS

%   Copyright 2019-2022 The MathWorks, Inc.
    
    properties (Dependent)       
%DISPLAY Level of display
        Display
        
%MAXFUNCTIONEVALUATIONS Maximum number of function evaluations allowed   
        MaxFunctionEvaluations
        
%MAXITERATIONS Maximum number of iterations allowed 
        MaxIterations

%OUTPUTFCN Callbacks that are called at each iteration
        OutputFcn
                
%PLOTFCN Plots various measures of progress while the algorithm executes
        PlotFcn
        
%FUNCTIONTOLERANCE Termination tolerance on the function value
        FunctionTolerance

%STEPTOLERANCE Termination tolerance on the change in x
        StepTolerance
        
    end
    
    properties(Hidden, Dependent)
        %FUNVALCHECK Check whether objective function and constraints values are
        %            valid
        FunValCheck
        
        %MAXFUNEVALS Maximum number of function evaluations allowed
        MaxFunEvals
        
        %MAXITER Maximum number of iterations allowed
        MaxIter
        
        %PLOTFCNS Plots various measures of progress while the algorithm executes
        PlotFcns
        
        %TOLFUN Termination tolerance on the function value
        TolFun
        
        %TOLX Termination tolerance on x
        TolX
    end
    
    properties (SetAccess = private, GetAccess = private)
        FminsearchVersion
    end
    
    properties (Hidden, Access = protected)
%OPTIONSSTORE Contains the option values and meta-data for the class
%         
        OptionsStore = createOptionsStore;
    end
    
    properties (Hidden)
%SOLVERNAME Name of the solver that the options are intended for
%         
        SolverName = 'fminsearch';
    end
    
        properties(Hidden, GetAccess=public)
% Globally visible metadata about this class.
% This data is used to spec the options in this class for internal clients
% such as: tab-complete, and the options validation
% Properties
        PropertyMetaInfo = genPropInfo();    
    end
    
    methods (Hidden)
        
        function obj = Fminsearch(varargin)
%Fminsearch Options for FMINSEARCH
%
%   The OPTIM.OPTIONS.FMINSEARCH class allows the user to create a set of
%   options for the FMINSEARCH solver. For a list of options that can be
%   set, see the documentation for FMINSEARCH.
%
%   OPTS = OPTIM.OPTIONS.FMINSEARCH creates a set of options for
%   FMINSEARCH with the options set to their default values.
%
%   OPTS = OPTIM.OPTIONS.FMINSEARCH(PARAM, VAL, ...) creates a set of
%   options for FMINSEARCH with the named parameters altered with the
%   specified values.
%
%   OPTS = OPTIM.OPTIONS.FMINSEARCH(OLDOPTS, PARAM, VAL, ...) creates a
%   copy of OLDOPTS with the named parameters altered with the specified
%   values.
%
%   See also OPTIM.OPTIONS.SINGLEALGORITHM, OPTIM.OPTIONS.SOLVEROPTIONS
            
            % Call the superclass constructor
            obj = obj@optim.options.SingleAlgorithm(varargin{:});
            
            % Record the class version. Do not change Version, change
            % FminsearchVersion instead.
            obj.Version = 1;
            
            obj.FminsearchVersion = 1;
            
        end

    end
    
    % Set/get methods
    methods

        % ---------------------- Set methods ------------------------------
        function obj = set.Display(obj, value)
            % Pass the possible values that the Display option can take via
            % the fourth input of setProperty.            
            obj = setProperty(obj, 'Display', value);
        end

        function obj = set.FunValCheck(obj, value)
            obj = setProperty(obj, 'FunValCheck', value);
        end        
        
        function obj = set.MaxIter(obj, value)
            obj = setProperty(obj, 'MaxIter', value);
        end
               
        function obj = set.MaxIterations(obj, value)
            obj = setAliasProperty(obj, 'MaxIterations', 'MaxIter', value);        
        end        

        function obj = set.MaxFunEvals(obj, value)
            obj = setProperty(obj, 'MaxFunEvals', value);
        end
        
        function obj = set.MaxFunctionEvaluations(obj, value)
            obj = setAliasProperty(obj, 'MaxFunctionEvaluations', 'MaxFunEvals', value);        
        end   

        function obj = set.OutputFcn(obj, value)            
            obj = setProperty(obj, 'OutputFcn', value);
        end
 
        function obj = set.PlotFcn(obj, value)
            obj = setAliasProperty(obj, 'PlotFcn', 'PlotFcns', value);        
        end 
        
        function obj = set.PlotFcns(obj, value)
            obj = setProperty(obj, 'PlotFcns', value);
        end
        
        function obj = set.FunctionTolerance(obj, value)
            obj = setAliasProperty(obj, 'FunctionTolerance', 'TolFun', value);        
        end          
        
        function obj = set.TolFun(obj, value)
            obj = setProperty(obj, 'TolFun', value);
        end

        function obj = set.StepTolerance(obj, value)
            obj = setAliasProperty(obj, 'StepTolerance', 'TolX', value);
        end
        
        function obj = set.TolX(obj, value)
            obj = setProperty(obj, 'TolX', value);
        end
 
        % ---------------------- Get methods ------------------------------
  
        function value = get.Display(obj)
            value = obj.OptionsStore.Options.Display;
        end

        function value = get.FunValCheck(obj)
            value = obj.OptionsStore.Options.FunValCheck;
        end
        
       function value = get.MaxIterations(obj)
            value = obj.OptionsStore.Options.MaxIter;
        end
        
        function value = get.MaxIter(obj)
            value = obj.OptionsStore.Options.MaxIter;
        end
        
        function value = get.MaxFunctionEvaluations(obj)
            value = obj.OptionsStore.Options.MaxFunEvals;
        end
        
        function value = get.MaxFunEvals(obj)
            value = obj.OptionsStore.Options.MaxFunEvals;
        end     
               
        function value = get.OutputFcn(obj)
            value = obj.OptionsStore.Options.OutputFcn;
        end
       
        function value = get.PlotFcn(obj)
            value = obj.OptionsStore.Options.PlotFcns;
        end
        
        function value = get.PlotFcns(obj)
            value = obj.OptionsStore.Options.PlotFcns;
        end
      
        function value = get.FunctionTolerance(obj)
            value = obj.OptionsStore.Options.TolFun;
        end 
        
        function value = get.TolFun(obj)
            value = obj.OptionsStore.Options.TolFun;
        end
     
        function value = get.StepTolerance(obj)
            value = obj.OptionsStore.Options.TolX;
        end
        
        function value = get.TolX(obj)
            value = obj.OptionsStore.Options.TolX;
        end    
    end    

end

function OS = createOptionsStore
%CREATEOPTIONSSTORE Create the OptionsStore
%
%   OS = createOptionsStore creates the OptionsStore structure. This
%   structure contains the options and meta-data for option display, e.g.
%   data determining whether an option has been set by the user. This
%   function is only called when the class is first instantiated to create
%   the OptionsStore structure in its default state. Subsequent
%   instantiations of this class pick up the default OptionsStore from the
%   MCOS class definition.
%
%   Class authors must create a structure containing all the options in a
%   field of OS called Defaults. This structure must then be passed to the
%   optim.options.generateSingleAlgorithmOptionsStore function to create
%   the full OptionsStore. See below for an example for Fminsearch.

% Define the option defaults for the solver
OS.Defaults.Display = 'notify';
OS.Defaults.FunValCheck = 'off';
OS.Defaults.MaxFunEvals = '200*numberOfVariables';
OS.Defaults.MaxIter = '200*numberOfVariables';
OS.Defaults.OutputFcn = [];
OS.Defaults.PlotFcns = [];
OS.Defaults.TolFun = 1e-4;
OS.Defaults.TolFunValue = 1e-4;
OS.Defaults.TolX = 1e-4;

% Call the package function to generate the OptionsStore
OS = optim.options.generateSingleAlgorithmOptionsStore(OS);

end

function propInfo = genPropInfo()
% Helper function to generate property metadata for the Fminsearch options
% class.
import optim.options.meta.Factory
import optim.options.meta.category
import optim.options.meta.label

% fminsearch also accepts 'none', 'iter-detailed', 'notify-detailed',
% 'final-detailed', 'simplex'
% If this options class is made public, these values must be added below
propInfo.Display = Factory.displayType({'off','iter','notify','final'});
propInfo.MaxFunctionEvaluations = Factory.maxFunEvalsType;
propInfo.MaxIterations = Factory.maxIterType;
propInfo.OutputFcn = Factory.outputFcnType;
propInfo.PlotFcn = Factory.plotFcnType({'optimplotx','optimplotfunccount','optimplotfval'});
propInfo.FunctionTolerance = Factory.functionToleranceType;
propInfo.StepTolerance = Factory.stepToleranceType;

% Hidden options
propInfo.FunValCheck = Factory.onOffType(label('FunValCheck'),category('Diagnostic'));
propInfo.MaxFunEvals = propInfo.MaxFunctionEvaluations;
propInfo.MaxIter = propInfo.MaxIterations;
propInfo.TolFun = propInfo.FunctionTolerance;
propInfo.TolX = propInfo.StepTolerance;
propInfo.PlotFcns = propInfo.PlotFcn;

end
