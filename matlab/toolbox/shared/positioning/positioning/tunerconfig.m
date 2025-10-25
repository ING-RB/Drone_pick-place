classdef tunerconfig < matlab.mixin.CustomDisplay
% TUNERCONFIG - Fusion filter tuner options
%   CONFIG = TUNERCONFIG(FILTCLS) creates a TUNERCONFIG object for
%   controlling the optimization algorithm of the TUNE function. The input
%   FILTCLS is the class name of the filter to be optimized by TUNE and
%   controls the default values of the object.
%
%   CONFIG = TUNERCONFIG(FILTOBJ) creates a TUNERCONFIG object based on the
%   class of the filter FILTOBJ. FILTEROBJ is the handle to a filter class.
%
%   CONFIG = TUNERCONFIG(..., PARAM1, VALUE1, ...) creates a
%   TUNERCONFIG object with each property set to a specified value.
%
%   TUNERCONFIG properties:
%
%   Filter              - Class of the filter being tuned
%   TunableParameters   - Filter parameters to optimize
%   StepForward         - Parameter-increase factor during tuning steps 
%   StepBackward        - Parameter-decrease factor during tuning steps
%   MaxIterations       - Maximum number of iterations 
%   ObjectiveLimit      - Cost at which to stop optimization early
%   FunctionTolerance   - Minimum change in cost to continue tuning
%   Display             - Verbosity of display during filter tuning
%   Cost                - Metric for evaluating filter performance
%   CustomCostFcn       - Custom defined cost metric for tuning
%   OutputFcn           - User-defined function to be called each iteration
%
%   Example: 
%   
%       tc1 = tunerconfig('imufilter');
%       tc2 = tunerconfig(imufilter);
%
%   See also TUNERNOISE

