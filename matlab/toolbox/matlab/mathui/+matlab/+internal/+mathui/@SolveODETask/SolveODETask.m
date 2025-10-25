classdef (Hidden = true,Sealed = true) SolveODETask < matlab.task.LiveTask
    % Solve ODE: live task for defining and solving ODEs
    %
    %   FOR INTERNAL USE ONLY -- This feature is intentionally undocumented.
    %   Its behavior may change, or it may be removed in a future release.

    %   Copyright 2024 The MathWorks, Inc.

    properties(Access = public, Transient, Hidden)
        % Handles for all of the controls in the live task
        Accordion                   matlab.ui.container.internal.Accordion

        % Select problem section
        ProblemFormatButtons        matlab.ui.control.StateButton
        ParametersCB                matlab.ui.control.CheckBox
        OdefunLabel                 matlab.ui.control.Label
        OdefunSelector              matlab.internal.dataui.FunctionSelector
        MassMatrixLabel             matlab.ui.control.Label
        MassMatrixOps               matlab.internal.mathui.MassMatrixOptions
        ParametersWSDD              matlab.ui.control.internal.model.WorkspaceDropDown
        InitialTimeEditField        matlab.ui.control.NumericEditField
        InitialValueVS              matlab.internal.dataui.VectorSelector

        % Advanced options section
        JacobianButton              matlab.ui.control.StateButton
        EventsButton                matlab.ui.control.StateButton
        InitialSlopeButton          matlab.ui.control.StateButton
        NonNegVarsButton            matlab.ui.control.StateButton
        MassSparsityButton          matlab.ui.control.StateButton
        SensitivityButton           matlab.ui.control.StateButton
        JacobianLabel               matlab.ui.control.Label
        JacobianOps                 matlab.internal.mathui.JacobianOptions
        InitialSlopeLabel           matlab.ui.control.Label
        InitialSlopeVS              matlab.internal.dataui.VectorSelector
        EventLabel                  matlab.ui.control.Label
        EventOps                    matlab.internal.mathui.EventOptions
        NonNegVarsLabel             matlab.ui.control.Label
        NonNegVarsVS                matlab.internal.dataui.VectorSelector
        MassSparsityLabel           matlab.ui.control.Label
        MassSparsityDD              matlab.ui.control.internal.model.WorkspaceDropDown

        % Solver options section
        SolverDropdown              matlab.ui.control.DropDown
        AbsTolEditField             matlab.ui.control.NumericEditField
        RelTolEditField             matlab.ui.control.NumericEditField
        InitialStepLabel            matlab.ui.control.Label
        InitialStepEditField        matlab.ui.control.NumericEditField
        MaxStepLabel                matlab.ui.control.Label
        MaxStepEditField            matlab.ui.control.NumericEditField
        MinStepLabel                matlab.ui.control.Label
        MinStepEditField            matlab.ui.control.NumericEditField
        NormControlCB               matlab.ui.control.CheckBox
        MaxOrderLabel               matlab.ui.control.Label
        MaxOrderSpinner             matlab.ui.control.Spinner
        VectorizationCB             matlab.ui.control.CheckBox
        BDFCB                       matlab.ui.control.CheckBox
        DetectStiffnessCB           matlab.ui.control.CheckBox

        % Solve section
        SolutionTypeDD              matlab.ui.control.DropDown
        TimeRangeEditField1         matlab.ui.control.NumericEditField
        TimeRangeEditField2         matlab.ui.control.NumericEditField
        TimeVectorSelector          matlab.internal.dataui.VectorSelector
        InterpolateTypeDD           matlab.ui.control.DropDown
        RefineSpinner               matlab.ui.control.Spinner
        ExtensionCB                 matlab.ui.control.CheckBox
        SolFcnHelpIcon              matlab.ui.control.Image

        % Display section
        DisplayDD                   matlab.ui.control.DropDown
        DisplayTypeDD               matlab.ui.control.DropDown
        DisplayVariablesLabel       matlab.ui.control.Label
        DisplayVariablesVS          matlab.internal.dataui.VectorSelector
        DisplayEventsCB             matlab.ui.control.CheckBox
        DisplaySensitivityCB        matlab.ui.control.CheckBox
    end

    properties(Access=private)
        % Internally make an ode object to inform what selected solver to
        % show, what solver options should be available, and the default
        % value for Refine based on the solver
        OdeObj
        % To make sure some optional inputs are the correct size, we'll
        % need to check them against the size of the initial value y0
        NumY0 = 1;
        % Hold on to whether or not selected params are a numeric vector so
        % we know whether we should offer Sensitivity
        HasNumericParams = false;
    end

    properties(Access=private,Constant)
        SupportedSolvers = ["ode45" "ode15s" "ode78" "ode89" "ode23" "ode23s" ...
            "ode23t" "ode23tb" "ode113" "cvodesstiff" "cvodesnonstiff" "idas"];
        % Default values of a WorkspaceDropDown
        WSDDselect = "select variable";
        WSDDdefault = "default value";
        % Names of functions in the examples used by the "New..." buttons
        ExampleODEName = 'odefun';
        ExampleMassName = 'massfun';
        ExampleJacobianName = 'jacobianfun';
        ExampleEventName = 'eventfun';
        ExampleEventCallbackName = 'callbackfun';
        % Default Value of most of the controls. Used for reseting defaults
        % and for determining what Values to save in the State
        DefaultValues = struct("ParametersCB",false,...
            "ParametersWSDD","select variable",...
            "InitialTimeEditField",0,...
            "AbsTolEditField",1e-6,...
            "RelTolEditField",1e-3,...
            "SolverDropdown","auto",...
            "NormControlCB",false,...
            "InitialStepEditField",[],...
            "MaxStepEditField",[],...
            "MinStepEditField",[],...
            "VectorizationCB",false,...
            "BDFCB",false,...
            "MaxOrderSpinner",5,...
            "DetectStiffnessCB",false,...
            "SolutionTypeDD","solveRange",...
            "DisplayEventsCB",true, ...
            "DisplaySensitivityCB",true,...
            "DisplayTypeDD","final",...
            "MassSparsityDD","select variable",...
            "DisplayDD","plot");
        DefaultStates = struct(...
            "OdefunSelectorState",struct("FcnType",'local',...
                "LocalValue",'select variable',...
                "HandleValue",'@(t,y) [y(1); y(2)]',...
                "BrowseValue",''),...
            "MassMatrixOpsState",struct(),...
            "InitialValueVSState",struct(),...
            "EventOpsState",struct(),...
            "JacobianOpsState",struct(),...
            "InitialSlopeVSState",struct("TargetSize",1),...
            "NonNegVarsVSState",struct("TargetSize",1),...
            "TimeVectorSelectorState",struct("EditFieldValue",'0:0.1:1',"NumValue",0:0.1:1),...
            "DisplayVariablesVSState",struct("EditFieldValue",'1',"TargetSize",1,"NumValue",1))
        % Buttons in section 2 (order matters as this is used for setup)
        AdvancedOptions = ["Jacobian" "Events" "InitialSlope" "MassSparsity" "Sensitivity" "NonNegVars"];

        % Serialization Version - used for managing compatibility
        %     1: original ship (R2024b)
        Version = 1;
    end

    properties
        % Required by base class
        State
        Summary
    end

    methods (Access = protected)
        % Required by base class, implemented in setup.m
        setup(app)
    end

    methods (Access = private)
        % Internal app methods

        % Private methods implemented in their own files
        doUpdate(app,src,~)
        setExampleFunctionScripts(app)

        function str = getMsgText(~,id,varargin)
            % Get the appropriate translated label or message
            str = string(message("MATLAB:mathui:" + id,varargin{:}));
        end

        function tf = filterSparsity(app,m)
            % FilterFcn for MassMatrix sparsity
            % Square numeric matrix compatibly sized to y0
            s = app.NumY0;
            tf = isa(m,"double") && isequal(size(m),[s s]);
        end

        function setControlsToDefault(app)
            % Set values of controls at construction and on 'reset'
            % This does not reset the problem definition section, but
            % resets everything else based on that selection

            % Turn off all advanced options
            for k = app.AdvancedOptions
                app.(k+"Button").Value = false;
            end
            % Static defaults: Don't include defaults in prob defn section
            % And wait to set items on DisplayDD before setting Value
            controls = setdiff(fieldnames(app.DefaultValues)',...
                ["ParametersCB" "ParametersWSDD" "InitialTimeEditField" "DisplayDD"]);
            for k = controls
                app.(k).Value = app.DefaultValues.(k);
            end
            % Custom components
            app.EventOps.reset();
            app.TimeVectorSelector.Value = '0:0.1:1';
            % These defaults depend on the problem setup
            app.TimeRangeEditField1.Value = app.InitialTimeEditField.Value;
            app.TimeRangeEditField2.Value = app.TimeRangeEditField1.Value + 1;
            app.RefineSpinner.Value = app.OdeObj.SolverOptions.DefaultRefine;
            % The rest depend on Y0 and may be changed at other times too
            resetValuesDependentOnNumY0(app);
        end

        function resetValuesDependentOnNumY0(app)
            % These controls revert to default when the size of Y0 changes
            % since they rely on the size of Y0.
            app.MassSparsityDD.Value = app.DefaultValues.MassSparsityDD;
            app.JacobianOps.reset();
            app.JacobianOps.ExpectedSize = app.NumY0;
            app.InitialSlopeVS.TargetSize = app.NumY0;
            app.InitialSlopeVS.Value = '';
            app.NonNegVarsVS.TargetSize = app.NumY0;
            app.NonNegVarsVS.Value = '';
            % Plot controls
            items = [getMsgText(app,"DisplayNone") getMsgText(app,"DisplayPlot") ...
                getMsgText(app,"DisplayPhas2") getMsgText(app,"DisplayPhas3")];
            itemsData = ["none" "plot" "phas2" "phas3"];
            if app.NumY0 < 3
                % odephas3 requires 3 variables
                items(4) = [];
                itemsData(4) = [];
                if app.NumY0 < 2
                    % odephas2 requires 2 variables
                    items(3) = [];
                    itemsData(3) = [];
                end
            end
            app.DisplayDD.Items = items;
            app.DisplayDD.ItemsData = itemsData;
            app.DisplayDD.Value = app.DefaultValues.DisplayDD;
            app.DisplayVariablesVS.TargetSize = app.NumY0;
            app.DisplayVariablesVS.Value = mat2str(1:app.NumY0);
        end

        function updateHasNumericParams(app)
            % Check whether we have currently selected numeric parameters
            % and store the value appropriately
            p = app.ParametersWSDD.WorkspaceValue;
            app.HasNumericParams = app.ParametersCB.Value && ...
                ~isempty(p) && isnumeric(p) && isvector(p);
            % toggle Sensitivity display based on number of params
            app.DisplaySensitivityCB.Value = ~app.HasNumericParams || numel(p) <= 10;
        end

        function tf = waitingOnParameters(app)
            % For use in determining Enable of elements and whether or not
            % we have enough information to generate the ODE command
            tf = app.ParametersCB.Value && ...
                isequal(app.ParametersWSDD.Value,app.WSDDselect);
        end

        % implemented in generateScriptODECall.m
        str = generateScriptODECall(app,solver,isInternalCall)
    end

    % Methods required for embedding in a Live Script
    methods (Access = public)
        function reset(app)
            % Required by base class. Called when user selects "Restore
            % Default Values" from the context menu. The guideline is to
            % not reset the main input. In this context, we apply this
            % guideline by not resetting problem type, ODE function,
            % MassMatrix, and initial conditions. The remaining controls
            % are reset
            setControlsToDefault(app);
            doUpdate(app,struct("Tag","reset"));
        end

        % implemented in generateCode.m
        [code,outputs] = generateCode(app)
    end

    methods
        function summary = get.Summary(app)
            % Required by base class - returns the string containing the
            % dynamic summary at the top of the live task.
            if isempty(app.OdefunSelector.Value) || waitingOnParameters(app) || ...
                    isWaiting(app.MassMatrixOps) || isempty(app.InitialValueVS.Value)
                % Input not (fully) selected, return H1 line
                summary = app.getMsgText("Tool_SolveODETask_Description");
                return
            end
            fun = strip(app.OdefunSelector.Value,"@");
            if startsWith(fun,"(")
                % Anonymous function
                hasfunName = false;
            else
                % We can use the function name in the summary
                hasfunName = true;
                fun = "`" + fun + "`";
            end
            if isequal(app.SolutionTypeDD.Value,"solveRange")
                % Solve over a time range, summary includes t_0 and t_final
                t0 = num2str(app.TimeRangeEditField1.Value);
                tf = num2str(app.TimeRangeEditField2.Value);
                if hasfunName
                    summary = app.getMsgText("SummarySolveRange",fun,t0,tf);
                else
                    summary = app.getMsgText("SummarySolveRangeAnon",t0,tf);
                end
            else
                % Solve for specified time values, summary doesn't include
                % these values explicitly
                if hasfunName
                    summary = app.getMsgText("SummarySolveVector",fun);
                else
                    summary = app.getMsgText("SummarySolveVectorAnon");
                end
            end
        end

        function state = get.State(app)
            % Store only as much info as we need to restore the live task
            % in the save/load workflow. Non-default values do not need to
            % be stored.
            state = struct(VersionSavedFrom = app.Version,...
                MinCompatibleVersion = 1);
            % Problem format buttons (No default, always store)
            state.ProblemFormatButtonValues = [app.ProblemFormatButtons.Value];
            % State of custom uicomponents
            for k = ["OdefunSelector" "MassMatrixOps" "InitialValueVS"...
                    "EventOps" "JacobianOps" "InitialSlopeVS" ...
                    "NonNegVarsVS" "TimeVectorSelector" "DisplayVariablesVS"]
                controlstate = app.(k).State; 
                if ~isequal(controlstate,app.DefaultStates.(k + "State"))
                    state.(k + "State") = controlstate;
                end
            end
            % Advanced options buttons
            selectedOptions = string.empty;
            for k = app.AdvancedOptions
                if app.(k + "Button").Value
                    selectedOptions(end+1) = k; %#ok<AGROW>
                end
            end
            if ~isempty(selectedOptions)
                state.SelectedOptions = selectedOptions;
            end
            % Value of simple components
            % Defaults of these controls is dependent on others, but we can
            % still reduce state by not storing most common values
            control = ["TimeRangeEditField1" "TimeRangeEditField2" "RefineSpinner"];
            expval = [0 1 4];
            for k = 1:numel(control)
                if ~isequal(app.(control(k)).Value,expval(k))
                    state.(control(k) + "Value") = app.(control(k)).Value;
                end
            end
            % All of the components whose Value is different from the one
            % in DefaultValues struct should be stored
            for k = string(fieldnames(app.DefaultValues))'
                if ~isequal(app.(k).Value,app.DefaultValues.(k))
                    state.(k + "Value") = app.(k).Value;
                end
            end
            % Remaining helper properties
            if app.HasNumericParams
                state.HasNumericParams = true;
            end
            if app.NumY0 ~= 1
                state.NumY0 = app.NumY0;
            end
        end

        function set.State(app,state)
            % Set saved state. Used for save/load, undo/redo, copy/paste.
            % This method is called by the editor on the above State,
            % except that it has gone through jsonencode/jsondecode.

            % Use isfield to determine whether a particular field should be
            % set to default or the saved value. This may also be used in
            % the future to assist in version control.
            if app.Version < state.MinCompatibleVersion
                % No op - saved from an incompatible future state
                return
            end
            % Problem format button values
            if isfield(state,"ProblemFormatButtonValues")
                for k = 1:numel(app.ProblemFormatButtons) %#ok<*MCSUP>
                    app.ProblemFormatButtons(k).Value = state.ProblemFormatButtonValues(k);
                end
            end
            % State of custom components
            for k = ["OdefunSelector" "MassMatrixOps" "InitialValueVS"...
                    "EventOps" "JacobianOps" "InitialSlopeVS" ...
                    "NonNegVarsVS" "TimeVectorSelector" "DisplayVariablesVS"]
                if isfield(state,k + "State")
                    app.(k).State = state.(k + "State");
                else
                    app.(k).State = app.DefaultStates.(k + "State");
                end
            end
            % Advanced options buttons
            if isfield(state,"SelectedOptions")
                selectedButtons = state.SelectedOptions;
            else
                selectedButtons = string.empty;
            end
            for k = app.AdvancedOptions
                app.(k + "Button").Value = matches(k,selectedButtons);
            end
            % Value of components without static defaults. We can still
            % reduce the state by not saving the most common values
            control = ["TimeRangeEditField1" "TimeRangeEditField2" "RefineSpinner"];
            expval = [0 1 4];
            for k = 1:numel(control)
                if isfield(state,control(k) + "Value")
                    app.(control(k)).Value = state.(control(k) + "Value");
                else
                    app.(control(k)).Value = expval(k);
                end
            end
            % All of the other components that have defaults stored in
            % DefaultValues struct
            for k = string(fieldnames(app.DefaultValues))'
                if isfield(state,k + "Value")
                    app.(k).Value = state.(k + "Value");
                else
                    app.(k).Value = app.DefaultValues.(k);
                end
            end
            % Remaining helper properties
            if isfield(state,"NumY0")
                app.NumY0 = state.NumY0;
            else
                app.NumY0 = 1;
            end
            if isfield(state,"HasNumericParams")
                app.HasNumericParams = state.HasNumericParams;
            else
                app.HasNumericParams = false;
            end
            doUpdate(app);
        end
    end
end