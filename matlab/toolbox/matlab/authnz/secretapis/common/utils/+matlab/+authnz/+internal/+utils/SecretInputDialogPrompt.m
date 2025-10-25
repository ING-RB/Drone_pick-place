% Open a dialog box for the user to enter a password. Returns a token to
% retrieve the password from the PasswordFieldStorage.

% Copyright 2022-2024 The MathWorks, Inc.

classdef SecretInputDialogPrompt <  matlab.authnz.internal.utils.AuthNZModalDialog

    properties (Access = private)
        PasswordField
        PasswordToken
    end

    properties (Constant)
        % Due to bugs in uifigure resize we try and estimate the final size
        % to minimize jitter
        EstimatedWidth = 280;
        EstimatedHeight = 105;
    end

    methods (Static)
        function token = prompt(title, msg)
            dialog = matlab.authnz.internal.utils.SecretInputDialogPrompt(title, msg);
            token = dialog.get();
        end
    end

    methods
        function obj = SecretInputDialogPrompt(title, msg)
            obj = obj@matlab.authnz.internal.utils.AuthNZModalDialog(title);
            obj.UIFigure.Position(3) = obj.EstimatedWidth;
            obj.UIFigure.Position(4) = obj.EstimatedHeight;

            obj.GridLayout.RowHeight = {'fit', 24, 24};
            obj.GridLayout.ColumnWidth = {140, 'fit', 'fit'};

            % Add description text
            obj.addHelpText(1, [1 3]);
            obj.HelpText.Text = msg;

            % Add password field
            obj.PasswordField = obj.addElement(@(g) matlab.ui.control.internal.PasswordField('Parent', g), 2, [1 3]);
            obj.PasswordToken = '';
            obj.PasswordField.PasswordEnteredFcn = @obj.updatePasswordToken;
            % Add the ability to toggle "view password" ON/OFF.
            obj.PasswordField.EnablePlainTextControl = matlab.lang.OnOffSwitchState('on');
            obj.PasswordField.Tag = 'PasswordField';

            % Add OK/Cancel buttons
            obj.addOKButton(true, 3, 2);
            obj.addCancelButton(3, 3);

            obj.show();
            focus(obj.PasswordField);
        end
    end

    methods (Access = private)
        function updatePasswordToken(obj, ~, evt)
            % Remember the new token
            obj.PasswordToken = evt.Token;
            % Handle the pressed key in the same way as the parent uifigure
            obj.handleKeyPress(struct('Key', obj.UIFigure.CurrentKey));
        end
    end

    methods (Access = protected)
        function okDelete(obj)
            token = obj.PasswordToken;
            obj.GetOutputFcn = @() token;
            delete(obj.UIFigure);
        end

        function closeDelete(obj)
            obj.GetOutputFcn = @iError;
            delete(obj.UIFigure);
        end
    end
end

function varargout = iError()
error(message('MATLAB:authnz:secretapis:SecretPromptCancelled'));
end