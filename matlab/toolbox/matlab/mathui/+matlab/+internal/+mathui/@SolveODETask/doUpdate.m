function doUpdate(app,src,evt)
% Main callback for most controls in SolveODETask. Reacts to changes in
% component values and sets defaults, Visible, and Enable accordingly.

% Copyright 2024 The MathWorks, Inc.

%%% Updates specific to control that was just used %%%
if nargin > 1 
    context = src.Tag;
    if startsWith(context,"ProbButton")
        % Mimic uitogglebutton behavior
        ind = matches({app.ProblemFormatButtons.Tag},context);
        selectedButton = app.ProblemFormatButtons(ind);
        selectedButton.Value = true;
        if evt.PreviousValue
            % This button had already been selected, nothing to do
            return
        end        
        [app.ProblemFormatButtons(~ind).Value] = deal(false);
        % Don't wait for other things in the task to change before drawing
        % this so it looks more seamlessly like a real togglebutton
        drawnow
        % Store the type, and update the MassMatrix controls
        app.MassMatrixOps.MType = src.UserData.MassMatrixType;
        % Input functions need new syntax based on type
        setExampleFunctionScripts(app);
    elseif isequal(context,"ParametersCB")
        % Input functions need new syntax based on ",p"
        setExampleFunctionScripts(app);
        % May have new parameters value
        updateHasNumericParams(app);
    elseif matches(context,["InitialValueVS" "MassMatrixOps"])
        % We potentially have a new size of problem based on MassMatrix or
        % Y0. Reset controls as needed.
        oldNumY0 = app.NumY0;        
        if isequal(context,"MassMatrixOps")
            if app.MassMatrixOps.MType == 1 && ~isequal(app.MassMatrixOps.MatrixWSDD.Value,app.WSDDselect)
                % We have a new MassMatrix WSDD value
                app.NumY0 = size(app.MassMatrixOps.MatrixWSDD.WorkspaceValue,1);
                resetY0VS = true;
            end
        elseif ~isempty(app.InitialValueVS.Value)
            % We have a new Y0
            app.NumY0 = numel(app.InitialValueVS.NumValue);
            resetY0VS = false;
        end
        if oldNumY0 ~= app.NumY0
            % Number of equations has changed. Reset values dependent on
            % this size
            if resetY0VS
                app.InitialValueVS.Value = '';
            else
                app.MassMatrixOps.MatrixWSDD.Value = app.WSDDselect;
            end
            resetValuesDependentOnNumY0(app);
        end
    elseif isequal(context,"ParametersWSDD")
        updateHasNumericParams(app);
    elseif isequal(context,"DisplayDD")
        % Reset default OutputVariables depending on plot type
        if isequal(app.DisplayDD.Value,'phas2')
            app.DisplayVariablesVS.Value = '[1 2]';
        elseif isequal(app.DisplayDD.Value,'phas3')
            app.DisplayVariablesVS.Value = '[1 2 3]';
        else
            app.DisplayVariablesVS.Value = mat2str(1:app.NumY0);
        end
    elseif isequal(context,"DisplayVariablesVS")
        % Enforce number of output variables for phas2 and phas3
        vars = app.DisplayVariablesVS.NumValue;
        if isequal(app.DisplayDD.Value,'phas2') && numel(vars) ~= 2
            % revert to default
            app.DisplayVariablesVS.Value = '[1 2]';
        elseif isequal(app.DisplayDD.Value,'phas3') && numel(vars) ~= 3
            % revert to default
            app.DisplayVariablesVS.Value = '[1 2 3]';
        end
    elseif isequal(context,"SensitivityButton")
        if app.SensitivityButton.Value
            % Open display results so user sees the new SensitivityCB
            expand(app.Accordion.Children(5));
        end
    end
end

