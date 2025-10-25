classdef GenerationMessageList < rptgen.internal.gui.GenerationMessageClient
    %GENERATIONMESSAGELIST Generation message list
    %   Defines a list of messages displayed during report generation.
    
    % Copyright 2020-2021 The MathWorks, Inc.
    
    properties (SetObservable)
        % List of filtered messages that are displayed in the dialog. These
        % messages are filtered based on the selected filter level in the
        % dialog.
        MessageList
    end
    
    properties (SetAccess = private)
        % List of all the messages
        MessageHistory
        
        % Priority filter level to filter the messages to be displayed in
        % the dialog
        FilterLevel
    end

    properties (Access = private)
        % Flag to preserve the status of the message filter list (g2525357)
        isFilterListEnabled = true;
    end
    
    properties (Constant, Access = private)
        % Path of the image file to be used as dialog icon
        DialogIcon = fullfile(matlabroot, "toolbox", "shared", "rptgen", ...
            "resources", "icons", "ReportGenerator.gif");
    end
    
    methods
        function this = GenerationMessageList()
            import rptgen.internal.gui.GenerationMessageList
            
            % Initialize the filter level from the MATLAB settings
            this.FilterLevel = ...
                GenerationMessageList.getFilterLevelSetting();
            
            % Initialize the message lists to be empty
            clearMessages(this);
        end
        
        function doSelectAll(this) %#ok<MANU>
            % TODO function can be removed once Java option is removed
        end
        
        function doCopy(this) %#ok<MANU>
            % Perform copy action based upon the current selection
            % TODO function can be removed once Java option is removed
        end
        
        function wrapperPara = toDocBook(this,d)
            % Returns a <programlisting> element containing a dump of all
            % messages. In the future, may return a table or a list, but is
            % always guaranteed to be legal paragraph/section content.
            
            allMsg = "";
            nMsgs = numel(this.MessageHistory);
            for i = 1:nMsgs
                allMsg = allMsg + this.MessageHistory{i}.Message + newline;
            end
            allMsg = deblank(allMsg);
            
            asText = d.createTextNode(d, allMsg);
            wrapperPara = d.createElement(d,"programlisting");
            setAttribute(wrapperPara,"xml:space","preserve");
            appendChild( wrapperPara,asText);
        end
        
        function frameify(this)
            % Launch the DDG dialog
            DAStudio.Dialog(this);
        end
        
        function setFrameVisible(this,framVis)
            % Sets the owning window to visible (or not). If visible, also
            % brings it to the front of other windows.
            dlg = DAStudio.ToolRoot.getOpenDialogs(this);
            if ~isempty(dlg)
                if framVis
                    % Show the dialog
                    dlg.show();
                else
                    % Hide the dialog
                    dlg.hide();
                end
            end
        end
        
        function clearMessages(this)
            % Clear all the message lists
            this.MessageHistory = {};
            this.MessageList = {};
        end
        
        function addMessage(this,message,priority)
            % Adds the specified message to the message lists
            import rptgen.internal.gui.GenerationDisplayClient
            
            % Create the message object
            message = GenerationDisplayClient.indentString(message,priority);
            msg.Message = message;
            msg.Priority = priority;
            
            % Add the message to MessageHistory property which stores all
            % the messages
            this.MessageHistory{end+1} = msg;
            
            % If the message priority is less than or equal to the current
            % filter level, also add the message to the MessageList so that
            % it can be displayed in the dialog
            if priority <= this.FilterLevel
                this.MessageList{end+1} = msg;
            end
        end
        
        function setPriorityFilter(this,priority)
            % Sets the priority filter level.
            % This callback method is called when user selects the
            % filter level from the drop down list in the dialog
            import rptgen.internal.gui.GenerationMessageList
            
            % Update the FilterLevel property
            this.FilterLevel = priority;
            
            % Update the filter level in MATLAB settings
            GenerationMessageList.setFilterLevelSetting(priority);
            
            % Update the message list to be displayed based on the selected
            % priority filter level
            updatePriorityFilter(this, priority);
        end
        
        function priority = getPriorityFilter(this)
            % Returns the current priority filter level
            priority = this.FilterLevel;
        end
        
        function msg = showMessageAsString(this)
            % Returns all the messages as a string
            msg = showMessagesAsString(this,this.FilterLevel);
        end
        
        function msgs = showMessagesAsString(this,filterLevel)
            % Returns all the messages for the specified filter level as a
            % string
            msgs = "";
            nMsgs = numel(this.MessageHistory);
            for i = 1:nMsgs
                m = this.MessageHistory{i};
                if m.Priority <= filterLevel
                    nLines = numel(m.Message);
                    for l = 1:nLines
                        msgs = msgs + m.Message(l) + newline;
                    end
                end
            end
            msgs = deblank(msgs);
        end
        
        function msgPanel = createMessageListPanel(this)
            % Creates the DDG Panel for the message list
            tag_prefix = "message_list_";
            
            % Create drop down for message list options
            filterMsgDropDown.Type = "combobox";
            filterMsgDropDown.Tag = strcat(tag_prefix, "filter");
            filterMsgDropDown.Editable = false;
            filterMsgDropDown.Entries = { ...
                strcat("0) ", getString(message("rptgen:MessageList:msgListFilter0"))), ...
                strcat("1) ", getString(message("rptgen:MessageList:msgListFilter1"))), ...
                strcat("2) ", getString(message("rptgen:MessageList:msgListFilter2"))), ...
                strcat("3) ", getString(message("rptgen:MessageList:msgListFilter3"))), ...
                strcat("4) ", getString(message("rptgen:MessageList:msgListFilter4"))), ...
                strcat("5) ", getString(message("rptgen:MessageList:msgListFilter5"))), ...
                strcat("6) ", getString(message("rptgen:MessageList:msgListFilter6"))), ...
                };
            filterMsgDropDown.Values = 0:6;
            filterMsgDropDown.Value = this.FilterLevel;
            filterMsgDropDown.ColSpan = [1 1];
            filterMsgDropDown.RowSpan = [1 1];
            filterMsgDropDown.ObjectMethod = "setPriorityFilter"; % callback method
            filterMsgDropDown.MethodArgs = {'%value'}; % callback method arguments
            filterMsgDropDown.ArgDataTypes = {'mxArray'}; % callback method argument's data type

            % getDialogSchema is called every time a new message is added.
            % Thus recover the status of filter list from
            % isFilterListEnabled flag (g2525357)
            filterMsgDropDown.Enabled = this.isFilterListEnabled;
            
            % Create message list
            msgList.Type = "listbox";
            msgList.Tag = strcat(tag_prefix, "entries");
            msgs = showMessageAsString(this);
            if ~isempty(msgs) && msgs~= ""
                msgList.Entries = cellstr(splitlines(showMessageAsString(this)));
            end
            msgList.MultiSelect = true;
            msgList.ColSpan = [1 1];
            msgList.RowSpan = [2 2];
            msgList.ListenToProperties = {'MessageList'}; % listen to changes in MessageList property
            msgList.Graphical = true; % widget should not become dirty (shaded) if an entry is selected
            
            % Create message panel
            msgPanel.Type = "panel";
            msgPanel.LayoutGrid = [2 1];
            msgPanel.Spacing = 0;
            msgPanel.ContentsMargins = 0;
            msgPanel.Items = {filterMsgDropDown, msgList};
        end
        
        function schema = getDialogSchema(this)
            % Returns the message list's DDG dialog schema

            % Create the DDG message list panel
            msgPanel = createMessageListPanel(this);
            
            % Set up the schema for the dialog and add panel to it
            schema.DialogTitle = getString(message("rptgen:MessageList:msgListTitle"));
            schema.DisplayIcon = this.DialogIcon;
            schema.DialogTag = "message_list_dialog";
            schema.Items = {msgPanel};
            schema.IsScrollable = false;
            schema.StandaloneButtonSet = {''}; % suppress the standalone button bar
            schema.MinMaxButtons = true; % add min/max buttons
            schema.Geometry = [0 5 327 185]; % set dialog position (TODO verify the preferred way)
            schema.HideOnClose = true; % hide the dialog on close
            
        end

        function enableFilterList(this)
            % Enable filter list
            this.isFilterListEnabled = true;
            dlg = DAStudio.ToolRoot.getOpenDialogs(this);
            if ~isempty(dlg)
                dlg.setEnabled('message_list_filter', true);
            end
        end

        function disableFilterList(this)
            % Disable filter list
            this.isFilterListEnabled = false;
            dlg = DAStudio.ToolRoot.getOpenDialogs(this);
            if ~isempty(dlg)
                dlg.setEnabled('message_list_filter', false);
            end
        end

    end
    
    methods (Access = private)
        
        function updatePriorityFilter(this, filterLevel)
            % Update the message list to be displayed based on the
            % specified filter level
            nMsgs = numel(this.MessageHistory);
            nFilteredMsgs = 0;
            this.MessageList = cell(1,nMsgs);
            for i = 1:nMsgs
                m = this.MessageHistory{i};
                if m.Priority <= filterLevel
                    nFilteredMsgs = nFilteredMsgs + 1;
                    this.MessageList{nFilteredMsgs} = m;
                end
            end
            this.MessageList(nFilteredMsgs+1:end) = [];
        end
        
    end
    
    methods (Static, Access = private)
        
        function srptgen = getRptgenSettings()
            % Returns the rptgen settings
            
            % Get the MATLAB settings root object
            s = settings;
            
            % Check for rptgen settings
            if ~s.hasGroup("rptgen")
                s.addGroup("rptgen");
            end
            
            % Get the rptgen settings
            srptgen = s.rptgen;
            
            % Check for the message list settings
            if ~srptgen.hasGroup("messagelist")
                sMsgList = srptgen.addGroup("messagelist");
                filterSetting = sMsgList.addSetting("filter");
                filterSetting.PersonalValue = 3;
            end
        end
        
        function level = getFilterLevelSetting()
            % Get the message filter level preferences from the MATLAB
            % settings
            import rptgen.internal.gui.GenerationMessageList
            
            srptgen = GenerationMessageList.getRptgenSettings();
            level = srptgen.messagelist.filter.ActiveValue;
        end
        
        function setFilterLevelSetting(newLevel)
            % Set the message filter level preferences to the MATLAB
            % settings
            import rptgen.internal.gui.GenerationMessageList
            
            srptgen = GenerationMessageList.getRptgenSettings();
            srptgen.messagelist.filter.PersonalValue = newLevel;
        end
        
    end
end
