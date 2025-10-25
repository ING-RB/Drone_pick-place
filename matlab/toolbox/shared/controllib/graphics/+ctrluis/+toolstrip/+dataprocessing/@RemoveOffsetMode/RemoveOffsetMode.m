classdef RemoveOffsetMode < ctrluis.toolstrip.Mode
    %
    
    % Copyright 2013-2023 The MathWorks, Inc.
    
    properties(Access = protected)
        Figure         = [];  %Parent figure that launched this mode
        Panel          = [];  %Toolstrip panel
        Widgets        = [];  %Panel widgets
        Section        = [];  %Toolstrip section(s)
        Preview        = [];  %Preview data
        
        UpdateSec      = []; %Update section
    end
    
    properties(Transient, Access = protected)
        EditBoxString = ''; % temporary string for combobox asynchronicity
        MouseSelectedSigIdx = []; % index of mouse selected signal
    end
    
    properties(GetAccess = public, SetAccess = protected)
        Offset
        SignalSelector = [];  %Signal selector
    end
    
    events(NotifyAccess = protected, ListenAccess = public)
        DataChanged
    end
    events(NotifyAccess = protected, ListenAccess = protected)
        OffsetChanged
    end
    
    methods
        function obj = RemoveOffsetMode(varargin)
            % REMOVEOFFSETMODE
            % Inputs: Figure handle, SaveAsEnabled flag
            if nargin > 2
                ModeInputs = varargin(3:end);
            else
                ModeInputs = {''};
            end
            obj = obj@ctrluis.toolstrip.Mode(ModeInputs{1:end});
            obj.Name   = 'RemoveOffset';
            obj.Offset = {0};
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
            % GETSELECTEDSIGNALS
            sig = this.SignalSelector.SelectedSignals;
        end
        
        function save(this)
            % SAVE Manage Save events
            
            %Notify listeners offset has changed
            ed = ctrluis.toolstrip.dataprocessing.GenericEventData('Save');
            notify(this,'DataChanged',ed)
            
            %Reset offset values
            this.Offset = repmat({0},1, numel(this.SignalSelector.AllSignals));
            setComboboxText(this,'0');
            updatePanel(this)
        end
        
        function saveAs(this)
            %SAVEAS Manage SaveAs events
            
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
        DISPLAYNAME = getString(message('Controllib:dataprocessing:lblRemoveOffset'));
        DESCRIPTION = getString(message('Controllib:dataprocessing:lblRemoveOffset_Description'));
        ICON        = 'twoParallelSignals';
        ICON_16     = 'RemoveOffset_16';
    end
    
    methods(Access = protected)
        function sec = getTabSection(this)
            % GETTABSECTION
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
            % ENABLEDCHANGED
            
            if this.Enabled
                
                enablePreview(this.Figure,true)
                
                %Ensure there are signals selected
                if isempty(this.SignalSelector)
                    createSignalSelector(this)
                elseif isempty(this.SignalSelector.SelectedSignals)
                    resetSelectedSignals(this.SignalSelector)
                end
                
                %Reset the offset
                this.Offset = repmat({0},1,numel(this.SignalSelector.AllSignals));
                setComboboxText(this,'0');
                if ~isempty(this.Widgets)
                    %Reset the GUI panel
                    updatePanel(this)
                end
                
                %Get the preview lines displayed on the plot, these will be
                %clickable
                hL = lGetPreviewCurves(this.Figure);
                nSig = numel(hL);
                this.Preview = struct(...
                    'Offset', repmat({{0}},nSig,1), ...
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
            if any(cellfun(@(x) any(x~=0),this.Offset))
                %Offset is in a dirty state, prompt to save
                selection = uiconfirm(getFigure(this.Figure), ...
                    getString(message('Controllib:dataprocessing:lblRemoveOffset_Close_No_Save')), ...
                    getString(message('Controllib:dataprocessing:lblRemoveOffset_Close')), ...
                    'Options', ...
                    {getString(message('Controllib:dataprocessing:lblYes')), ...
                    getString(message('Controllib:dataprocessing:lblNo')) } );
                ok = strcmp(selection, getString(message('Controllib:dataprocessing:lblYes')) );
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
            this.MouseSelectedSigIdx = iSig;
            if isscalar(this.SignalSelector.SelectedSignals)
                setSelectedSignals(this.SignalSelector,this.SignalSelector.AllSignals(iSig));
            else
                setSelectedSignals(this.SignalSelector, this.SignalSelector.AllSignals)
            end
            
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
            
            iSig = this.MouseSelectedSigIdx;
            offset = this.Offset;
            WMM = getWindowMotionManager(this.Figure);
            delta = WMM.PT(1,2) - WMM.PT0(1,2);
            if isscalar(this.SignalSelector.SelectedSignals)
                offset{iSig} = offset{iSig} - delta;
            else
                offset = cellfun(@(x) x-delta, offset, 'uni',0);
            end
            updatePreview(this, offset)
        end
        function wmStop(this)
            %WMSTOP
            %
            
            WMM = getWindowMotionManager(this.Figure);
            delta = WMM.PT(1,2) - WMM.PT0(1,2);
            iSig = this.MouseSelectedSigIdx;
            offset = this.Offset;
            if isscalar(this.SignalSelector.SelectedSignals)
                offset{iSig} = offset{iSig} - delta;
            else
                offset = cellfun(@(x) x - delta, offset, 'uni', 0);
            end
            this.Offset = offset;
            this.MouseSelectedSigIdx = [];
            this.EditBoxString = mat2str(this.Offset{iSig},8);
            setComboboxText(this, this.EditBoxString);
            [this.Offset{iSig}]  = deal(delta);
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
            
            %Create select signal section to choose which signal to remove offset from
            if isempty(this.SignalSelector)
                createSignalSelector(this)
            end
            secSignal = getSection(this.SignalSelector);
            
            %Create section for remove offset widgets
            OffTxt = getString(message('Controllib:dataprocessing:lblRemoveOffset_OffsetToRemove'));
            InitValTxt = getString(message('Controllib:dataprocessing:lblRemoveOffset_RemoveInitialValue'));
            SecName = getString(message('Controllib:dataprocessing:lblRemoveOffset_Offset'));
            fixedItems = this.getFixedComboItems();

            lblOffset = matlab.ui.internal.toolstrip.Label(OffTxt);
            cmbOffset = matlab.ui.internal.toolstrip.DropDown([{'0'}; fixedItems]);
            cmbOffset.Editable = true;
            cmbOffset.Tag = 'cmbOffset';
            Col = matlab.ui.internal.toolstrip.Column('HorizontalAlignment','left');
            Col.addEmptyControl();
            Col.add(lblOffset);
            Col.add(cmbOffset);
            sec = matlab.ui.internal.toolstrip.Section(SecName);
            sec.Tag = 'secRemoveOffset_Offset';
            Col0 = matlab.ui.internal.toolstrip.Column('HorizontalAlignment','left');
            Col0.addEmptyControl();
            Col1 = matlab.ui.internal.toolstrip.Column('HorizontalAlignment','left');
            Col1.addEmptyControl();
            sec.add(Col0);
            sec.add(Col);
            sec.add(Col1);
                
            %Create section for update
            secUpdate = getSection(this.UpdateSec);
            
            %Store sections
            if isempty(this.DataNameSection)
                this.Section = [secSignal; sec; secUpdate];
            else
               secName = getSection(this.DataNameSection);
               this.Section = [secName; secSignal; sec; secUpdate];
            end
            
            %Store the widgets for later use
            this.Widgets = struct(...
                'cmbOffset',          cmbOffset);
        end
        function connectGUI(this)
            %CONNECTGUI
            %
            
            %Add listener to cmbOffset events
            Evt = 'ValueChanged';
            addlistener(this.Widgets.cmbOffset,Evt,@(hSrc,hData) cbOffsetChanged(this,hSrc));
            
            %Add listener to data to update panel
            addlistener(this,'OffsetChanged',@(hSrc,hData) updatePanel(this));
        end
        function createSignalSelector(this)
            %CREATESIGNALSELECTOR
            %
            
            %Create a SignalSelector for this mode
            Labels = struct(...
                'lblAll',      getString(message('Controllib:dataprocessing:lblRemoveOffset_RemoveAll')), ...
                'lblSelected', getString(message('Controllib:dataprocessing:lblRemoveOffset_RemoveSelected')));
            this.SignalSelector = ctrluis.toolstrip.dataprocessing.ModeSignalSelector(this.Figure, Labels);
        end
        function updatePanel(this)
            %UPDATEPANEL
            %
            items = this.getFixedComboItems();
            CurrentText = this.Widgets.cmbOffset.Value;
            if ~any(strcmp(CurrentText, items))
                if isscalar(this.SignalSelector.SelectedSignals)
                    idx = strcmp(this.SignalSelector.AllSignals,this.SignalSelector.SelectedSignals);
                else
                    idx = 1;
                end
                setComboboxText(this, mat2str(this.Offset{idx},8));
            end
            setEnabled(this.UpdateSec,any(cellfun(@(x) any(x~=0),this.Offset)));
        end
        
        function updatePreview(this,delta)
            %UPDATEPREVIEW
            %
            
            if isnumeric(delta) && isscalar(delta)
                delta = repmat({delta},1,numel(this.Preview));
            end
            
            dSrc = this.Figure.getWorkingData;
            for ct=1:numel(this.Preview)
                if any(strcmp(this.Preview(ct).Signal,this.SignalSelector.SelectedSignals))
                    this.Preview(ct).Offset = delta{ct};
                    newData = getSignalData(dSrc,this.Preview(ct).Signal);
                    %Subtract offset from the signal
                    if isscalar(delta{ct})
                        newData.Data = newData.Data - delta{ct};
                    else
                        newData.Data = newData.Data - ones(size(newData.Data,1),1)*delta{ct};
                    end
                    setSignalData(dSrc,this.Preview(ct).Signal,newData,true);   %Update preview
                end
            end
            
            %Fire preview redraw
            send(this.Figure.PreDataSrc,'SourceChanged')
        end
        function cbOffsetChanged(this,hSrc)
            %CBOFFSETCHANGED Manage cmbOffset events
            %
             
            hPlot = getPlot(this.Figure);
            txt = hSrc.Value;
            
            if isscalar(this.SignalSelector.SelectedSignals)
                idx = find(strcmp(this.SignalSelector.AllSignals,this.SignalSelector.SelectedSignals));
            else
                idx = 1:numel(this.SignalSelector.AllSignals);
            end
            sigs = this.SignalSelector.SelectedSignals;
            val = this.Offset;
            dSrc = this.Figure.getWorkingData;
            switch txt
                case getString(message('Controllib:dataprocessing:lblRemoveOffset_RemoveMean'))
                    for ct = 1:numel(sigs)
                        val{ct} = mean(getSignalData(dSrc,sigs{ct}));
                    end
                case getString(message('Controllib:dataprocessing:lblRemoveOffset_RemoveInitialValue'))
                    for ct=1:numel(sigs)
                        d = getSignalData(dSrc,sigs{ct});
                        val{ct} = d.Data(1,:);
                    end
                otherwise
                    if ~isempty(this.EditBoxString)
                        %This is to get around the issue that when
                        %this.Widgets.cmbOffset.SelectedItem is manually
                        %set to a string, "hSrc" does not see it and offers
                        %the older value.
                        %Same for hData.
                        txt = this.EditBoxString;
                        this.EditBoxString = '';
                    end
                    try
                        v = evalin(getWorkspace(this.Figure),txt);
                        if isnumeric(v) && isreal(v)
                            [val{idx}] = deal(v);
                        else
                            error(message('Controllib:general:UnexpectedError','Bad value'));
                        end
                    catch
                        %No change
                        updatePanel(this)
                        return
                    end
            end
            dirty = false;
            ct = 1;
            while ~dirty && ct <= numel(this.Offset)
                if any(abs(this.Offset{ct}-val{ct}) > sqrt(eps))
                    dirty = true;
                else
                    ct = ct + 1;
                end
            end
            if dirty
                this.Offset = val;
                updatePreview(this,val)
                updatePanel(this)
                for ct=1:numel(hPlot)
                    updatelims(hPlot(ct))
                end
            end
        end
        
        function setComboboxText(this, str)
            % set combo box text to input string
            this.Widgets.cmbOffset.Value = str;
        end
    end
    
    methods (Static, Access = protected)
        function Items = getFixedComboItems()
            % get fixed items of the editable combo box.
            Items = {...
                getString(message('Controllib:dataprocessing:lblRemoveOffset_RemoveMean')); ...
                getString(message('Controllib:dataprocessing:lblRemoveOffset_RemoveInitialValue'))};
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