%   Copyright 2020-2021 The MathWorks, Inc.      

    properties (Dependent, SetAccess = protected)
        % Filter Class of the filter being tuned
        % Filter is the class name used to create the tunerconfig object.
        Filter
    end

    properties
        % TunableParameters Parameters to optimize 
        % Specify noise names and optional indices to optimize through the
        % TUNE function. To tune each noise property specify the
        % TunableParameters as a string array or cell array of character
        % vectors of noise property names. All elements of a single noise
        % property will scaled up or down by the same amount.
        % Alternatively, to tune individual elements of a noise property
        % array, specify the TunableParameters as a cell array noise
        % property names and/or 1-by-2 cells. For each 1-by-2 cell, the
        % first element is the name of the noise property and the second
        % element is a vector containing the indices of the property to
        % tune.
        TunableParameters = ""

        % StepForward Factor by which to increase a parameter in one step.
        % During the coordinate ascent tuning algorithm, noise parameters
        % are increased and decreased. Specify the factor by which a
        % parameter should be increased when the metric is decreasing.
        StepForward(1,1) {mustBeFinite, mustBeNonempty, mustBeReal, mustBeGreaterThan(StepForward,1)}= 1.1

        % StepBackward Factor by which to decrease a parameter in one step.
        % During the coordinate ascent tuning algorithm, noise parameters
        % are increased and decreased. Specify the factor by which a
        % parameter should be decreased when the metric is increasing.
        StepBackward(1,1) {mustBeFinite, mustBePositive, mustBeNonempty, mustBeReal, mustBeLessThan(StepBackward,1)} = 0.5

        % MaxIterations Maximum number of iterations to optimize parameters 
        % Maximum number of iterations each parameter will be optimized in the
        % tuning algorithm. A single iteration will try to improve the value of
        % each parameter once. Specify a positive integer number of iterations. 
        MaxIterations(1,1) {mustBeFinite, mustBePositive, mustBeNonempty, mustBeInteger} = 20

        % ObjectiveLimit Cost at which to stop optimization early
        % Specify the cost at which the coordinate ascent algorithm will
        % terminate prior to MaxIterations. 
        ObjectiveLimit(1,1) {mustBeFinite, mustBePositive, mustBeNonempty, mustBeReal}= 1e-1

        % FunctionTolerance Minimum change in cost to continue tuning
        % Specify the minimum absolute change in cost from one iteration
        % to the next to continue tuning of the filter
        FunctionTolerance(1,1) {mustBeFinite, mustBeNonnegative, mustBeNonempty, mustBeReal}= 0 

        % Display Verbosity of display during filter tuning
        % Specify the verbosity of the display echoed to the Command Window
        % during filter tuning. Setting Display to a value of 'iter' will
        % show the cost at each iteration of the coordinate ascent. Setting
        % the Display to 'none' will not report anything during the ascent.
        Display fusion.internal.tuner.DisplayChoices = "iter"

        % Cost Metric to use for evaluating the filter performance
        % Specify the cost metric to use when optimizing the filter
        % performance during tuning. Set the Cost property to 'RMS' to
        % optimize the RMS error. Set the Cost property to 'Custom' to
        % specify an alternate cost metric using the CustomCostFcn
        % property.
        Cost fusion.internal.tuner.CostChoices = "RMS"

        % CustomCostFcn Custom cost metric for tuning 
        % Specify a function handle to use for evaluating the performance
        % of the filter during each step of the coordinate ascent
        % optimization. The function takes three input arguments : a struct
        % containing the current best filter parameters, the input sensor
        % data, and the input ground truth. The function should return a
        % scalar numeric value indicating the cost of these filter
        % parameters, typically a measure of the difference between the
        % filter estimate and ground truth. This property is only valid
        % when the Cost property is set to 'Custom'.
        CustomCostFcn

        % OutputFcn User-defined function to be called at each iteration
        % Specify a function handle to be called at the end of each
        % iteration. For example, the function can be used to log or plot
        % data, or terminate the tuning.  The function takes two inputs, a
        % struct containing the current best filter parameters and a second
        % struct containing several fields related to the tuning, including
        % the input sensor data and ground truth. The function returns
        % false if tuning should continue and returns true if the tuning should
        % stop.
        OutputFcn
    end
    
    properties (Hidden)
        % UseMex Use mex accelerated version of filters for tuning. The
        % default value of this property is true. This property has no
        % effect if a CustomCostFcn is used.
        UseMex logical = true;
    end

    properties (Access = protected)
        FilterClass
        AllowedTunableParameters
    end

    methods
        function obj = tunerconfig(flt, varargin)
            obj = addFilter(obj, flt);
            if ~isempty(varargin)
                obj = matlabshared.fusionutils.internal.setProperties(obj, ...
                    nargin-1, varargin{:}); 
            end
        end

        function obj = set.Filter(obj, val)
            obj.FilterClass = string(val);
        end
        function x = get.Filter(obj)
            x = string(obj.FilterClass);
        end

        function obj = set.TunableParameters(obj, val)
            if ischar(val) % support a single character array
                x = string(val);
            else
                x = val;
            end
            oktp = obj.AllowedTunableParameters; %#ok<MCSUP> 
            fusion.internal.tuner.TunableParameterHandler.validateForm(x);
            fusion.internal.tuner.TunableParameterHandler.validateParams(x, oktp);
            obj.TunableParameters = x;
        end

        function obj = set.CustomCostFcn(obj, val)
            fcn = validateCostFcn(obj, val);
            obj.CustomCostFcn = fcn;
        end
        
        function obj = set.OutputFcn(obj, val)
            fcn = validateOutputFcn(obj, val);
            obj.OutputFcn = fcn;
        end
        
    end

    methods (Access = protected)
        function obj = addFilter(obj, filt)
            if isStringScalar(filt) || ischar(filt)
                % filt is perhaps a class name
                fusion.internal.tuner.validateClassName(filt, ...
                    'shared_positioning:tuner:TunerConfigClassInput');
                obj.FilterClass = filt; 
                % call static method
                prms = feval(filt + ".getParamsForAutotune"); 
                defaultprms = prms;
            elseif isa(filt, 'fusion.internal.tuner.FilterTuner')
                % filt is a handle to a filter
                obj.FilterClass = class(filt); 
                % call Hidden method
                prms = filt.getParamsForAutotuneFromInst;
                defaultprms = getDefaultTunableParameters(filt);
            else
                % Nothing else works
                error(message('shared_positioning:tuner:TunerConfigClassInput'));
            end
            % Set filter specific defaults
            obj.AllowedTunableParameters = prms;
            obj.TunableParameters = defaultprms; 
        end
    end

    methods (Static, Hidden)
        function obj = loadobj(s)
            % Custom loadobj because FilterClass needs to be set first.
            % This method must be Static (it is called by MATLAB), but is
            % Hidden to avoid display.
            obj = tunerconfig(s.FilterClass);
            obj.TunableParameters = s.TunableParameters;
            obj.StepBackward = s.StepBackward;
            obj.StepForward = s.StepForward;
            obj.MaxIterations = s.MaxIterations;
            obj.ObjectiveLimit = s.ObjectiveLimit;
            obj.Display = s.Display;
            obj.Cost = s.Cost;
            
            % Don't load the function_handle in the case it is the default
            % value of [].
            if isa(s.CustomCostFcn, 'function_handle')
                obj.CustomCostFcn = s.CustomCostFcn;
            end

            % Backwards compatibility to 20b.
            conditionalLoad('UseMex');
            conditionalLoad('FunctionTolerance');
            conditionalLoad('OutputFcn');
            
            function conditionalLoad(field)
                if isfield(s, field)
                    obj.(field) = s.(field);
                end
            end
            
        end
    end
    
    methods (Hidden)
        function validate(obj)
            % Cross validation of properties. Called by tune()
            if strcmp(obj.Cost, "Custom") && isempty(obj.CustomCostFcn)
                error(message('shared_positioning:tuner:InvalidCustomCostFcn', ...
                        'CustomCostFcn'));
            end    
            
            % Verify that Cost ~= Custom while using tunerPlotPose.
            if strcmpi(obj.Cost, "Custom") && ~isempty(obj.OutputFcn)
                assert(~strcmpi( func2str(obj.OutputFcn), 'tunerPlotPose'), ...
                    message('shared_positioning:tuner:PlotPoseAndCustom', ...
                    'OutputFcn', 'tunerPlotPose', 'Cost', 'Custom'));
            end
        end
        function validateTunableParamsAndIndices(obj, filtparams)
            % Late stage validation called by tune(). Ensures that indices
            % in TunableParameters are okay, in addition to previous
            % checks. This cannot be done until a filter instance is
            % supplied because of the parameterizability of the insEKF.
            % The filtparams struct contains all filter object properties
            % and measurement noises.
            fusion.internal.tuner.TunableParameterHandler.validateTunableParametersFully(...
                obj.TunableParameters, obj.AllowedTunableParameters, ...
                filtparams); 
        end
    end

    methods (Access = protected)
        function fcn = validateCostFcn(~, val)
            [fcn, nin] = makeFcnHandle(val, 'CustomCostFcn');
            if ~isempty(fcn)
                % Must be three inputs or varargin
                assert((nin == 3) || (nin == -1), ...
                    message('shared_positioning:tuner:InvalidCustomCostFcn', ...
                        'CustomCostFcn'));
            end
        end
        
        function fcn = validateOutputFcn(~, val) 
            [fcn, nin] = makeFcnHandle(val, 'OutputFcn');
            if ~isempty(fcn)
                % Must be two inputs or varargin
                assert((nin == 2) || (nin == -1), ...
                    message('shared_positioning:tuner:InvalidOutputFcn', ...
                        'OutputFcn'));
            end
        end
        
        function  p = getPropertyGroups(obj)
            if isscalar(obj)

                if iscell(obj.TunableParameters)
                    tp = {obj.TunableParameters};
                else
                    tp = obj.TunableParameters;
                end
                grp = struct( ...
                    'Filter', obj.Filter, ...
                    'TunableParameters', tp, ...
                    'StepForward', obj.StepForward, ...
                    'StepBackward', obj.StepBackward, ...
                    'MaxIterations', obj.MaxIterations, ...
                    'ObjectiveLimit', obj.ObjectiveLimit, ...
                    'FunctionTolerance', obj.FunctionTolerance, ...
                    'Display', obj.Display, ...
                    'Cost', obj.Cost);
                if strcmpi(obj.Cost, "Custom")
                    grp.CustomCostFcn = obj.CustomCostFcn;
                end
                grp.OutputFcn = obj.OutputFcn;

                p = matlab.mixin.util.PropertyGroup(grp);
            else
                % In the vector case, just use the default, including
                % displaying the CustomCostFcn. We could have the case in a
                % vector of numel ==3 where only 1 has a Cost = "custom".
                % It's safer just to display all props in this vector case.
                p = getPropertyGroups@matlab.mixin.CustomDisplay(obj);
      
            end
        end
    end
end

function [fcn, nin] = makeFcnHandle(val, prop)
%MAKEFCNHANDLE Create and validate a function handle
%   Create a function handle from a string if necessary and validate that
%   is a valid function on the path using nargin. Return nargin and the
%   function handle.



if isempty(val)
    fcn = val;
    nin = -1;
else
    
    if (isa(val, 'string') && isscalar(val)) || isa(val, 'char')
        fcn = str2func(val);
    else
        fcn = val;
        assert(isa(fcn, 'function_handle'), ...
            message('shared_positioning:tuner:InvalidFunctionHandle', prop));
    end
    % It's a real function handle. Now see if it maps to a real function using nargin
    try
        nin = nargin(fcn);
    catch 
        % Could be a mex which cannot answer nargin/nargout. Just set to
        % -1. It will error later.
        nin = -1;
    end
end
end


