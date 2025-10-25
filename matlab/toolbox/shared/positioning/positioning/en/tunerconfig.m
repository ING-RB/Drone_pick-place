classdef tunerconfig< matlab.mixin.CustomDisplay
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

    methods
        function out=tunerconfig
        end

        function out=addFilter(~) %#ok<STOUT>
        end

        function out=getPropertyGroups(~) %#ok<STOUT>
        end

        function out=validateCostFcn(~) %#ok<STOUT>
        end

        function out=validateOutputFcn(~) %#ok<STOUT>
        end

    end
    properties
        AllowedTunableParameters;

        % Cost Metric to use for evaluating the filter performance
        % Specify the cost metric to use when optimizing the filter
        % performance during tuning. Set the Cost property to 'RMS' to
        % optimize the RMS error. Set the Cost property to 'Custom' to
        % specify an alternate cost metric using the CustomCostFcn
        % property.
        Cost;

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
        CustomCostFcn;

        % Display Verbosity of display during filter tuning
        % Specify the verbosity of the display echoed to the Command Window
        % during filter tuning. Setting Display to a value of 'iter' will
        % show the cost at each iteration of the coordinate ascent. Setting
        % the Display to 'none' will not report anything during the ascent.
        Display;

        % Filter Class of the filter being tuned
        % Filter is the class name used to create the tunerconfig object.
        Filter;

        FilterClass;

        % FunctionTolerance Minimum change in cost to continue tuning
        % Specify the minimum absolute change in cost from one iteration
        % to the next to continue tuning of the filter
        FunctionTolerance;

        % MaxIterations Maximum number of iterations to optimize parameters 
        % Maximum number of iterations each parameter will be optimized in the
        % tuning algorithm. A single iteration will try to improve the value of
        % each parameter once. Specify a positive integer number of iterations.
        MaxIterations;

        % ObjectiveLimit Cost at which to stop optimization early
        % Specify the cost at which the coordinate ascent algorithm will
        % terminate prior to MaxIterations.
        ObjectiveLimit;

        % OutputFcn User-defined function to be called at each iteration
        % Specify a function handle to be called at the end of each
        % iteration. For example, the function can be used to log or plot
        % data, or terminate the tuning.  The function takes two inputs, a
        % struct containing the current best filter parameters and a second
        % struct containing several fields related to the tuning, including
        % the input sensor data and ground truth. The function returns
        % false if tuning should continue and returns true if the tuning should
        % stop.
        OutputFcn;

        % StepBackward Factor by which to decrease a parameter in one step.
        % During the coordinate ascent tuning algorithm, noise parameters
        % are increased and decreased. Specify the factor by which a
        % parameter should be decreased when the metric is increasing.
        StepBackward;

        % StepForward Factor by which to increase a parameter in one step.
        % During the coordinate ascent tuning algorithm, noise parameters
        % are increased and decreased. Specify the factor by which a
        % parameter should be increased when the metric is decreasing.
        StepForward;

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
        TunableParameters;

    end
end
