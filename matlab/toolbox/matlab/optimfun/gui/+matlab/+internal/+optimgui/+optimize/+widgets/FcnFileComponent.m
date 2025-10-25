classdef FcnFileComponent < matlab.internal.optimgui.optimize.widgets.AbstractFcnComponent
    % The FcnFileComponent class wraps a Button component to browse for a function file
    %
    % FOR INTERNAL USE ONLY -- This feature is intentionally undocumented.
    % Its behavior may change, or it may be removed in a future release.

    % Copyright 2021-2023 The MathWorks, Inc.

    properties (Access = public)

        % Value is the fcn name that appears as the button text
        Value = matlab.internal.optimgui.optimize.OptimizeConstants.UnsetFromFileFcn; % (1, :) char
    end

    methods (Access = protected)

        function setup(this)

            % Call superclass method
            setup@matlab.internal.optimgui.optimize.widgets.AbstractFcnComponent(this);

            % Input
            this.Input = uibutton(this.Grid);
            this.Input.Layout.Row = 1;
            this.Input.Layout.Column = 1;
            this.Input.ButtonPushedFcn = @this.inputChanged;
            this.Input.Tooltip = matlab.internal.optimgui.optimize.utils.getMessage('Tooltips', 'FromFileWidget');
            matlab.ui.control.internal.specifyIconID(this.Input, "openFolder", 16, 16);
        end

        function updateValue(this)

            % Set input from the component Value
            this.Input.Text = [this.Value, '...'];
        end

        function inputChanged(this, ~, ~)

            % Store previous value to include in ValueChanged event data
            previousValue = this.Value;

            % Have user select file
            [file, path] = uigetfile({'*.m; *.mlx'}, matlab.internal.optimgui.optimize.utils.getMessage(...
                'Labels', 'BrowseMessage'), [pwd, filesep]);

            % If a valid file was selected, extra handling
            if ~isequal(file, 0)

                % Set the component value
                [~, this.Value, ~] = fileparts(file);

                % Add fcn folder to path
                addpath(path);

                % Notify listeners the value changed, along with the fcn file full name
                % and previous value
                fcnName = [path, file];
                data = struct('FcnName', fcnName, 'PreviousValue', previousValue);
                eventData = matlab.internal.optimgui.optimize.OptimizeEventData(data);
                this.notify('ValueChanged', eventData);
            end
        end
    end

    methods (Static, Access = public)

        function createTemplate(~, fcnText)

            % Create a new .m file with the template fcnText
            matlab.desktop.editor.newDocument(fcnText);
        end
    end
end
