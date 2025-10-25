classdef (Sealed) Fzero < optim.options.SingleAlgorithm
%

%Fzero Options for FZERO
%
%   The OPTIM.OPTIONS.FZERO class allows the user to create a set of
%   options for the FZERO solver. For a list of options that can be
%   set, see the documentation for FZERO.
%
%   OPTS = OPTIM.OPTIONS.FZERO creates a set of options for
%   FZERO with the options set to their default values.
%
%   OPTS = OPTIM.OPTIONS.FZERO(PARAM, VAL, ...) creates a set of
%   options for FZERO with the named parameters altered with the
%   specified values.
%
%   OPTS = OPTIM.OPTIONS.FZERO(OLDOPTS, PARAM, VAL, ...) creates a
%   copy of OLDOPTS with the named parameters altered with the specified
%   values.
%
%   See also OPTIM.OPTIONS.SINGLEALGORITHM, OPTIM.OPTIONS.SOLVEROPTIONS

%   Copyright 2019-2022 The MathWorks, Inc.
    
    properties (Dependent)       
%DISPLAY Level of display
        Display
          
%OUTPUTFCN Callbacks that are called at each iteration
        OutputFcn
     
%PLOTFCN Plots various measures of progress while the algorithm executes
        PlotFcn

%STEPTOLERANCE Termination tolerance on x
        StepTolerance        
    end
    
    properties(Hidden, Dependent)
        %FUNVALCHECK Check whether objective function and constraints values are
        %            valid
        FunValCheck
        
        %PLOTFCNS Plots various measures of progress while the algorithm executes
        PlotFcns
        
        %TOLX Termination tolerance on x
        TolX
    end
    
    properties (SetAccess = private, GetAccess = private)
        FzeroVersion
    end
    
    properties (Hidden, Access = protected)
%OPTIONSSTORE Contains the option values and meta-data for the class
%         
        OptionsStore = createOptionsStore;
    end
    
    properties (Hidden)
%SOLVERNAME Name of the solver that the options are intended for
%         
        SolverName = 'fzero';
    end
    
        properties(Hidden, GetAccess=public)
% Globally visible metadata about this class.
% This data is used to spec the options in this class for internal clients
% such as: tab-complete, and the options validation
% Properties
        PropertyMetaInfo = genPropInfo();    
    end
    
    methods (Hidden)
        
        function obj = Fzero(varargin)
%Fzero Options for FZERO
%
%   The OPTIM.OPTIONS.FZERO class allows the user to create a set of
%   options for the FZERO solver. For a list of options that can be
%   set, see the documentation for FZERO.
%
%   OPTS = OPTIM.OPTIONS.FZERO creates a set of options for
%   FZERO with the options set to their default values.
%
%   OPTS = OPTIM.OPTIONS.FZERO(PARAM, VAL, ...) creates a set of
%   options for FZERO with the named parameters altered with the
%   specified values.
%
%   OPTS = OPTIM.OPTIONS.FZERO(OLDOPTS, PARAM, VAL, ...) creates a
%   copy of OLDOPTS with the named parameters altered with the specified
%   values.
%
%   See also OPTIM.OPTIONS.SINGLEALGORITHM, OPTIM.OPTIONS.SOLVEROPTIONS
            
            % Call the superclass constructor
            obj = obj@optim.options.SingleAlgorithm(varargin{:});
            
            % Record the class version. Do not change Version, change
            % FzeroVersion instead.
            obj.Version = 1;
            
            obj.FzeroVersion = 1;
            
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
        
        function obj = set.OutputFcn(obj, value)
            obj = setProperty(obj, 'OutputFcn', value);
        end
 
        function obj = set.PlotFcn(obj, value)
            obj = setAliasProperty(obj, 'PlotFcn', 'PlotFcns', value);        
        end 
        
        function obj = set.PlotFcns(obj, value)
            obj = setProperty(obj, 'PlotFcns', value);
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
        
        function value = get.OutputFcn(obj)
            value = obj.OptionsStore.Options.OutputFcn;
        end
       
        function value = get.PlotFcn(obj)
            value = obj.OptionsStore.Options.PlotFcns;
        end
        
        function value = get.PlotFcns(obj)
            value = obj.OptionsStore.Options.PlotFcns;
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
%   the full OptionsStore. See below for an example for Fzero.

% Define the option defaults for the solver
OS.Defaults.Display = 'notify';
OS.Defaults.FunValCheck = 'off';
OS.Defaults.OutputFcn = [];
OS.Defaults.PlotFcns = [];
OS.Defaults.TolX = eps;

% Call the package function to generate the OptionsStore
OS = optim.options.generateSingleAlgorithmOptionsStore(OS);

end

function propInfo = genPropInfo()
% Helper function to generate property metadata for the Fzero options
% class.
import optim.options.meta.Factory
import optim.options.meta.category
import optim.options.meta.label

% fzero also accepts 'none', 'iter-detailed', 'notify-detailed', 'final-detailed'
% If this options class is made public, these values must be added below
propInfo.Display = Factory.displayType({'off','iter','notify','final'});
propInfo.OutputFcn = Factory.outputFcnType;
propInfo.PlotFcn = Factory.plotFcnType({'optimplotx','optimplotfunccount','optimplotfval'});
propInfo.StepTolerance = Factory.stepToleranceType;

% Hidden options
propInfo.FunValCheck = Factory.onOffType(label('FunValCheck'),category('Diagnostic'));
propInfo.TolX = propInfo.StepTolerance;
propInfo.PlotFcns = propInfo.PlotFcn;

end
