classdef ExtractDataMode < ctrluis.toolstrip.Mode
    %
    
    % Copyright 2013-2023 The MathWorks, Inc.
    
    properties(Access = protected)
        Figure 
        Widgets
        Section
        UseSaveAs
        
        RangePatch
        TimeRange
    end
    
    properties(GetAccess = public, SetAccess = protected)
        StartTime
        EndTime        
    end
    
    events(NotifyAccess = protected, ListenAccess = public)
        DataChanged
    end
    
    methods
        function obj = ExtractDataMode(varargin)
            %EXTRACTDATAMODE
            % Inputs: Figure handle, SaveAsEnabled flag
            if nargin > 2
                ModeInputs = varargin(3:end);
            else
                ModeInputs = {''};
            end
            obj = obj@ctrluis.toolstrip.Mode(ModeInputs{1:end});
            obj.Name = 'ExtractData';
            if nargin > 0
                obj.Figure = varargin{1};
            end
            if nargin > 1
                obj.UseSaveAs = varargin{2};
            else
                obj.UseSaveAs = true;
            end
        end
    end
    
    %Testing API
    methods(Hidden = true)
        function wdgts = getWidgets(this)
            %GETWIDGETS
            %
            
            wdgts = this.Widgets;
            wdgts.RangePatch = this.RangePatch;
        end
        function pv = getPreview(this) %#ok<MANU>
            %GETPREVIEW
            %
            
            pv = [];
        end
    end
    
    %Override Mode API
    properties(Constant = true)
        DISPLAYNAME = getString(message('Controllib:dataprocessing:lblExtractData'));
        DESCRIPTION = getString(message('Controllib:dataprocessing:lblExtractData_Description'));
        ICON        = 'signalRegion';
        ICON_16     = 'ExtractData_16';
        %ICON_24     = 'ExtractData_24';
        %ICON_40     = 'ExtractData_60x40';
    end
    methods(Access = protected)
        function sec = getTabSection(this)
            %GETTABSECTION
            %
            
            if isempty(this.Section) 
                %Construct the sections
                createSection(this)
                
                %Install listeners to section widget changes
                connectGUI(this)
            end
            sec = this.Section;
            
            updatePanel(this)
        end
        function enabledChanged(this)
            %ENABLEDCHANGED
            %
            
            if this.Enabled
                
                %Find time range of the responses to default start/end time
                dSrc = this.Figure.getWorkingData;
                sigs = getSignalData(dSrc);
                rMin = -inf; rMax = inf;
                for ct=1:numel(sigs)
                    rMin = max(rMin, min(sigs(ct).Time));
                    rMax = min(rMax, max(sigs(ct).Time));
                end
                this.StartTime = (3*rMin + rMax)/4; %1/4 into range  
                this.EndTime   = (3*rMax+rMin)/4;   %3/4 into range
                this.TimeRange = [rMin, rMax];
                
                %Create interactive patch(es) to mark data for extraction
                createPatch(this)
                
                %Target the WMM at this mode 
                target(getWindowMotionManager(this.Figure),'install', this, ...
                    [this.RangePatch.hLMin,this.RangePatch.hLMax])
                
                updatePanel(this)
            else
                
                %Remove interactive patched
                removePatch(this)
                
                %Detarget the WWM from this mode
                target(getWindowMotionManager(this.Figure),this,'uninstall');
            end
            
        end
    end % Mode API
    
    %WindowMotion API
    properties(Access = protected)
        MoveEdge   %Flag indicating which edge is being moved
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
            
            if any(this.RangePatch.hLMin == widget)
                this.MoveEdge = 'MoveStart';
            elseif any(this.RangePatch.hLMax == widget)
                this.MoveEdge = 'MoveEnd';
            else
                %Got to here clicking something other than expected
                return
            end
            
            setptr(this.Figure.Figure,'closedhand')
            updatePanel(this)
        end
        function wmMove(this)
            %WMMOVE
            %
            WMM = getWindowMotionManager(this.Figure);
            delta = min(max(WMM.PT(1,1),this.TimeRange(1)),this.TimeRange(2)) - WMM.PT0(1,1);
            updatePatch(this,delta,this.MoveEdge)
        end
        function wmStop(this)
            %WMSTOP
            %
            
            WMM = getWindowMotionManager(this.Figure);
            delta = WMM.PT(1,1)-WMM.PT0(1,1);
            if strcmp(this.MoveEdge,'MoveStart')
                this.StartTime = max(this.StartTime + delta,this.TimeRange(1));
            elseif strcmp(this.MoveEdge,'MoveEnd')
                this.EndTime = min(this.EndTime + delta,this.TimeRange(2));
            end
            %Redraw patches and update panel
            updatePatch(this,0,'MoveStart')
            updatePatch(this,0,'MoveEnd')
            updatePanel(this)
            
            setptr(this.Figure.Figure,'hand')
        end
    end % WindowMotion API
    
    methods(Access = protected)
        function createSection(this)
            %CREATESECTION
            %
            
            %Section for start-end times
            StartTxt = getString(message('Controllib:dataprocessing:lblExtractData_StartTime'));
            EndTxt = getString(message('Controllib:dataprocessing:lblExtractData_EndTime'));
            SecName = getString(message('Controllib:dataprocessing:lblExtractData'));

            lblStartTime = matlab.ui.internal.toolstrip.Label(StartTxt);
            edtStartTime = matlab.ui.internal.toolstrip.EditField();
            edtStartTime.Tag = 'edtStartTime';
            lblEndTime = matlab.ui.internal.toolstrip.Label(EndTxt);
            edtEndTime = matlab.ui.internal.toolstrip.EditField();
            edtEndTime.Tag = 'edtEndTime';
            col1 = matlab.ui.internal.toolstrip.Column();
            col2 = matlab.ui.internal.toolstrip.Column();

            col1.add(lblStartTime);
            col2.add(edtStartTime);
            col1.add(lblEndTime);
            col2.add(edtEndTime);

            sec = matlab.ui.internal.toolstrip.Section(SecName);
            sec.Tag = 'secExtractDataMode';
            sec.add(col1);
            sec.add(col2);

            %Split button to save data changes
            if this.UseSaveAs
                btnSave = matlab.ui.internal.toolstrip.Button(...
                    getString(message('Controllib:dataprocessing:lblSaveAs')), ...
                    matlab.ui.internal.toolstrip.Icon('saveAs'));
                lblSec = getString(message('Controllib:dataprocessing:lblSaveAs'));
            else
                btnSave = matlab.ui.internal.toolstrip.Button(...
                    getString(message('Controllib:dataprocessing:lblUpdate')), ...
                    matlab.ui.internal.toolstrip.Icon('greenCheck'));
                lblSec = getString(message('Controllib:dataprocessing:lblUpdate'));
            end
            btnSave.Tag = 'btnSave';
            col = matlab.ui.internal.toolstrip.Column();
            col.add(btnSave);
            secUpdate = matlab.ui.internal.toolstrip.Section(lblSec);
            secUpdate.Tag = 'secUpdate';
            secUpdate.add(col);

            this.Section = [sec; secUpdate];

            %Store the widgets for later use
            this.Widgets = struct(...
                'edtStartTime', edtStartTime, ...
                'edtEndTime',   edtEndTime, ...
                'btnSave',      btnSave);
        end
        function connectGUI(this)
            %CONNECTGUI
            %
            
            Evt1 = 'ValueChanged';
            Evt2 = 'ButtonPushed';
            
            %Add listener to edtStartTime widget
            addlistener(this.Widgets.edtStartTime,Evt1, @(hSrc,hData) cbTimeChanged(this,hSrc));
            addlistener(this.Widgets.edtStartTime,'FocusLost', @(hSrc,hData) cbTimeChanged(this,hSrc));
            
            %Add listener to edtEndTime widget
            addlistener(this.Widgets.edtEndTime,Evt1, @(hSrc,hData) cbTimeChanged(this,hSrc));
            addlistener(this.Widgets.edtEndTime,'FocusLost', @(hSrc,hData) cbTimeChanged(this,hSrc));
            
            %Add listener to btnSave
            addlistener(this.Widgets.btnSave,Evt2, @(hSrc,hData) cbSave(this));
        end
        function updatePanel(this)
            %UPDATEPANEL
            %
            
            this.Widgets.edtStartTime.Value = mat2str(min(this.StartTime,this.EndTime),8);
            this.Widgets.edtEndTime.Value   = mat2str(max(this.StartTime,this.EndTime),8);
        end
        function createPatch(this)
            %CREATEPATCHES
            %
            
            hPlot = getPlot(this.Figure);
            hAx   = getaxes(hPlot);
            for ct=numel(hAx):-1:1
                ylim = get(hAx(ct),'ylim');
                zLevel = -2;
                hLMin(ct) = line(...
                    'parent',    hAx(ct), ...
                    'xdata',     [this.StartTime this.StartTime], ...
                    'ydata',     ylim, ...
                    'zdata',     (zLevel+1)*[1 1], ...
                    'Color',     [0 0 0], ...
                    'LineWidth', 2, ...
                    'Tag',       'lnExtractMin', ...
                    'Hittest',   'on');
                hLMax(ct) = line(...
                    'parent',    hAx(ct), ...
                    'xdata',     [this.EndTime this.EndTime], ...
                    'ydata',     ylim, ...
                    'zdata',     (zLevel+1)*[1 1], ...
                    'color',     [0 0 0], ...
                    'LineWidth', 2, ...
                    'Tag',       'lnExtractMax', ...
                    'Hittest',   'on');
                hPatch(ct) = patch(...
                    'parent',    hAx(ct), ...
                    'xdata',     [this.StartTime this.StartTime this.EndTime this.EndTime, this.StartTime], ...
                    'ydata',     [ ylim([1 2]), ylim([2 1]), ylim(1)], ...
                    'zdata',     zLevel*[1 1 1 1 1], ...
                    'FaceColor', [250 250 210]/255, ...
                    'EdgeColor', 'none', ...
                    'FaceAlpha', 0.5, ...
                    'Tag',       'ptchExtract');
            end
            this.RangePatch = struct(...
                'hLMin',  hLMin, ...
                'hLMax',  hLMax, ...
                'hPatch', hPatch);
        end
        function removePatch(this)
            %REMOVEPATCHES
            %
            
            h = [this.RangePatch.hLMin(:); ...
                this.RangePatch.hLMax(:); ...
                this.RangePatch.hPatch(:)];
            for ct=1:numel(h)
                delete(h(ct))
            end
        end
        function updatePatch(this,delta,edge)
            %UPDATEPATCH
            %
            % Don't update if object is deleted g2831011
            checkValid = this.RangePatch.hPatch;
            if any(isvalid(checkValid))
                xdata = [this.StartTime this.StartTime this.EndTime this.EndTime, this.StartTime]; 
                if strcmp(edge,'MoveStart')
                    xdata([1 2 5]) = this.StartTime+delta;
                    set(this.RangePatch.hLMin,'xdata',[1 1]*(this.StartTime+delta))
                elseif strcmp(edge,'MoveEnd')
                    xdata([3 4]) = this.EndTime+delta;
                    set(this.RangePatch.hLMax,'xdata',[1 1]*(this.EndTime+delta))
                end
                set(this.RangePatch.hPatch,'xdata',xdata);
            end
        end
        function cbTimeChanged(this,hSrc)
            %CBTIMECHANGED
            %
            val = hSrc.Value;
            Name = hSrc.Tag;
            
            try
                t = evalin(getWorkspace(this.Figure),val);
            catch
                %Evaluation failed for some reason
                updatePanel(this)
                return
            end
            if isreal(t) && isscalar(t)
                switch Name
                case 'edtStartTime'
                    moveEdge = 'MoveStart';
                    this.StartTime = max(t,this.TimeRange(1));
                case 'edtEndTime'
                    moveEdge = 'MoveEnd';
                    this.EndTime = min(t,this.TimeRange(2));
                end
                updatePatch(this,0,moveEdge)
            end
            updatePanel(this)
        end
        function cbSave(this)
            %CBSAVE
            %
            
            %Update all previews with extracted data
            Ts = this.StartTime;
            Te = this.EndTime;
            dSrc = getWorkingData(this.Figure);
            names = [getOutputName(dSrc); getInputName(dSrc)];
            for ct=1:numel(names)
                sig = getSignalData(dSrc,names{ct});
                idx = sig.Time < Ts | sig.Time > Te;
                sig = delsample(sig,'Index',find(idx));
                setSignalData(dSrc,names{ct},sig,true)%Save data a preview
            end
            
            if this.UseSaveAs
                %Notify listeners data is ready to be extracted
                ed = ctrluis.toolstrip.dataprocessing.GenericEventData('SaveAs');
                notify(this,'DataChanged',ed);
            else
                ed = ctrluis.toolstrip.dataprocessing.GenericEventData('Save');
                notify(this,'DataChanged',ed);
            end
        end
    end
end