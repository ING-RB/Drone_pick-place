classdef (Hidden = true, AllowedSubclasses = ...
        {?matlab.internal.dataui.dataSmoother ...
        ?matlab.internal.dataui.missingDataCleaner ...
        ?matlab.internal.dataui.outlierDataCleaner ...
        ?matlab.internal.dataui.localExtremaFinder}) ...
        movwindowWidgets < handle & matlab.mixin.internal.Scalar
    % movwindowWidgets Helper for (moving) window widgets
    %
    %   FOR INTERNAL USE ONLY -- This feature is intentionally undocumented.
    %   Its behavior may change, or it may be removed in a future release.
    
    %   Copyright 2018-2024 The MathWorks, Inc.
    
    % All properties are Transient because we do not have a use-case for
    % saving and loading these objects.
    
    properties (Access = public, Transient, Hidden)
        WindowParentGrid    matlab.ui.container.GridLayout
        WindowLabel         matlab.ui.control.Label
        WindowTypeDropDown  matlab.ui.control.DropDown
        WindowSizeSpinner1  matlab.ui.control.Spinner
        WindowSizeSpinner2  matlab.ui.control.Spinner
        WindowUnitDropDown  matlab.ui.control.DropDown
        WindowUnitVisible   logical = false;
    end
    
    methods (Access = public, Hidden)
        
        function app = movwindowWidgets()
        end
        
        function createWindowWidgets(app,parentGrid,rowNum,startingCol,valueChangedFcn,label,unitTooltip)
            app.WindowParentGrid = parentGrid;
            
            % Layout
            if ~isempty(label)
                app.WindowLabel = uilabel(parentGrid,'Text',label);
                app.WindowLabel.Layout.Row = rowNum;
                app.WindowLabel.Layout.Column = startingCol;
                startingCol = startingCol + 1;
            end
            app.WindowTypeDropDown = uidropdown(parentGrid);
            app.WindowTypeDropDown.Layout.Row = rowNum;
            app.WindowTypeDropDown.Layout.Column = startingCol;
            app.WindowSizeSpinner1 = uispinner(parentGrid);
            app.WindowSizeSpinner2 = uispinner(parentGrid);
            app.WindowUnitDropDown = uidropdown(parentGrid);
            
            % Properties
            app.WindowTypeDropDown.Items = cellstr([getMsgText('Centered') getMsgText('Asymmetric')]);
            app.WindowTypeDropDown.ItemsData = {'full' 'half'};
            app.WindowTypeDropDown.Tooltip = getMsgText('WindowTypeTooltip');
            app.WindowTypeDropDown.ValueChangedFcn = valueChangedFcn;
            app.WindowTypeDropDown.Tag = 'WindowTypeDropDown';
            app.WindowSizeSpinner1.Limits = [0 Inf];
            app.WindowSizeSpinner1.UpperLimitInclusive = false;
            app.WindowSizeSpinner1.ValueChangedFcn = valueChangedFcn;
            app.WindowSizeSpinner1.Tooltip = getMsgText('WindowSizeTooltipCentered');
            app.WindowSizeSpinner1.Tag = 'WindowSizeSpinner1';
            app.WindowSizeSpinner2.Limits = [0 Inf];
            app.WindowSizeSpinner2.UpperLimitInclusive = false;
            app.WindowSizeSpinner2.ValueChangedFcn = valueChangedFcn;
            app.WindowSizeSpinner2.Tooltip = getMsgText('WindowSizeTooltip2');
            app.WindowSizeSpinner2.Tag = 'WindowSizeSpinner2';
            app.WindowUnitDropDown.Items = cellstr([getMsgText('Milliseconds') getMsgText('Seconds') ...
                getMsgText('Minutes') getMsgText('Hours') getMsgText('Days') getMsgText('Years')]);
            app.WindowUnitDropDown.ItemsData = {'milliseconds' 'seconds' 'minutes' 'hours' 'days' 'years'};
            app.WindowUnitDropDown.ValueChangedFcn = valueChangedFcn;
            app.WindowUnitDropDown.Tag = 'WindowUnitDropDown';
            if isempty(unitTooltip)
                app.WindowUnitDropDown.Tooltip = getMsgText('WindowUnitsTooltip');
            else
                app.WindowUnitDropDown.Tooltip = unitTooltip;
            end
        end
        
        function setWindowDefault(app,A,x)
            app.WindowUnitDropDown.Value = 'days';
            app.WindowSizeSpinner2.Value = 1;
            app.WindowTypeDropDown.Value = 'full';
            app.WindowSizeSpinner1.LowerLimitInclusive = false;
            
            if nargin < 2
                % Used for reset()
                app.WindowSizeSpinner1.Value = 1;
            else
                dim = matlab.internal.math.firstNonSingletonDim(A);
                A = full(A); % Auto window not supported for sparse vectors
                dv = [];
                if istimetable(A) || istable(A)
                    B = getSelectedSubTable(app,A);
                    if ~isempty(B)
                        A = B;
                        dv = 1:width(A);
                    else
                        % User has not selected any vars and no vars
                        % are valid inputs
                        app.WindowSizeSpinner1.Value = 1;
                        return
                    end
                end
                w = matlab.internal.math.chooseWindowSize(A,dim,x,0.75,dv);
                if isduration(x) || isdatetime(x)
                    % reset default unit
                    % possible units: milliseconds, seconds, minutes, hours, days, years
                    secondsInUnit = [1/1000 1 60 3600 86400 31556952];
                    % default to largest unit where value is non-fractional
                    % e.g. 30 minutes, not 0.5 hours
                    index = find(seconds(w) >= secondsInUnit,1,'last');
                    if isempty(index)
                        % less than a millisecond
                        index = 1;
                    end
                    app.WindowUnitDropDown.Value = app.WindowUnitDropDown.ItemsData{index};
                    w = feval(app.WindowUnitDropDown.Value,w);
                end
                % matlab.ui.control.Spinner.Value must be double
                app.WindowSizeSpinner1.Value = round(double(w),2,'significant');
            end
        end
        
        function setWindowType(app)
            if isequal(app.WindowTypeDropDown.Value,'full')
                app.WindowSizeSpinner1.Value = app.WindowSizeSpinner1.Value + app.WindowSizeSpinner2.Value;
                app.WindowSizeSpinner1.Tooltip = getMsgText('WindowSizeTooltipCentered');
                % window = 0 is not allowed
                app.WindowSizeSpinner1.LowerLimitInclusive = false;
            else
                app.WindowSizeSpinner1.Value = app.WindowSizeSpinner1.Value/2;
                app.WindowSizeSpinner2.Value = app.WindowSizeSpinner1.Value;
                app.WindowSizeSpinner1.Tooltip = getMsgText('WindowSizeTooltip1');
                % window = [0 0] is allowed
                app.WindowSizeSpinner1.LowerLimitInclusive = true;
            end
        end
        
        function setWindowVisibility(app,doOn,hasData,hasUnits)
            % set visibility
            if ~isempty(app.WindowLabel)
                app.WindowLabel.Visible = doOn;
            end
            app.WindowTypeDropDown.Visible = doOn;
            app.WindowSizeSpinner1.Visible = doOn;
            app.WindowSizeSpinner2.Visible = doOn && isequal(app.WindowTypeDropDown.Value,'half');
            if nargin == 4
                % When we can eval in base, also update unit visibility
                app.WindowUnitVisible = hasUnits;
            end
            app.WindowUnitDropDown.Visible = doOn && app.WindowUnitVisible;
            % unparent invisible widgets for correct 'fit' width
            for widget = {'WindowTypeDropDown' 'WindowSizeSpinner1' ...
                    'WindowSizeSpinner2' 'WindowUnitDropDown'}
                if isequal(app.(widget{1}).Visible,'on')
                    app.(widget{1}).Parent = app.WindowParentGrid;
                else
                    app.(widget{1}).Parent = [];
                end
            end
            % shift units dropdown depending on 2nd spinner visibility
            shiftRight = isequal(app.WindowSizeSpinner2.Visible,'on');
            app.WindowUnitDropDown.Layout.Column = app.WindowSizeSpinner2.Layout.Column + shiftRight;
            % set enable
            app.WindowTypeDropDown.Enable = hasData;
            app.WindowSizeSpinner1.Enable = hasData;
            app.WindowSizeSpinner2.Enable = hasData;
            app.WindowUnitDropDown.Enable = hasData;
        end
        
        function window = generateScriptForWindowSize(app)
            window = num2str(app.WindowSizeSpinner1.Value,'%.16g');
            if ~isequal(app.WindowTypeDropDown.Value,'full')
                window = ['[' window ' ' num2str(app.WindowSizeSpinner2.Value,'%.16g') ']'];
            end
            if app.WindowUnitVisible
                % milliseconds, seconds, minutes, days, years
                window = [app.WindowUnitDropDown.Value '(' window ')'];
            end
        end
        
        function state = getWindowDropDownValues(app,state)
            for k = {'WindowTypeDropDown' 'WindowSizeSpinner1' ...
                    'WindowSizeSpinner2' 'WindowUnitDropDown'}
                state.([k{1} 'Value']) = app.(k{1}).Value;
            end
            state.WindowUnitVisible = app.WindowUnitVisible;
        end
        function setWindowDropDownValues(app,state)
            for k = {'WindowTypeDropDown' 'WindowSizeSpinner1' ...
                    'WindowSizeSpinner2' 'WindowUnitDropDown'}
                f = [k{1} 'Value'];
                if isfield(state,f)
                    app.(k{1}).Value = state.(f);
                end
            end
            if isfield(state,'WindowUnitVisible')
                app.WindowUnitVisible = state.WindowUnitVisible;
            end
        end
        function propTable = getWindowProperties(app)
            Name = ["WindowTypeDropDown"; "WindowSizeSpinner1";...
                    "WindowSizeSpinner2";"WindowUnitDropDown"];
            Group = repmat(getMsgText('Movingwindow'),4,1);
            if isequal(app.WindowTypeDropDown.Value,'full')
                spinner1Label = getMsgText('WindowLengthCentered');
            else
                spinner1Label = getMsgText('WindowLengthLeft');
            end
            DisplayName = [getMsgText('MovingWindowType');...
                spinner1Label; getMsgText('WindowLengthRight');...
                getMsgText('Units')];
            StateName = Name + "Value";
            propTable = table(Name,Group,DisplayName,StateName);
        end
    end
end

function s = getMsgText(msgId,varargin)
s = string(message(['MATLAB:dataui:' msgId],varargin{:}));
end
