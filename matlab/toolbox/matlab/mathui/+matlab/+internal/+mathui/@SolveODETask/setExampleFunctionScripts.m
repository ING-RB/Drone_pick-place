function setExampleFunctionScripts(app)
% Method of the SolveODETask that sets the defaults and examples for the
% FunctionSelectors in the task based on the problem type and parameters
%
%   FOR INTERNAL USE ONLY -- This feature is intentionally undocumented.
%   Its behavior may change, or it may be removed in a future release.

% Copyright 2024 The MathWorks, Inc.
if app.ParametersCB.Value
    commaP = ',p';
    beta = 'p(1)';
    delta = 'p(2)';
else
    commaP = '';
    beta = '0.01';
    delta = '0.02';
end
% Indent the local functions based on user preference
s = settings;
if isequal(s.matlab.editor.language.matlab.FunctionIndentingFormat.ActiveValue,...
        'AllFunctionIndent')
    tab = '    ';
else
    tab = '';
end
helpM = '';
commaY = ',y';
switch  app.MassMatrixOps.MType
    case 0
        form = ['dy/dt = f(t,y' commaP ')'];
    case 1
        form = ['M*dy/dt = f(t,y' commaP ')'];
        helpM = [newline tab '% ' getMsgText('MConstant')];
    case 2
        form = ['M(t' commaP ')*dy/dt = f(t,y' commaP ')'];
        helpM = [newline tab '% ' getMsgText('MFunction',['M(t' commaP ')'])];
        commaY = '';
    case 3
        form = ['M(t,y' commaP ')*dy/dt = f(t,y' commaP ')'];
        helpM = [newline tab '% ' getMsgText('MFunction',['M(t,y' commaP ')'])];
end

app.OdefunSelector.NewFcnText = [newline 'function out = ' app.ExampleODEName '(t,y' commaP ')' ...
    newline tab '% ' getMsgText('ODEFcn',form)...
    helpM ...
    newline ...
    newline tab '% ' getMsgText('PredPrey') ...
    newline tab 'out = [y(1) .* (1 - ' beta '*y(2));' ...
    newline tab '    y(2) .* (-1 + ' delta '*y(1))];' ...
    newline 'end'];
app.OdefunSelector.HandleDefault = ['@(t,y' commaP ') [y(1); y(2)]'];
app.OdefunSelector.resetToDefault();

app.MassMatrixOps.FcnSelector.NewFcnText = [newline 'function M = ' app.ExampleMassName '(t' commaY commaP ')' ...
    newline tab '% ' getMsgText('MassMatrix',form) ...
    newline tab 'M = [1 0; 0 1];' newline 'end'];
app.MassMatrixOps.FcnSelector.HandleDefault = ['@(t'  commaY commaP  ') [1 0; 0 1]'];
app.MassMatrixOps.FcnSelector.resetToDefault();

app.JacobianOps.FcnSelector.NewFcnText = [newline 'function dfdy = ' app.ExampleJacobianName '(t,y' commaP ')' ...
    newline tab '% ' getMsgText('Jacobian1') ...
    newline tab '% ' getMsgText('Jacobian2')  ...
    newline tab 'dfdy = [0 1; 0 -t];' newline 'end'];
app.JacobianOps.FcnSelector.HandleDefault = ['@(t,y' commaP ') [0 1; 0 -t]'];
app.JacobianOps.FcnSelector.resetToDefault();

app.EventOps.EventfunSelector.NewFcnText = [newline 'function v = ' app.ExampleEventName '(t,y' commaP ')' ...
    newline tab '% ' getMsgText('EventDefinition') ...
    newline tab 'v = y(1);' newline 'end'];
app.EventOps.EventfunSelector.HandleDefault = ['@(t,y' commaP ') y(1)'];
app.EventOps.EventfunSelector.resetToDefault();

app.EventOps.CallbackSelector.NewFcnText = [newline 'function [stop,y] = ' app.ExampleEventCallbackName '(t,y' commaP ')' ...
    newline tab '% ' getMsgText('EventCallback') ...
    newline tab 'display(t);' ...
    newline tab 'stop = false;' newline 'end'];
app.EventOps.CallbackSelector.HandleDefault = ['@(t,y' commaP ') disp(t)'];
app.EventOps.CallbackSelector.resetToDefault();
end

function str = getMsgText(id,varargin)
% Get the appropriate translated label or message
str = getString(message("MATLAB:mathui:CodeComment" + id,varargin{:}));
end