classdef absFilterMode < ctrluis.toolstrip.Mode
    %
    
    % Copyright 2013-2023 The MathWorks, Inc.
    
    properties(Access = protected)
        Figure  = [];        %Parent figure that launched this filter mode
        Panel   = [];        %Toolstrip panel
        Widgets = [];        %Panel widgets
        Section = [];        %Toolstrip section(s)
        UpdateSec  = [];     %Update section
        
        Plot = [];  %Bode Magnitude plots for each signal
        
        FilterPatch   = [];
        Filter        = struct('a',[],'b',[],'c',[],'d',[]);  %Filter coefficients
        FilterOptions = struct('Order',[],'Causal',[]);       %Filter options (array with 1st actual value 2nd dialog preapply value)
        
        FilterOptDlg     = [];  %Dialog for filter options
        FilterOptWidgets = [];  %Filter options widgets
        FilterOptHelp    = struct('MapFile',[],'Topic',[]);
        
        MSGIds   %Message ID's for configurable labels
        FreqData = struct('Fs',[],'dF',[]);                
    end
    
    % Formats for toolstrip 1.0
    properties(SetAccess=private,GetAccess=protected)
        % Width of the input widgets for the filter options dialog.
        ValueWidgetWidth = getValueWidgetWidth(); 
        
        % Minimum gap between two widgets.
        Pad = getMinWidgetGap();
        
        % Flexible gap that grows uniformly between widgets.
        FlexPad = [getMinWidgetGap() ':g'];
        
        % Right-aligned label column.
        LabelCol = 'r:p';
        
        % Left-aligned value column.
        ValueCol = ['l:' num2str(getValueWidgetWidth()) 'px'];
        
        % Row format with fill and preferred size.
        Row = 'f:p';
    end
    
    properties(GetAccess = public, SetAccess = protected)
        SignalSelector = [];  %Signal selector
    end
    
    properties(Access = protected, SetObservable = true)
        Dirty = false;  %Flag indicating filter has been applied to data
    end
    
    events(NotifyAccess = protected, ListenAccess = public)
        DataChanged
    end
    
    methods(Access = protected)
         function obj = absFilterMode(varargin)
            %ABSFILTERMODE
            % Inputs: Figure handle, SaveAsEnabled flag
            if nargin > 2
                ModeInputs = varargin(3:end);
            else
                ModeInputs = {''};
            end
            obj = obj@ctrluis.toolstrip.Mode(ModeInputs{1:end});
            
            %Set object properties
            if nargin>0
                obj.Figure = varargin{1};
            end
            SaveAsEnabled = true;
            if nargin > 1
                SaveAsEnabled = varargin{2};
            end
            obj.UpdateSec = ctrluis.toolstrip.dataprocessing.UpdateSection(obj,SaveAsEnabled);
            
            %Set defaults
            obj.FilterOptions = struct(...
                'Order',    {4, 4}, ...
                'Causal',   {true, true});
            obj.FilterOptHelp.MapFile = 'ident';
            obj.FilterOptHelp.Topic   = 'preprocess_filter';
         end
    end
    
    methods
        function sig = getSelectedSignals(this)
            %GETSELECTEDSIGNALS
            %
            
            sig = this.SignalSelector.SelectedSignals;
        end
        function save(this)
             %SAVE Manage Save events
             %
             
             %Notify listeners data has been filtered
             ed = ctrluis.toolstrip.dataprocessing.GenericEventData('Save');
             notify(this,'DataChanged',ed)
             this.Dirty = false;
         end
         function saveAs(this)
            %SAVEAS Manage SaveAs events
            %
            
            ed = ctrluis.toolstrip.dataprocessing.GenericEventData('SaveAs');
            notify(this,'DataChanged',ed);
         end
         function setHelpData(this,mapfile,topicid)
             %SETHELPDATA 
             %
             %    setHelpData(obj,mapfile,topicic)
             %
             %    Set the help mapfile and topic id for this filter tool.
             %
             
             this.FilterOptHelp.MapFile = mapfile;
             this.FilterOptHelp.TopicID = topicid;
         end
    end
    
    %Testing API
    methods(Hidden = true)
        function wdgts = getWidgets(this)
            %GETWIDGETS
            %
            
            wdgts = this.Widgets;
            wdgts.SigSelector = this.SignalSelector;
            wdgts.FilterPatch = this.FilterPatch;
            wdgts.Filter      = this.Filter;
            wdgts.Plot        = this.Plot;
            updateSecWdgts    = getWidgets(this.UpdateSec);
            wdgts.btnSave     = updateSecWdgts.btnSave;
        end
        
        function optWidgets = getFilterOptWidgets(this)
            % GETFILTEROPTWIDGETS Get filter options widgets
            %

            optWidgets = this.FilterOptWidgets;
        end
    end
    
    %Mode API Implementation
    methods(Access = protected)
        function sec = getTabSection(this)
            %GETTABSECTION
            %
            
            if isempty(this.Section)
                %Construct the sections
                createSection(this);
                
                %Install listeners to panel changes
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
                
                %Check filtering is possible for this data
                dSrc  = getWorkingData(this.Figure);
                names = [getOutputName(dSrc); getInputName(dSrc)];
                for ct=1:numel(names)
                    sig = getSignalData(dSrc,names{ct});
                    dt  = diff(sig.Time);
                    if isempty(dt)
                        hMsg = errordlg(...
                            getString(message('Controllib:dataprocessing:errABSFilter_EmptySignal',names{ct})), ...
                            getString(message('Controllib:dataprocessing:lblABSFilter_Filter')));
                        centerfig(hMsg,this.Figure.Figure)
                        this.Dirty   = false;
                        this.Enabled = false;
                        return
                    end
                end
                Ts    = sig.TimeInfo.Increment;
                if isnan(Ts)
                    %Get Ts from time vector directly and check that the signal
                    %is uniformly sampled
                    TsR = [min(dt) max(dt)];
                    if abs(TsR(1)-TsR(2)) < sqrt(eps)
                        Ts = TsR(1);
                    end
                end
                if isnan(Ts)
                    hMsg = errordlg(...
                        getString(message('Controllib:dataprocessing:errABSFilter_VariableSamplePeriod')), ...
                        getString(message('Controllib:dataprocessing:lblABSFilter_Filter')));
                    centerfig(hMsg,this.Figure.Figure)
                    this.Dirty   = false;
                    this.Enabled = false;
                    return
                else
                    %Store frequency range data
                    this.FreqData.Fs = 2*pi/Ts;
                    this.FreqData.dF = 2*pi/(size(sig.Data,1))/Ts;
                end
                
                %Enable the preview
                enablePreview(this.Figure,true)
                
                %Ensure there are signals selected
                if isempty(this.SignalSelector)
                    createSignalSelector(this)
                elseif isempty(this.SignalSelector.SelectedSignals)
                    resetSelectedSignals(this.SignalSelector)
                end
                                
                %Configure the Tab panels and plot
                this.Dirty = true;
                configurePlot(this,'setup')
                updatePanel(this)
                
                %Target the WMM at this mode
                target(getWindowMotionManager(this.Figure),'install',this,...
                    getClickableWidgets(this))
                
                %Apply the default filter
                applyFilter(this)
            else
                enablePreview(this.Figure,false);
                                
                %Restore the plot
                if ishandle(this.Plot)
                    configurePlot(this,'cleanup')
                end
                
                %Detarget the WWM from this mode
                target(getWindowMotionManager(this.Figure),'uninstall',this);
            end
        end
        function configurePlot(this,action)
            %CONFIGUREPLOT
            %
            
            switch action
                case 'setup'
                    %Resize original plot and plot specific to this mode
                    hPlot = getPlot(this.Figure);
                    pos = hPlot.AxesGrid.Position;
                    gap = hPlot.AxesGrid.Geometry.VerticalGap;
                    gap = hgconvertunits(this.Figure.Figure,[0 0 0 gap],'pixels','normalized',this.Figure.Figure);
                    this.Widgets.PlotVertGap = gap(4);
                    hPlot.AxesGrid.Position = [pos(1:3) pos(4)/2-gap(4)];
                    createPlot(this)
                    axH = this.Plot.AxesGrid.allaxes;
                    for ct=1:length(axH)
                        controllib.plot.internal.createToolbar(axH(ct,1))
                    end
                    
                    %Create filter patch(es)
                    createPatch(this)
                case 'cleanup'
                    %Delete the mode plot and restore the original
                    delete(this.Plot);
                    hPlot = getPlot(this.Figure);
                    pos = hPlot.AxesGrid.Position;
                    hPlot.AxesGrid.Position = [pos(1:3) 2*(pos(4)+this.Widgets.PlotVertGap)];
            end
        end
        function ok = cbPreClose(this)
            %CBPRECLOSE
            %
            
            ok = true;
            if this.Dirty
                %Offset is in a dirty state, prompt to save
                selection = uiconfirm(getFigure(this.Figure), ...
                    getString(message(this.MSGIds.CloseNoSave)), ...
                    getString(message(this.MSGIds.Close)), ...
                    'Options', {...
                    getString(message('Controllib:dataprocessing:lblYes')), ...
                    getString(message('Controllib:dataprocessing:lblNo')) } );
                ok = strcmp(selection, getString(message('Controllib:dataprocessing:lblYes')));
            end
        end
    end % Mode API
    
    %WindowMotion API
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
    end
    methods(Abstract = true)
        wmStart(this,widget)
        wmMove(this)
        wmStop(this)
    end % WindowMotion API
    
    % absFilterMode API
    methods(Access = protected, Abstract = true)
        createSection(this)
        connectGUI(this)
        getClickableWidgets(this)
        updateFilter(this)
        createPatch(this)
        updatePatch(this,delta)
    end
    
    methods(Access = protected)
        function createSignalSelector(this)
            %CREATESIGNALSELECTOR
            %
            
            %Create a SignalSelector for this mode
            Labels = struct(...
                'lblAll',      getString(message('Controllib:dataprocessing:lblABSFilter_FilterAll')), ...
                'lblSelected', getString(message('Controllib:dataprocessing:lblABSFilter_FilterSelected')));
            this.SignalSelector = ctrluis.toolstrip.dataprocessing.ModeSignalSelector(this.Figure, Labels);
        end
        function updatePanel(this) %#ok<MANU>
            %UPDATEPANEL
            %
            
        end
        function updatePreview(this)
            %UPDATEPREVIEW
            %
            
            if isempty(this.Figure.PreDataSrc)
                %Quick return nothing to do
                return
            end
            
            src = this.Figure.getWorkingData;
            allSigs = vertcat(getOutputName(src),getInputName(src));
            fSigs = intersect(allSigs,this.SignalSelector.SelectedSignals);

            Enabled = getChkZeroPSEnabled(this);
            this.FilterOptWidgets.chkZeroPS.Enabled = Enabled;

            for ct=1:numel(allSigs)
                data = getSignalData(src,allSigs(ct));
                if any(strcmp(allSigs{ct},fSigs))
                    fData = ctrluis.toolstrip.dataprocessing.tfilt(...
                        this.Filter.a,...
                        this.Filter.b,...
                        this.Filter.c,...
                        this.Filter.d,...
                        data.Data, ...
                        this.FilterOptions(1).Causal);
                    data.Data = fData;
                end
                setSignalData(src,allSigs{ct},data,true);  %Set preview data              
            end
            
            send(this.Figure.PreDataSrc,'SourceChanged')
        end
        function cbDirty(this)
            %CBDIRTY Manage dirty events
            %
            updatePanel(this)
        end
        function applyFilter(this)
            %APPLYFILTER Filter the selected signal(s)
            %
            
            %Compute the filter and apply it to the preview
            updateFilter(this)
            updatePreview(this)
            %Update the filter patch, this is  needed as axis limits can
            %change when filtering
            updatePatch(this)
        end
        function cbSignalChanged(this)
            %CBSIGNALCHANGED Manage cmbSignal events
            %
            %
            
            updatePatch(this)
            if this.Dirty
                applyFilter(this)
            else
                updatePatch(this)
            end
        end
    end
    
    %Methods for filter options dialog
    methods(Access = protected)        
        function createFilterOptionWidgets(this)
            % Create widgets of the filter option dialog.
            
            [lblOrderTxt,chkZeroPSTxt] = getWidgetLabels;
            
            % Create widgets.
            lblOrder = matlab.ui.internal.toolstrip.Label(lblOrderTxt);
            edtOrder = matlab.ui.internal.toolstrip.Spinner(...
                [1 intmax], this.FilterOptions(2).Order);
            chkZeroPS = matlab.ui.internal.toolstrip.CheckBox(chkZeroPSTxt, ...
                ~this.FilterOptions(2).Causal);
            
            %Store widgets.
            this.FilterOptWidgets.lblOrder = lblOrder;
            this.FilterOptWidgets.edtOrder = edtOrder;
            this.FilterOptWidgets.chkZeroPS = chkZeroPS;

            Enabled = getChkZeroPSEnabled(this);
            this.FilterOptWidgets.chkZeroPS.Enabled = Enabled;
        end
            
        function connectFilterOptionWidgets(this)
            % Attach the callback functions with the filter option widgets.

            % Add listener to apply the updated filter order value.
            addlistener(this.FilterOptWidgets.edtOrder,'ValueChanged', ...
                @(hSrc,hData) cbFilterOrderChanged(this,hSrc));

            % Add listener to apply the updated zero-phase shift filter
            % selection.
            addlistener(this.FilterOptWidgets.chkZeroPS,'ValueChanged', ...
                @(hSrc,hData) cbZeroPSFilterSelectionChanged(this,hSrc));
        end
    end
    
    methods(Access = public, Static = true)
        function updateWaveForm(wf)
            %UPDATEWAVEFORM
            %
            
            %Get the new data from the waveform data src
            ioDataSrc = wf.DataSrc.IOData;
            preview   = wf.DataSrc.UsePreview;
            
            frdSignals = getFRDSignals(ioDataSrc,preview);
            
            %Update waveform data source with the new FRD objects
            magphaseresp(wf.DataSrc,wf,frdSignals)
        end
    end
            
    methods(Access=private)
        function cbFilterOrderChanged(this,hSrc)
            % Callback function for updating filter order value.
            
            % Verify the user specified filter order value.
            try
                val = hSrc.Value;
                if isnumeric(val) && isscalar(val) && isreal(val) && isfinite(val) && ...
                        val > 0 && rem(val,1) == 0
                    this.FilterOptions(2).Order = val;
                else
                    error(message('Controllib:general:UnexpectedError','Invalid order value'));
                end
            catch
                % For an invalid value, reset the filter order to the
                % previous value.
                this.FilterOptWidgets.edtOrder.Value = this.FilterOptions(2).Order;
                this.FilterOptWidgets.chkZeroPS.Value = ~this.FilterOptions(2).Causal;
                return
            end
            
            % Apply if the filter order value is changed.
            if this.FilterOptions(1).Order ~= this.FilterOptions(2).Order
                this.FilterOptions(1).Order = this.FilterOptions(2).Order;
                applyFilter(this)
            end
        end
        
        function cbZeroPSFilterSelectionChanged(this,hSrc)
            % Callback function for zero-phase-shift filter selection
            % checkbox.
            
            % Get the user selection.
            this.FilterOptions(2).Causal = ~hSrc.Value;
            
            % Apply if the selection is changed.
            if this.FilterOptions(1).Causal ~= this.FilterOptions(2).Causal
                this.FilterOptions(1).Causal = this.FilterOptions(2).Causal; 
                applyFilter(this)
            end
        end        
        end
            
end
% Helper functions --------------------------------------------------------
function [lblOrderTxt,chkZeroPSTxt] = getWidgetLabels
% Returns widget labels for filter option dialog.

% Label for filter order edit field.
lblOrderTxt = getString(message(...
    'Controllib:dataprocessing:lblABSFilter_FilterOptions_Order'));

% Label for zero-phase shift filter checkbox.
chkZeroPSTxt = getString(message(...
    'Controllib:dataprocessing:lblABSFilter_FilterOptions_ZeroPhaseShift'));
end

function gap = getMinWidgetGap
gap = '2dlu';
end

function width = getValueWidgetWidth
width = 100;
end

function Enabled = getChkZeroPSEnabled(this)
% Disable Zero-Phase Shift Filter Checkbox if Data length is
% too short
src = this.Figure.getWorkingData;
n  = size(this.Filter.a,1);
nf = 3*n;            % length of edge transients
nd = size(src.Data,1);
if nf<nd
    Enabled = true;
else
    Enabled = false;
end
end
