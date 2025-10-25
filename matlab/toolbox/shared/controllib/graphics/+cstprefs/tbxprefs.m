function prefs = tbxprefs
%% Creates toolbox preferences.
%    Toolbox preferences:
%       FrequencyUnits - Property is of type 'string'
%       FrequencyScale - Property is of type 'string'
%       MagnitudeUnits - Property is of type 'string'
%       MagnitudeScale - Property is of type 'string'
%       PhaseUnits - Property is of type 'string'
%       TimeUnits - Property is of type 'string'
%       Grid - Property is of type 'string'
%       TitleFontSize - Property is of type 'MATLAB array'
%       TitleFontWeight - Property is of type 'string'
%       TitleFontAngle - Property is of type 'string'
%       XYLabelsFontSize - Property is of type 'MATLAB array'
%       XYLabelsFontWeight - Property is of type 'string'
%       XYLabelsFontAngle - Property is of type 'string'
%       AxesFontSize - Property is of type 'MATLAB array'
%       AxesFontWeight - Property is of type 'string'
%       AxesFontAngle - Property is of type 'string'
%       IOLabelsFontSize - Property is of type 'MATLAB array'
%       IOLabelsFontWeight - Property is of type 'string'
%       IOLabelsFontAngle - Property is of type 'string'
%       AxesForegroundColor - Property is of type 'MATLAB array'
%       GridColor - Property is of type 'MATLAB array'
%       SettlingTimeThreshold - Property is of type 'MATLAB array'
%       RiseTimeLimits - Property is of type 'MATLAB array'
%       UnwrapPhase - Property is of type 'string'
%       PhaseWrappingBranch - Property is of type 'MATLAB array'
%       ComparePhase - Property is of type 'MATLAB array'
%       MinGainLimit - Property is of type 'MATLAB array'
%       PIDTunerPreferences - Property is of type 'MATLAB array'
%       CompensatorFormat - Property is of type 'string'
%       ShowSystemPZ - Property is of type 'string'
%       SISOToolStyle - Property is of type 'MATLAB array'
%       UIFontSize - Property is of type 'MATLAB array'
%       JavaFontSize - Property is of type 'MATLAB array'
%       JavaFontP - Property is of type 'MATLAB array'
%       JavaFontB - Property is of type 'MATLAB array'
%       JavaFontI - Property is of type 'MATLAB array'
%       Version - Property is of type 'MATLAB array'
%       StartUpMsgBox - Property is of type 'MATLAB array'
%
%    Toolbox preference methods:
%       edit -  Opens GUI for editing toolbox preferences
%       load -  Loads toolbox preferences from a file
%       save -  Saves current toolbox preferences to a file
%
%    Example:
%        %% Create toolbox preferences.
%        prefs = cstprefs.tbxprefs;
%        
%        %% Edit toolbox preferences using UI.
%        edit(prefs)
%
%        %% Update and save toolbox preferences.
%        prefs.Grid = 'on';
%        save(prefs,<fileName>)
%
%        %% Load toolbox preferences from a file.
%        load(prefs,<fileName>)
%
%    See also cstprefs.viewprefs

%  Copyright 1986-2021 The MathWorks, Inc.

prefs = controllib.widget.internal.cstprefs.ToolboxPreferences.getInstance;
end