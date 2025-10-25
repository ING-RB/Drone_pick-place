function [code,outputs] = generateCode(app)
% Method of the SolveODETask that generates the script stored in CODE for
% the live task. When CODE is executed, the variables specified by OUTPUTS
% are generated. This method is required by the live task base class.
%
%   FOR INTERNAL USE ONLY -- This feature is intentionally undocumented.
%   Its behavior may change, or it may be removed in a future release.

% Copyright 2024 The MathWorks, Inc.

outputs = {};
% Always generate code since there is a good chance user has local
% functions in the file and there may not be any other code to prevent the
% editor from thinking the script is a function file.
if isempty(app.OdefunSelector.Value)
    code = "disp(""" + getMsgText("DispODEFcn") + """);";
    return
elseif isWaiting(app.MassMatrixOps)
    if app.MassMatrixOps.MType == 1
        code = "disp(""" + getMsgText("DispMassConstant") + """);";
    else
        code = "disp(""" + getMsgText("DispMassFunction") + """);";
    end
    return
elseif waitingOnParameters(app)
    code = "disp(""" + getMsgText("DispParameters") + """);";
    return
elseif isempty(app.InitialValueVS.Value)
    code = "disp(""" + getMsgText("DispInitialValue") + """);";
    return
end

% Get the script for the ODE call
doOutputFcn = ~isequal(app.DisplayDD.Value,"none") && isequal(app.DisplayTypeDD.Value,"live");
if doOutputFcn
    % even if user wants 'auto' solver, we need to send in the selected
    % solver so that we can set OutputFcn
    odeCall = generateScriptODECall(app,string(app.OdeObj.SelectedSolver),false);
else
    odeCall = generateScriptODECall(app,'',false);
end
code = "% " + getMsgText("SetupODE") +  newline + "odeObj = " + odeCall;
tempVars = "odeObj";
doStiffnessDetection = app.DetectStiffnessCB.Visible && app.DetectStiffnessCB.Value;
if doStiffnessDetection
    % Calculate interval length
    if isequal(app.SolutionTypeDD.Value,"solveVector")
        if isequal(app.TimeVectorSelector.DropDown.Value,"ef")
            % user has typed out a vector, calculate interval length and
            % print answer
            vec = app.TimeVectorSelector.NumValue;
            interval = num2str(max(vec) - min(vec));
        else
            % using a workspace variable, calculate interval lenth in
            % generated code
            vec = app.TimeVectorSelector.Value;
            interval = "max(" + vec + ") - min(" + vec + ")";
        end
    else
        % User has specified start and end times (not necessarily in
        % order), calculate interval length and print answer
        interval = num2str(abs(app.TimeRangeEditField2.Value - app.TimeRangeEditField1.Value));
    end
    code = code + newline + "odeObj.Solver = selectSolver(odeObj,DetectStiffness = ""on"", ...";
    code = code + newline + "    IntervalLength = " + interval + ");";
else
    % Set solver options (when user has selected non-default values)
    if app.InitialStepEditField.Visible && ~isempty(app.InitialStepEditField.Value)
        code = code + newline + "odeObj.SolverOptions.InitialStep = " + app.InitialStepEditField.Value + ";";
    end
    if app.MaxStepEditField.Visible && ~isempty(app.MaxStepEditField.Value)
        code = code + newline + "odeObj.SolverOptions.MaxStep = " + app.MaxStepEditField.Value + ";";
    end
    if app.MinStepEditField.Visible && ~isempty(app.MinStepEditField.Value)
        code = code + newline + "odeObj.SolverOptions.MinStep = " + app.MinStepEditField.Value + ";";
    end
    if app.NormControlCB.Visible && app.NormControlCB.Value
        code = code + newline + "odeObj.SolverOptions.NormControl = ""on"";";
    end
    if app.MaxOrderSpinner.Visible && app.MaxOrderSpinner.Value ~= 5
        code = code + newline + "odeObj.SolverOptions.MaxOrder = " + app.MaxOrderSpinner.Value + ";";
    end
    if app.VectorizationCB.Visible && app.VectorizationCB.Value
        code = code + newline + "odeObj.SolverOptions.Vectorization = ""on"";";
    end
    if app.BDFCB.Visible && app.BDFCB.Value
        code = code + newline + "odeObj.SolverOptions.BDF = ""on"";";
    end
end

% For plotting 'during' solve, set the OutputFunction to a local function
% that we will generate at the end of the script we are writing
if doOutputFcn
    switch app.DisplayDD.Value
        case "plot"
            fun = "@plotsolution";
        case "phas2"
            fun = "@plotphas2";
        case "phas3"
            fun = "@plotphas3";
    end
    code = code + newline + "odeObj.SolverOptions.OutputFcn = " + fun + ";";
    if app.DisplayVariablesVS.Visible && ~isequal(app.DisplayVariablesVS.NumValue,1:app.NumY0)
        code = code + newline + "odeObj.SolverOptions.OutputSelection = " + app.DisplayVariablesVS.Value + ";";
    end
end
% Generate the call to the solve or solutionFcn method to get the output(s)
code = code + newline + newline + "% " + getMsgText("SolveODE") + newline;
if isequal(app.SolutionTypeDD.Value,"solveVector")
    outputs = {'solData'};
    code = code + "solData = solve(odeObj," + app.TimeVectorSelector.Value + ");";
elseif isequal(app.InterpolateTypeDD.Value,"refine")
    outputs = {'solData'};
    code = code + "solData = solve(odeObj," + ...
        app.TimeRangeEditField1.Value + "," + app.TimeRangeEditField2.Value;
    if (app.RefineSpinner.Value ~= app.OdeObj.SolverOptions.DefaultRefine) || ...
            doStiffnessDetection
        % Only pass in refinement factor if non-default, except if
        % detecting stiffness, then default value is unknown until after
        % script is run
        code = code + ",Refine = " + app.RefineSpinner.Value;
    end
    code = code + ");";
else % Use solutionFcn method
    outputs = {'solData' 'solFun'};
    code = code + "[solFun,solData] = solutionFcn(odeObj," + ...
        app.TimeRangeEditField1.Value + "," + app.TimeRangeEditField2.Value;
    if app.ExtensionCB.Value
        code = code + ",Extension=""on""";
    end
    code = code + ");";
