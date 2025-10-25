classdef BPFilterMode < ctrluis.toolstrip.dataprocessing.absFilterMode
    %
    
    % Copyright 2013-2023 The MathWorks, Inc.
    
    properties(GetAccess = public, SetAccess = protected)
        BPStart %Filter pass-band start frequency in normalized frequency [0 1]->[0 Fs/2]
        BPEnd   %Filter pass-band end frequency in normalized frequency [0 1]->[0 Fs/2]
    end
    
    
    methods
        function obj = BPFilterMode(varargin)
            %BPFILTERMODE
            % Inputs: Figure handle, SaveAsEnabled flag
            obj = obj@ctrluis.toolstrip.dataprocessing.absFilterMode(varargin{:});
            obj.Name   = 'BandPassFilter';
            obj.MSGIds = struct(...
                'Close',       'Controllib:dataprocessing:lblBPFilter_Close', ...
                'CloseNoSave', 'Controllib:dataprocessing:lblBPFilter_Close_No_Save');
        end
    end
    
    %Mode API Implementation
    properties(Constant = true)
        DISPLAYNAME = getString(message('Controllib:dataprocessing:lblBPFilter'));
        DESCRIPTION = getString(message('Controllib:dataprocessing:lblBPFilter_Description'));
        ICON        = 'bandpassFilter';
        ICON_16     = 'BandPassFilter_16';
        %ICON_24     = 'BandPassFilter_24';
        %ICON_40     = 'BandPassFilter_60x40';
    end
        
    %WindowMotion API
    properties(Access = protected)
        MoveEdge   %Flag indicating which edge is being moved
    end
    methods
        function wmStart(this,widget)
            %WMSTART
            %
            
            if any(this.FilterPatch.hLMin == widget)
                this.MoveEdge = 'MoveStart';
            elseif any(this.FilterPatch.hLMax == widget)
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
            limitPT = min(max(WMM.PT(1,1),this.FreqData.dF),this.FreqData.Fs/2);
            delta   = limitPT/WMM.PT0(1,1);
            updatePatch(this, delta,this.MoveEdge)
        end
        function wmStop(this)
            %WMSTOP
            %
            
            WMM     = getWindowMotionManager(this.Figure);
            limitPT = min(max(WMM.PT(1,1),this.FreqData.dF),this.FreqData.Fs/2);
            delta   = limitPT/WMM.PT0(1,1);
            if strcmp(this.MoveEdge,'MoveStart')
                this.BPStart = this.BPStart*delta;
            elseif strcmp(this.MoveEdge,'MoveEnd')
                this.BPEnd = this.BPEnd*delta;
            end
            this.Dirty  = true;
            updatePanel(this); %Update toolstrip widgets
            applyFilter(this)
            
            setptr(this.Figure.Figure,'hand')
        end
    end % WindowMotion API
    
    methods(Access = protected)
        function createSection(this)
            %CREATESECTION
            %
            
            %Create select signal section to choose which signal to filter
            if isempty(this.SignalSelector)
                createSignalSelector(this)
            end
            secSignal = getSection(this.SignalSelector);
            
            %Create section for filter widgets
            StartLblTxt = getString(message('Controllib:dataprocessing:lblBPFilter_Start'));
            EndLblTxt = getString(message('Controllib:dataprocessing:lblBPFilter_End'));
            SecName = getString(message('Controllib:dataprocessing:lblBPFilter'));

            % Create labels and edit fields for cutt-off frequencies.
            lblStart      = matlab.ui.internal.toolstrip.Label(StartLblTxt);
            edtStart      = matlab.ui.internal.toolstrip.EditField();
            edtStart.Tag = 'edtStart';
            lblEnd      = matlab.ui.internal.toolstrip.Label(EndLblTxt);
            edtEnd      = matlab.ui.internal.toolstrip.EditField();
            edtEnd.Tag = 'edtEnd';

            createFilterOptionWidgets(this)

            %  Create a section and add two columns for cutt-off
            %  frequency and filter option widgets.
            sec = matlab.ui.internal.toolstrip.Section(SecName);
            sec.Tag = 'secBPFilter_Filter';

            col1 = sec.addColumn('HorizontalAlignment','right');
            col2 = sec.addColumn;
            col3 = sec.addColumn;

            % Add cutt-off frequency widgets.
            col1.add(lblStart);
            col2.add(edtStart);
            col1.add(lblEnd);
            col2.add(edtEnd);

            % Add filter option widgets.
            col1.add(this.FilterOptWidgets.lblOrder)
            col2.add(this.FilterOptWidgets.edtOrder)
            col3.add(this.FilterOptWidgets.chkZeroPS)

            % Add empty contols for row alignment.
            col3.addEmptyControl;
            col3.addEmptyControl;

            %Create section for update
            secUpdate = getSection(this.UpdateSec);
            
            %Store sections
            this.Section = [secSignal; sec; secUpdate];
            
            %Store the widgets for later use
            this.Widgets.edtStart   = edtStart;
            this.Widgets.edtEnd     = edtEnd;
        end
        function connectGUI(this)
            %CONNECTGUI
            %

            %Add listener to edtStart & edtStop events
            Evt1 = 'ValueChanged';
            addlistener(this.Widgets.edtStart,Evt1,@(hSrc,hData) cbCutoffChanged(this,hSrc,'MoveStart'));
            addlistener(this.Widgets.edtStart,'FocusLost',@(hSrc,hData) cbCutoffChanged(this,hSrc,'MoveStart'));
            addlistener(this.Widgets.edtEnd,Evt1,@(hSrc,hData) cbCutoffChanged(this,hSrc,'MoveEnd'));
            addlistener(this.Widgets.edtEnd,'FocusLost',@(hSrc,hData) cbCutoffChanged(this,hSrc,'MoveEnd'));
            
            %Add listener for Dirty property events
            addlistener(this,'Dirty','PostSet', @(hSrc,hData) cbDirty(this));
            
            %Add listener for SignalSelector events
            addlistener(this.SignalSelector,'SelectionChanged', @(hSrc,hData) cbSignalChanged(this));
            
            connectFilterOptionWidgets(this)
        end
        function updatePanel(this)
            %UPDATEPANEL
            %
            setStartEditFieldText(this, mat2str(this.BPStart,8));
            setEndEditFieldText(this, mat2str(this.BPEnd,8));
            setEnabled(this.UpdateSec,this.Dirty)
        end
        function createPatch(this)
            %CREATEPATCHES
            %
            
            getCutoffs(this);
            sig   = this.SignalSelector.AllSignals;
            fPlot = this.Plot;
            ax    = getaxes(fPlot);
            data  = fPlot.Responses(1).Data;
            for ct=numel(sig):-1:1
                
                hAx     = ax(ct,1,1);   %Get magnitude axis
                
                Fs(ct)  = pi/data.Ts{ct};
                pEdge   = [this.BPStart this.BPEnd]*Fs(ct);
                                
                ylim    = get(hAx,'ylim');
                zLevel  = -2;
                
                if any(strcmp(sig(ct),this.SignalSelector.SelectedSignals))
                    vis = 'on';
                else
                    vis = 'off';
                end
                hLMin(ct) = line(...
                    'parent',    hAx, ...
                    'xdata',     [pEdge(1) pEdge(1)], ...
                    'ydata',     ylim, ...
                    'zdata',     (zLevel+1)*[1 1], ...
                    'Color',     [0 0 0], ...
                    'LineWidth', 2, ...
                    'Visible',   vis, ...
                    'Tag',       'lnFilterStart', ...
                    'Hittest',   'on');
                hLMax(ct) = line(...
                    'parent',    hAx, ...
                    'xdata',     [pEdge(2) pEdge(2)], ...
                    'ydata',     ylim, ...
                    'zdata',     (zLevel+1)*[1 1], ...
                    'Color',     [0 0 0], ...
                    'LineWidth', 2, ...
                    'Visible',   vis, ...
                    'Tag',       'lnFilterStop', ...
                    'Hittest',   'on');
                
                hPatch(ct) = patch(...
                    'parent',    hAx, ...
                    'xdata',     pEdge([1 1 2 2 1]), ...
                    'ydata',     [ylim([1 2]), ylim([2 1]), ylim(1)], ...
                    'zdata',     zLevel*[1 1 1 1 1], ...
                    'FaceColor', [250 250 210]/255, ...
                    'FaceAlpha', 0.75, ...
                    'EdgeColor', 'none', ...
                    'Visible',   vis, ...
                    'Tag',       'ptchFilter');
            end
            this.FilterPatch = struct(...
                'hLMin',  hLMin, ...
                'hLMax',  hLMax, ...
                'hPatch', hPatch, ...
                'Fs',     Fs, ...
                'Sig',    {sig});
        end

        function getCutoffs(this)
            %GETCUTOFFS Get cutoff frequencies

            %Determine if any cutoff frequencies need to be set
            somethingEmpty = true;
            if isempty(this.BPStart)  &&  isempty(this.BPEnd)
                scenario = 'BothEmpty';
            elseif isempty(this.BPStart)
                scenario = 'StartEmpty';
            elseif isempty(this.BPEnd)
                scenario = 'EndEmpty';
            else
                somethingEmpty = false;
            end

            if somethingEmpty
                assignCutoffs(this,scenario);
            end

            enforceOrdering(this);
        end
        
        function assignCutoffs(this,scenario)
            %ASSIGNCUTOFFS Assign cutoff frequencies
            
            %Assign normalized filter cutoff frequencies based on the dF/Fs
            %ratio. Modify if needed to keep cutoffs within bounds.
            lowerBound   = 0.001;
            lowerDefault = 0.01;
            upperDefault = 0.5;
            upperBound   = 0.9;
            val1 = 4*2*this.FreqData.dF/this.FreqData.Fs; %Cutoff, 4*dF_normalized
            val2 = 8*2*this.FreqData.dF/this.FreqData.Fs; %Cutoff, 8*dF_normalized

            switch scenario
                case 'BothEmpty'
                    if val1 >= upperBound
                        val1 = lowerDefault;
                        val2 = upperBound;
                    elseif val2 <= lowerBound
                        val1 = lowerBound;
                        val2 = upperDefault;
                    else
                        val1 = max(lowerBound, val1);
                        val1 = min(upperBound, val1);
                        val2 = max(lowerBound, val2);
                        val2 = min(upperBound, val2);
                    end
                    this.BPStart = val1;
                    this.BPEnd = val2;
                case 'StartEmpty'
                    val1 = max(lowerBound, val1);
                    val1 = min(upperBound, val1);
                    this.BPStart = val1;
                case 'EndEmpty'
                    val2 = max(lowerBound, val2);
                    val2 = min(upperBound, val2);
                    this.BPEnd = val2;
            end
        end

        function enforceOrdering(this)
            %ENFORCEORDERING Enforce that BPStart can't be > BPEnd
            if this.BPStart > this.BPEnd
                tmp          = this.BPStart;
                this.BPStart = this.BPEnd;
                this.BPEnd   = tmp;
            end
        end

        function updatePatch(this,delta,edge)
            %UPDATEPATCH
            %
            
            if nargin < 2
                delta = 1;
            end
            if nargin < 3
                both = true;
            else
                both = false;
            end
            
            ax = getaxes(this.Plot);
            for ct=1:numel(this.FilterPatch.hPatch)
                if any(strcmp(this.FilterPatch.Sig(ct),this.SignalSelector.SelectedSignals))
                    hAx     = ax(ct,1,1);   %Magnitude axis only
                    ylim    = get(hAx,'ylim');
                    xdata = [this.BPStart, this.BPStart, this.BPEnd, this.BPEnd, this.BPStart]*...
                        this.FilterPatch.Fs(ct);
                    if both || strcmp(edge,'MoveStart')
                        xdata([1 2 5]) = this.BPStart*delta*this.FilterPatch.Fs(ct);
                        set(this.FilterPatch.hLMin(ct),...
                            'xdata',   xdata(1)*[1 1], ...
                            'ydata',   ylim, ...
                            'Visible', 'on')
                    end
                    if both || strcmp(edge,'MoveEnd')
                        xdata([3 4]) = this.BPEnd*delta*this.FilterPatch.Fs(ct);
                        set(this.FilterPatch.hLMax(ct),...
                            'xdata',   xdata(3)*[1 1], ...
                            'ydata',   ylim, ...
                            'Visible', 'on')
                    end
                    set(this.FilterPatch.hPatch(ct),...
                        'xdata',   xdata, ...
                        'ydata',   [ylim([1 2]), ylim([2 1]), ylim(1)], ...
                        'Visible', 'on');
                else
                    set(this.FilterPatch.hLMin(ct),'Visible','off')
                    set(this.FilterPatch.hLMax(ct),'Visible','off')
                    set(this.FilterPatch.hPatch(ct),'Visible','off');
                end
            end
        end
        function wdgts = getClickableWidgets(this)
            %GETCLICKABLEWIDGETS
            %
            
            wdgts = [this.FilterPatch.hLMin(:); this.FilterPatch.hLMax(:)];
        end
        function updateFilter(this)
            %UPDATEFILTER
            %
            
            [a,b,c,d] = ctrluis.toolstrip.dataprocessing.butter(this.FilterOptions(1).Order,sort([this.BPStart, this.BPEnd]));
            this.Filter = struct(...
                'a', a, ...
                'b', b, ...
                'c', c, ...
                'd', d);
        end
        function cbCutoffChanged(this,hSrc,edge)
            %CBCUTOFFCHANGED Manage edtCutoff events
            %
            
            try
                txt = hSrc.Value;
                val = evalin(getWorkspace(this.Figure),txt);
                if ~(isnumeric(val) && isscalar(val) && isreal(val) && val > 0 && val < 1)
                    error(message('Controllib:general:UnexpectedError','Bad value'));
                end
            catch
                %No change
                updatePanel(this)
                return
            end
            if strcmp(edge,'MoveStart')
                fld = 'BPStart';
            elseif strcmp(edge,'MoveEnd')
                fld = 'BPEnd';
            end
            if ~isequal(this.(fld),val)
                this.(fld) = val;
                this.Dirty = true;
                updatePatch(this,1,edge)
                applyFilter(this)
            end
        end
        function cbSaveAsMenuItemSelected(this,hSrc)
            %CBSAVEASMENUITEMSELECTED
            %
            
            item = hSrc.Items(hSrc.SelectedIndex);
            switch item.Name
                case 'mnuSaveAs'
                    ed = ctrluis.toolstrip.dataprocessing.GenericEventData('SaveAs');
                    notify(this,'DataChanged',ed);
            end
        end
        
        function setStartEditFieldText(this, str)
            % set edit box text to input string
            this.Widgets.edtStart.Value = str;
        end
        
        function setEndEditFieldText(this, str)
            % set edit box text to input string
            this.Widgets.edtEnd.Value = str;
        end
    end  
end