classdef AgentModelSection < matlab.ui.internal.toolstrip.Section
    %
    
    %   Copyright 2020 The MathWorks, Inc.
    properties
        SourceType = 'predefined';
        Source = '';
        CosimTarget = 'current';
    end
    
    properties (SetAccess = protected, Hidden)
        hSourceType
        hSource
        hCosimItems
    end
    
    events
        SourceChanged
        CosimTargetChanged
    end
    
    methods
        function this = AgentModelSection()
            this@matlab.ui.internal.toolstrip.Section(getString(message('Spcuilib:application:AgentModelSectionTitle')));
            
            this.Tag = 'agentModel';
            
            import matlab.ui.internal.toolstrip.*;
            
            c = addColumn(this);
            
            items = {'predefined', getString(message('Spcuilib:application:PredefinedTrajectory'))
                'simulink', getString(message('Spcuilib:application:SimulinkModel'))
                'systemobject', getString(message('Spcuilib:application:MATLABSystemObject'))
                'cpp', getString(message('Spcuilib:application:CppClass'))};
        
            sourceType = DropDown;
            sourceType.Items = items;
            sourceType.Tag = 'Model';
            sourceType.ValueChangedFcn = @this.sourceTypeCallback;
            
            add(c, sourceType);
            
            p = Panel;
            
            label  = Label(getString(message('Spcuilib:application:SourceLabelText')));
            source = EditField;
            open   = Button('', Icon.OPEN_16);
            open.ButtonPushedFcn = @this.openCallback;
            
            add(addColumn(p), label);
            add(addColumn(p, 'Width', 160), source);
            add(addColumn(p), open);
            
            add(c, p);
            
            p = Panel;
            
            new = Button(getString(message('Spcuilib:application:NewText')), Icon.NEW_16);
            new.ButtonPushedFcn = @this.newCallback;
            
            edit = Button(getString(message('Spcuilib:application:EditText')), Icon(fullfile(toolboxdir('shared'), 'spcuilib', 'applications', '+matlabshared', '+application', 'Edit16.png')));
            new.ButtonPushedFcn = @this.editCallback;
            
            add(addColumn(p), new);
            add(addColumn(p), edit);
            
            add(c, p);
            
            cosimOptions = DropDownButton(getString(message('Spcuilib:application:CosimButtonText')), Icon.SETTINGS_24);
            popup = PopupList;
            cosimOptions.Popup = popup;
            
            current = ListItemWithCheckBox(getString(message('Spcuilib:application:CurrentSessionCosimText')));
            current.Tag = 'current';
            current.ValueChangedFcn = @(~,~) cosimTargetCallback(this, 'current');
            current.Description = getString(message('Spcuilib:application:CurrentSessionCosimDescription'));
            local   = ListItemWithCheckBox(getString(message('Spcuilib:application:LocalSessionCosimText')));
            local.Tag = 'local';
            local.ValueChangedFcn = @(~,~) cosimTargetCallback(this, 'local');
            local.Description   = getString(message('Spcuilib:application:LocalSessionCosimDescription'));
            remote  = ListItemWithCheckBox(getString(message('Spcuilib:application:RemoteSessionCosimText')));
            remote.Tag = 'remote';
            remote.ValueChangedFcn = @(~,~) cosimTargetCallback(this, 'remote');
            remote.Description  = getString(message('Spcuilib:application:RemoteSessionCosimDescription'));
            
            add(popup, current);
            add(popup, local);
            add(popup, remote);
            
            add(addColumn(this), cosimOptions);
            
            this.hSourceType = sourceType;
            this.hSource     = source;
            this.hCosimItems = [current local remote];
            
            updateCosimTargetItems(this);
            updateSourceTypeDropDown(this);
            updateSourceEdit(this);
        end
        
        function set.SourceType(this, newSourceType)
            this.SourceType = newSourceType;
            updateSourceTypeDropDown(this);
            updateSourceEdit(this);
            notify(this, 'SourceChanged');
        end
        
        function set.Source(this, newSource)
            this.Source = newSource;
            updateSourceEdit(this);
            notify(this, 'SourceChanged');
        end
        
        function set.CosimTarget(this, newTarget)
            this.CosimTarget = newTarget;
            updateCosimTargetItems(this);
            notify(this, 'CosimTargetChanged');
        end
    end
    
    methods (Hidden)
        
        function sourceTypeCallback(this, h, ~)
            this.SourceType = h.SelectedItem;
        end
        
        function cosimTargetCallback(this, target)
            this.CosimTarget = target;
        end
        
        function openCallback(this, ~, ~)
            [filename, pathname] = uigetfile( ...
                {'*.m';'*.mdl';'*.mat';'*.*'}, ...
                'Pick a file');
            if isequal(filename, 0)
                return;
            end
            %xxx probably need to change source type here?
            this.Source = fullfile(pathname, filename);
        end
        
        function newCallback(this, ~, ~)
        end
        
        function editCallback(this, ~, ~)
        end
    end
    
    methods (Access = protected)
        function updateCosimTargetItems(this)
            matlabshared.application.updateDropDownChecked(this.hCosimItems, this.CosimTarget);
        end
        
        function updateSourceEdit(this)
            if strcmp(this.SourceType, 'predefined')
                value = '';
                enab  = false;
            else
                value = this.Source;
                enab  = true;
            end
            this.hSource.Value   = value;
            this.hSource.Enabled = enab;
        end
        
        function updateSourceTypeDropDown(this)
            this.hSourceType.Value = this.SourceType;
        end
    end
end

% [EOF]