end

% Generate the local function that will be used as the OutputFcn
vars = app.DisplayVariablesVS.NumValue;
if isequal(app.DisplayTypeDD.Value,"live")
    switch app.DisplayDD.Value
        case "plot"
            plotfun = @generateCodeOdePlot;
        case "phas2"
            plotfun = @generateCodeOdePhas2;
        case "phas3"
            plotfun = @generateCodeOdePhas3;
    end
    code = code + newline + newline + plotfun(vars);
    code = code + newline + "clear " + tempVars;
    return
end
% Generate plot code
if isequal(app.DisplayDD.Value,"plot")
    % Generate code to plot solution vs time for the selected variables
    % Additionally, add lines for events if specified
    % Additionally, generate plots for sensitivity if specified
    code = code + newline + newline + "% " + getMsgText("PlotSolution");
    if ~isequal(vars,1:app.NumY0)
        % index into solData.Solution
        plotidx = "(" + app.DisplayVariablesVS.Value + ",:)";
        % index into solData.Sensitivity (if needed)
        plotidxSens = "(" + app.DisplayVariablesVS.Value + ",p,:)";
    else
        plotidx = "";
        plotidxSens = "(:,p,:)";
    end
    code = code + newline + "plot(solData.Time,solData.Solution" + plotidx + ","".-"");";
    code = code + newline + "ylabel(""" + getMsgText("SolutionLabel") +""")";
    code = code + newline + "xlabel(""" + getMsgText("TimeLabel") +""")";
    code = code + newline + "title(""" + getMsgText("PlotSolutionTitle") +""")";
    varNames = strjoin("""y_" + vars,""",") + """";
    code = code + newline + "legend(" + varNames + ")";
    plotEvents = app.DisplayEventsCB.Value && app.DisplayEventsCB.Visible;
    if plotEvents
        % Like xline, but make it so only one legend item appears
        % Matches vertical lines created using DataPreprocessingTask
        code = code + newline + "ev = repelem(solData.EventTime,3);";
        code = code + newline + "y = repmat([ylim(gca) missing],1,numel(solData.EventTime));";
        tempVars = tempVars + " ev y";
        code = code + newline + "hold on";
        % Use SeriesIndex = "none" to create black lines in light mode and
        % white lines in dark mode
        code = code + newline + "plot(ev,y,SeriesIndex = ""none"",DisplayName = """ + ...
            string(message("MATLAB:mathui:EventsButtonLabel")) + """);";
        code = code + newline + "hold off";
    end
    if app.DisplaySensitivityCB.Visible && app.DisplaySensitivityCB.Value
        % Add a second figure displaying sensitivity in a tiledlayout
        tempVars = tempVars + " f t p";
        code = code + newline + newline + generateCodePlotSensitivity(vars,...
            varNames,app.ParametersWSDD.Value,plotidx,plotidxSens,plotEvents);
    end
elseif isequal(app.DisplayDD.Value,"phas2")
    % Generate code for 2D phase plot (plotting events and sensitivity not
    % supported with this plot type)
    code = code + newline + newline + "% " + getMsgText("PlotPhas2");
    code = code + newline + "plot(solData.Solution(" + vars(1) + ",:)," + ...
        "solData.Solution(" + vars(2) + ",:),"".-"");";
    code = code + newline + "xlabel(""y_" + vars(1) + """)";
    code = code + newline + "ylabel(""y_" + vars(2) + """)";
    code = code + newline + "title(""" + getMsgText("PlotPhas2Title") + """)";
elseif isequal(app.DisplayDD.Value,"phas3")
    % Generate code for 3D phase plot (plotting events and sensitivity not
    % supported with this plot type)
    code = code + newline + newline + "% " + getMsgText("PlotPhas3");
    code = code + newline + "plot3(solData.Solution(" + vars(1) + ",:)," + ...
        "solData.Solution(" + vars(2) + ",:)," + ...
        "solData.Solution(" + vars(3) + ",:),"".-"");";
    code = code + newline + "xlabel(""y_" + vars(1) + """)";
    code = code + newline + "ylabel(""y_" + vars(2) + """)";
    code = code + newline + "zlabel(""y_" + vars(3) + """)";
    code = code + newline + "title(""" + getMsgText("PlotPhas3Title") + """)";
end % else no plot

% Finally, clear any temporary variables
code = code + newline + "clear " + tempVars;
end

% Helpers
function str = generateCodeOdePlot(vars)
varNames = "(" + strjoin("""y_" + vars,""",") + """)";
tab = getTab();
str = "function status = plotsolution(t,y,flag)" + newline + tab +...
    "% " + getMsgText("OutputFcn") + ":" + newline + tab +...
    "% " + getMsgText("PlotSolutionAnim") + newline + tab +...
    "status = 0;" + newline + tab +...
    "switch flag" + newline + tab +...
    "    case ""init""" + newline + tab +...
    "        figure" + newline + tab +...
    "        plot(t(1),y,"".-"");" + newline + tab +...
    "        xlim([min(t) max(t)]);" + newline + tab +...
    "        title(""" + getMsgText("PlotSolutionTitle") + """)" + newline + tab +...
    "        xlabel(""" + getMsgText("TimeLabel") + """)" + newline + tab +...
    "        ylabel(""" + getMsgText("SolutionLabel") + """)" + newline + tab +...
    "        legend" + varNames + newline + tab +...
    "        drawnow" + newline + tab +...
    "    case ""done""" + newline + tab +...
    "        drawnow" + newline + tab +...
    "otherwise" + newline + tab +...
    "    linePlots = flip(get(gca,""Children""));" + newline + tab +...
    "    for i = 1 : numel(linePlots)" + newline + tab +...
    "        linePlots(i).YData = [linePlots(i).YData y(i,:)];" + newline + tab +...
    "        linePlots(i).XData = [linePlots(i).XData t];" + newline + tab +...
    "    end" + newline + tab +...
    "    drawnow limitrate" + newline + tab +...
    "end" + newline + ...
    "end";