%%%% Updates to section 1: Problem definition %%%%
% Update ODE format labels depending on ParametersCB
showP = app.ParametersCB.Value;
str = app.getMsgText("ParametersCBLabel");
if showP
    app.ParametersCB.Text = str + ": p";
    commaP = ",p";
else
    app.ParametersCB.Text = str;
    commaP = "";
end
% Uses tex interpreter for nice display
app.ProblemFormatButtons(1).Text = "$\frac{dy}{dt} = f(t,y" + commaP + ")$";
app.ProblemFormatButtons(2).Text = "$M\frac{dy}{dt} = f(t,y" + commaP + ")$";
app.ProblemFormatButtons(3).Text = "$M(t" + commaP + ")\frac{dy}{dt} = f(t,y" + commaP + ")$";
app.ProblemFormatButtons(4).Text = "$M(t,y" + commaP + ")\frac{dy}{dt} = f(t,y" + commaP + ")$";
% Set Enable of Problem definition controls based on whether user has
% selected a format button
hasProblem = sum([app.ProblemFormatButtons.Value]) == 1;
if hasProblem && ~app.OdefunSelector.Enable
    % A problem type has been selected for the first time, expand "solve"
    % section (others stay collapsed by default)
    expand(app.Accordion.Children(4));
end
app.ParametersWSDD.Enable = hasProblem;
app.OdefunSelector.Enable = hasProblem;
app.InitialTimeEditField.Enable = hasProblem;
app.InitialValueVS.Enable = hasProblem;
% (No need to toggle enable for M and P, since they won't be visible until
% after a problem is selected.)
% Update the problem definition section based on selections
app.ParametersWSDD.Visible = showP;
% ODEFcn and MassMatrix labels need to show the correct syntax
odeStr = app.getMsgText("ODEFcnLabel");
app.OdefunLabel.Text = odeStr + ": f(t,y" + commaP + ")";
mmStr = app.getMsgText("MassMatrixLabel");
mtype = app.MassMatrixOps.MType;
switch mtype
    case 1 % constant M
        app.MassMatrixLabel.Text = mmStr + ": M";
    case 2 % time-dependent M
        app.MassMatrixLabel.Text = mmStr + ": M(t" + commaP + ")";
    otherwise %state-dependent M (or no M, invisible label)
        app.MassMatrixLabel.Text = mmStr + ": M(t,y" + commaP + ")";
end
showM = mtype >=1;
app.MassMatrixLabel.Visible = showM;
app.MassMatrixOps.Visible = showM;
setupGrid = app.Accordion.Children(1).Children;
% Can't use 'fit' to hide MassMatrix row because we can't unparent the
% icon. It stops being a target of the popout. Instead toggle the RowHeight
% manually with a pixel height of 0 or 22.
setupGrid.RowHeight{4} = showM*22; 
matlab.internal.dataui.setParentForWidgets([app.ParametersWSDD app.MassMatrixLabel],setupGrid);

