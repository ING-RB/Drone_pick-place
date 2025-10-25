classdef ReplaceDataMode < ctrluis.toolstrip.Mode
    %
    
    % Copyright 2013-2024 The MathWorks, Inc.
    
    properties(Access = protected)
        Figure         = [];  %Parent figure that launched this mode
        Panel          = [];  %Toolstrip panel
        Widgets        = [];  %Panel widgets
        Section        = [];  %Toolstrip section(s)
        Preview        = [];  %Preview data
        RBPatch        = [];  %Rubber-band box used for data selection
        SelectionData  = [];  %Data of ranges selected for each signal
        SelectedSignal = [];  %Active signal by RBBox to set selected range

        ReplaceValueDlg = []; %Dialog for specifying replace value
        RVWidgets       = []; %Replace value dialog widgets

        UpdateSec = [];     %Update section
        HelpData  = [];     %Struct with map file and topic id for replace value help
    end

     properties(Access = protected, SetObservable = true)
        Dirty = false; %Data has been replaced but not saved
    end
    
    properties(GetAccess = public, SetAccess = protected)
        ReplaceMethod
        ReplaceValue
    end
    
    events(NotifyAccess = protected, ListenAccess = public)
        DataChanged
    end
    
    methods
        function obj = ReplaceDataMode(varargin)
            %REPLACEDATAMODE
            % Inputs: Figure handle, SaveAsEnabled flag
            if nargin > 2
                ModeInputs = varargin(3:end);
            else
                ModeInputs = {''};
            end
            obj = obj@ctrluis.toolstrip.Mode(ModeInputs{1:end});
            
            %Set object properties
            obj.Name           = 'ReplaceData';
            obj.ReplaceMethod  = 'constant';
            obj.ReplaceValue   = 0;
            obj.SelectedSignal = {};
            resetSelectionData(obj);
            if nargin>0
                obj.Figure = varargin{1};
            end
            SaveAsEnabled = true;
            if nargin > 1
                SaveAsEnabled = varargin{2};
            end
            obj.UpdateSec = ctrluis.toolstrip.dataprocessing.UpdateSection(obj,SaveAsEnabled);
            obj.HelpData = struct(...
                'MapFile', 'sldo', ...
                'TopicID', 'replaceData');
        end
        function save(this)
            %SAVE Manage Save events
            %
            
            %Notify listeners data has changed
            ed = ctrluis.toolstrip.dataprocessing.GenericEventData('Save');
            notify(this,'DataChanged',ed)
            
            %Reset offset values
            resetSelectionData(this);
            this.ReplaceValue  = 0;
            this.Dirty = false;
            updatePanel(this)
        end
        function saveAs(this)
            %SAVEAS Manage SaveAs events
            %
            
            ed = ctrluis.toolstrip.dataprocessing.GenericEventData('SaveAs');
            notify(this,'DataChanged',ed);
        end
        
        function setReplaceValue(this,val)
            if isnumeric(val) && isscalar(val) && isreal(val)
                this.ReplaceValue = val;
                updatePreview(this)
            end
        end
        
        function delete(this)
            if ~isempty(this.ReplaceValueDlg) && isvalid(this.ReplaceValueDlg)
                delete(this.ReplaceValueDlg)
            end
        end
        function setHelpData(this,mapfile,topicid)
             %SETHELPDATA 
             %
             %    setHelpData(obj,mapfile,topicic)
             %
             %    Set the help mapfile and topic id for this filter tool.
             %
             
             this.HelpData.MapFile = mapfile;
             this.HelpData.TopicID = topicid;
         end
    end
    
    %Testing API
    methods(Hidden = true)
        function wdgts = getWidgets(this)
            %GETWIDGETS
            %
            
            wdgts = this.Widgets;
            updateSecWdgts    = getWidgets(this.UpdateSec);
            wdgts.btnSave     = updateSecWdgts.btnSave;
            wdgts.RBPatch     = this.RBPatch;
            wdgts.RVWidgets   = this.RVWidgets;
        end
        function pv = getPreview(this)
            %GETPREVIEW
            %
            
            pv = this.Preview;
        end
        function data = getSelectionData(this)
            %GETSELECTIONDATA
            %
            
            data = this.SelectionData;
        end
        function setSelectionData(this,data)
            %SETSELECTIONDATA
            
            this.SelectionData = data;
        end
        function initSelectionData(this)
            %INITSELECTIONDATA
            %
            
            %Trigger code to generate selection curves
            hAx = getaxes(getPlot(this.Figure));
            for ct=1:numel(hAx)
                createSelectionCurve(this,hAx(ct));
            end
        end
    end
    
    %Mode API Implementation
    properties(Constant = true)
        DISPLAYNAME = getString(message('Controllib:dataprocessing:lblReplaceData'));
        DESCRIPTION = getString(message('Controllib:dataprocessing:lblReplaceData_Description'));
        ICON        = 'replaceSignal';
        ICON_16     = 'BrushData_16';
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
                
                %Reset the selected range
                resetSelectionData(this)
                
                %Target the WMM at this mode
                hPlot = getPlot(this.Figure);
                target(getWindowMotionManager(this.Figure),'install',this,getaxes(hPlot))
            else
                resetSelectionData(this)
                enablePreview(this.Figure,false)
                
                %Detarget the WWM from this mode
                target(getWindowMotionManager(this.Figure),'uninstall',this);
            end
        end
        function ok = cbPreClose(this)
            %CBPRECLOSE
            %
            
            ok = true;
            if this.Dirty
                %Offset is in a dirty state, prompt to save
                selection = uiconfirm(getFigure(this.Figure), ...
                    getString(message('Controllib:dataprocessing:lblReplaceData_Close_No_Save')), ...
                    getString(message('Controllib:dataprocessing:lblReplaceData_Close')), ...
                    'Options', {...
                    getString(message('Controllib:dataprocessing:lblYes')), ...
                    getString(message('Controllib:dataprocessing:lblNo')) } );
                ok = strcmp(selection, getString(message('Controllib:dataprocessing:lblYes')));
            end
            if ok && ~isempty(this.ReplaceValueDlg) && isvalid(this.ReplaceValueDlg)
                close(this.ReplaceValueDlg)
            end
        end
    end % Mode API
    
    %WindowMotion API
    properties(Access = protected)
        YLimMode0    %Cached YLim mode so can disable during move
    end
    methods
        function wmStart(this,widget)
            %WMSTART
            %
            
            %Create curve(s) to highlight selections
            createSelectionCurve(this,widget);

            %Draw box to indicated selection region
            WMM = getWindowMotionManager(this.Figure);
            xRange = sort([WMM.PT0(1,1) WMM.PT(1,1)]);
            yRange = sort([WMM.PT0(1,2) WMM.PT(1,2)]);
            this.RBPatch = line(...
                'Parent', WMM.HostAx, ...
                'xdata',  [xRange(1) xRange(1) xRange(2) xRange(2) xRange(1)], ...
                'ydata',  [yRange(1) yRange(2) yRange(2) yRange(1) yRange(1)], ...
                'zdata',  10*ones(1,5), ...
                'LineStyle', '--');
        end
        function wmHover(~)
            %WMHOVER
            %
            
            %No-op
        end
        function wmMove(this)
            %WMMOVE
            %
            
            WMM = getWindowMotionManager(this.Figure);
            xRange = sort([WMM.PT0(1,1) WMM.PT(1,1)]);
            yRange = sort([WMM.PT0(1,2) WMM.PT(1,2)]);
            set(this.RBPatch, ...
                'xdata', [xRange(1) xRange(1) xRange(2) xRange(2) xRange(1)], ...
                'ydata', [yRange(1) yRange(2) yRange(2) yRange(1) yRange(1)]);
        end
        function wmStop(this)
            %WMSTOP
            %
            
            if ishghandle(this.RBPatch)
                delete(this.RBPatch)
                this.RBPatch = [];
            end
            
            WMM = getWindowMotionManager(this.Figure);
            xRange = sort([WMM.PT0(1,1) WMM.PT(1,1)]);
            yRange = sort([WMM.PT0(1,2) WMM.PT(1,2)]);
            idx = strcmp(this.SelectionData.Signal,this.SelectedSignal);
            if any(idx)
                r = this.SelectionData.Range{idx};
                r = vertcat(r,[xRange, yRange]);
                this.SelectionData.Range{idx} = r;
            end
            updateSelectionCurves(this)
        end
    end % WindowMotion API
    
    methods(Access = protected)
        function createSection(this)
            %CREATESECTION
            %
            ReplaceBtnTxt = getString(message('Controllib:dataprocessing:lblReplaceData_ReplaceSelectedData'));
            RestoreBtnTxt = getString(message('Controllib:dataprocessing:lblReplaceData_Restore'));
            SecName = getString(message('Controllib:dataprocessing:lblReplaceData'));

            btnIcon = ctrluis.toolstrip.dataprocessing.getIcon(this.ICON);
            %Create section for resample widgets
            btnReplaceData    = matlab.ui.internal.toolstrip.DropDownButton(ReplaceBtnTxt, ...
                btnIcon);
            btnReplaceData.Tag = 'btnReplaceData';
            btnRestore = matlab.ui.internal.toolstrip.Button(RestoreBtnTxt, ...
                matlab.ui.internal.toolstrip.Icon('undo'));
            btnRestore.Tag = 'btnRestore';

            col1 = matlab.ui.internal.toolstrip.Column();
            col2 = matlab.ui.internal.toolstrip.Column();
            col1.add(btnReplaceData);
            col2.add(btnRestore);

            sec = matlab.ui.internal.toolstrip.Section(SecName);
            sec.Tag = 'secReplaceData';
            sec.add(col1);
            sec.add(col2);

            %Create section for update
            secUpdate = getSection(this.UpdateSec);
            
            %Store sections
            this.Section = [sec; secUpdate];
            
            %Store the widgets for later use
            this.Widgets = struct(...
                'btnReplaceData', btnReplaceData, ...
                'btnRestore',     btnRestore);
        end
        function connectGUI(this)
            %CONNECTGUI
            %
            
            %Add listener to btnReplaceData events
            hBtn = this.Widgets.btnReplaceData;
            createReplaceDataMenuItems(this,hBtn);
            Evt = 'ButtonPushed';
            
            %Add listener to btnRestore events
            hBtn = this.Widgets.btnRestore;
            addlistener(hBtn,Evt,@(hSrc,hData) cbRestore(this));
            
        end
        function updatePanel(this)
            %UPDATEPANEL
            %
            
            setEnabled(this.UpdateSec,this.Dirty);
        end
        function updatePreview(this)
            %UPDATEPREVIEW
            %
            
            nSig = checkSelection(this);
            if nSig == 0
                return
            end
            dSrc = this.Figure.getWorkingData;
            for ct=1:nSig
                sig = getSignalData(dSrc,this.SelectionData.Signal{ct},true);
                idx = lGetSelectionIdx(this.SelectionData.Range{ct},sig);
                
                if strcmp(this.ReplaceMethod,'Constant')
                    for ctR=1:size(idx,1)
                        for ctCh=1:size(sig.Data,2)
                            sig.Data(idx(ctR,:,ctCh),ctCh) = this.ReplaceValue;
                        end
                    end
                elseif strcmp(this.ReplaceMethod,'InitialValue')
                    for ctR = 1:size(idx,1)
                        for ctCh=1:size(sig.Data,2)
                            iVal = find(idx(ctR,:,ctCh),1);
                            val  = sig.Data(iVal,ctCh);
                            sig.Data(idx(ctR,:,ctCh),ctCh) = val;
                        end
                    end
                elseif strcmp(this.ReplaceMethod,'FinalValue')
                    for ctR = 1:size(idx,1)
                        for ctCh=1:size(sig.Data,2)
                            iVal = find(idx(ctR,:,ctCh),1,'last');
                            val  = sig.Data(iVal,ctCh);
                            sig.Data(idx(ctR,:,ctCh),ctCh) = val;
                        end
                    end
                elseif strcmp(this.ReplaceMethod,'Line')
                    for ctR=1:size(idx,1)
                        for ctCh=1:size(sig.Data,2)
                            r = find(idx(ctR,:,ctCh));
                            if numel(r) > 1
                                dx = sig.Time(max(r))-sig.Time(min(r));
                                dy = sig.Data(max(r),ctCh)-sig.Data(min(r),ctCh);
                                sig.Data(idx(ctR,:,ctCh),ctCh) = sig.Data(min(r),ctCh) + ...
                                    dy/dx*(sig.Time(idx(ctR,:,ctCh))-sig.Time(min(r)));
                            end
                        end
                    end
                end
                
                %Update the preview data source
                setSignalData(dSrc,this.SelectionData.Signal{ct},sig,true);
            end
            this.Dirty = true;
            updatePanel(this)
            
            %Fire preview redraw and reset selection data
            send(this.Figure.PreDataSrc,'SourceChanged')
            resetSelectionData(this)
        end
        function createReplaceDataMenuItems(this,hBtn)
            %REPLACEDATAMENUITEMS
            %

            import matlab.ui.internal.toolstrip.*
            % Create popup list
            popup = PopupList();
            popup.Tag = 'mnuReplaceData';

            % Replace with Constant Value
            item = ListItem(getString(message('Controllib:dataprocessing:lblReplaceData_UseConstant')));
            item.Tag = 'mnuReplaceData_Constant';
            item.ItemPushedFcn = @(~,~) cbReplaceDataMenuItemSelected(this,item.Tag);
            item.ShowDescription = false;
            popup.add(item);

            % Replace with Region Initial Value
            item = ListItem(getString(message('Controllib:dataprocessing:lblReplaceData_UseInitialValue')));
            item.Tag = 'mnuReplaceData_InitialValue';
            item.ItemPushedFcn = @(~,~) cbReplaceDataMenuItemSelected(this,item.Tag);
            item.ShowDescription = false;
            popup.add(item);

            % Replace with Region Final Value
            item = ListItem(getString(message('Controllib:dataprocessing:lblReplaceData_UseFinalValue')));
            item.Tag = 'mnuReplaceData_FinalValue';
            item.ItemPushedFcn = @(~,~) cbReplaceDataMenuItemSelected(this,item.Tag);
            item.ShowDescription = false;
            popup.add(item);

            % Replace with Line
            item = ListItem(getString(message('Controllib:dataprocessing:lblReplaceData_UseLine')));
            item.Tag = 'mnuReplaceData_Line';
            item.ItemPushedFcn = @(~,~) cbReplaceDataMenuItemSelected(this,item.Tag);
            item.ShowDescription = false;
            popup.add(item);

            % Separator
            header = PopupListHeader();
            popup.add(header);

            % Clear Region
            item = ListItem(getString(message('Controllib:dataprocessing:lblReplaceData_ClearSelection')));
            item.Tag = 'mnuReplaceData_Clear';
            item.ItemPushedFcn = @(~,~) cbReplaceDataMenuItemSelected(this,item.Tag);
            item.ShowDescription = false;
            popup.add(item);
            hBtn.Popup = popup;
        end
        function hMenu = createSelectionLineMenu(this)
            %CREATESELECTIONLINEMENU
            %
            
            hMenu = uicontextmenu('parent',this.Figure.Figure);
            uimenu(hMenu, ...
                'Tag',     'mnuReplaceData_Constant', ...
                'Label',   getString(message('Controllib:dataprocessing:lblReplaceData_UseConstant')), ...
                'Callback', @(hSrc,hData) cbReplaceDataMenuItemSelected(this, 'mnuReplaceData_Constant'));
            uimenu(hMenu, ...
                'Tag',     'mnuReplaceData_InitialValue', ...
                'Label',   getString(message('Controllib:dataprocessing:lblReplaceData_UseInitialValue')), ...
                'Callback', @(hSrc,hData) cbReplaceDataMenuItemSelected(this, 'mnuReplaceData_InitialValue'));
            uimenu(hMenu, ...
                'Tag',     'mnuReplaceData_FinalValue', ...
                'Label',   getString(message('Controllib:dataprocessing:lblReplaceData_UseFinalValue')), ...
                'Callback', @(hSrc,hData) cbReplaceDataMenuItemSelected(this, 'mnuReplaceData_FinalValue'));
            uimenu(hMenu, ...
                'Tag',     'mnuReplaceData_Line', ...
                'Label',   getString(message('Controllib:dataprocessing:lblReplaceData_UseLine')), ...
                'Callback', @(hSrc,hData) cbReplaceDataMenuItemSelected(this, 'mnuReplaceData_Line'));
            uimenu(hMenu, ...
                'Separator', 'on', ...
                'Tag',       'mnuReplaceData_Clear', ...
                'Label',     getString(message('Controllib:dataprocessing:lblReplaceData_ClearSelection')), ...
                'Callback',  @(hSrc,hData) cbReplaceDataMenuItemSelected(this, 'mnuReplaceData_Clear'));
            
        end
        function cbReplaceDataMenuItemSelected(this,hSrc)
            %CBREPLACEMENUITEMSELECTED
            %
            
            if ischar(hSrc)
                name = hSrc;
            else
                item = hSrc.Items(hSrc.SelectedIndex);
                name = item.Name;
            end
            switch name
                case 'mnuReplaceData_Constant'
                    nSig = checkSelection(this);
                    if nSig == 0, return, end
                    this.ReplaceMethod = 'Constant';
                    if isempty(this.ReplaceValueDlg)
                        this.ReplaceValueDlg = ctrluis.toolstrip.dataprocessing.ReplaceDataDialog(this);
                        setHelpData(this.ReplaceValueDlg,this.HelpData.MapFile, this.HelpData.TopicID);
                    end
                    updateUI(this.ReplaceValueDlg)
                    show(this.ReplaceValueDlg);
                case 'mnuReplaceData_InitialValue'
                    this.ReplaceMethod = 'InitialValue';
                    updatePreview(this)
                case 'mnuReplaceData_FinalValue'
                    this.ReplaceMethod = 'FinalValue';
                    updatePreview(this)
                case 'mnuReplaceData_Line'
                    this.ReplaceMethod = 'Line';
                    updatePreview(this)
                case 'mnuReplaceData_Clear'
                    resetSelectionData(this)
            end
        end
        function cbRestore(this)
            %CBRESTORE
            % 
            
            if ~this.Dirty
                %Quick return, nothing to do
                return
            end
            
            dSrc = getWorkingData(this.Figure);
            names = [getInputName(dSrc);getOutputName(dSrc)];
            for ct=1:numel(names)
                data = getSignalData(dSrc,names{ct});
                setSignalData(dSrc,names{ct},data,true);
            end
            
            %Fire preview redraw and reset selection data
            send(this.Figure.PreDataSrc,'SourceChanged')
            resetSelectionData(this)
            this.Dirty = false;
            updatePanel(this)
        end
        function createSelectionCurve(this,widget)
            %CREATESELECTIONCURVE
            %
            
            
            % Determine which signal is being selected, we are passed an
            % axis so use that to determine signals. First need to find all
            % the preview curves.
            hPlot = getPlot(this.Figure);
            found = false; ct = 1;
            while ~found && ct <= numel(hPlot.Waves)
                found = (hPlot.Waves(ct).DataSrc == this.Figure.PreDataSrc);
                if ~found, ct = ct + 1; end
            end
            if found
                hL = hPlot.Waves(ct).View.Curves;
            else
                hL  = hPlot.Waves(1).View.Curves;
            end
            %Find which signal(s) from the passed axes
            ax    = ancestor(hL,{'axes'});
            if iscell(ax)
                idx = ([ax{:}]==widget);
            else
                idx = (ax == widget);
            end
            hL    = hL(idx);
            sig   = get(hL,{'Tag'});
            this.SelectedSignal = sig;
            if isempty(this.SelectionData.Signal) || ~any(strcmp(this.SelectionData.Signal,sig))
                this.SelectionData.Signal = vertcat(this.SelectionData.Signal, sig);
                this.SelectionData.Range  = vertcat(this.SelectionData.Range, {[]});
                %Create line(s) to highlight selections
                hMenu = createSelectionLineMenu(this);
                for ct=numel(hL):-1:1
                    clr = get(hL(ct),'color');
                    hLSel(ct) = handle(line(...
                        'Parent',          get(hL(ct),'Parent'), ...
                        'Tag',             sig{ct}, ...
                        'xdata',           [], ...
                        'ydata',           [], ...
                        'zdata',           [], ...
                        'color',           clr, ...
                        'LineStyle',       'none', ...
                        'Marker',          'x', ...
                        'MarkerEdgeColor', clr, ...
                        'MarkerFaceColor', clr, ...
                        'uicontextmenu',   hMenu));
                end
                if isempty(this.SelectionData.Curve)
                    this.SelectionData.Curve  = [hL(:), hLSel(:)];
                else
                    this.SelectionData.Curve  = vertcat(this.SelectionData.Curve, [hL(:), hLSel(:)]);
                end
            end
        end
        function updateSelectionCurves(this)
            %UPDATESELECTIONCURVES
            %
            
            nL = numel(this.SelectionData.Signal);
            for ct=1:nL
                rSelected = this.SelectionData.Range{ct};
                sig = getSignalData(getWorkingData(this.Figure),this.SelectionData.Signal{ct},true);
                idx = lGetSelectionIdx(rSelected,sig);
                
                xData = [];
                yData = [];
                for ctR=1:size(idx,1)
                    for ctCh = 1:size(sig.Data,2)
                        if any(idx(ctR,:))
                            xData = vertcat(xData,sig.Time(idx(ctR,:,ctCh)));
                            yData = vertcat(yData,sig.Data(idx(ctR,:,ctCh),ctCh));
                        end
                    end
                end
                zData = 10*ones(size(xData));
                set(this.SelectionData.Curve(ct,2), ...
                    'xdata', xData, ...
                    'ydata', yData, ...
                    'zdata', zData);
            end
        end
        function resetSelectionData(this)
            %RESETSELECTIONDATA
            %
            
            %Delete any selection curves that were created
            if ~isempty(this.SelectionData) && ~isempty(this.SelectionData.Curve)
                hL = this.SelectionData.Curve(:,2);
                delete(hL)
            end
            
            %Reset all the selection data
            this.SelectionData = struct(...
                'Signal', {{}}, ...
                'Range',  {[]}, ...
                'Curve',  {[]});
        end
        
        function createReplaceValueDlg(this)
            %CREATEREPLACEVALUEDLG

            this.ReplaceValueDlg = ctrluis.toolstrip.dataprocessing.ReplaceDataDialog();
        end
        function connectRVGUI(this)
            %CONNECTRVGUI
            %
            
            %Install edtValue listener
            btn = this.RVWidgets.edtValue;
            addlistener(btn,'ActionPerformed', @(hSrc,hData) cbReplaceValueEdit(this));
        end
        function cbReplaceValueEdit(this)
            %CBREPLACEVALUEEDIT
            %
            
            edtValue = this.RVWidgets.edtValue;
            try
                val = eval(edtValue.Text);
            catch
                updateReplaceValueDlg(this)
                return
            end
            
            if isnumeric(val) && isscalar(val) && isreal(val)
                this.ReplaceValue = val;
                
                %Close dialog and update preview
                close(this.ReplaceValueDlg)
                updatePreview(this)
            else
                updateReplaceValueDlg(this);
            end
        end
        function updateReplaceValueDlg(this)
            %UPDATEREPLACEVALUEDLG
            %
            
            this.RVWidgets.edtValue.Text = mat2str(this.ReplaceValue,8);
        end
        function nsig = checkSelection(this)
            %CHECKSELECTION
            %
            
            nsig = numel(this.SelectionData.Signal);
            if nsig == 0
                hMsg = errordlg(...
                    getString(message('Controllib:dataprocessing:msgReplaceData_NoSelectedData')), ...
                    getString(message('Controllib:dataprocessing:lblReplaceData')));
                centerfig(hMsg,this.Figure.Figure)
            end
        end
    end
    
    %QE Methods
    methods
        function dlg = qeGetReplaceValueDlg(this)
            dlg = this.ReplaceValueDlg;
        end
    end
