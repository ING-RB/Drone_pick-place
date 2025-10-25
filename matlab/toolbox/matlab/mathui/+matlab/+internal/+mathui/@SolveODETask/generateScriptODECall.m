function str = generateScriptODECall(app,solver,isInternalCall)
% Method of the SolveODETask that generates code for constructing an ode
% object based on selected values in the task. This is used for both the
% internal app.ODEObj and for the user-facing generated script.
%
%   FOR INTERNAL USE ONLY -- This feature is intentionally undocumented.
%   Its behavior may change, or it may be removed in a future release.

% Copyright 2024 The MathWorks, Inc.

% For the internal call, we can usa a dummyFcn for the function handle
% inputs, and dummy values from for the workspace values. This works
% because the ODE 'auto' solver does not currently evaluate the functions
% until calling a solve method. This makes it safe to call when the
% function is no longer on the path or in the script, or the workspace
% variable is no longer in the workspace

hasParams = app.ParametersCB.Value;
if isInternalCall
    if hasParams
        dummyFcn = '@(t,y,p) y';
    else
        dummyFcn = '@(t,y) y';
    end
    odefcnval = dummyFcn;
else
    odefcnval = app.OdefunSelector.Value;
end

% Note that f, M, p, and y0 are either not in the problem or required
% before attempting to generate the ode, so once we are here we don't need
% to check that we have a Value for those controls. However, all other
% control Values may or may not be empty at this point.

% Note also that we are not using the typical code-wrapper helper
% addCharToCode since each NV input is going on its own line.

%%%% Define Problem %%%%
% ODEFcn
str = "ode(ODEFcn = " + odefcnval;
% InitialValue
if isInternalCall
    % Cannot rely on base workspace values in internal eval
    iv = mat2str(app.InitialValueVS.NumValue);
else
    iv = app.InitialValueVS.Value;
end
str = str + ", ..." + newline + "    InitialValue = " + iv;
% InitialTime
if app.InitialTimeEditField.Value ~= 0
    str = str + ", ..." + newline + "    InitialTime = " + app.InitialTimeEditField.Value;
end % else 0 is the default, so no need to specify
% MassMatrix
if app.MassMatrixOps.MType
    % Most info stored in MassMatrixOps, but SparsityDD is separate
    M = getMassValue(app.MassMatrixOps,isInternalCall,app.NumY0);
    nvpairs = getNVValue(app.MassMatrixOps);
    sparsity = '';
    if app.MassSparsityButton.Value && ~isequal(app.MassSparsityDD.Value,app.WSDDselect)
        if isInternalCall
            sparsity = ", SparsityPattern = eye(" + app.NumY0 + ")";
        else
            sparsity = ", SparsityPattern = " + app.MassSparsityDD.Value;
        end
    end
    if isempty(nvpairs) && isempty(sparsity)
        str = str + ", ..." + newline + "    MassMatrix = " + M;
    else
        % Need the odeMassMatrix constructor
        str = str + ", ..." + newline + "    MassMatrix = odeMassMatrix(MassMatrix = " + M + nvpairs + sparsity + ")";
    end
end
% Parameters
if hasParams
    if isInternalCall
        % Cannot rely on base workspace values in internal eval
        val = "1";
    else
        val = app.ParametersWSDD.Value;
    end
    str = str + ", ..." + newline + "    Parameters = " + val;
end

%%%% Advanced Problem Options %%%%
% Jacobian
if app.JacobianButton.Value
    jac = getValue(app.JacobianOps,isInternalCall);
    if ~isempty(jac)
        str = str + ", ..." + newline + "    Jacobian = " + jac;
    end
end
% InitialSlope
if app.InitialSlopeButton.Value && ~isempty(app.InitialSlopeVS.Value)
    if isInternalCall
        % Cannot rely on base workspace values in internal eval
        val = mat2str(app.InitialSlopeVS.NumValue);
    else
        val = app.InitialSlopeVS.Value;
    end
    str = str + ", ..." + newline + "    InitialSlope = " + val;
end
% EventDefinition
if app.EventsButton.Value
    ev = getValue(app.EventOps,isInternalCall);
    if ~isempty(ev)
        str = str + ", ..." + newline + "    EventDefinition = " + ev;
    end
end
% NonNegativeVariables
if app.NonNegVarsButton.Value && ~isempty(app.NonNegVarsVS.Value)
    str = str + ", ..." + newline + "    NonNegativeVariables = " + app.NonNegVarsVS.Value;
end
% Sensitivity
if app.SensitivityButton.Value
    str = str + ", ..." + newline + "    Sensitivity = odeSensitivity";
end

%%%% Top-level solver options %%%%
% Note: solver-specific options are specified only in the external code and
% are specified after the ode constructor.
if isempty(solver)
    % In user-facing code, we may pass in the solver explicitly even though
    % user selection is 'auto' so that we can access SolverOptions for
    % plotting purposes
    solver = app.SolverDropdown.Value;
end
% Specify solver options only for non-default values
if ~isequal(solver,'auto')
    str = str + ", ..." + newline + "    Solver = """ + solver + """";
end
if ~isequal(app.AbsTolEditField.Value,1e-6)
    str = str + ", ..." + newline + "    AbsoluteTolerance = " + app.AbsTolEditField.Value;
end
if ~isequal(app.RelTolEditField.Value,1e-3)
    str = str + ", ..." + newline + "    RelativeTolerance = " + app.RelTolEditField.Value;
end

% End call to constructor
str = str + ");";
end