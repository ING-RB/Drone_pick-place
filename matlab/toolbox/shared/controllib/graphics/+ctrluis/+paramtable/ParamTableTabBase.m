classdef ParamTableTabBase < ctrluis.ControlsFigureTool
    %PARAMTABLETAB -- Parameter table editor
    %   Allows interactive editing of parameter values
    %   Supports both toolpack and toolstrip
    
    % Copyright 2014-2025 The MathWorks, Inc.
    
    
    %% Read-Only properties
    properties (GetAccess = public, SetAccess = protected)
        % Data
        ParentToolGroupName
        ParamTableTC
        ParamTableGC
        DataSrc   % Needed for plot manager infrastructure in SDO
        % Widgets
        ManageButton
        InsertButton
        DeleteButton
        GenerateButton
        % Dialogs
        VariableSelectorTC
        VariableSelector
        ParamWks
        GenerateParamValueGC
        GenerateParamRandomValuesGC
        ParamList
        % Model
        Model
    end

    properties (Access = protected)
        ParentAppContainer
    end
    
    %% Public properties
    properties (Access = public)
        ParamVarName
    end
    
    %% Constant Properties
    properties(GetAccess = public, Constant = true)
        % Interface for plot gallery
        NAME         = getString(message('Controllib:gui:ParamTableGalleryName'));
        DESCRIPTION  = getString(message('Controllib:gui:ParamTableGalleryDescription'));
    end
    
    %% Public Properties
    properties (GetAccess = public, SetAccess = private)
       ICON 
    end

    %% Private Properties
    properties (Access = private)
        % Title used for tab and document by non-SampleSet clients
        ClientTitle
    end
    
    %% Events
    events
        ParamsChanged
        ParamListChanged
    end
    
    %% Abstract protected methods
    methods (Abstract, Access = protected)
        createTab(this, generate_buttontype);
        icon = createIcon(this,path);
        btn = createButton(this,text,icon,name);
        ddbtn = createDropDownButton(this,text,icon,name);
        sec = createSection(this,title,name);
        addParamPanel(this,sec);
        addEditPanel(this,sec);
        showParamDialog(this,Dlg,anchor,varargin);
        anchor = getAnchor(this,AnchorObject);
        addManageButtonListener(this);
        addInsertButtonListener(this);
        addDeleteButtonListener(this);
        addGenerateButtonListener(this);
        addGenerateDropDownListener(this);
    end
    
    %% Public methods
    methods
        function this = ParamTableTabBase(version,group,clienttitle,tabtitle,model,paramdata,extra)
            %Constructor
            tag = "ParameterTable "  +  matlab.lang.internal.uuid;
            numTabs = 1;
            this = this@ctrluis.ControlsFigureTool(tag,numTabs);
            this.ICON = createIcon(this,LocalGetIconPath);

            if controllib.internal.util.openJavaApp
                this.ParentToolGroupName = group.Name;
                this.ParentAppContainer  = [];
            else
                %group is a struct with field 'AppContainer'
                this.ParentToolGroupName = group.AppContainer.Tag;
                this.ParentAppContainer  = group.AppContainer;
            end
            this.Model = model;
            
            % Create table tool component
            this.ParamTableTC = ctrluis.paramtable.ParamTableTC(paramdata,this);

            if strcmp('SampleSet', getDataType(this.ParamTableTC))
                tabName = getString(message('Controllib:gui:ParamTableTitle_Sensitivity'));
            else
                % Update tab name and ClientTitle (for document name later) for non-SampleSet workflows
                tabName = tabtitle;
                this.ClientTitle = clienttitle;
            end
            
            this.Tabs(1).Title = tabName;

            % Add the listener to throw ParamsChanged event - Necessary
            % for param picker to update itself
            addlistener(this.ParamTableTC, 'ComponentChanged', @(es,ed) notifyParamsChanged(this));
            
            % Create table visual
            this.ParamTableGC = createView(this.ParamTableTC);
            
            % Initialize with specified parameter data
            if this.numParameters(paramdata) == 0
                this.ParamList = {''};
            else
                this.ParamList = this.getParameterList(paramdata);
            end
            
            % Define parameter variable name
            if numel(extra) < 2
                this.ParamVarName = 'Parameters';
            else
                this.ParamVarName = extra{2};
            end
            refreshTitle(this);

            % Define parameter workspace
            if numel(extra) < 1
                this.ParamWks = toolpack.databrowser.LocalWorkspaceModel;
                % Initialize with specified parameter data
                if this.numParameters(paramdata) == 0
                    NewParamData = [];
                else
                    NewParamData = getParameterFromModel(this, this.ParamList);
                end
                assignin(this.ParamWks,this.ParamVarName,NewParamData);
            else
                this.ParamWks = extra{1};
            end

            %Specify whether "Generate Values" is regular button or
            %dropdown
            if numel(extra) < 3
                generate_buttontype = 'Button';
            else
                generate_buttontype = 'DropDownButton';
            end
            
            %Add data source
            if strcmp('SampleSet', getDataType(this.ParamTableTC))
                if numel(extra) < 4
                    dataSource = sldoplots.DataSrc(this.ParamVarName, '', 'table');
                else
                    dataSource = extra{4};
                end
                addSource(this,dataSource);
            end
            
            % % % Create contextual tab
            % % this.Tab = createTab(this,tabtitle);
            % % createWidgets(this, generate_buttontype);   % % these are in the toolstrip
            
            % % this added the figure to the app tabgroup
            % Figure's tab gains focus, except for Sensitivity Analysis UI
            % %             if numel(extra) < 3
            % %                 add(this, group);
            % %             else
            % %                 add(this, group, true);   % Sensitivity Analysis
            % %             end
            
            %Create toolstrip for tab
            createTab(this, generate_buttontype);

            % % Consider moving listener definitions inside createTab
            installListeners(this, generate_buttontype);   % % toolstrip button listeners

            this.VariableSelectorTC = ctrluis.paramtable.VariableSelectorTC();

            %Listener to clean up when parameter table is closed
            addlistener(getFigure(this), 'ObjectBeingDestroyed', @(es,ed) deleteTab(this));
            
            % Create generate table dialog
            if strcmp('SampleSet', getDataType(this.ParamTableTC))
                % For sensitivity analysis UI, dialog title specifies
                % gridded samples
                this.GenerateParamValueGC = ctrluis.paramtable.GenerateParamValueDialog(...
                    this, Title=getString(message('Controllib:gui:EditParamValue_TitleGridded')),...
                    ProductName='sldo');
            else
                this.GenerateParamValueGC = ctrluis.paramtable.GenerateParamValueDialog(this);
            end
            this.GenerateParamRandomValuesGC = [];
            
            % Force refresh after data is set
            updateParamList(this)
        end

        %Add source
        function addSource(this,dataSource)

            %Minimal version of addSource method as in SDO plots, because
            %for this plot the source will not change

            %Store data source
            this.DataSrc = vertcat(this.DataSrc, dataSource);
        end

        %Get hidden sources
        function sources = getHiddenSources(~)

            %Used with SDO plots.  Parameter table does not have hidden
            %sources.
            sources = [];
        end

        % Close figure
        function closeFigure(this)
            switch getDataType(this.ParamTableTC)
                case 'SampleSet'
                    %Deletion consistent with SDO plots in document area
                    delete(this);
                otherwise
                    close(getFigure(this));
            end
        end
        %Close - API of parent class
        function close(this)
            closeFigure(this);
        end
        % Get Parameter Data
        function paramdata = getParameterData(this)
            paramdata = getParameterData(this.ParamTableTC);
        end
        % Set Parameter Data
        function setParameterData(this,params)
            setParameterData(this.ParamTableTC,params);
        end
        % Append Parameter Data
        function appendParameterData(this,params)
            appendParameterData(this.ParamTableTC,params);
        end
        %Update view based on data
        function update(this)
            if isempty(this.InsertButton)  ||  isempty(this.DeleteButton)
                %Quick return if widgets are not defined
                return
            end
            
            %Common items            
            nParams = this.numParameters(getParameterData(this));
            nRows = getDataSize(this.ParamTableTC, 1);
            selRow = this.ParamTableTC.SelectedRow;

            %For the insert button to be enabled:
            %   - there must be at least one parameter
            %   - there must be at least one selected row, or zero rows
            if nParams == 0
                enInsert = false;
            else
                ok1 = (nRows >= 1)  &&  ~isempty(selRow);
                ok2 = (nRows == 0);
                enInsert = ok1  ||  ok2;
            end
            if this.InsertButton.Enabled ~= enInsert
                this.InsertButton.Enabled = enInsert;
            end
            
            %The delete button is enabled if there is at least one
            %parameter, at least one row of data, and at least one selected
            %row
            enDelete = (nParams >= 1)  &&  (nRows >= 1)  && ...
                ~isempty(selRow);
            if this.DeleteButton.Enabled ~= enDelete
                this.DeleteButton.Enabled = enDelete;
            end
        end
        
        % Update Generate Parameter Table
        function updateGenerateParamTable(this)
            if ~(isempty(this.GenerateParamValueGC) || ~isvalid(this.GenerateParamValueGC))
                updateParameterList(this.GenerateParamValueGC,getParameterData(this));
            end
        end
        
        % Add parameter selection dialog
        function addParam(this, varargin)
            %
            %    addParam(obj)
            %
            %    addParam(obj, anchor) includes anchor for placing dialog to
            %    select parameters
            %
            if isempty(this.VariableSelector)
                this.VariableSelector = createView(this.VariableSelectorTC);
                dataType = getDataType(this.ParamTableTC);
                switch dataType
                    case 'struct'
                        lblTitle = getString(message('Controllib:gui:lblVariableSelector_Variables'));
                    case 'SampleSet'
                        lblTitle = getString(message('Controllib:gui:lblVariableSelector_SampleSet'));
                        setMapFile(this.VariableSelector,'sldo')
                end
                labels = struct(...
                    'lblTitle',  lblTitle, ...
                    'lblFilter', getString(message('Controllib:gui:lblVariableSelector_FilterByName')), ...
                    'lblName',   getString(message('Controllib:gui:lblDesignVariableTable_Variables')), ...
                    'lblValue',  getString(message('Controllib:gui:lblDesignVariableSelectorTable_CurrentValue')), ...
                    'lblUsedBy', getString(message('Controllib:gui:lblDesignVariableSelectorTable_UsedBy')));
                setConfiguration(this.VariableSelector,'var',labels,false);
                addlistener(this.VariableSelector,'ActionPerformed',@(hSrc,hData) cbParamAdded(this));
            end
            setCandidateVariables(this.VariableSelectorTC,getCandidateVariables(this));
            if isempty(varargin)
                anchor = this.ManageButton;
            else
                anchor = varargin{1};
            end
            show(this.VariableSelector,anchor,true)
        end
        
        %Get parameter values from Simulink model
        function params = getParameterFromModel(this, varNames)
            switch getDataType(this.ParamTableTC)
                case 'SampleSet'
                    params = sdo.getParameterFromModel(this.Model, varNames);
                otherwise
                    params = ctrluis.paramtable.getParameterFromModel(this.Model, varNames);
            end
        end
        
        % Generate random values
        function generateRandomValues(this)
            if isempty(this.GenerateParamRandomValuesGC) || ~isvalid(this.GenerateParamRandomValuesGC)
                % Create random sampling dialog, and open it centered on
                % sensitivity analysis UI
                this.GenerateParamRandomValuesGC = ...
                    sldodialogs.sensitivityanalysis.randomsample.GenerateParamRandomValuesGC(this);
            end
            %Always open dialog centered on the app, since the close mode
            %of the dialog causes dialog to be destroyed
            show(this.GenerateParamRandomValuesGC, this.ParentAppContainer);
        end
        % Generate gridded values
        function generateValues(this, varargin)
            %    generateValues(obj)
            %
            %    generateValues(obj, anchor) includes anchor for placing
            %    dialog to generate values
            %
            if isempty(this.GenerateParamValueGC) || ~isvalid(this.GenerateParamValueGC)
                if strcmp('SampleSet', getDataType(this.ParamTableTC))
                    % For sensitivity analysis UI, dialog title specifies
                    % gridded samples
                    this.GenerateParamValueGC = ctrluis.paramtable.GenerateParamValueDialog(...
                        this, Title=getString(message('Controllib:gui:EditParamValue_TitleGridded')),...
                        ProductName='sldo');
                else
                    this.GenerateParamValueGC = ctrluis.paramtable.GenerateParamValueDialog(this);
                end
            end
            if ~controllib.internal.util.openJavaApp
            %if ~isempty(ancestor(this.GenerateButton,{'matlab.ui.internal.toolstrip.Tab'},'toplevel'))
                this.GenerateParamValueGC.show(this.ParentAppContainer);
                return
            end
            if isempty(varargin)
                showParamDialog(this,this.GenerateParamValueGC, this.GenerateButton);
            else
                showParamDialog(this,this.GenerateParamValueGC, varargin{1});
            end
        end
        
        %% QE METHODS
        function s = getTesters(this)
            s.ManageButton = this.ManageButton;
            s.InsertButton = this.InsertButton;
            s.DeleteButton = this.DeleteButton;
            s.GenerateButton = this.GenerateButton;
            s.Figure = getFigure(this);
            widgets = qeGetWidgets(this.ParamTableGC);
            s.MessageString = widgets.NoParamsLabel.Text;
            s.GenerateDlgTesters = qeGetWidgets(this.GenerateParamValueGC);
            s.VariableSelector = this.VariableSelector;
            s.ParameterTable = this.ParamTableGC;
        end
        
    end
    
    %% Protected methods
    methods (Access = protected)

        % Create Toolstrip Widgets
        function sections = createWidgets(this, generate_buttontype)
            %% Parameters section
            paramSection = createSection(this,...
                getString(message('Controllib:gui:ParamSectionParameters')),'params');
            % Widgets
            switch getDataType(this.ParamTableTC)
                case 'SampleSet'
                    % Sensitivity Analysis tool
                    msgID = 'Controllib:gui:ParamSetAdd_Sensitivity';
                otherwise
                    % Tools other than sensitivity analysis
                    msgID = 'Controllib:gui:ParamSetAdd';
            end
            this.ManageButton = createButton(this,...
                getString(message(msgID)),...
                createIcon(this,...
                fullfile(matlabroot,'toolbox','shared','controllib','graphics','resources',...
                'Parameters_24px.png')),...
                'MangeButton');

            % "generate values" button
            if iscellstr(generate_buttontype)
                generate_buttontype = generate_buttontype{1};
            end
            switch generate_buttontype
                case 'Button'
                    this.GenerateButton = createButton(this,...
                        getString(message('Controllib:gui:ParamGenerateGenerate')),...
                        createIcon(this,'import'),...
                        []);
                case 'DropDownButton'
                    this.GenerateButton = createDropDownButton(this,...
                        getString(message('Controllib:gui:ParamGenerateGenerate')),...
                        createIcon(this,'import'),...
                        []);
                otherwise
                    error(message('Controllib:gui:errUnexpected', 'Unrecognized button type' ));
            end
            this.GenerateButton.Enabled = false;

            %Add widgets to parameter-section
            addParamPanel(this,paramSection);

            %% Edit section
            editSection = createSection(this,...
                getString(message('Controllib:gui:ParamSectionEdit')),'edit');
            this.InsertButton = createDropDownButton(this,...
                getString(message('Controllib:gui:ParamEditInsert')),...
                createIcon(this,...
                fullfile(matlabroot,'toolbox','shared','controllib','graphics','resources',...
                'Insert_Row_24.png')),...
                'InsertButton');
            this.InsertButton.Enabled = false;   % enabled when data available
            this.DeleteButton = createButton(this,...
                getString(message('Controllib:gui:ParamEditDelete')),...
                createIcon(this,...
                fullfile(matlabroot,'toolbox','shared','controllib','graphics','resources',...
                'Delete_Row_24.png')),...
                'DeleteButton');
            this.DeleteButton.Enabled = false;   % enabled when data available

            %Add widgets to edit-section
            addEditPanel(this,editSection);

            %Collect sections for output
            sections = [paramSection editSection];
        end

        % Install Listeners
        function installListeners(this, generate_buttontype)
            addManageButtonListener(this);
            addInsertButtonListener(this);
            addDeleteButtonListener(this);
            % listener for "generate values"
            if iscellstr(generate_buttontype)
                generate_buttontype = generate_buttontype{1};
            end
            switch generate_buttontype
                case 'Button'
                    addGenerateButtonListener(this);
                case 'DropDownButton'
                    addGenerateDropDownListener(this);
                otherwise
                    error(message('Controllib:gui:errUnexpected', 'Unrecognized button type' ));
            end
            % React to changes in parameter variable name, for the
            % Sensitivity Analysis UI
            if strcmp('SampleSet', getDataType(this.ParamTableTC))
                addlistener(this.ParamTableTC, 'ComponentChanged', @(es,ed) refreshTitle(this));
            end
        end
        % Delete dialogs that the parameter table tab may have spawned
        function deleteTab(this)
            isValidGC = @(gc) ~isempty(gc) && isvalid(gc);
            %Clean up variable selector dialog
            if isValidGC(this.VariableSelector)
                % No need to call CLOSE since DELETE also cleans up UI. See
                %   - controllib.ui.internal.dialog.AbstractUI/delete
                %   - controllib.ui.internal.dialog.MixedInDialog/delete
                delete(this.VariableSelector)
                this.VariableSelector = [];
            end
            %Clean up dialog for gridded parameter values
            if ~isempty(this.GenerateParamValueGC) && isvalid(this.GenerateParamValueGC)
                delete(this.GenerateParamValueGC);
            end
            %Clean up dialog for random parameter values
            if isValidGC(this.GenerateParamRandomValuesGC)
                % Close and clean up dialog
                close(this.GenerateParamRandomValuesGC);
                % Delete dialog in case objects still reference it
                delete(this.GenerateParamRandomValuesGC);
            end
            delete(this.ParamTableGC);   % delete GC so it can be deleted from dialog manager
            delete(this.ManageButton);
        end
        % Callback for selecting insert item
        function selectInsertItem(this,es)
            %
            try
                if isnumeric(es)
                    idx = es;
                else
                    idx = es.SelectedIndex;
                end
                if idx == 1
                    insertRow(this.ParamTableTC,true);
                else
                    insertRow(this.ParamTableTC,false);
                end
            catch Ex
                openUIAlertErrorDialog(this,this.InsertButton,Ex.message);
            end
        end
        % Get dropdown data for generate button
        function data = getDropDownGenerateValues(this)
            % Populate items
            items(1) = struct(...
                'Title',           getString(message('Controllib:gui:ParamGenerateRandom')), ...
                'Icon',            createIcon(this, fullfile(sldodialogs.getIconResourcePath('sldodialogs'), 'GenerateValues_Random_16.png')) );
            items(2) = struct(...
                'Title',           getString(message('Controllib:gui:ParamGenerateGridded')), ...
                'Icon',            createIcon(this, fullfile(sldodialogs.getIconResourcePath('sldodialogs'), 'GenerateValues_Gridded_16.png')) );
            data = items;
        end
        % Get dropdown data for Insert Button
        function data = getDropDownInsertValues(this)
            % Populate items
            icon = createIcon(this,...
                fullfile(matlabroot,'toolbox','shared','controllib','graphics','resources',...
                'Insert_Row_16.png'));
            if getDataSize(this.ParamTableTC, 1) > 0
                items(1) = struct(...
                    'Title', getString(message('Controllib:gui:ParamEditInsertAbove')), ...
                    'Icon', icon);
                items(2) = struct(...
                    'Title', getString(message('Controllib:gui:ParamEditInsertBelow')), ...
                    'Icon', icon);
            else
                items = struct(...
                    'Title', getString(message('Controllib:gui:ParamEditInsertFromModel')), ...
                    'Icon', icon);
            end
            data = items;
        end
        % Callback for Generate Dropdown button
        function selectGenerateValues(this,es)
            % Numeric index or event source
            try
                if isnumeric(es)
                    idx = es;
                else
                    idx = es.SelectedIndex;
                end
                if idx == 1
                    generateRandomValues(this);
                else
                    generateValues(this);
                end
            catch Ex
                openUIAlertErrorDialog(this,this.GenerateButton,Ex.message);
            end
        end
        % Callback for Delete Button
        function deleteRow(this)
            try
                deleteRow(this.ParamTableTC);
            catch Ex
                openUIAlertErrorDialog(this,this.DeleteButton,Ex.message);
            end
        end
    end
    
    %% Static methods
    methods (Static = true)
        % Number of parameters in data object
        function n = numParameters(paramData)
            if isa(paramData, 'struct')
                n = numel(paramData);
            elseif isa(paramData, 'param.Continuous')
                n = numel(paramData);
            elseif isa(paramData, 'sldodialogs.data.SampleSet')  &&  isscalar(paramData)
                n = numParameters(paramData);
            elseif isempty(paramData)
                n = 0;
            else
                error(message('Controllib:gui:errUnexpected', ...
                    ['The input to the numParameters method must be a struct,' ...
                    ' param.Continuous object, or scalar SampleSet'] ));
            end
        end
        % Get list of parameter names
        function paramList = getParameterList(paramData)
            if isa(paramData, 'struct')
                paramList = {paramData.Name};
            elseif isa(paramData, 'param.Continuous')
                paramList = {paramData.Name};
            elseif isa(paramData, 'sldodialogs.data.SampleSet')
                paramList = getParameterNames(paramData);
            elseif isempty(paramData)
                paramList = {''};
            end
        end
        % Remove parameter(s) at indices specified
        function paramData = removeParameter(paramData, indices)
            if isa(paramData, 'param.Continuous')
                paramData(indices) = [];
            elseif isa(paramData, 'sldodialogs.data.SampleSet')
                removeParameter(paramData, indices);
            end
            % if paramData is empty, no change, nothing to remove
        end
        % Add parameter(s)
        function paramData = addParameter(paramData, paramsToAdd)
            if isa(paramData, 'param.Continuous')
                paramData = vertcat(paramData, paramsToAdd);
            elseif isa(paramData, 'sldodialogs.data.SampleSet')
                addParameter(paramData, paramsToAdd);
            elseif isempty(paramData)
                paramData = paramsToAdd;
            end
        end
        % Verify is value tunable
        function ok = isTunableValue(val)
            ok = isnumeric(val) && ismatrix(val) && isreal(val);
        end
    end
    
    %% Private methods
    methods (Access = private)
        % Update mode buttons
        function updateModeButtons(this,hData)
            if nargin <= 1 || strcmp(hData.Type,'PostModeChanged')
                btns = this.GenerateButton;
                for ct=1:numel(btns)
                    btns(ct).Selected = this.ModeManager.Modes(ct).Enabled;
                end
            end
        end
        
        % Callback for VariableSelector
        function cbParamAdded(this)
            %CBPARAMADDED  Manage added parameters
            %
            
            %Get parameters from selection
            sVars = this.VariableSelectorTC.CandidateVariables;
            
            %If a selected variable is not floating-point, it will be cast
            %to double, so warn for Sensitivity Analysis, error otherwise
            selNonFloating = false(size(sVars,1), 1);
            for ct = 1:size(sVars,1)
                %Check the data type if the variable is selected
                if sVars{ct,1}
                    value = sVars{ct,3};
                    selNonFloating(ct) = ~isfloat(value);
                end
            end
            if any(selNonFloating)
                %Collect names of variables that are selected, but not
                %floating-point
                namesNonFloat = {sVars{selNonFloating, 2}};
                %Convert cell array of names to text
                if numel(namesNonFloat) == 1
                    txt = namesNonFloat{1};
                else
                    %Handle more than one entry
                    frmt = repmat('%s, ', 1, numel(namesNonFloat)-1);
                    frmt = [frmt  '%s'];
                    txt = sprintf(frmt, namesNonFloat{:});
                end
                
                %Depending on the app, throw warning vs. error for
                %non-floating value
                dataType = getDataType(this.ParamTableTC);
                switch dataType
                    case 'SampleSet'
                        %For sensitivity analysis, throw a warning
                        uialert(getFigure(this), ...
                            getString(message('Controllib:gui:lblVariableSelector_CastingNonFloatingPoint', txt)), ...
                            getString(message('sldo:dialogs:lblSensitivityAnalysis')), ...
                            'Icon', 'warning');
                    otherwise
                        %For other tools, throw an error
                        Ex = MException('Controllib:gui:errVariableSelector_NotFloatingPoint', ...
                            getString(message('Controllib:gui:errVariableSelector_NotFloatingPoint', txt)) );
                        slcontrollib.internal.utils.nagctlr(this.Model,...
                            ctrlMsgUtils.message('Controllib:gui:ParamManageErrorProduct'),...
                            ctrlMsgUtils.message('Controllib:gui:ParamManageErrorOperation'),...
                            Ex);
                        return
                end
            end
            
            %Process selected variables
            idx   = [sVars{:,1}];
            sVars = sVars(idx,2);
            nA    = numel(sVars);
            if nA > 0
                pAdd = getParameterFromModel(this, sVars);
                idxAdd = true(nA,1);
                for ct=1:nA
                    idxAdd(ct) = ctrluis.paramtable.ParamTableTabBase.isTunableValue(pAdd(ct).Value);
                    msg = [];
                    if ~idxAdd(ct)
                        msg = getString(message('Controllib:gui:errDesignVariable_BadVarType_Estimation',pAdd(ct).Name,pAdd(ct).Name));
                    end
                    if ~isscalar(pAdd(ct).Value)
                        msg = getString(message('Controllib:gui:errDesignVariable_BadVarType_NonScalar',pAdd(ct).Name,pAdd(ct).Name));
                    end
                    if ~isempty(msg)
                        % Some error occurred
                        % First bring the dialog back up
                        show(this.VariableSelector,this.ManageButton,true)
                        openUIAlertErrorDialog(this,this.InsertButton,msg);
                        return;
                    end
                end
                if any(idxAdd)
                    pAdd = pAdd(idxAdd);
                    nA = numel(pAdd);
                else
                    idx = false; %Nothing to add
                    nA = 0;
                end
            end
            
            %Get parameters from existing selection
            wksp   = this.ParamWks;
            params = evalin(wksp,this.ParamVarName);
            
            nP = this.numParameters(params);
            
            %Update parameters without modifying parameters that were
            %already selected
            if any(idx)
                iR = true(nP,1);   %Parameters to remove
                iA = false(nA,1);  %Parameters to add
                for ct=1:nA
                    i = cellfun(@(x) isequal(x, pAdd(ct).Name), ...
                        this.getParameterList(params) );
                    if any(i)
                        iR(i) = false;
                    else
                        iA(ct) = true;
                    end
                end
                % Remove and add parameters
                if any(iR)
                    params = this.removeParameter(params, iR);
                end
                if any(iA)
                    params = this.addParameter(params, pAdd(iA));
                end
                
                assignin(wksp,this.ParamVarName,params);
                
                updateParamList(this);
            elseif nP > 0
                %All selected parameters have been de-selected
                if isa(params, 'sldodialogs.data.SampleSet')
                    this.removeParameter(params,true(numel(params.Parameters),1));
                    cmd = sprintf('%s = sldodialogs.data.SampleSet;', this.ParamVarName);
                else
                    cmd = sprintf('%s = [];',this.ParamVarName);
                end
                evalin(wksp, cmd);
                updateParamList(this);
            end

            %Update the view
            vUpdate(this.ParamTableGC);
        end
        
        % Callback for ParamTableTC
        function refreshTitle(this)
            if strcmp('SampleSet', getDataType(this.ParamTableTC))
                title = [getString(message('Controllib:gui:ParamTableTitle_Sensitivity'))   ':  '  this.ParamVarName];
            else
                % Use ClientTitle for non-SampleSet document title
                title = this.ClientTitle;
            end
            this.Document.Title = title;
        end
        % Callback for ParamtTableTC
        function notifyParamsChanged(this)
            ed = ctrluis.paramtable.GenericEventData(getParameterData(this));
            notify(this,'ParamsChanged',ed);
        end   
        % Called by cbParamAdded
        function updateParamList(this)
            curval = this.ParamList;
            if isequal(curval,{''}),curval = {}; end
            % Update the list
            params = evalin(this.ParamWks,this.ParamVarName);
            
            if this.numParameters(params) == 0
                sVars = {};
                this.ParamList = {''};
                this.GenerateButton.Enabled = false;
            else
                sVars = this.getParameterList(params);
                this.ParamList = sVars;
                this.GenerateButton.Enabled = true;
            end
            % Update the table
            if (isempty(curval) && isempty(sVars)) || ...
                    ((numel(curval) == numel(sVars)) && ...
                    all(strcmp(curval(:),sVars(:))))
                % No new parameter - nothing to do
            else
                param2remove = setdiff(curval,sVars);
                param2add = setdiff(sVars,curval);
                updateTableForNewParameters(this.ParamTableTC,param2remove,param2add,params);
            end
            notify(this, 'ParamListChanged');
        end
        
        % Get candidtate variables
        function data = getCandidateVariables(this,useExp)
            if nargin < 2
                useExp = '';
            end
            
            mdl = this.Model;
            dataType = getDataType(this.ParamTableTC);
            try
                switch dataType
                    case 'SampleSet'
                        %Sensitivity Analysis tool
                        vars = sldodialogs.getModelVariables(mdl);
                    otherwise
                        vars = ctrluis.paramtable.getModelVariables(mdl);
                end
            catch Ex
                slcontrollib.internal.utils.nagctlr(mdl,...
                    getString(message('Controllib:gui:ParamManageErrorProduct')),...
                    getString(message('Controllib:gui:ParamManageErrorOperation')),...
                    Ex);
                data = cell(0,4);
                return;
            end
            if isempty(useExp)
                params = evalin(this.ParamWks,this.ParamVarName);
            else
                %Find workspace where all experiments are defined and get
                %the used parameters
                params = evalin(this.TCPeer.ExpWksp,strcat(useExp,'.Parameters'));
            end
            if this.numParameters(params) == 0
                sVars   = {};
                hasSubs = false;
            else
                sVars    = this.getParameterList(params);
                [root,subs] = strtok(sVars,'{.(');
                hasSubs  = ~cellfun('isempty',subs);
            end
            nV   = numel(vars);
            data = cell(0,4);
            if nV > 0
                [~,mdlRef] = slcontrollib.internal.utils.getNormalModeBlocks(mdl);
                mdls = vertcat(mdl,mdlRef(:));
                dataCount = 1;
                for ct=1:nV
        
                    % g2134864: Preprocess variables to remove configset
                    % that is unable to resolve.  If variables were found
                    % using sldodialogs.getModelVariables, that filters out
                    % configuration sets but leaves model variables.
                    varUser = vars(ct).Users;
                    if isequal(varUser{1},mdl)  &&  ~strcmp('SampleSet', dataType)
                        % Ignore the variable if its user is the model itself
                        continue
                    else
                        vr = vars(ct);
                        switch dataType
                            case 'SampleSet'
                                %Get variables for Sensitivity Analysis tool.
                                %Determine full variable name.  If the variable
                                %is in a referenced model, include the source.
                                if strncmp(vr.SourceType, 'model', 5)  && ...
                                        ~strcmp(this.Model, vr.Source)
                                    pth = vr.Source;
                                else
                                    pth = [];
                                end
                                name = sdo.internal.buildParameterName(pth, vr.Name);
                                selected = any(strcmp(sVars,vr.Name));
                                value = sdo.getValueFromModel(mdl, name);
                                data(dataCount,:) = {selected, name, value, vr.UsedByBlocks};
                            otherwise
                                selected = any(strcmp(sVars,vr.Name));
                                value = slcontrollib.internal.utils.slResolve(vr.Name,mdls,'variable');
                                data(dataCount,:) = {selected, vr.Name, value, vr.UsedByBlocks};
                        end
                        dataCount = dataCount + 1;
                    end
                end
            end
            if any(hasSubs)
                %Handle parameters with sub-referencing
                addData = cell(sum(hasSubs),4);
                ctAdd=1;
                for ct=find(hasSubs)
                    value = sdo.getValueFromModel(mdl, sVars{ct});
                    parts = sdo.internal.splitParameterName(root{ct});
                    idx = strcmp({vars.Name}, parts.name);
                    addData(ctAdd,:) = {true, sVars{ct}, value, vars(idx).UsedByBlocks};
                    ctAdd = ctAdd+1;
                end
                data = vertcat(addData,data);
            end
        end
        
        % Open error dialog
        function openUIAlertErrorDialog(this,~,ErrorMessage)
            ErrorTitle = getString(message('Controllib:gui:AddParamTable_ErrorTitle'));
            % % Branch based on the anchor.  Remove branching when
            % % toolstrip is fully converted.
            uialert(this.Document.Figure,ErrorMessage,ErrorTitle);
        end
    end
end

% Helper function to return Icon file location
function loc = LocalGetIconPath()
loc = fullfile(LocalGetIconResourcePath, 'Table_60x40.png');
end

% Helper function to return icon resource path
function pth = LocalGetIconResourcePath()
pth = fullfile(matlabroot,'toolbox','shared','controllib','graphics','resources');
end