end

function [idx,r] = lGetSelectionIdx(range,sig)
%Helper to find indexes into a signal that satisfy specified ranges
%
% Inputs
%   range - a nx4 array where each row specifies a selected region [tmin
%           tmax ymin ymax]
%   sig   - the signal being selected
%
% Outputs:
%   idx - a r*np*nch logical matrix where r is the number of selection
%         regions (rows in range), np the number of time points in sig, and
%         nch the number of channels in sig
%   r   - a mx4 array or unique non-overlapping ranges
%

xData = sig.Time;
yData = sig.Data;

%Reduce ranges to non-overlapping ranges
r = range(1,:);
for ct=2:size(range,1)
    iL = range(ct,1) >= r(:,1) & range(ct,1) <= r(:,2);
    if any(iL)
        %Start of new range is contained in some existing range
        if range(ct,2) > r(iL,2)
            r(iL,2) = range(ct,2);
        end
    end
    iR = range(ct,2) >= r(:,1) & range(ct,2) <= r(:,2);
    if any(iR)
        %End of new range is contained in some existing range
        if range(ct,1) < r(iR,1)
            r(iR,1) = range(ct,1);
        end
    end
    if ~any(iR) && ~any(iL)
        iB = range(ct,1) < r(:,1) & range(ct,2) > r(:,2);
        if any(iB)
            %New range overlaps existing range
            r(iB,:) = range(ct,:);
        else
            %New range not contained in any existing range
            r = vertcat(r,range(ct,:));
        end
    end
end

idx = false([size(r,1),size(yData)]);
nCh = size(yData,2);     %Number of channels
for ct = 1:size(r,1)
    ix  = (xData >= r(ct,1) & xData <= r(ct,2));
    iy  = (yData >= r(ct,3) & yData <= r(ct,4));
    tmp = (repmat(ix,1,nCh) & iy);
    idx(ct,:) = tmp(:);
end
end