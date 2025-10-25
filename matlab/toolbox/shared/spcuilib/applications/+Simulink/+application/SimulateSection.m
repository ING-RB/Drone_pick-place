classdef SimulateSection < matlabshared.application.Section
    %
    
    %   Copyright 2020-2021 The MathWorks, Inc.
    properties
        Model
        ApplicationOpenedListener;
    end
    
    methods
        
        function this = SimulateSection(model)
            this@matlabshared.application.Section('Simulate');

            import matlab.ui.internal.toolstrip.Icon;
            add(addColumn(this), createButton(this, 'StepBack', 'settings_stepBackwardBlue'));
            add(addColumn(this), createButton(this, 'Run', 'simulate'));
            add(addColumn(this), createButton(this, 'StepForward', 'stepForwardGreen'));
            add(addColumn(this), createButton(this, 'Stop', 'stopRecordingUI'));
            
            if nargin > 0
                this.Model = model;
            end
        end
        
        function set.Model(this, newModel)
            this.Model = newModel;
            attachToModel(this);
            % Register the Container with the proxy
            Simulink.proxyinterface.SLWebScopesPBCInterface.SLWebScopesRegisterToPBC(newModel, num2str(newModel, 16), 1);
        end
        
        function processEvent(this, ev)
            switch lower(ev.ButtonName)
                case 'run'
                    Simulink.proxyinterface.SLWebScopesPBCInterface.ExecutePlayPauseAction(this.Model);
                case 'stop'
                    Simulink.proxyinterface.SLWebScopesPBCInterface.ExecuteStopAction(this.Model);
                case 'stepback'
                    % We check the icon path to determine whether or not we need to step back or use the step back configuration menu         
                    if contains(ev.Source.Widgets.StepBack.Icon.Description, 'settings_stepBackwardBlue')
                        Simulink.proxyinterface.SLWebScopesPBCInterface.ExecuteStepBackConfigAction(this.Model);
                    else
                        Simulink.proxyinterface.SLWebScopesPBCInterface.ExecuteStepBackwardsAction(this.Model);
                    end
                case 'stepforward'
                    Simulink.proxyinterface.SLWebScopesPBCInterface.ExecuteStepForwardAction(this.Model);
            end
        end

        function onApplicationOpened(this, ~, ~)
            Simulink.proxyinterface.SLWebScopesPBCInterface.SLWebScopesRefreshPBCWidgets(this.Model, num2str(this.Model, 16), 1);
        end
    end
    
    methods (Access = protected)
        function attachToModel( ~ ) % this
        end
    end
end

% [EOF]
