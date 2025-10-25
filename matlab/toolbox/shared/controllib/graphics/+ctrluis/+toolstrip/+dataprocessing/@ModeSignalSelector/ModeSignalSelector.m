classdef ModeSignalSelector < handle
    %
    
    % Copyright 2013-2023 The MathWorks, Inc.
    
    properties(GetAccess = public, SetAccess = protected)
        SelectedSignals
        AllSignals
    end
    
    properties(GetAccess = protected, SetAccess = protected)
        Widgets
        Section
        Figure
        Labels
    end
    
    events(NotifyAccess = protected, ListenAccess = public)
        SelectionChanged
    end
        
    methods
        function obj = ModeSignalSelector(fig,labels)
            %MODESIGNALSELECTOR Construct ModeSignalSelector object
            %
            %   obj = ModeSignalSelector(ParentFigure,data)
            %
            
            obj.Figure = fig;
            obj.Labels = labels;
            
            %Initialize signal selection
            resetSelectedSignals(obj);
        end
        function sec = getSection(this)
            %GETSECTION
            %
            
            if isempty(this.Section)
                %Construct the Section widgets
                createSection(this);
                
                %Initialize the section
                connectGUI(this)
            end
            sec = this.Section;
        end
        function resetSelectedSignals(this)
            %RESETSELECTEDSIGNALS
            %
            
            if isempty(this.Figure)
                %Nothing to do
                return
            end
            
            dSrc = this.Figure.getWorkingData;
            sOut = getOutputName(dSrc);
            sIn  = getInputName(dSrc);
            sigs = vertcat(sOut(:),sIn(:));
            this.AllSignals      = sigs;
            this.SelectedSignals = sigs;
        end
        function setSelectedSignals(this,sig)
            %SETSELECTEDSIGNAL
            %
            %   setSelectedSignals(obj,sig)
            %
            %   Inputs:
            %     sig - cell array of signal names
            
            if ~iscell(sig), sig = {sig}; end
            
            %Check signals are valid
            sigs = intersect(this.AllSignals,sig);
            if isempty(sigs)
                error(message('Controllib:general:UnexpectedError','Invalid signal name(s).'))
            elseif ~isequal(this.SelectedSignals, sig)
                this.SelectedSignals = sig;
                updatePanel(this)
            end
        end
        function wdgts = getWidgets(this)
            %GETWIDGETS
            %
            
            wdgts = this.Widgets;
        end
    end
    
    methods(Access = private)
        function createSection(this)
            %CREATESECTION Construct the section widgets
            %
            
            items = this.AllSignals; % combo-box items
            if isempty(items)
                items = {'Signal1'};
            end

            rbtnGroup = matlab.ui.internal.toolstrip.ButtonGroup;
            rbtnAll = matlab.ui.internal.toolstrip.RadioButton(rbtnGroup,this.Labels.lblAll);
            rbtnAll.Tag = 'rbtnAll';
            rbtnAll.Value = true;
            rbtnSelected = matlab.ui.internal.toolstrip.RadioButton(rbtnGroup,this.Labels.lblSelected);
            rbtnSelected.Tag = 'rbtnSelected';
            cmbSignal = matlab.ui.internal.toolstrip.DropDown(items);
            cmbSignal.SelectedIndex = 1;
            cmbSignal.Enabled  = rbtnSelected.Value;
            cmbSignal.Tag     = 'cmbSignal';
            Col1 = matlab.ui.internal.toolstrip.Column('HorizontalAlignment','left');
            %Col1.addEmptyControl();
            Col1.add(rbtnAll);
            Col1.add(rbtnSelected);
            Col2 = matlab.ui.internal.toolstrip.Column('HorizontalAlignment','left');
            %Col2.addEmptyControl();
            Col2.addEmptyControl();
            Col2.add(cmbSignal);
            Col3 = matlab.ui.internal.toolstrip.Column('HorizontalAlignment','left');
            Col3.addEmptyControl();
            sec = matlab.ui.internal.toolstrip.Section(getString(message('Controllib:dataprocessing:lblSignal')));
            sec.Tag = 'secSignal';
            sec.add(Col1);
            sec.add(Col2);
            sec.add(Col3);
            this.Section = sec;

            this.Widgets = struct(...
                'rbtnAll',      rbtnAll, ...
                'rbtnSelected', rbtnSelected, ...
                'cmbSignal',    cmbSignal);
        end
        function connectGUI(this)
            %CONNECTGUI Configure the section widgets
            %
            addlistener(this.Widgets.rbtnSelected, 'ValueChanged', @(hSrc,hData) cbSelectedSignalButton(this));
            addlistener(this.Widgets.cmbSignal,'ValueChanged', @(hSrc,hData) cbSignalChanged(this));
        end
        function updatePanel(this, updateRbtns)
            %UPDATEPANEL Push info from the data to the view
            %    updatePanel(this)
            %    updatePanel(this, updateRbtns) where updateRbtns is a
            %        logical indicating whether radio buttons need to be
            %        updated
            %
            
            %Parse inputs
            if nargin < 2
                updateRbtns = true;
            end
            
            %Determine if one signal is selected
            isOne = isscalar(this.SelectedSignals);
            
            %Update radio buttons
            if updateRbtns
                this.Widgets.rbtnSelected.Value = isOne;
                this.Widgets.rbtnAll.Value = ~isOne;
            end
            
            %Update combo box with selected signal
            this.Widgets.cmbSignal.Enabled = isOne;
            if isOne
                this.Widgets.cmbSignal.Value = this.SelectedSignals{1};
            end
        end
        function cbSelectedSignalButton(this)
            %CBSELECTEDSIGNALBUTTON Manage rbtn* events
            %
            
            SingleSelect = this.Widgets.rbtnSelected.Value;
            if SingleSelect
                idx = this.Widgets.cmbSignal.SelectedIndex;
                
                if ~isempty(idx) && idx>0
                    this.SelectedSignals = this.AllSignals(idx);
                else
                    this.SelectedSignals = this.AllSignals(1);
                end
            else
                this.SelectedSignals = this.AllSignals;
            end
            updatePanel(this, false)
            notify(this,'SelectionChanged')
        end
        function cbSignalChanged(this)
            %CBSIGNALCHANGED Manage cmbSignal events
            %
            idx = this.Widgets.cmbSignal.SelectedIndex;
            txt = this.AllSignals(idx);
            
            if isempty(this.SelectedSignals) || ~strcmp(this.SelectedSignals,txt)
                idx = strcmp(this.AllSignals,txt);
                this.SelectedSignals = this.AllSignals(idx);
                notify(this,'SelectionChanged')
            end
        end
    end
end