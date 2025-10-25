classdef ObjectiveSenseManager < handle
    % This class is a utility for solver functions to manage updating
    % iterative results before presenting them to the user. Depending on
    % whether the user is maximizing or minimizing, and/or the existence of
    % an objective offset, some fields of the optimValues struct passed to
    % output and plot fcns may need to be updated. Also, the fval shown as
    % part of iterative display may need to be updated.
    %
    % FOR INTERNAL USE ONLY -- This feature is intentionally undocumented.
    % Its behavior may change, or it may be removed in a future release.

    % Copyright 2022-2024 The MathWorks, Inc.

    properties (SetAccess = protected, GetAccess = public)

        % Objective sense: minimize or maximize
        ObjectiveSense (1, 1) string
        
        % Lists of optimValues fieldnames to update. Some fields need both
        % the multiplier and offset applied (like fval). Others need only the
        % multiplier (like gradient). These lists should be mutually exclusive.
        % They are set on the first call to the updateOptimValues() method.
        MultiplierOffsetFields (1, :) string
        MultiplierFields (1, :) string
        FieldListsUnset (1, 1) logical = true;

        % Functions to update the optimValues fields. These anonymous fcns
        % are delcared in the constructor given a multiplier and offset.
        MultiplierOffsetFcn % (1, 1) function_handle
        MultiplierOffsetRestoreFcn % (1, 1) function_handle
        MultiplierFcn % (1, 1) function_handle
        MultiplierRestoreFcn % (1, 1) function_handle

        % Sometimes, the same optimValues struct that is passed to output or
        % plot fcns for display is fed back into the solver (ga). These
        % properties cache the most recent optimValues struct being used
        % by the algorithm (CachedOptimValuesAlgorithm) and for display
        % (CachedOptimValuesDisplay) so the values can be restored as needed
        CachedOptimValuesAlgorithm (1, 1) struct
        CachedOptimValuesDisplay (1, 1) struct
    end

    properties (Hidden, Constant)

        % Reference fieldnames for determining the MultiplierOffsetFields
        % and MultiplierFields properties on the first call to the
        % updateOptimValues() method. The fieldnames of the optimValues
        % struct is compared to these lists to determine the properties.
        AllMultiplierOffsetFields (1, :) string = ["fval", "Best", "Score", "Fitness", ...
            "bestfval", "meanfval", "swarmfvals", "currentFval", "incumbentFval", ...
            "dualbound"];
        AllMultiplierFields (1, :) string = ["gradient", "searchdirection"];

        % If we determine a manager object does not have to do anything,
        % for performance we substitute the object with a struct where
        % the public methods updateFval(), updateOptimValues(), and
        % restoreOptimValues() are identity function handles.
        DoNothingStruct = struct(...
            "ObjectiveSense", "minimize", ...
            "updateFval", @(x) full(x), ...
            "updateOptimValues", @(x) x, ...
            "restoreOptimValues", @(x) x, ...
            "DoNothing", true);
        % Therefore, the DoNothing property of an objective sense manager
        % object is always false
        DoNothing (1, 1) logical = false;

        % For c++ algorithms, the manager just needs to pass along the multipler
        % and offset to be used. The IsLSQ field helps determine iterative dispay
        % headers (fval vs. resnorm).
        DefaultStructManager = struct(...
            "ObjectiveSense", "minimize", ...
            "ObjectiveMultiplier", optim.internal.constants.DefaultOptionValues.ProblemdefOptions.ObjectiveMultiplier, ...
            "ObjectiveOffset", optim.internal.constants.DefaultOptionValues.ProblemdefOptions.ObjectiveOffset, ...
            "IsLSQ", false, ...
            "DoNothing", true);
    end

    methods (Static, Access = public)

        function options = setup(options, createOuputFcnWrapper, createStructManager)

            % Convenience method for creating an objective sense manger and
            % overriding any related options (output fcn, plot fcn).

            arguments

                % Solver options struct to edit. An ObjectiveSenseManager field
                % is always added to this struct. OutputFcn and PlotFcn fields
                % may also be edited
                options (1, 1) struct

                % Specify to substitute one wrapper output function that accounts for
                % objective sense for all output and plot functions. This is generally
                % used by optim toolbox solvers only. Global solvers often have different
                % output fcn syntaxes across solvers and are managed by solver-specific
                % functions like gaoutput, psoutput, saoutput, etc.
                createOuputFcnWrapper (1, 1) logical = false;

                % Specify to ensure the ObjectiveSenseManager field is a struct.
                % This is required by c++ algorithms.
                createStructManager (1, 1) logical = false;
            end

            % Set default manager then check for quick returns
            if createStructManager
                options.ObjectiveSenseManager = optim.internal.utils.ObjectiveSenseManager.DefaultStructManager;
            else
                options.ObjectiveSenseManager = optim.internal.utils.ObjectiveSenseManager.DoNothingStruct;
            end

            % Return for unsupported ProblemdefOptions. Note, we assume existence
            % of ObjectiveMultiplier field means ObjectiveOffset field is also there
            if ~isfield(options, "ProblemdefOptions") || ...
                    ~isfield(options.ProblemdefOptions, "FromSolve") || ...
                    ~options.ProblemdefOptions.FromSolve || ...
                    ~isfield(options.ProblemdefOptions, "ObjectiveMultiplier")
                return
            end

            % Return for default objective sense/offset
            defaults = optim.internal.constants.DefaultOptionValues.ProblemdefOptions;
            if all(options.ProblemdefOptions.ObjectiveMultiplier == defaults.ObjectiveMultiplier) && ...
                    all(options.ProblemdefOptions.ObjectiveOffset == defaults.ObjectiveOffset)
                return
            end

            % ObjectiveSense
            if options.ProblemdefOptions.ObjectiveMultiplier == 1
                sense = "minimize";
            else
                sense = "maximize";
            end
            options.ObjectiveSenseManager.ObjectiveSense = sense;

            % output/plot fcn checks
            hasOutputFcn = isfield(options, "OutputFcn") && ~isempty(options.OutputFcn);
            hasPlotFcn = isfield(options, "PlotFcn") && ~isempty(options.PlotFcn);
            hasPlotFcns = isfield(options, "PlotFcns") && ~isempty(options.PlotFcns); % legacy name
            hasOutputOrPlotFcn = hasOutputFcn || hasPlotFcn || hasPlotFcns;

            % If we've made it here, we need a non-default manager.
            if createStructManager % required by c++ algorithms
                % Edit the ObjectiveMultiplier and ObjectiveOffset fields of the default manager
                options.ObjectiveSenseManager.ObjectiveMultiplier = options.ProblemdefOptions.ObjectiveMultiplier;
                options.ObjectiveSenseManager.ObjectiveOffset = options.ProblemdefOptions.ObjectiveOffset;
                options.ObjectiveSenseManager.DoNothing = false;
            else
                % Create an ObjectiveSenseManager object
                options.ObjectiveSenseManager = optim.internal.utils.ObjectiveSenseManager(sense, ...
                    options.ProblemdefOptions.ObjectiveMultiplier, options.ProblemdefOptions.ObjectiveOffset);
            end

            % If requested and necessary, create wrapper output function for all output and plot functions
            if createOuputFcnWrapper && hasOutputOrPlotFcn

                % Ensure we have either empties or a cell array of functions.
                % Also set relevant plot fcn to empty as plots will be routed
                % through the custom output fcn
                outputfcns = [];
                plotfcns = [];
                if hasOutputFcn
                    outputfcns = matlab.internal.optimfun.utils.createCellArrayOfFunctions(options.OutputFcn, "OutputFcn");
                end
                if hasPlotFcn
                    plotfcns = matlab.internal.optimfun.utils.createCellArrayOfFunctions(options.PlotFcn, "PlotFcn");
                    options.PlotFcn = [];
                elseif hasPlotFcns
                    plotfcns = matlab.internal.optimfun.utils.createCellArrayOfFunctions(options.PlotFcns, "PlotFcns");
                    options.PlotFcns = [];
                end

                % Route functions through custom output fcn that accounts for objective sense
                objSenseMgr = options.ObjectiveSenseManager;
                if createStructManager % for example, fmincon sqp
                    % Create a manager class for the output fcn wrapper
                    objSenseMgr = optim.internal.utils.ObjectiveSenseManager(sense, ...
                        options.ProblemdefOptions.ObjectiveMultiplier, options.ProblemdefOptions.ObjectiveOffset);
                end
                options.OutputFcn = @(x, optimValues, state, varargin) matlab.internal.optimfun.utils.callAllOptimOutputAndPlotFcns(...
                    x, optimValues, state, objSenseMgr, outputfcns, plotfcns, varargin{:});
            end
        end

        function options = setupStructManager(options)

            % Convenience method for creating an objective sense manager for
            % c++ algorithms. In these cases, the manager must be a struct
            % instead of an ObjectiveSenseManager object. Also, these algorithms
            % do not generally support output or plot fcns so there is no
            % need to create a wrapper for them.
            createOuputFcnWrapper = false;
            createStructManager = true;
            options = optim.internal.utils.ObjectiveSenseManager.setup(...
                options, createOuputFcnWrapper, createStructManager);
        end

        function options = setupLinprogManager(options, algorithm)

            % Convenience method for creating an objective sense manager for
            % linprog. Depending on the algorithm, various internal options
            % may need to be set.
            options = optim.internal.utils.ObjectiveSenseManager.setupStructManager(options);
            if strcmpi(algorithm, "interior-point")
                options.InternalOptions.ObjectiveSenseManager = options.ObjectiveSenseManager;
            end
        end

        function options = setupLsqlinManager(options, d)

            % Convenience method for creating an objective sense manager for
            % lsqlin. In this case, the manager is used to map the iterative
            % display value from fval to resnorm
            options.ObjectiveSenseManager = optim.internal.utils.ObjectiveSenseManager.DefaultStructManager;
            options.ObjectiveSenseManager.ObjectiveMultiplier = 2;
            options.ObjectiveSenseManager.ObjectiveOffset = (d'*d)/2;
            options.ObjectiveSenseManager.IsLSQ = true;
            options.ObjectiveSenseManager.DoNothing = false;
        end

        function options = setupIntlinprogManager(options)

            % Extract plain structure data from options object
            optionsStruct = extractOptionsStructure(options);

            % Setup objective sense manager
            createOuputFcnWrapper = true;
            createStructManager = true;
            optionsStruct = optim.internal.utils.ObjectiveSenseManager.setup(...
                optionsStruct, createOuputFcnWrapper, createStructManager);

            % Return if manager does not need to do anything
            if optionsStruct.ObjectiveSenseManager.DoNothing || ...
                strcmpi(options.Algorithm, 'highs')
                return
            end

            % intlinprog handles objective sense via the xdispd (max/min) and
            % xconsf (constant offset) InternalOptions fields. Note, for manager
            % field ObjectiveMultiplier, -1 means maximization (negate value) and
            % 1 means minimization (identity operator). However, for xdispd, -1 means
            % minimization and 1 means maximization. Also, the manager always stores
            % the constant offset in minimization world. However, intlinprog requires
            % the offset to have the same objective sense as fval
            xdispd = -1*optionsStruct.ObjectiveSenseManager.ObjectiveMultiplier;
            xconsf = optionsStruct.ObjectiveSenseManager.ObjectiveOffset.*optionsStruct.ObjectiveSenseManager.ObjectiveMultiplier;
            optionsStruct = optim.internal.utils.ObjectiveSenseManager.setupSLBIInternalOptions(optionsStruct, xdispd, xconsf);

            % Need to return an options object back to intlinprog. Update the
            % properties that may have changed.
            options.OutputFcn = optionsStruct.OutputFcn;
            options.PlotFcn = optionsStruct.PlotFcns;
            options = setInternalOptions(options, optionsStruct.InternalOptions);
        end
    end

    methods (Access = protected)

        function this = ObjectiveSenseManager(sense, multiplier, offset)

            % Set the sense and update fcns. Note, +0 prevents printing of negative 0 ("-0")
            this.ObjectiveSense = sense;
            this.MultiplierOffsetFcn = @(x) ((x + offset) .* multiplier) + 0;
            this.MultiplierOffsetRestoreFcn = @(x) ((x ./ multiplier) - offset) + 0;
            this.MultiplierFcn = @(x) (x .* multiplier) + 0;
            this.MultiplierRestoreFcn = @(x) (x ./ multiplier) + 0;
        end
    end

    methods (Access = public)

        function fval = updateFval(this, fval)

            % fval needs both the multiplier and offset applied
            fval = this.MultiplierOffsetFcn(fval);
        end

        function optimValues = updateOptimValues(this, optimValues)

            % If necessary, set the fields to update
            if this.FieldListsUnset
                fields = string(fieldnames(optimValues));
                this.MultiplierOffsetFields = intersect(fields, this.AllMultiplierOffsetFields);
                this.MultiplierFields = intersect(fields, this.AllMultiplierFields);
                this.FieldListsUnset = false;
            end

            % Cache the optimValues currently being used by the algorithm
            this.CachedOptimValuesAlgorithm = optimValues;

            % Update optimValues struct fields
            optimValues = this.updateFields(optimValues, this.MultiplierOffsetFields, this.MultiplierOffsetFcn);
            optimValues = this.updateFields(optimValues, this.MultiplierFields, this.MultiplierFcn);

            % Cache the optimValues currently being used for display
            this.CachedOptimValuesDisplay = optimValues;
        end

        function optimValues = restoreOptimValues(this, optimValues)

            % Restore optimValues struct fields
            optimValues = this.restoreFields(optimValues, this.MultiplierOffsetFields, this.MultiplierOffsetRestoreFcn);
            optimValues = this.restoreFields(optimValues, this.MultiplierFields, this.MultiplierRestoreFcn);
        end
    end

    methods (Static, Access = protected)

        function options = setupSLBIInternalOptions(options, xdispd, xconsf)

            % Set SLBI internal options for objective offset (xconsf) and objective sense (xdispd)
            if isfield(options, "InternalOptions") && ~isempty(options.InternalOptions)

                % Append internal options based on data type (numeric or struct)
                % Do NOT overwrite any existing internal options, including
                % ones for xconsf or xdispd.
                if isnumeric(options.InternalOptions)
                    appendNumericInternalOption(108, xconsf);
                    appendNumericInternalOption(110, xdispd);
                else
                    appendStructFieldInternalOption("xconsf", xconsf);
                    appendStructFieldInternalOption("xdispd", xdispd);
                end
            else
                % Create an InternalOptions struct with necessary fields
                addStructFieldInternalOption("xconsf", xconsf);
                addStructFieldInternalOption("xdispd", xdispd);
            end

            function appendNumericInternalOption(number, value)
                % Only append if not already set
                if ~any(options.InternalOptions(:, 1) == number)
                    options.InternalOptions = [...
                        options.InternalOptions; ...
                        number, value];
                end
            end

            function appendStructFieldInternalOption(field, value)
                % Only append if not already set
                if ~isfield(options.InternalOptions, field)
                    addStructFieldInternalOption(field, value);
                end
            end

            function addStructFieldInternalOption(field, value)
                options.InternalOptions.(field) = value;
            end
        end
    end

    methods (Access = protected)

        function optimValues = updateFields(~, optimValues, fieldnames, fun)

            % Update fields
            for ct = 1:numel(fieldnames)
                thisField = fieldnames(ct);
                optimValues.(thisField) = fun(optimValues.(thisField));
            end
        end

        function optimValues = restoreFields(this, optimValues, fieldnames, fun)

            % Restore fields
            for ct = 1:numel(fieldnames)
                thisField = fieldnames(ct);
                thisValue = optimValues.(thisField);

                % If the value being restored equals the cached displayed
                % value (that is, the user did not change it), restore the
                % cached algorithm value. This allows us to precisely restore
                % the value.
                % Else, the user has updated the value and we must use reverse
                % operations to restore it.
                if isequal(thisValue, this.CachedOptimValuesDisplay.(thisField))
                    optimValues.(thisField) = this.CachedOptimValuesAlgorithm.(thisField);
                else
                    optimValues.(thisField) = fun(optimValues.(thisField));
                end
            end
        end
    end
end
