classdef ScaleDataMode < ctrluis.toolstrip.Mode
    %
    
    % Copyright 2013-2023 The MathWorks, Inc.
    
    properties(Access = protected)
        Figure         = [];  %Parent figure that launched this mode
        Panel          = [];  %Toolstrip panel
        Widgets        = [];  %Panel widgets
        Section        = [];  %Toolstrip section(s)
        Preview        = [];  %Preview data
        UpdateSec      = [];     %Update section
    end
    
    properties(GetAccess = public, SetAccess = protected)
        Scale
        SignalSelector = []; %Signal selector
    end
    
    events(NotifyAccess = protected, ListenAccess = public)
        DataChanged
    end
    events(NotifyAccess = protected, ListenAccess = protected)
        ScaleChanged
    end
    
    methods
        function obj = ScaleDataMode(varargin)
            %SCALEDATAMODE
            %
            % Inputs: Figure handle, SaveAsEnabled flag
            if nargin > 2
                ModeInputs = varargin(3:end);
            else
                ModeInputs = {''};
            end
            obj = obj@ctrluis.toolstrip.Mode(ModeInputs{1:end});
            obj.Name  = 'ScaleData';
            obj.Scale = {1};
            if nargin>0
                obj.Figure = varargin{1};
            end
            SaveAsEnabled = true;
            if nargin > 1
                SaveAsEnabled = varargin{2};
            end
            obj.UpdateSec = ctrluis.toolstrip.dataprocessing.UpdateSection(obj,SaveAsEnabled);
        end
        function sig = getSelectedSignals(this)
            %GETSELECTEDSIGNALS
            %
            
            sig = this.SignalSelector.SelectedSignals;
        end
        function save(this)
            %SAVE Manage save events
            %
            
            %Notify listeners scale has changed
            ed = ctrluis.toolstrip.dataprocessing.GenericEventData('Save');
            notify(this,'DataChanged',ed)
            
            %Reset scale values
            this.Scale = repmat({1},1, numel(this.SignalSelector.AllSignals));
            setComboboxText(this, '1')
            updatePanel(this)
        end
        function saveAs(this)
            %SAVEAS Manage save-as events
            %
            
            ed = ctrluis.toolstrip.dataprocessing.GenericEventData('SaveAs');
            notify(this,'DataChanged',ed);
        end
    end
    
    %Testing API
    methods(Hidden = true)
        function wdgts = getWidgets(this)
            %GETWIDGETS
            %
            
            wdgts = this.Widgets;
            wdgts.SigSelector = this.SignalSelector;
            updateSecWdgts    = getWidgets(this.UpdateSec);
            wdgts.btnSave     = updateSecWdgts.btnSave;
        end
        function pv = getPreview(this)
            %GETPREVIEW
            %
            
            pv = this.Preview;
        end
    end
    
    %Mode API Implementation
    properties(Constant = true)
        DISPLAYNAME = getString(message('Controllib:dataprocessing:lblScaleData'));
        DESCRIPTION = getString(message('Controllib:dataprocessing:lblScaleData_Description'));
        ICON        = 'twoSignals';
        ICON_16     = 'Scale_16';
    end
    methods(Access = protected)
        function sec = getTabSection(this)
            %GETTABSECTION
            %
            
            if isempty(this.Section)
                %Construct the sections
                createSection(this);
                
                %Install listeners to section widget changes
                connectGUI(this);
            end
            sec = this.Section;
            %Make sure panel/section is up to date
            updatePanel(this)
        end
        function enabledChanged(this)
            %ENABLEDCHANGED
            %
            
            if this.Enabled
                
                enablePreview(this.Figure,true)
                
                %Ensure there are signals selected
                if isempty(this.SignalSelector)
                    createSignalSelector(this)
                elseif isempty(this.SignalSelector.SelectedSignals)
                    resetSelectedSignals(this.SignalSelector)
                end
                
                %Reset the scale
                this.Scale = repmat({1},1,numel(this.SignalSelector.AllSignals));
                setComboboxText(this,'1');
                if ~isempty(this.Widgets)
                    %Reset the GUI panel
                    updatePanel(this)
                end
                
                %Get the preview lines displayed on the plot, these will be
                %clickable
                hL = lGetPreviewCurves(this.Figure);
                nSig = numel(hL);
                this.Preview = struct(...
                    'Scale',  repmat({{1}},nSig,1), ...
                    'Signal', this.SignalSelector.AllSignals);
                
                %Target the WMM at this mode
                target(getWindowMotionManager(this.Figure),'install',this,hL)
            else
                
                enablePreview(this.Figure,false)
                
                %Detarget the WWM from this mode
                target(getWindowMotionManager(this.Figure),'uninstall',this);
            end
        end
        function ok = cbPreClose(this)
            %CBPRECLOSE
            %
            
            ok = true;
            if any(cellfun(@(x) any(x~=1),this.Scale))
                %Scale is in a dirty state, prompt to save
                selection = uiconfirm(getFigure(this.Figure), ...
                    getString(message('Controllib:dataprocessing:lblScaleData_Close_No_Save')), ...
                    getString(message('Controllib:dataprocessing:lblScaleData_Close')), ...
                    'Options', {...
                    getString(message('Controllib:dataprocessing:lblYes')), ...
                    getString(message('Controllib:dataprocessing:lblNo')) } );
                ok = strcmp(selection, getString(message('Controllib:dataprocessing:lblYes')));
            end
        end
    end % Mode API
    
    %WindowMotion API
    properties(Access = protected)
        YLimMode0    %Cached YLim mode so can disable during move
    end
    methods
        function wmHover(this)
            %WMHOVER
            %
            
            Tool = this.Figure;
            hFig = Tool.Figure;
            HitObject = hittest(hFig);
            
            WMM = getWindowMotionManager(Tool);
            if any(HitObject == WMM.Widgets)
                setptr(hFig,'hand');
            else
                setptr(hFig,'arrow');
            end
        end
        function wmStart(this,widget)
            %WMSTART
            %
            
            %Clicked a line, set selected signals appropriately
            found = false; ct = 1;
            while ~found && ct <= numel(this.SignalSelector.AllSignals)
                found = strncmp(this.SignalSelector.AllSignals(ct),get(widget,'tag'), ...
                    numel(this.SignalSelector.AllSignals{ct}));
                if found
                    iSig = ct;
                else
                    ct = ct + 1;
                end
            end
            if isscalar(this.SignalSelector.SelectedSignals)
                setSelectedSignals(this.SignalSelector,this.SignalSelector.AllSignals(iSig));
            else
                setSelectedSignals(this.SignalSelector, this.SignalSelector.AllSignals)
            end
            
            %Can 'Start' while have active preview (by clicking on a
            %different signal, so need to reset PT0
            WMM = getWindowMotionManager(this.Figure);
            pt0      = WMM.PT0;
            pt0(1,2) = pt0(1,2)/this.Scale{iSig}(1);  %Need scale defined by clicked line
            resetPT(WMM,pt0);
            
            %Disable ylim updates while in motion and set response
            %refresh mode
            hPlot = getPlot(this.Figure);
            this.YLimMode0 = cell(numel(hPlot),1);
            for ct=1:numel(hPlot)
                this.YLimMode0{ct} = hPlot(ct).AxesGrid.YLimMode;
                hPlot(ct).AxesGrid.YLimMode = repmat({'manual'},size(this.YLimMode0{ct}));
            end
            
            setptr(this.Figure.Figure,'closedhand')
            updatePanel(this);
        end
        function wmMove(this)
            %WMMOVE
            %
            
            WMM = getWindowMotionManager(this.Figure);
            delta = WMM.PT(1,2)-WMM.PT0(1,2);
            scale = 1 + delta/WMM.PT0(1,2);
            updatePreview(this, scale)
        end
        function wmStop(this)
            %WMSTOP
            %
            
            WMM = getWindowMotionManager(this.Figure);
            delta = WMM.PT(1,2)-WMM.PT0(1,2);
            scale = 1 + delta/WMM.PT0(1,2);
            if isscalar(this.SignalSelector.SelectedSignals)
                iSig = strcmp(this.SignalSelector.AllSignals,this.SignalSelector.SelectedSignals);
            else
                iSig = true(numel(this.SignalSelector.AllSignals),1);
            end
            [this.Scale{iSig}]  = deal(scale);
            setComboboxText(this, mat2str(this.Scale{1},8));
            updatePanel(this); %Update toolstrip widgets
            
            %Restore axes limit update mode and fire an update
            hPlot = getPlot(this.Figure);
            for ct=1:numel(hPlot)
                hPlot(ct).AxesGrid.YLimMode = this.YLimMode0{ct};
                updatelims(hPlot(ct));
            end
            
            setptr(this.Figure.Figure,'hand')
        end
    end % WindowMotion API
    
    methods(Access = protected)
        function createSection(this)
            %CREATESECTION
            %
            
            %Create select signal section to choose which signal to scale
            if isempty(this.SignalSelector)
                createSignalSelector(this)
            end
            secSignal = getSection(this.SignalSelector);
            
            %Create section for scale widgets
            ScaleTxt = getString(message('Controllib:dataprocessing:lblScaleData_ScaleToUse'));
            cmbScaleTxt = {'1'; ...
                getString(message('Controllib:dataprocessing:lblScaleData_ScaleMaxValue')); ...
                getString(message('Controllib:dataprocessing:lblScaleData_ScaleInitialValue'))};
            SecName = getString(message('Controllib:dataprocessing:lblScaleData_Scale'));
            lblScale   = matlab.ui.internal.toolstrip.Label(ScaleTxt);
            cmbScale   = matlab.ui.internal.toolstrip.DropDown(cmbScaleTxt);
            cmbScale.Editable = true;
            cmbScale.Enabled  = true;
            cmbScale.Tag     = 'cmbScale';
            col = matlab.ui.internal.toolstrip.Column();
            col.add(lblScale);
            col.add(cmbScale);
            sec = matlab.ui.internal.toolstrip.Section(SecName);
            sec.Tag = 'secScaleData_Scale';
            sec.add(col);

            %Create section for update
            secUpdate = getSection(this.UpdateSec);
            
            %Store sections
            this.Section = [secSignal; sec; secUpdate];
            
            %Store the widgets for later use
            this.Widgets = struct(...
                'cmbScale', cmbScale);
        end
        function connectGUI(this)
            %CONNECTGUI
            %

            Evt = 'ValueChanged';

            %Add listener to cmbScale events
            addlistener(this.Widgets.cmbScale,Evt,@(hSrc,hData) cbScaleChanged(this,hSrc));
            
            %Add listener to data to update panel
            addlistener(this,'ScaleChanged',@(hSrc,hData) updatePanel(this));
        end
        function createSignalSelector(this)
            %CREATESIGNALSELECTOR
            %
            
            %Create a SignalSelector for this mode
            Labels = struct(...
                'lblAll',      getString(message('Controllib:dataprocessing:lblScaleData_ScaleAll')), ...
                'lblSelected', getString(message('Controllib:dataprocessing:lblScaleData_ScaleSelected')));
            this.SignalSelector = ctrluis.toolstrip.dataprocessing.ModeSignalSelector(this.Figure, Labels);
        end
        function updatePanel(this)
            %UPDATEPANEL
            %

            CurrentText = this.Widgets.cmbScale.Value;
                
            items = {...
                getString(message('Controllib:dataprocessing:lblScaleData_ScaleMaxValue')); ...
                getString(message('Controllib:dataprocessing:lblScaleData_ScaleInitialValue'))};
            if ~any(strcmp(CurrentText, items))
                if isscalar(this.SignalSelector.SelectedSignals)
                    idx = strcmp(this.SignalSelector.AllSignals,this.SignalSelector.SelectedSignals);
                else
                    idx = 1;
                end
                setComboboxText(this, mat2str(this.Scale{idx},8));
            end
            setEnabled(this.UpdateSec,any(cellfun(@(x) any(x~=1),this.Scale)));
        end
        
        function updatePreview(this,scale)
            %UPDATEPREVIEW
            %
            
            if isnumeric(scale) && isscalar(scale)
                scale = repmat({scale},1,numel(this.Preview));
            end
            
            dSrc = this.Figure.getWorkingData;
            for ct=1:numel(this.Preview)
                if any(strcmp(this.Preview(ct).Signal,this.SignalSelector.SelectedSignals))
                    this.Preview(ct).Scale = scale{ct};
                    newData = getSignalData(dSrc,this.Preview(ct).Signal);
                    if isscalar(scale{ct})
                        newData.Data = newData.Data * scale{ct};
                    else
                        newData.Data = newData.Data .* (ones(size(newData.Data,1),1)*scale{ct});
                    end
                    setSignalData(dSrc,this.Preview(ct).Signal,newData,true);   %Update preview
                end
            end
            
            %Fire preview redraw
            send(this.Figure.PreDataSrc,'SourceChanged')
        end
        function cbScaleChanged(this,hSrc)
            %CBSCALECHANGED Manage cmbScale events
            %
            
            hPlot = getPlot(this.Figure);
            txt = hSrc.Value;
            
            if isscalar(this.SignalSelector.SelectedSignals)
                idx = strcmp(this.SignalSelector.AllSignals,this.SignalSelector.SelectedSignals);
            else
                idx = true(1,numel(this.SignalSelector.AllSignals));
            end
            sigs = this.SignalSelector.SelectedSignals;
            val  = this.Scale;
            dSrc = this.Figure.getWorkingData;
            switch txt
                case getString(message('Controllib:dataprocessing:lblScaleData_ScaleMaxValue'))
                    for ct = 1:numel(sigs)
                        d = getSignalData(dSrc,sigs{ct});
                        val{ct} = max(abs(d.Data));
                    end
                case getString(message('Controllib:dataprocessing:lblScaleData_ScaleInitialValue'))
                    for ct=1:numel(sigs)
                        d = getSignalData(dSrc,sigs{ct});
                        val{ct} = abs(d.Data(1,:));
                    end
                otherwise
                    try
                        v = evalin(getWorkspace(this.Figure),txt);
                        if isnumeric(v) && isreal(v) && isscalar(v)
                            [val{idx}] = deal(1/v);
                        else
                            error(message('Controllib:general:UnexpectedError','Bad value'));
                        end
                    catch
                        %No change
                        updatePanel(this)
                        return
                    end
            end
            %Convert to scale
            for ct=1:numel(val)
                if abs(val{ct}) <= eps
                    val{ct} = ones(size(val{ct})); 
                else
                    val{ct} = 1./val{ct};
                end
            end
            %Find if any scales have changed
            dirty = false;
            ct = 1;
            while ~dirty && ct <= numel(this.Scale)
                if any(abs(this.Scale{ct}-val{ct}) > sqrt(eps))
                    dirty = true;
                else
                    ct = ct + 1;
                end
            end
            if dirty
                this.Scale = val;
                updatePreview(this,val)
                updatePanel(this)
                for ct=1:numel(hPlot)
                    updatelims(hPlot(ct))
                end
            end
        end
        
        function setComboboxText(this, str)
            % set combo box text to input string
            this.Widgets.cmbScale.Value = str;
        end
    end
end

function hL = lGetPreviewCurves(fTool)
%Helper to get the preview lines displayed on the figure tool

hL = [];
hPlot = getPlot(fTool);
found = false; ct = 1;
while ~found && ct <= numel(hPlot.Waves)
    if hPlot.Waves(ct).DataSrc == fTool.PreDataSrc
        wf = hPlot.Waves(ct);
        found = true;
    else
        ct = ct + 1;
    end
end

if found
    hL = wf.View.Curves;
end
end