classdef(Sealed) StopButton < matlab.ui.componentcontainer.ComponentContainer
    % StopButton  Training plot stop button

    %   Copyright 2022-2023 The MathWorks, Inc.

    events (HasCallbackProperty, NotifyAccess = protected)
        ButtonClicked
    end

    properties(Access = {?experiment.shared.view.accessors.StopButtonHelper}, Transient, NonCopyable)
        % UIHTML   (uihtml) This is the uihtml object that is the button
        UIHTML
    end

    properties
        Disabled = false;
    end

    methods (Access = protected)
        function setup(this)
            % Make sure this component class never gets saved. This ensures
            % that any internal classes which listen to this component will
            % also never get saved, ensuring forward compatibility.
            this.Serializable = 'off';

            % Create vertical grid to ensure the stop button is correctly
            % vertically centered. Unfortunately, we must hardcode the
            % centering because uihtml isn't positioned correct inside a
            % uigridlayout.
            spacingOnTop = 7;  % hard-coded spacing on top (above the stop button)
            mainComponent = uigridlayout(this, ...
                'RowHeight', {'1x'}, ...
                'ColumnWidth', {'1x'}, ...
                'RowSpacing', 0, 'ColumnSpacing', 0, 'Padding', [0,0,0,spacingOnTop]);

            this.UIHTML = uihtml(mainComponent, ...
                'HTMLSource', iPathToHTMLSource(), ...
                'DataChangedFcn', @this.buttonClickedCallback, ...
                'Tooltip', string(message('shared_experimentmonitor:stopButton:StopButtonTooltip')));
            this.UIHTML.Data = struct(WasClicked=false, IsDisabled=this.Disabled);
            matlab.ui.internal.HTMLUtils.enableTheme(this.UIHTML);
        end

        function update(this)
            % Update disablement only
            existingData = this.UIHTML.Data;
            wasClicked = existingData.WasClicked;
            this.UIHTML.Data = struct(WasClicked=wasClicked, IsDisabled=this.Disabled);

            if this.Disabled
                this.UIHTML.Tooltip = string(message('shared_experimentmonitor:stopButton:StopButtonDisabledTooltip'));
            end
        end
    end

    methods
        function delete(this)
            delete(this.UIHTML);
        end
    end

    methods(Access = private)
        function buttonClickedCallback(this, ~, ~)
            this.notify('ButtonClicked');
            this.UIHTML.Tooltip = string(message('shared_experimentmonitor:stopButton:StopButtonProgressTooltip'));
        end
    end
end

% helpers
function path = iPathToHTMLSource()
path = fullfile(matlabroot, "toolbox/shared/experimentmonitor_js/index.html");
end