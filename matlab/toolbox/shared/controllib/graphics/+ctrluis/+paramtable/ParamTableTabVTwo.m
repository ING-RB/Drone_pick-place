classdef ParamTableTabVTwo < ctrluis.paramtable.ParamTableTabBase
    % PARAMTABLETAB supports TOOLSTRIP
    
    % Copyright 2016-2023 The MathWorks, Inc.
    
    %% Constant properties for SDO plot infrastructure
    properties(GetAccess = public, Constant = true)
        SUPPORTED_SOURCE_TYPES = {'table'};
    end
    
    %% Public methods
    methods
        % Constructor:
        function this = ParamTableTabVTwo(group,clienttitle,tabtitle,model,paramdata,varargin)
            version = 2; % TOOLSTRIP VERSION
            extra = varargin; % Extra input arguments
            this = this@ctrluis.paramtable.ParamTableTabBase(version,group,clienttitle,tabtitle,model,paramdata,extra);
        end
    end
    
    %% Implementation of abstract methods from superclass ParamTabBase
    methods (Access = protected)
        % Create Tab
        % %         function tab = createTab(this,tabtitle)
        % %             tab = matlab.ui.internal.toolstrip.Tab(tabtitle);
        % %             tab.Tag = 'paramtab';
        % %         end
        %Create toolstrip for tab
        function createTab(this, generate_buttontype)
            sections = createWidgets(this, generate_buttontype);
            if ~isa(sections,'matlab.ui.internal.toolstrip.Section')
                error(message('Controllib:gui:errUnexpected','Unrecognized class for toolstrip section'));
            end
            
            for ct = 1:numel(sections)
                sec = sections(ct);
                add(this.Tabs, sec);
            end

            %Push data to view, e.g. whether widgets are enabled
            update(this);
        end

        % Create Icon
        function icon = createIcon(this,path)
            if strcmp(path,'import')
                icon = matlab.ui.internal.toolstrip.Icon.IMPORT_24;
            else
                icon = matlab.ui.internal.toolstrip.Icon(path);
            end
        end
        % Create Button
        function btn = createButton(this,text,icon,name)
            btn = matlab.ui.internal.toolstrip.Button(text,icon);
            if ~isempty(name)
                btn.Tag = name;
            end
        end
        % Create Dropdown Button
        function ddbtn = createDropDownButton(this,text,icon,name)
            ddbtn =  matlab.ui.internal.toolstrip.DropDownButton(text,icon);
            if ~isempty(name)
                ddbtn.Tag = name;
            end
        end
        % Create Section
        function sec = createSection(this,title,name)
            sec =   matlab.ui.internal.toolstrip.Section(title);
            sec.Tag = name;
        end
        % Create Param panel
        function addParamPanel(this,sec)
            import matlab.ui.internal.toolstrip.*
            column1 = Column();
            add(sec,column1);
            add(column1,this.ManageButton);
            column2 = Column();
            add(sec,column2);
            add(column2,this.GenerateButton);
        end
        % Create Edit Panel
        function addEditPanel(this,sec)
            import matlab.ui.internal.toolstrip.*
            column1 = Column();
            add(sec,column1);
            add(column1,this.InsertButton);
            column2 = Column();
            add(sec,column2);
            add(column2,this.DeleteButton);
        end
        % Show Dialogs
        function showParamDialog(this,Dlg,anchor,varargin)
            Dlg.show()
        end
        % Get anchor for opening error dialog
        function  anchor = getAnchor(this,~)
            anchor = getFrame(getTool(this));
        end
        % Add listener for Manage Button
        function addManageButtonListener(this)
            addlistener(this.ManageButton,'ButtonPushed',@(es,ed) addParam(this));
        end
        % Add listener for Insert Button
        function addInsertButtonListener(this)
            this.InsertButton.DynamicPopupFcn = @(es,ed)populateInsertPopup(this);
        end
        % Add listener for Delete Button
        function addDeleteButtonListener(this)
            addlistener(this.DeleteButton,'ButtonPushed',@(es,ed) deleteRow(this));
        end
        % Add listener for Generate Button
        function addGenerateButtonListener(this)
            addlistener(this.GenerateButton,'ButtonPushed',@(es,ed)generateValues(this));
        end
        % Add listener for Dropdown Button
        function addGenerateDropDownListener(this)
            this.GenerateButton.DynamicPopupFcn = @(es,ed)populateGenerateValuesPopup(this);
        end
    end
    
    %% Private methods
    methods (Access = private)
        % Callback for Insert dropdown button
        function Popup = populateInsertPopup(this)
            import matlab.ui.internal.toolstrip.*
            % Create the popup list
            Popup = PopupList();
            Popup.Tag = 'mnuParamInsert';
            % Get dropdown data for Insert Button
            data = getDropDownInsertValues(this);
            % Create the popup
            iconFile = fullfile(matlabroot,'toolbox','shared','controllib','graphics','resources', ...
                'Insert_Row_24.png');
            for ct = 1:numel(data)
                item = ListItem(data(ct).Title);
                item.ShowDescription = false;
                item.Icon = Icon(iconFile);
                addlistener(item, 'ItemPushed', @(es,ed)selectInsertItem(this,ct));
                Popup.add(item);
            end
        end
        % Callback for Generate dropdown button
        function Popup = populateGenerateValuesPopup(this)
            import matlab.ui.internal.toolstrip.*
            % Create the popup list
            Popup = PopupList();
            Popup.Tag = 'mnuGenerateValues';
            % Get dropdown data for generate button
            data = getDropDownGenerateValues(this);
            % Create the popup
            for ct = 1:numel(data)
                item = ListItem(data(ct).Title,data(ct).Icon);
                item.ShowDescription = false;
                addlistener(item, 'ItemPushed', @(es,ed)selectGenerateValues(this,ct));
                Popup.add(item);
            end
        end
    end
    
end