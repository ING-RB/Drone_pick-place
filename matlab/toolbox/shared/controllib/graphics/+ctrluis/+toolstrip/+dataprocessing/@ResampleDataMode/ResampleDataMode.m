classdef ResampleDataMode < ctrluis.toolstrip.Mode
    %
    
    % Copyright 2013-2023 The MathWorks, Inc.
    
    properties(Access = protected)
        Figure         = [];    %Parent figure that launched this mode
        Panel          = [];    %Toolstrip panel
        Widgets        = [];    %Panel widgets
        Section        = [];    %Toolstrip section(s)
        SignalSelector = [];    %Signal selector
        Preview        = [];    %Preview data
        UpdateSec      = [];     %Update section
    end
    
    properties(Access = protected, SetObservable = true)
        Dirty = false; %Data has been re-sampled but not saved
    end
    
    properties(GetAccess = public, SetAccess = protected)
        SamplePeriod
        SampleMethod
    end
    
    events(NotifyAccess = protected, ListenAccess = public)
        DataChanged
    end
    
    methods
        function obj = ResampleDataMode(varargin)
            %RESAMPLEDATA
            %
            % Inputs: Figure handle, SaveAsEnabled flag
            if nargin > 2
                ModeInputs = varargin(3:end);
            else
                ModeInputs = {''};
            end
            obj = obj@ctrluis.toolstrip.Mode(ModeInputs{1:end});
            obj.Name         = 'ResampleData';
            obj.SamplePeriod = 0;  %Implies no change
            obj.SampleMethod = 'ZOH';
            if nargin>0
                obj.Figure = varargin{1};
            end
            
            SaveAsEnabled = true;
            if nargin > 1
                SaveAsEnabled = varargin{2};
            end
            obj.UpdateSec = ctrluis.toolstrip.dataprocessing.UpdateSection(obj,SaveAsEnabled);
        end
        function set.SampleMethod(this,newval)
            %SampleMethod must be one of {'ZOH','Linear'}
            validVals = {'ZOH','Linear'};
            if any(strcmp(newval,validVals))
                this.SampleMethod = newval;
            else
                error(message('Controllib:general:UnexpectedError','Invalid value for SampleMethod'))
            end
        end
        function save(this)
            %SAVE Manage save events
            %
            
            %Notify listeners offset has changed
            ed = ctrluis.toolstrip.dataprocessing.GenericEventData('Save');
            notify(this,'DataChanged',ed)
            
            this.Dirty = false;
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
            updateSecWdgts = getWidgets(this.UpdateSec);
            wdgts.btnSave  = updateSecWdgts.btnSave;
        end
        function pv = getPreview(this)
            %GETPREVIEW
            %
            
            pv = this.Preview;
        end
    end
    
    %Mode API Implementation
    properties(Constant = true)
        DISPLAYNAME = getString(message('Controllib:dataprocessing:lblResampleData'));
        DESCRIPTION = getString(message('Controllib:dataprocessing:lblResampleData_Description'));
        ICON        = 'resampleSignal';
        ICON_16     = 'Resample_16';
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
                
                %Reset the tool settings, choose default sample time based
                %on 1st output or input signal
                dSrc  = getWorkingData(this.Figure);
                names = [getOutputName(dSrc); getInputName(dSrc)];
                sig   = getSignalData(dSrc,names{1});
                Ts    = sig.TimeInfo.Increment;
                if isnan(Ts)
                    %Get Ts from time vector directly and check for empty
                    %signal
                    dt = diff(sig.Time);
                    if isempty(dt)
                        hMsg = errordlg(...
                            getString(message('Controllib:dataprocessing:errResampleData_EmptySignal',names{1})), ...
                            getString(message('Controllib:dataprocessing:lblResampleData')));
                        centerfig(hMsg,this.Figure.Figure)
                        this.Dirty   = false;
                        this.Enabled = false;
                        return
                    end
                    TsR = [min(dt) max(dt)];
                    if abs(TsR(1)-TsR(2)) < sqrt(eps)
                        Ts = TsR(1);
                    end
                end
                if isnan(Ts)
                    %Variable step data, choose initial value as median.
                    %Add protection in case this would create a large
                    %resampled signal.
                    dt = (sig.TimeInfo.End-sig.TimeInfo.Start)/1e6;
                    this.SamplePeriod = max(median(diff(sig.Time)),dt);
                    hMsg = msgbox(...
                        getString(message('Controllib:dataprocessing:msgResampleData_VariableStep')), ...
                        getString(message('Controllib:dataprocessing:lblResampleData')));
                    centerfig(hMsg,this.Figure.Figure)
                    updatePreview(this)
                else
                    this.SamplePeriod = Ts;
                end
                                
                %Make sure panel is uptodate
                updatePanel(this)
            else
                enablePreview(this.Figure,false)
            end
        end
        function ok = cbPreClose(this)
            %CBPRECLOSE
            %
            
            ok = true;
            if this.Dirty
                %In a dirty state, prompt to save
                selection = uiconfirm(getFigure(this.Figure), ...
                    getString(message('Controllib:dataprocessing:lblResampleData_Close_No_Save')), ...
                    getString(message('Controllib:dataprocessing:lblResampleData_Close')), ...
                    'Options', {...
                    getString(message('Controllib:dataprocessing:lblYes')), ...
                    getString(message('Controllib:dataprocessing:lblNo')) } );
                ok = strcmp(selection, getString(message('Controllib:dataprocessing:lblYes')));
            end
        end
    end % Mode API
    
    methods(Access = protected)
        function createSection(this)
            %CREATESECTION
            %
            SamplePeriodTxt = getString(message('Controllib:dataprocessing:lblResampleData_SamplePeriod'));
            SampleUsingTxt = getString(message('Controllib:dataprocessing:lblResampleData_SampleUsing'));
            cmbSampleTxt = {getString(message('Controllib:dataprocessing:lblResampleData_ZOH'));...
                getString(message('Controllib:dataprocessing:lblResampleData_Linear'))};
            
            %Create section for resample widgets
            lblSamplePeriod = matlab.ui.internal.toolstrip.Label(SamplePeriodTxt);
            edtSamplePeriod = matlab.ui.internal.toolstrip.EditField();
            lblSampleUsing  = matlab.ui.internal.toolstrip.Label(SampleUsingTxt);
            cmbSampleUsing  = matlab.ui.internal.toolstrip.DropDown(cmbSampleTxt);
            cmbSampleUsing.SelectedIndex = 1;
            cmbSampleUsing.Editable = false;
            cmbSampleUsing.Enabled  = true;
            cmbSampleUsing.Tag     = 'cmbSampleUsing';

            % Layout
            pnl1 = matlab.ui.internal.toolstrip.Panel;
            pnl1_col1 = pnl1.addColumn();
            pnl1_col2 = pnl1.addColumn();
            pnl1_col1.add(lblSamplePeriod);
            pnl1_col2.add(edtSamplePeriod);

            pnl2 = matlab.ui.internal.toolstrip.Panel;
            pnl2_col1 = pnl2.addColumn();
            pnl2_col2 = pnl2.addColumn();
            pnl2_col1.add(lblSampleUsing);
            pnl2_col2.add(cmbSampleUsing);

            sec = matlab.ui.internal.toolstrip.Section(getString(message('Controllib:dataprocessing:lblResampleData')));
            sec.Tag = 'secResampleData';
            col = sec.addColumn();
            col.add(pnl1);
            col.add(pnl2);
            
            %Create section for update
            secUpdate = getSection(this.UpdateSec);
            
            %Store sections
            this.Section = [sec; secUpdate];
            
            %Store the widgets for later use
            this.Widgets = struct(...
                'edtSamplePeriod', edtSamplePeriod, ...
                'cmbSampleUsing',  cmbSampleUsing);
        end
        function connectGUI(this)
            %CONNECTGUI
            %
            
            %Common items
            Evt = 'ValueChanged';
            
            %Add listener to edtSamplePeriod events
            addlistener(this.Widgets.edtSamplePeriod,Evt,@(hSrc,hData) cbSamplePeriodChanged(this,hSrc));
            addlistener(this.Widgets.edtSamplePeriod,'FocusLost',@(hSrc,hData) cbSamplePeriodChanged(this,hSrc));
            
            %Add listener to cmbSampleUsing events
            addlistener(this.Widgets.cmbSampleUsing,Evt,@(hSrc,hData) cbSampleUsingChanged(this,hSrc));
                        
            %Add listener to dirty events
            addlistener(this,'Dirty','PostSet', @(hSrc,hData) updatePanel(this));
        end
        function updatePanel(this)
            %UPDATEPANEL
            %

            this.Widgets.edtSamplePeriod.Value = mat2str(this.SamplePeriod,8);
            setEnabled(this.UpdateSec,this.Dirty);
        end
        function updatePreview(this)
            %UPDATEPREVIEW
            %
            
            dSrc = getWorkingData(this.Figure);
            sigs = [getInputName(dSrc); getOutputName(dSrc)];
            for ct=1:numel(sigs)
                newData = getSignalData(dSrc,sigs{ct});
                newData = ctrluis.toolstrip.dataprocessing.resampleData(newData,this.SamplePeriod,this.SampleMethod);
                setSignalData(dSrc,sigs{ct},newData,true);   %Update preview
            end
            this.Dirty = true;
            
            %Fire preview redraw
            send(this.Figure.PreDataSrc,'SourceChanged')
        end
        function cbSamplePeriodChanged(this,hSrc)
            %CBOFFSETCHANGED Manage cmbOffset events
            %
            
            txt = hSrc.Value;
            try
                v = evalin(getWorkspace(this.Figure),txt);
                if ~isnumeric(v) || ~isreal(v) || ~isscalar(v) || ~isfinite(v) || v <= 0
                    error(message('Controllib:general:UnexpectedError','Bad value'));
                end
            catch
                %No change
                updatePanel(this)
                return
            end
            
            if ~isequal(v,this.SamplePeriod)
                this.SamplePeriod = v;
                updatePreview(this)
            end
        end
        function cbSampleUsingChanged(this,hSrc)
            %CBSAMPLEUSINGCHANGED
            %
            
            txt = hSrc.Value;
            switch txt
                case getString(message('Controllib:dataprocessing:lblResampleData_ZOH'))
                    val = 'ZOH';
                case getString(message('Controllib:dataprocessing:lblResampleData_Linear'))
                    val = 'Linear';
            end
            if ~isequal(this.SampleMethod,val)
                this.SampleMethod = val;
                updatePreview(this)
            end
        end
    end
end