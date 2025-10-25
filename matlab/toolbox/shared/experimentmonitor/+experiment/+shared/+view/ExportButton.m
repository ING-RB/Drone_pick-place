classdef(Sealed) ExportButton < matlab.ui.componentcontainer.ComponentContainer
    % ExportButton   View for the training plot export button
    
    %   Copyright 2022-2023 The MathWorks, Inc.

    properties (Access = {?experiment.shared.view.accessors.ExportButtonHelper}, Transient, NonCopyable)
        % Button (uibutton) The export button
        Button
    end

    events (HasCallbackProperty, NotifyAccess = protected)
        % ExportButtonClicked (event) Gets fired when the export button is
        % clicked.
        ExportButtonClicked
    end

    methods (Access = protected)
        function setup(this)
            % Make sure this component class never gets saved. This ensures
            % that any internal classes which listen to this component will
            % also never get saved, ensuring forward compatibility.
            this.Serializable = 'off';
            
            mainLayout = uigridlayout(this, ...
                'RowHeight', {'fit'}, ...
                'ColumnWidth', {30, 'fit'}, ...
                'RowSpacing', 0, 'ColumnSpacing', 0, 'Padding', [0,0,0,0]);
            
            % First insert a uilabel into the second column with the text
            % that would live inside the uibutton. This is to fix the size
            % needed for the text first, and then insert the button into 
            % that space. We need to do this because uibutton doesn't
            % provide a way to specify the minimum size of the icon, and
            % instead it will reduce the size of the icon or remove it 
            % completely to fit more of the text.
            lb = uilabel(mainLayout, "Text", iMessageString('shared_experimentmonitor:exportButton:ExportButton'));
            lb.Layout.Column = 2;

            this.Button = uibutton(mainLayout, ...
                'Text', iMessageString('shared_experimentmonitor:exportButton:ExportButton'), ...
                'Tooltip', iMessageString('shared_experimentmonitor:exportButton:ExportButtonTooltip'),...
                'FontSize', iFontSizeInPixels(),...
                'ButtonPushedFcn', @this.buttonClickedCallback);
            matlab.ui.control.internal.specifyIconID(this.Button, 'export_trainingPlot', 16);

            % Position the button to overwrite the text we just placed.
            % Now, the layout will allocate enough horizontal space for the
            % text + icon inside the button, rather than compressing the 
            % button until the icon cannot be seen.
            this.Button.Layout.Row = 1;
            this.Button.Layout.Column = [1 2];
        end

        function update(~)
        end
    end

    methods (Access = private)
        function buttonClickedCallback(this, ~, ~)
            this.notify("ExportButtonClicked")
        end
    end
end

function str = iMessageString(varargin)
m = message(varargin{:});
str = m.getString();
end

function pixels = iFontSizeInPixels()
pixels = 12;
end