end

function str = generateCodeOdePhas2(vars)
tab = getTab();
str = "function status = plotphas2(~,y,flag)" + newline + tab +...
    "% " + getMsgText("OutputFcn") + ":" + newline + tab +...
    "% " + getMsgText("PlotPhas2Anim") + newline + tab +...
    "status = 0;" + newline + tab +...
    "switch flag" + newline + tab +...
    "    case ""init""" + newline + tab +...
    "        figure" + newline + tab +...
    "        plot(y(1),y(2),"".-"");" + newline + tab +...
    "        xlabel(""y_" + vars(1) + """)" + newline + tab +...
    "        ylabel(""y_" + vars(2) + """)" + newline + tab +...
    "        title(""" + getMsgText("PlotPhas2Title") + """)" + newline + tab +...
    "        drawnow" + newline + tab +...
    "    case ""done""" + newline + tab +...
    "        drawnow" + newline + tab +...
    "    otherwise" + newline + tab +...
    "        linePlot = get(gca,""Children"");" + newline + tab +...
    "        linePlot.XData = [linePlot.XData y(1,:)];" + newline + tab +...
    "        linePlot.YData = [linePlot.YData y(2,:)];" + newline + tab +...
    "        drawnow limitrate" + newline + tab +...
    "end" + newline + tab +...
    "end";