%%%% Update Section 2: Advanced problem definition options %%%%
% Update prob options that are available based on ODE format
app.InitialSlopeButton.Visible = showM;
app.NonNegVarsButton.Visible = ~showM;
app.MassSparsityButton.Visible = mtype == 3;
app.SensitivityButton.Visible = app.HasNumericParams;
% Shift Sensitivity button based on visibility of MassSparsity button (else
% we may show a gap due to width of EventOps which can't be unparented)
app.SensitivityButton.Layout.Column = 5 + app.MassSparsityButton.Visible;
% Also, make sure the hidden buttons are false so corresponding controls
% are not visible either
if showM
    app.NonNegVarsButton.Value = false;
else
    app.InitialSlopeButton.Value = false;
end
if mtype < 3
    app.MassSparsityButton.Value = false;
end
if ~app.HasNumericParams
    app.SensitivityButton.Value = false;
end
% Enable based on whether we have f, M, p, and y0 defined (as needed)
% Visible based on corresponding button in first row
hasProblem = hasProblem && ~isempty(app.OdefunSelector.Value) && ...
    ~waitingOnParameters(app) && ~isWaiting(app.MassMatrixOps) && ...
    ~isempty(app.InitialValueVS.Value);
app.JacobianLabel.Visible = app.JacobianButton.Value;
app.JacobianOps.Enable = hasProblem;
app.JacobianOps.Visible = app.JacobianButton.Value;
showEvents = app.EventsButton.Value;
app.EventLabel.Visible = showEvents;
app.EventOps.Visible = showEvents;
app.EventOps.Enable = hasProblem;
problemGrid = app.Accordion.Children(2).Children;
% Can't use 'fit' to hide Events row because we can't unparent the icon. It
% stops being a target of the popout. Instead toggle the RowHeight manually
% with a pixel height of 0 or 22.
problemGrid.RowHeight{3} = showEvents*22;
app.InitialSlopeLabel.Visible = app.InitialSlopeButton.Value;
app.InitialSlopeVS.Visible = app.InitialSlopeButton.Value;
app.InitialSlopeVS.Enable = hasProblem;
app.NonNegVarsLabel.Visible = app.NonNegVarsButton.Value;
app.NonNegVarsVS.Visible = app.NonNegVarsButton.Value;
app.NonNegVarsVS.Enable = hasProblem;
app.MassSparsityLabel.Visible = app.MassSparsityButton.Value;
app.MassSparsityDD.Visible = app.MassSparsityButton.Value;
app.MassSparsityDD.Enable = hasProblem;
% Parent/Unparent controls based on visibility so 'fit' width/height is
% calculated correctly
matlab.internal.dataui.setParentForWidgets([app.InitialSlopeButton ...
    app.NonNegVarsButton app.MassSparsityButton app.SensitivityButton ...
    app.JacobianLabel app.JacobianOps app.InitialSlopeLabel app.InitialSlopeVS ...
    app.NonNegVarsLabel app.NonNegVarsVS app.EventLabel ...
    app.MassSparsityLabel app.MassSparsityDD],problemGrid)

%%%% Update Section 3: Solver Options %%%%
app.SolverDropdown.Enable = hasProblem;
app.AbsTolEditField.Enable = hasProblem;
app.RelTolEditField.Enable = hasProblem;
app.InitialStepEditField.Enable = hasProblem;
app.MaxStepEditField.Enable = hasProblem;
app.MinStepEditField.Enable = hasProblem;
app.NormControlCB.Enable = hasProblem;
app.VectorizationCB.Enable = hasProblem;
app.MaxOrderSpinner.Enable = hasProblem;
app.BDFCB.Enable = hasProblem;
app.DetectStiffnessCB.Enable = hasProblem;
% SolverDropdown Tooltip is dynamic, based on selection
app.SolverDropdown.Tooltip = app.getMsgText("SolverTooltip_" + app.SolverDropdown.Value);

prevSolver = app.OdeObj.SelectedSolver;
doStiffnessDetection = isequal(app.SolverDropdown.Value,"auto") && app.DetectStiffnessCB.Value;
if hasProblem && ~doStiffnessDetection
    % Update internal object to get things like SelectedSolver, current
    % SolverOptions, and Refine default. Using isInternal guarantees
    % generated script doesn't rely on functions or workspace variables we
    % don't have access to.
    % If doing stiffness detection, the point is moot since we won't know
    % selected solver until user runs generated code.
    isInternal = true;
    app.OdeObj = eval(generateScriptODECall(app,'',isInternal));
else
    app.OdeObj = ode();
end
showSolverOptions = ~matches(app.SolverDropdown.Value,["auto" "stiff" "nonstiff"]);
% To display the solver, need 'string' to display from enum 
solverStr = string(app.OdeObj.SelectedSolver);
if showSolverOptions
    % e.g. "Specify solver options: ode113"
    sectionTitle = app.getMsgText("SectionTitle3Solver") + ": " + solverStr;
else
    % Get user-facing name of 'auto','stiff', or 'nonstiff'    
    type = app.SolverDropdown.Items(matches(app.SolverDropdown.ItemsData,app.SolverDropdown.Value));
    % e.g. "Specify solver options: Automatic"
    sectionTitle = app.getMsgText("SectionTitle3Solver") + ": " + type;
    if ~doStiffnessDetection
        % e.g. "Specify solver options: Automatic nonstiff (ode45)"
        sectionTitle = sectionTitle + " (" + solverStr +")";
    end
end
app.Accordion.Children(3).Title = sectionTitle;
currentSolverOpts = properties(app.OdeObj.SolverOptions);
showInitialStep = showSolverOptions && matches("InitialStep",currentSolverOpts);
app.InitialStepLabel.Visible = showInitialStep;
app.InitialStepEditField.Visible = showInitialStep;
showMaxStep = showSolverOptions && matches("MaxStep",currentSolverOpts);
app.MaxStepLabel.Visible = showMaxStep;
app.MaxStepEditField.Visible = showMaxStep;
showMinStep = showSolverOptions && matches("MinStep",currentSolverOpts);
app.MinStepLabel.Visible = showMinStep;
app.MinStepEditField.Visible = showMinStep;
app.NormControlCB.Visible = showSolverOptions && matches("NormControl",currentSolverOpts);
app.VectorizationCB.Visible = showSolverOptions && matches("Vectorization",currentSolverOpts);
showMaxOrder = showSolverOptions && matches("MaxOrder",currentSolverOpts);
app.MaxOrderLabel.Visible = showMaxOrder;
app.MaxOrderSpinner.Visible = showMaxOrder;
if showMinStep % case ~Sundials solvers
    % Max order doesn't fit on row 2, move to row 3
    app.MaxOrderLabel.Layout.Row = 3;
    app.MaxOrderLabel.Layout.Column = [1 2];
    app.MaxOrderSpinner.Layout.Row = 3;
    app.MaxOrderSpinner.Layout.Column = 3;
    % Max step is shifted right, giving space for MinStep
    app.MaxStepLabel.Layout.Column = 8;
    app.MaxStepEditField.Layout.Column = 9;
else % case Sundials solvers
    % Max order should be on row 2 after Abstol & Reltol
    app.MaxOrderLabel.Layout.Row = 2;
    app.MaxOrderLabel.Layout.Column = 6;
    app.MaxOrderSpinner.Layout.Row = 2;
    app.MaxOrderSpinner.Layout.Column = 7;
    % Max step is shifted left, to MinStep's place
    app.MaxStepLabel.Layout.Column = 6;
    app.MaxStepEditField.Layout.Column = 7;
end
app.BDFCB.Visible = showSolverOptions && matches("BDF",currentSolverOpts);
app.DetectStiffnessCB.Visible = isequal("auto",app.SolverDropdown.Value);
matlab.internal.dataui.setParentForWidgets([app.InitialStepLabel ...
    app.InitialStepEditField app.MaxStepLabel app.MaxStepEditField ...
    app.MinStepLabel app.MinStepEditField app.NormControlCB app.VectorizationCB ...
    app.MaxOrderLabel app.MaxOrderSpinner app.BDFCB app.DetectStiffnessCB],...
    app.SolverDropdown.Parent);

%%%% Update section 4: Solve ODE %%%%
app.SolutionTypeDD.Enable = hasProblem;
app.TimeRangeEditField1.Enable = hasProblem;
app.TimeRangeEditField2.Enable = hasProblem;
app.TimeVectorSelector.Enable = hasProblem;
app.InterpolateTypeDD.Enable = hasProblem;
app.ExtensionCB.Enable = hasProblem;
app.RefineSpinner.Enable = hasProblem;
if ~isequal(prevSolver,app.OdeObj.SelectedSolver) && nargin > 1 % not from set.State
    % Solver has just been updated, reset the value of 'Refine' to new
    % default based on default for that solver
    app.RefineSpinner.Value = app.OdeObj.SolverOptions.DefaultRefine;
end
doTimeRange = isequal(app.SolutionTypeDD.Value,"solveRange");
app.TimeRangeEditField1.Visible = doTimeRange;
app.TimeRangeEditField2.Visible = doTimeRange;
app.TimeVectorSelector.Visible = ~doTimeRange;
app.InterpolateTypeDD.Visible = doTimeRange;
doRefine = isequal(app.InterpolateTypeDD.Value,"refine");
app.RefineSpinner.Visible = doTimeRange && doRefine;
doSolutionFcn = doTimeRange && ~doRefine;
app.ExtensionCB.Visible = doSolutionFcn;
app.SolFcnHelpIcon.Visible = doSolutionFcn;
matlab.internal.dataui.setParentForWidgets([...
    app.TimeRangeEditField1 app.TimeRangeEditField2 app.TimeVectorSelector ...
    app.InterpolateTypeDD app.SolFcnHelpIcon ...
    app.RefineSpinner app.ExtensionCB],app.SolutionTypeDD.Parent);

%%%% Update section 5: Display %%%%
app.DisplayDD.Enable = hasProblem;
app.DisplayTypeDD.Enable = hasProblem;
app.DisplayVariablesVS.Enable = hasProblem;
app.DisplayEventsCB.Enable = hasProblem;
app.DisplaySensitivityCB.Enable = hasProblem;
% Hide 'during/final' option when we can't do 'during':
% solutionFcn method doesn't call OutputFcn SolverOption, and some solvers
% don't have OutputFcn SolverOption (and if detecting stiffness, we don't
% know the solver)
app.DisplayTypeDD.Visible = ~isequal(app.DisplayDD.Value,"none") && ~doSolutionFcn && ...
    matches("OutputFcn",currentSolverOpts) && ~doStiffnessDetection;
