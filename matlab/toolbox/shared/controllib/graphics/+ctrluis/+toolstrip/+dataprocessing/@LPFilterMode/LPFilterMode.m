classdef LPFilterMode < ctrluis.toolstrip.dataprocessing.absFilterMode
    %
    
    % Copyright 2013-2023 The MathWorks, Inc.
    
    properties(GetAccess = public, SetAccess = protected)
        Cutoff %Filter cutoff frequency in normalized frequency [0 1]->[0 Fs/2]
    end
    
    
    methods
        function obj = LPFilterMode(varargin)
            %LPFILTERMODE
            % Inputs: Figure handle, SaveAsEnabled flag            
            obj = obj@ctrluis.toolstrip.dataprocessing.absFilterMode(varargin{:});
            obj.Name   = 'LowPassFilter';
            obj.MSGIds = struct(...
                'Close',       'Controllib:dataprocessing:lblLPFilter_Close', ...
                'CloseNoSave', 'Controllib:dataprocessing:lblLPFilter_Close_No_Save');
        end
    end
    
    %Mode API Implementation
    properties(Constant = true)
        DISPLAYNAME = getString(message('Controllib:dataprocessing:lblLPFilter'));
        DESCRIPTION = getString(message('Controllib:dataprocessing:lblLPFilter_Description'));
        ICON        = 'lowpassFilter';
        ICON_16     = 'LowPassFilter_16';
    end
        
    %WindowMotion API
    methods
        function wmStart(this,widget) %#ok<INUSD>
            %WMSTART
            %
            
            setptr(this.Figure.Figure,'closedhand')
            updatePanel(this);
        end
        function wmMove(this)
            %WMMOVE
            %
            
            WMM     = getWindowMotionManager(this.Figure);
            limitPT = min(max(WMM.PT(1,1),this.FreqData.dF),this.FreqData.Fs/2);
            delta   = limitPT/WMM.PT0(1,1);
            updatePatch(this, delta)
        end
        function wmStop(this)
            %WMSTOP
            %
            
            WMM   = getWindowMotionManager(this.Figure);
            limitPT = min(max(WMM.PT(1,1),this.FreqData.dF),this.FreqData.Fs/2);
            delta   = limitPT/WMM.PT0(1,1);
            this.Cutoff = this.Cutoff*delta;
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
            CutoffTxt = getString(message('Controllib:dataprocessing:lblLPFilter_Cutoff'));
            SecName = getString(message('Controllib:dataprocessing:lblLPFilter'));

            % Create label and edit field for cutt-off frequency.
            lblCutoff      = matlab.ui.internal.toolstrip.Label(CutoffTxt);
            edtCutoff      = matlab.ui.internal.toolstrip.EditField();
            edtCutoff.Tag = 'edtCutoff';

            createFilterOptionWidgets(this)

            %  Create a section and add two columns for cutt-off
            %  frequency and filter option widgets.
            sec = matlab.ui.internal.toolstrip.Section(SecName);
            sec.Tag = 'secLPFilter_Filter';

            col1 = sec.addColumn('HorizontalAlignment','right');
            col2 = sec.addColumn;
            col3 = sec.addColumn;

            % Add cutt-off frequency widgets.
            col1.add(lblCutoff);
            col2.add(edtCutoff);

            % Add filter option widgets.
            col1.add(this.FilterOptWidgets.lblOrder)
            col2.add(this.FilterOptWidgets.edtOrder)
            col3.add(this.FilterOptWidgets.chkZeroPS)

            % Add empty contols for row alignment.
            col3.addEmptyControl;

            %Create section for update
            secUpdate = getSection(this.UpdateSec);
            
            %Store sections
            this.Section = [secSignal; sec; secUpdate];
            
            %Store the widgets for later use
            this.Widgets.edtCutoff  = edtCutoff;
        end
        function connectGUI(this)
            %CONNECTGUI
            %

            %Add listener to edtCutoff events
            Evt1 = 'ValueChanged';
            addlistener(this.Widgets.edtCutoff,Evt1,@(hSrc,hData) cbCutoffChanged(this,hSrc));
            addlistener(this.Widgets.edtCutoff,'FocusLost',@(hSrc,hData) cbCutoffChanged(this,hSrc));
            
            %Add listener for Dirty property events
            addlistener(this,'Dirty','PostSet', @(hSrc,hData) cbDirty(this));
            
            %Add listener for SignalSelector events
            addlistener(this.SignalSelector,'SelectionChanged', @(hSrc,hData) cbSignalChanged(this));
            
            connectFilterOptionWidgets(this)
        end
        function wdgts = getClickableWidgets(this)
            %GETCLICKABLEWIDGETS
            %
            
            wdgts = this.FilterPatch.hL;
        end
        function updatePanel(this)
            %UPDATEPANEL
            %
            
            setEditFieldText(this, mat2str(this.Cutoff,8));
            setEnabled(this.UpdateSec,this.Dirty);
        end
        function createPatch(this)
            %CREATEPATCHES
            %
            
            if isempty(this.Cutoff)
                lowerBound = 0.01;
                upperBound = 0.9;
                cutoffVal = 4*2*this.FreqData.dF/this.FreqData.Fs; %Cutoff, 4*dF_normalized
                cutoffVal = max(lowerBound, cutoffVal);
                cutoffVal = min(upperBound, cutoffVal);
                this.Cutoff = cutoffVal;
            end
            
            sig   = this.SignalSelector.AllSignals;
            fPlot = this.Plot;
            ax    = getaxes(fPlot);
            data  = fPlot.Responses(1).Data;
            for ct=numel(sig):-1:1
                
                hAx     = ax(ct,1,1);   %Get magnitude axis
                
                Fs(ct)  = pi/data.Ts{ct};
                pEdge   = [data.Frequency{ct}(2) this.Cutoff*Fs(ct)];
                
                ylim    = get(hAx,'ylim');
                zLevel  = -2;
                
                if any(strcmp(sig(ct),this.SignalSelector.SelectedSignals))
                    vis = 'on';
                else
                    vis = 'off';
                end
                hL(ct)  = line(...
                    'parent',    hAx, ...
                    'xdata',     [pEdge(2) pEdge(2)], ...
                    'ydata',     ylim, ...
                    'zdata',     (zLevel+1)*[1 1], ...
                    'Color',     [0 0 0], ...
                    'LineWidth', 2, ...
                    'Visible',   vis, ...
                    'Tag',       'lnFilterCuttoff');
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
                'hL',     hL, ...
                'hPatch', hPatch, ...
                'Fs',     Fs, ...
                'Sig',    {sig});
        end
        function updatePatch(this,delta)
            %UPDATEPATCH
            %
            
            if nargin < 2
                delta = 1;
            end
            
            ax = getaxes(this.Plot);
            for ct=1:numel(this.FilterPatch.hPatch)
                if any(strcmp(this.FilterPatch.Sig(ct),this.SignalSelector.SelectedSignals))
                    hAx     = ax(ct,1,1);   %Magnitude axis only
                    ylim    = get(hAx,'ylim');
                    rEdge = this.Cutoff*this.FilterPatch.Fs(ct)*delta;
                    set(this.FilterPatch.hL(ct),...
                        'xdata',   rEdge*[1 1], ...
                        'ydata',   ylim, ...
                        'Visible', 'on')
                    xdata = get(this.FilterPatch.hPatch(ct),'xdata');
                    xdata([3 4]) = rEdge;
                    set(this.FilterPatch.hPatch(ct),...
                        'xdata',   xdata, ...
                        'ydata',   [ylim([1 2]), ylim([2 1]), ylim(1)], ...
                        'Visible', 'on');
                else
                    set(this.FilterPatch.hL(ct),'Visible','off')
                    set(this.FilterPatch.hPatch(ct),'Visible','off');
                end
            end
        end
        function updateFilter(this)
            %UPDATEFILTER
            %
            
            [a,b,c,d] = ctrluis.toolstrip.dataprocessing.butter(this.FilterOptions(1).Order,this.Cutoff);
            this.Filter = struct(...
                'a', a, ...
                'b', b, ...
                'c', c, ...
                'd', d);
        end
        function cbCutoffChanged(this,hSrc)
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
            if ~isequal(this.Cutoff,val)
                this.Cutoff = val;
                this.Dirty = true;
                updatePatch(this)
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
        
        function setEditFieldText(this, str)
            % set edit box text to input string
            this.Widgets.edtCutoff.Value = str;
        end
    end  
end