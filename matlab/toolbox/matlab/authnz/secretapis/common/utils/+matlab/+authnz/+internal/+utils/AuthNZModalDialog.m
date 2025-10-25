% Standardised base dialog which has an OK button which closes the dialog
% successfully and a Cancel button which closes the dialog exceptionally.

% Copyright 2022-2025 The MathWorks, Inc.

classdef (Abstract) AuthNZModalDialog < handle

    properties (Access = protected)
        UIFigure
        GridLayout

        % Child dialogs should set this function handle to set the output
        % of the dialog on close.
        GetOutputFcn = @iNoop

        HelpText
        OKButton
        CancelButton
    end

    methods (Hidden)
        function fig = hGetFigure(obj)
        % Access to figure for testing
            fig = obj.UIFigure;
        end

        function varargout = hGet(obj)
        % Access to get output for testing
            [varargout{1:nargout}] = obj.GetOutputFcn();
        end
    end

    methods
        function varargout = get(obj)
        % Blocks until figure is closed then returns the result of GetOutputFcn
            theListener = event.listener(obj.UIFigure, 'Close', @iNoOpCallback);
            waiter = matlab.authnz.internal.utils.AuthNZEventWaiter(theListener);
            waiter.waitForEvent(@() isvalid(obj.UIFigure), Inf, 1);
            [varargout{1:nargout}] = obj.GetOutputFcn();
        end
    end

    methods (Access = protected)
        function obj = AuthNZModalDialog(name)
            obj.UIFigure = uifigure('Name', name, ...
                                    'WindowStyle', 'modal', ...
                                    'Resize', 'on', ...
                                    'AutoResizeChildren', 'off', ...
                                    'Visible', 'off', ...
                                    'HandleVisibility', 'off');
            matlab.graphics.internal.themes.figureUseDesktopTheme(obj.UIFigure);
            obj.UIFigure.CloseRequestFcn = @(~, ~) obj.closeDelete();
            obj.UIFigure.KeyPressFcn = @(~, data) obj.handleKeyPress(data);
            obj.GridLayout = uigridlayout(obj.UIFigure);
            obj.GridLayout.Padding = [10 10 10 10];
            obj.GridLayout.RowSpacing = 10;
            obj.GridLayout.ColumnSpacing = 10;
        end

        function element = addElement(obj, createElementFcn, row, col)
        % Add a ui element to the grid at the given row and column
            element = createElementFcn(obj.GridLayout);
            element.Layout.Row = row;
            element.Layout.Column = col;
        end

        function show(obj)
            movegui(obj.UIFigure, 'center');
        % Removing the SizeChangedFcn/ResizeFcn callback for now because 
        % of an issue in fitToContent API due to which it returns slightly
        % off value each time it is called and hence gets called infinitly
        % in the the callbacks
            matlab.ui.internal.PositionUtils.fitToContent(obj.UIFigure);
            obj.UIFigure.Visible = 'on';
        end

        function addHelpText(obj, rows, cols)
            obj.HelpText = obj.addElement(@uilabel, rows, cols);
            obj.HelpText.Tag = 'helpText';
            obj.HelpText.WordWrap = 'on';
            obj.HelpText.HorizontalAlignment = 'Left';
        end

        function addOKButton(obj, enable, row, col)
            obj.OKButton = obj.addElement(@uibutton, row, col);
            obj.OKButton.Text = getString(message('MATLAB:authnz:secretapis:PromptOk'));
            obj.OKButton.ButtonPushedFcn = @(~, ~) obj.okDelete();
            obj.OKButton.Enable = enable;
            obj.OKButton.Tag = 'OKButton';
        end

        function addCancelButton(obj, row, col)
            obj.CancelButton = obj.addElement(@uibutton, row, col);
            obj.CancelButton.Text = getString(message('MATLAB:authnz:secretapis:PromptCancel'));
            obj.CancelButton.ButtonPushedFcn = @(~, ~) obj.closeDelete();
            obj.CancelButton.Tag = 'cancelButton';
        end

        function handleKeyPress(obj, data)
        % The third condition on obj.UIFigure.UserData only applies to tests
            if strcmp(data.Key, 'return') && obj.OKButton.Enable && ~isequal(obj.UIFigure.UserData, "MATLAB:authnz:secretapis:test")
                obj.okDelete();
            elseif strcmp(data.Key, 'escape') && obj.CancelButton.Enable
                obj.closeDelete();
            end
        end
    end

    methods (Access = protected, Abstract)
        % Method called when OK/Enter hit
        okDelete(obj);

        % Method called when figure is closed/Cancel/Escape hit
        closeDelete(obj);
    end
end

function iNoop()
end

function iNoOpCallback(~, ~)
end
