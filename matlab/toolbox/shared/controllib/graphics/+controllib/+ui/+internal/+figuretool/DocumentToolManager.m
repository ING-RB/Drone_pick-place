classdef DocumentToolManager < controllib.ui.internal.figuretool.AbstractManager
% DocumentToolManager is the super-class that supports the "Tab Sharing"
% design pattern.  It should be used together with the "DocumentTool"
% super-class.
%
% Developer needs to overload the "customUpdateTabState" method in the
% sub-class to refresh tab states after document is switched.

% Author(s): Rong Chen
% Copyright 2019-2020 The MathWorks, Inc.

    properties (Access = private,Transient)
        DocDestroyedListener
        DGListener
        TGListener
    end
   
    methods(Access = public)
        
        function delete(this)
            delete(this.DocDestroyedListener);
            delete(this.DGListener);
            delete(this.TGListener);
        end
        
        function addDocumentTool(this, dt)
            % Method "addDocumentTool": 
            %
            %   addDocumentTool(this, DT) adds "DT.Document" to
            %   "this.DocumentGroup", where DT is a DocumentTool.  It also
            %   automatically select the first shared contextual tab.
            %
            %   Afterwards, you can access DT by its Tag via methods like
            %   "hasDocumentTool" and "getDocumentTool".
            this.ToolMap(dt.Tag) = dt;
            % add document to document group
            this.addDocument(dt.Document);
            % select first shared contextual tab and update LastSelectedTab
            if ~isempty(this.TabGroup.Children)
                this.TabGroup.SelectedTab = this.TabGroup.Children(1);
                dt.LastSelectedTab = this.TabGroup.SelectedTab;
            end
            % listen to document destroyed event
            weakThis = matlab.lang.WeakReference(this);
            this.DocDestroyedListener = addlistener(dt.Document,'ObjectBeingDestroyed',@(es,ed) cbDocumentDeleted(weakThis.Handle, dt.Tag));
        end
        
        function deleteDocumentTool(this, tagordt)
            % Method "deleteDocumentTool": 
            %
            %   deleteDocumentTool(this, DT) deletes "DT.Document" from
            %   "this.DocumentGroup", where DT is a DocumentTool.  It also
            %   removes DT from the hashmap and delete it.
            %
            %   deleteDocumentTool(this, tag) deletes a document from
            %   "this.DocumentGroup", where "tag" is document's tag.  It
            %   also removes corresponding DT from the hashmap and delete
            %   it.
            if ischar(tagordt) || isstring(tagordt)
                tag = tagordt;
            else
                tag = tagordt.Tag;
            end
            if this.hasDocumentTool(tag)
                % this following line triggers "ObjectBeingDestroyed" event
                % from the FigureDocument and in "cbDocumentDeleted"
                % callback we remove hashmap entry and delete DocumentTool.
                this.removeDocument(tag);
            end
        end
        
        function val = hasDocumentTool(this, tagordt)
            % Method "hasDocumentTool": 
            %
            %   true/false = hasDocumentTool(this, DT) checks whether a
            %   DocumentTool is part of DocumentToolManager, where DT is the
            %   handle of the DocumentTool.
            %
            %   true/false = hasDocumentTool(this, tag) checks whether a
            %   DocumentTool is part of DocumentToolManager, where "tag" is
            %   the tag of the DocumentTool.
            if isvalid(this.ToolMap)
                if ischar(tagordt) || isstring(tagordt)
                    val = this.ToolMap.isKey(tagordt);
                else
                    val = this.ToolMap.isKey(tagordt.Tag);
                end
            else
                val = false;
            end
        end
        
        function val = getDocumentTool(this, tagordt)
            % Method "getDocumentTool": 
            %
            %   DT = getDocumentTool(this, tag) returns a DocumentTool
            %   belonging to this DocumentToolManager based on the given
            %   "tag".  It returns the handle of DocumentTool or [] if not
            %   found.
            if isvalid(this.ToolMap)
                if ischar(tagordt) || isstring(tagordt)
                    if this.ToolMap.isKey(tagordt)
                        val = this.ToolMap(tagordt);
                    else
                        val = [];
                    end
                else
                    val = tagordt;
                end
            else
                val = [];
            end
        end
        
        function setDocumentToolTitle(this, tagordt, title)
            % Method "setDocumentToolTitle": 
            %
            %   setDocumentToolTitle(this, DT, title) sets the displayed
            %   title of the document, where DT is the DocumentTool handle.
            %
            %   setDocumentToolTitle(this, tag, title) sets the displayed
            %   title of the document, where tag is the DocumentTool tag.
            if ischar(tagordt) || isstring(tagordt)
                if this.ToolMap.isKey(tagordt)
                    dt = this.getDocumentTool(tagordt);
                    dt.Document.Title = title; 
                end
            else
                if this.ToolMap.isKey(tagordt.Tag)
                    tagordt.Document.Title = title; 
                end
            end            
        end
        
        function val = isDocumentToolSelected(this, tagordt)
            % Method "isDocumentToolSelected": 
            %
            %   isDocumentToolSelected(this, DT) checks whether the
            %   document is currently selected in the DocumentToolManager,
            %   based on the handle of the DocumentTool.
            %
            %   isDocumentToolSelected(this, tag) checks whether the
            %   document is currently selected in the DocumentToolManager,
            %   based on the tag of the DocumentTool.
            if ischar(tagordt) || isstring(tagordt)
                if this.ToolMap.isKey(tagordt)
                    dt = this.getDocumentTool(tagordt);
                    if isempty(this.DocumentGroup.LastSelected)
                        val = false;
                    else
                        val = strcmp(this.DocumentGroup.LastSelected.tag, dt.Tag);
                    end
                end
            else
                if isempty(this.DocumentGroup.LastSelected)
                    val = false;
                else
                    val = strcmp(this.DocumentGroup.LastSelected.tag, tagordt.Tag);
                end
            end
        end
        
        function selectDocumentTool(this, tagordt)
            % Method "selectDocumentTool": 
            %
            %   selectDocumentTool(this, DT) programmatically selects a
            %   document in the DocumentToolManager, based on the handle of
            %   the DocumentTool.
            %
            %   selectDocumentTool(this, tag) programmatically selects a
            %   document in the DocumentToolManager, based on the tag of the
            %   DocumentTool.
            if ischar(tagordt) || isstring(tagordt)
                if this.ToolMap.isKey(tagordt)
                    dt = this.getDocumentTool(tagordt);
                    if isvalid(dt.Document)
                        dt.Document.Selected = true;
                    end
                end
            else
                if this.ToolMap.isKey(tagordt.Tag)
                    if isvalid(tagordt.Document)
                        tagordt.Document.Selected = true;
                    end
                end
            end
        end
        
    end
    
    methods(Access = protected)
        
        function this = DocumentToolManager(tag, appcontainer)
            % Constructor "DocumentToolManager": 
            %
            %   DocumentToolManager(tag, appcontainer) creates DocumentGroup
            %   and contextual TabGroup.  It must be called in the subclass
            %   constructor.
            %
            %   A sub-class of DocumentToolManager can be created after
            %   AppContainer is rendered but it cannot be deleted until
            %   AppContainer is deleted.
            %% super
            this = this@controllib.ui.internal.figuretool.AbstractManager(tag, appcontainer);
            %% Add listener
            weakThis = matlab.lang.WeakReference(this);
            this.DGListener = addlistener(this.DocumentGroup, 'PropertyChanged', @(es, ed) cbDocumentSwitched(weakThis.Handle, es, ed));
            this.TGListener = addlistener(this.TabGroup, 'SelectedTabChanged', @(es,ed) cbSaveLastSelectedTab(weakThis.Handle, es, ed));
        end
        
        function customUpdateTabState(this, tag) %#ok<INUSD>
            % Method "customUpdateTabState": 
            %
            %   customUpdateTabState(this, tag)
            %
            %   Overload this method to refresh tab states based on the
            %   newly selected document.  "tag" is the document tag. 
        end
        
    end
    
    methods(Access = private)
        
        function cbDocumentSwitched(this, src, data)
            % handle tab selection based on memory and call custom tab
            % state update after document switches.
            switch data.PropertyName
                case 'LastSelected'
                    tag = src.LastSelected.tag;
                    % select the last selected tab based on dt.LastSelectedTab
                    if this.hasDocumentTool(tag)
                        dt = this.getDocumentTool(tag);
                        % select the tab in memory
                        if isstruct(dt.LastSelectedTab)
                            this.AppContainer.SelectedToolstripTab = dt.LastSelectedTab;
                        else
                            this.TabGroup.SelectedTab = dt.LastSelectedTab;
                        end
                        % update panel
                        this.refreshPanel(dt);
                    end
                    % call custom function for tab state update
                    customUpdateTabState(this, tag);
            end
        end

        function cbSaveLastSelectedTab(this, src, data)
            % Save selected tab in DocumentTool.LastSelectedTab.
            if isvalid(this.AppContainer)
                % workaround a bug in AppContainer
                try
                    documents = this.AppContainer.getDocuments;
                catch ME
                    return
                end
                for ct=1:length(documents)
                    if this.isDocumentSelected(documents{ct}.Tag)
                        dt = this.getDocumentTool(documents{ct}.Tag);
                        if ~isempty(dt)
                            if isempty(data.EventData.NewValue)
                                % a global tab
                                dt.LastSelectedTab = this.AppContainer.SelectedToolstripTab;
                            else
                                % a contextual tab
                                dt.LastSelectedTab = data.EventData.NewValue;
                            end
                        end
                        break
                    end
                end
            end            
        end
        
        function cbDocumentDeleted(this, tag)
            % when a FigureDocument is deleted by user, remove its
            % DocumentTool from the hashmap and delete it as well.
            if isvalid(this)
                if hasDocumentTool(this, tag)
                    dt = this.getDocumentTool(tag);
                    this.ToolMap.remove(tag);
                    delete(dt);
                end
            end
        end
        
    end
    
end