classdef (Abstract) MixInEditorInteractions < matlab.graphics.chartcontainer.mixin.Mixin
    % Mixin for Editor Interactions

    % Copyright 2024 The MathWorks, Inc.

    %% Properties
    properties (Hidden,Dependent,AbortSet,SetAccess=protected)
        InteractionMode
    end

    properties (Access=private,Transient,NonCopyable)
        InteractionMode_I = "default"

        AddPoleButton
        AddZeroButton
        AddCCPoleButton
        AddCCZeroButton
        RemovePZButton
        EditPZDropDown
    end

    properties (Dependent,Access=private)
        Toolbar
        StateButtons
        PanButton
        ZoomInButton
        ZoomOutButton
        DatatipButton        
    end

    %% Get/Set
    methods
        % InteractionMode
        function InteractionMode = get.InteractionMode(this)
            InteractionMode = this.InteractionMode_I;
        end

        function set.InteractionMode(this,InteractionMode)
            arguments
                this (1,1) controllib.chart.editor.internal.mixin.MixInEditorInteractions
                InteractionMode (1,1) string {mustBeMember(InteractionMode,["default","addpole","addzero","addccpole","addcczero","removepz"])}
            end
            this.InteractionMode_I = InteractionMode;
        end

        % Toolbar
        function Toolbar = get.Toolbar(this)
            Toolbar = ancestor(this.AddPoleButton,'axestoolbar');
        end

        % StateButtons
        function StateButtons = get.StateButtons(this)
            StateButtons = [this.AddPoleButton;this.AddZeroButton;...
                this.AddCCPoleButton;this.AddCCZeroButton;this.RemovePZButton;...
                this.PanButton;this.ZoomInButton;this.ZoomOutButton;this.DatatipButton];
        end

        % PanButton
        function PanButton = get.PanButton(this)
            PanButton = this.Toolbar.Children(strcmp({this.Toolbar.Children.Tag},'pan'));
        end

        % ZoomInButton
        function ZoomInButton = get.ZoomInButton(this)
            ZoomInButton = this.Toolbar.Children(strcmp({this.Toolbar.Children.Tag},'zoomin'));
        end

        % ZoomOutButton
        function ZoomOutButton = get.ZoomOutButton(this)
            ZoomOutButton = this.Toolbar.Children(strcmp({this.Toolbar.Children.Tag},'zoomout'));
        end

        % DatatipButton
        function DatatipButton = get.DatatipButton(this)
            DatatipButton = this.Toolbar.Children(strcmp({this.Toolbar.Children.Tag},'datacursor'));
        end
    end

    %% Protected methods
    methods (Access=protected)
        function setup(this)
            weakThis = matlab.lang.WeakReference(this);
            this.AddPoleButton = matlab.ui.controls.ToolbarStateButton(Parent=[],Tag='addpole');
            this.AddPoleButton.ValueChangedFcn = @(es,ed) setInteractionMode(weakThis.Handle,'addpole',es,ed);
            this.AddPoleButton.Tooltip = getString(message('Controllib:plots:strAddPole'));
            this.AddPoleButton.Icon = fullfile(matlabroot,'toolbox','shared','controllib',...
                'graphics','resources','realPole.png');
            this.AddZeroButton = matlab.ui.controls.ToolbarStateButton(Parent=[],Tag='addzero');
            this.AddZeroButton.ValueChangedFcn = @(es,ed) setInteractionMode(weakThis.Handle,'addzero',es,ed);
            this.AddZeroButton.Tooltip = getString(message('Controllib:plots:strAddZero'));
            this.AddZeroButton.Icon = fullfile(matlabroot,'toolbox','shared','controllib',...
                'graphics','resources','realZero.png');
            this.AddCCPoleButton = matlab.ui.controls.ToolbarStateButton(Parent=[],Tag='addccpole');
            this.AddCCPoleButton.ValueChangedFcn = @(es,ed) setInteractionMode(weakThis.Handle,'addccpole',es,ed);
            this.AddCCPoleButton.Tooltip = getString(message('Controllib:plots:strAddCCPole'));
            this.AddCCPoleButton.Icon = fullfile(matlabroot,'toolbox','shared','controllib',...
                'graphics','resources','complexPole.png');
            this.AddCCZeroButton = matlab.ui.controls.ToolbarStateButton(Parent=[],Tag='addcczero');
            this.AddCCZeroButton.ValueChangedFcn = @(es,ed) setInteractionMode(weakThis.Handle,'addcczero',es,ed);
            this.AddCCZeroButton.Tooltip = getString(message('Controllib:plots:strAddCCZero'));
            this.AddCCZeroButton.Icon = fullfile(matlabroot,'toolbox','shared','controllib',...
                'graphics','resources','complexZero.png');
            this.RemovePZButton = matlab.ui.controls.ToolbarStateButton(Parent=[],Tag='removepz');
            this.RemovePZButton.ValueChangedFcn = @(es,ed) setInteractionMode(weakThis.Handle,'removepz',es,ed);
            this.RemovePZButton.Tooltip = getString(message('Controllib:plots:strRemovePZ'));
            this.RemovePZButton.Icon = fullfile(matlabroot,'toolbox','shared','controllib',...
                'graphics','resources','eraser.png');
            if matlab.internal.feature("PersistentAxesToolbar")
                this.EditPZDropDown = matlab.ui.controls.ToolbarDropdown(Parent=[],Tag='modifyPoleZero');
                this.EditPZDropDown.Tooltip = getString(message('Controllib:plots:strModifyPZ'));
                this.EditPZDropDown.Icon = fullfile(matlabroot,'toolbox','shared','controllib',...
                'graphics','resources','edit_zerosAndPoles.png');
                this.AddPoleButton.Parent = this.EditPZDropDown;
                this.AddZeroButton.Parent = this.EditPZDropDown;
                this.AddCCPoleButton.Parent = this.EditPZDropDown;
                this.AddCCZeroButton.Parent = this.EditPZDropDown;
                this.RemovePZButton.Parent = this.EditPZDropDown;
            end
        end

        function update(this)
            if isempty(ancestor(this,'figure'))
                this.AddPoleButton.Value = false;
                this.AddZeroButton.Value = false;
                this.AddCCPoleButton.Value = false;
                this.AddCCZeroButton.Value = false;
                this.RemovePZButton.Value = false;
                this.InteractionMode = "default";
            end
            switch this.InteractionMode
                case "default"
                    enableListeners(this,'OpenPropertyEditor');
                otherwise
                    disableListeners(this,'OpenPropertyEditor');
            end
        end

        function initializeToolbar(this,toolbar)
            if matlab.internal.feature("PersistentAxesToolbar")
                this.EditPZDropDown.Parent = toolbar;
            else
                this.RemovePZButton.Parent = toolbar;
                this.AddCCZeroButton.Parent = toolbar;
                this.AddCCPoleButton.Parent = toolbar;
                this.AddZeroButton.Parent = toolbar;
                this.AddPoleButton.Parent = toolbar;
            end
            weakThis = matlab.lang.WeakReference(this);
            this.DatatipButton.ValueChangedFcn = @(es,ed) setInteractionMode(weakThis.Handle,'datacursor',es,ed);
            this.PanButton.ValueChangedFcn = @(es,ed) setInteractionMode(weakThis.Handle,'pan',es,ed);
            this.ZoomInButton.ValueChangedFcn = @(es,ed) setInteractionMode(weakThis.Handle,'zoom',es,ed);
            this.ZoomOutButton.ValueChangedFcn = @(es,ed) setInteractionMode(weakThis.Handle,'zoomout',es,ed);
        end

        function setInteractionMode(this,mode,es,ed)
            % Clear other state buttons
            for ii = 1:length(this.StateButtons)
                if this.StateButtons(ii) ~= es && this.StateButtons(ii).Value
                    this.StateButtons(ii).Value = false;
                    switch this.StateButtons(ii).Tag
                        case {'datacursor','pan','zoomin','zoomout'}
                            ed2 = matlab.graphics.controls.eventdata.ValueChangedEventData(this.StateButtons(ii));
                            mode2 = this.StateButtons(ii).Tag;
                            if strcmp(mode2,'zoomin')
                                mode2 = 'zoom';
                            end
                            matlab.graphics.controls.internal.interactionsModeCallback(mode2,this.StateButtons(ii),ed2);
                    end
                end
            end
            % Activate mode
            switch mode
                case {'addpole','addzero','addccpole','addcczero','removepz'}
                    if ed.Value
                        this.InteractionMode = mode;
                    else
                        this.InteractionMode = "default";
                    end
                case {'datacursor','pan','zoom','zoomout'}
                    this.InteractionMode = "default";
                    matlab.graphics.controls.internal.interactionsModeCallback(mode,es,ed);
            end
        end
    end

    %% Hidden methods
    methods (Hidden)
        function qeClickToolbarButton(this,btn)
            arguments
                this (1,1) controllib.chart.editor.internal.mixin.MixInEditorInteractions
                btn (1,1) string {mustBeMember(btn,["addpole","addzero","addccpole","addcczero","removepz","pan","zoomin","zoomout","datacursor","none"])}
            end
            switch btn
                case "addpole"
                    es = this.AddPoleButton;
                case "addzero"
                    es = this.AddZeroButton;
                case "addccpole"
                    es = this.AddCCPoleButton;
                case "addcczero"
                    es = this.AddCCZeroButton;
                case "removepz"
                    es = this.RemovePZButton;
                case "pan"
                    es = this.PanButton;
                case "zoomin"
                    es = this.ZoomInButton;
                    btn = "zoom";
                case "zoomout"
                    es = this.ZoomOutButton;
                case "datacursor"
                    es = this.DatatipButton;
                case "none"
                    this.InteractionMode = "default";
                    this.AddPoleButton.Value = false;
                    this.AddZeroButton.Value = false;
                    this.AddCCPoleButton.Value = false;
                    this.AddCCZeroButton.Value = false;
                    this.RemovePZButton.Value = false;
                    this.PanButton.Value = false;
                    this.ZoomInButton.Value = false;
                    this.ZoomOutButton.Value = false;
                    this.DatatipButton.Value = false;
                    return;
            end
            es.Value = ~es.Value;
            ed = matlab.graphics.controls.eventdata.ValueChangedEventData(es);
            setInteractionMode(this,char(btn),es,ed)
        end
    end
end