end

function str = generateCodeOdePhas3(vars)
tab = getTab();
str = "function status = plotphas3(~,y,flag)" + newline + tab +...
    "% " + getMsgText("OutputFcn") + ":" + newline + tab +...
    "% " + getMsgText("PlotPhas3Anim") + newline + tab +...
    "status = 0;" + newline + tab +...
    "switch flag" + newline + tab +...
    "    case ""init""" + newline + ...
    "        plot3(y(1),y(2),y(3),'.-');" + newline + tab +...
    "        xlabel(""y_" + vars(1) + """)" + newline + tab +...
    "        ylabel(""y_" + vars(2) + """)" + newline + tab +...
    "        zlabel(""y_" + vars(3) + """)" + newline + tab +...
    "        title(""" + getMsgText("PlotPhas3Title") + """)" + newline + tab +...
    "        grid on" + newline + tab +...
    "        drawnow" + newline + tab +...
    "    case ""done""" + newline + tab +...
    "        drawnow" + newline + tab +...
    "    otherwise" + newline + tab +...
    "        linePlot = get(gca,""Children"");" + newline + tab +...
    "        linePlot.XData = [linePlot.XData y(1,:)];" + newline + tab +...
    "        linePlot.YData = [linePlot.YData y(2,:)];" + newline + tab +...
    "        linePlot.ZData = [linePlot.ZData y(3,:)];" + newline + tab +...
    "        drawnow limitrate;" + newline + tab +...
    "end" + newline + ...
    "end";
end

function tab = getTab
% Indent the local functions based on user preference
s = settings;
if isequal(s.matlab.editor.language.matlab.FunctionIndentingFormat.ActiveValue,...
        'AllFunctionIndent')
    tab = "    ";
else
    tab = "";
end
end

function str = generateCodePlotSensitivity(vars,varNames,params,idx1,idx2,plotEvents)
% Since sensitivity is returned as 3D, we will use squeeze to get the
% appropriate 2D result for each plot
if isscalar(vars)
    % squeeze pushes sensitivity results into column, need transpose to
    % make it row to match orientation of solution
    tick = "'";
else
    tick = "";
end
str = "% " + getMsgText("PlotSensitivity");
str = str + newline + "f = figure(Units = ""normalized"");";
% Change height of figure based on num params, matches behavior of
% DataPreprocessingTask's multi variable plots
str = str + newline + "f.Position(4) = (numel(" + params + ")/2)*f.Position(3);";
str = str + newline + "t = tiledlayout(numel(" + params + "),1);";
str = str + newline + "ylabel(t,""" + getMsgText("PlotSensitivityAxesLabel") + """)";
str = str + newline + "for p = 1:numel(" + params + ")";
str = str + newline + "    nexttile";
str = str + newline + "    plot(solData.Time,squeeze(solData.Sensitivity" + idx2 +")" + tick + ".* ...";
str = str + newline + "        (params(p)./solData.Solution" + idx1 + "),"".-"");";
str = str + newline + "    ylabel(""p_"" + p)";
str = str + newline + "    if p == 1";
% Plot title and legend only on first tile. Visually these work for all the tiles
str = str + newline + "        title([""" + getMsgText("PlotSensitivityTitle") +""",""p = "" + mat2str(" + params + ")])";
str = str + newline + "        legend(" + varNames + ",Location = ""eastoutside"")";
str = str + newline + "    end";
str = str + newline + "    hold on";
% Add a base line for readablility. Color is a gray that works in dark and light mode
str = str + newline + "    yline(0,Color = [145 145 145]/255,DisplayName = """ + getMsgText("PlotSensitivityNoEffect") +""")";
if plotEvents
    % Add vertical lines for events matching main plot. Same "ev" as we
    % already calculated, but each plot is a different height, so we need a
    % new y each loop.
    str = str + newline + "    y = repmat([ylim(gca) missing],1,numel(solData.EventTime));";
    str = str + newline + "    plot(ev,y,SeriesIndex = ""none"",DisplayName = """ + ...
        string(message("MATLAB:mathui:EventsButtonLabel")) + """);";
end
str = str + newline + "    hold off";
str = str + newline + "end";
% Add xlabel after loop since we only need it on the last plot
str = str + newline + "xlabel(""" + getMsgText("TimeLabel") +""")";
% This acts like 'hold off' for tiledlayout
str = str + newline + "f.NextPlot = ""replaceChildren"";";
end

function str = getMsgText(id)
% Get the appropriate translated code comment or plot label
str = string(message("MATLAB:mathui:CodeComment" + id));
end