if ~app.DisplayTypeDD.Visible
    % Only 'final' is available when this dd is hidden
    app.DisplayTypeDD.Value = "final";
end
% Only show DisplayVariablesVS (OutputVariables) conditionally: Generally,
% when user has an actual choice in variables to plot
hideDispVars = app.NumY0 <= 1 || isequal(app.DisplayDD.Value,"none") || ...
    (isequal(app.DisplayDD.Value,"phas2") && app.NumY0 <= 2) ||...
    (isequal(app.DisplayDD.Value,"phas3") && app.NumY0 <= 3);
app.DisplayVariablesLabel.Visible = ~hideDispVars;
app.DisplayVariablesVS.Visible = ~hideDispVars;
% Only show DisplayEventsCB conditionally
isFinalPlot = isequal(app.DisplayDD.Value,"plot") && ...
    isequal(app.DisplayTypeDD.Value,"final");
app.DisplayEventsCB.Visible =  isFinalPlot && app.EventsButton.Value && ...
    ~isempty(app.EventOps.EventfunSelector.Value);
% Only show DisplaySensitivityCB conditionally
app.DisplaySensitivityCB.Visible = isFinalPlot && app.SensitivityButton.Value;
matlab.internal.dataui.setParentForWidgets([app.DisplayTypeDD app.DisplayVariablesLabel ...
    app.DisplayVariablesVS app.DisplayEventsCB app.DisplaySensitivityCB],...
    app.Accordion.Children(5).Children);

%%%% Wrap up doUpdate %%%%
% We've now updated everything necessary for the Editor to get a new State
% and generated code, time to notify
notify(app,"StateChanged")
% With undo/redo, icons can go invisible without user clicking away.
% Make sure the popouts don't linger
if mtype < 2
    close(app.MassMatrixOps.Popout)
end
if ~app.EventOps.Visible
    close(app.EventOps.Popout)
end
end