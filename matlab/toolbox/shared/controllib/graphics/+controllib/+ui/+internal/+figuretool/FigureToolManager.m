classdef FigureToolManager < controllib.ui.internal.figuretool.AbstractManager
% FigureToolManager is the super-class that supports the "Tab Swapping"
% design pattern.  It should be used together with the "FigureTool"
% super-class.

% Author(s): Rong Chen
% Copyright 2019-2020 The MathWorks, Inc.

    properties (Access = private,Transient)
        DocDestroyedListener
        DGListener
        TGListener
    end
   
    methods(Access = public)
        
        function delete(this)
            delete(this.DGListener);
            delete(this.TGListener);
        end
        
        function addFigureTool(this, ft)
            % Method "addFigureTool": 
            %
            %   addFigureTool(this, FT) adds "FT.Document" to
            %   "this.DocumentGroup" and refresh "this.TabGroup" with
            %   "FT.Tabs", where FT is a FigureTool.  It also automatically
            %   select the first contextual tab if it exists.
            %
            %   Afterwards, you can access FT by its Tag via methods like
            %   "hasFigureTool" and "getFigureTool".
            this.ToolMap(ft.Tag) = ft;
            % add document to document group
            this.addDocument(ft.Document);
            % add tab to contextual tab group and remove old ones
            this.replaceTabs_Creation(ft);
            % listen to document destroyed event
            weakThis = matlab.lang.WeakReference(this);
            this.DocDestroyedListener = addlistener(ft.Document,'ObjectBeingDestroyed',@(src,data) cbDocumentDeleted(weakThis.Handle, ft.Tag));
        end
        
        function deleteFigureTool(this, tagorft)
            % Method "deleteFigureTool": 
            %
            %   deleteFigureTool(this, FT) deletes "FT.Document" from
            %   "this.DocumentGroup" and deletes tabs from "this.TabGroup",
            %   where FT is a FigureTool.  It also removes FT from the
            %   hashmap and delete it.
            %
            %   deleteFigureTool(this, tag) deletes a document from
            %   "this.DocumentGroup" and deletes its contextual tabs from
            %   "this.TabGroup", where "tag" is the tag of a FigureTool. It
            %   also removes FT from the hashmap, delete all the tabs and
            %   delete FT itself.
            if ischar(tagorft) || isstring(tagorft)
                tag = tagorft;
            else
                tag = tagorft.Tag;
            end
            if this.hasFigureTool(tag)
                % this following line triggers "ObjectBeingDestroyed" event
                % from the FigureDocument and in "cbDocumentDeleted"
                % callback we remove hashmap entry, delete all the tabs and
                % delete FigureTool.
                this.removeDocument(tag); 
            end
        end
        
        function val = hasFigureTool(this, tagorft)
            % Method "hasFigureTool": 
            %
            %   true/false = hasFigureTool(this, FT) checks whether a
            %   FigureTool is part of FigureToolManager, where FT is the
            %   handle of the FigureTool.
            %
            %   true/false = hasFigureTool(this, tag) checks whether a
            %   FigureTool is part of FigureToolManager, where "tag" is the
            %   tag of the FigureTool.
            if isvalid(this.ToolMap)
                if ischar(tagorft) || isstring(tagorft)
                    val = this.ToolMap.isKey(tagorft);
                else
                    val = this.ToolMap.isKey(tagorft.Tag);
                end
            else
                val = false;
            end
        end
        
        function val = getFigureTool(this, tagorft)
            % Method "getFigureTool": 
            %
            %   FT = getFigureTool(this, tag) returns a FigureTool
            %   belonging to the FigureToolManager based on the given
            %   "tag".  It returns the handle of FigureTool or [] if not
            %   found.
            if isvalid(this.ToolMap)
                if ischar(tagorft) || isstring(tagorft)
                    if this.ToolMap.isKey(tagorft)
                        val = this.ToolMap(tagorft);
                    else
                        val = [];
                    end
                else
                    val = tagorft;
                end
            else
                val = [];
            end
        end
        
        function setFigureToolTitle(this, tagorft, title)
            % Method "setFigureToolTitle": 
            %
            %   setFigureToolTitle(this, FT, title) sets the displayed
            %   title of the document, where FT is the FigureTool handle.
            %
            %   setFigureToolTitle(this, tag, title) sets the displayed
            %   title of the document, where tag is the FigureTool tag.
            if ischar(tagorft) || isstring(tagorft)
                if this.ToolMap.isKey(tagorft)
                    ft = this.getFigureTool(tagorft);
                    ft.Document.Title = title; 
                end
            else
                if this.ToolMap.isKey(tagorft.Tag)
                    tagorft.Document.Title = title; 
                end
            end            
        end
        
        function val = isFigureToolSelected(this, tagorft)
            % Method "isFigureToolSelected": 
            %
            %   isFigureToolSelected(this, FT) checks whether the
            %   document is currently selected in the FigureToolManager,
            %   based on the handle of the FigureTool.
            %
            %   isFigureToolSelected(this, tag) checks whether the
            %   document is currently selected in the FigureToolManager,
            %   based on the tag of the FigureTool.
            if ischar(tagorft) || isstring(tagorft)
                if this.ToolMap.isKey(tagorft)
                    ft = this.getFigureTool(tagorft);
                    if isempty(this.DocumentGroup.LastSelected)
                        val = false;
                    else
                        val = strcmp(this.DocumentGroup.LastSelected.tag, ft.Tag);
                    end
                end
            else
                if isempty(this.DocumentGroup.LastSelected)
                    val = false;
                else
                    val = strcmp(this.DocumentGroup.LastSelected.tag, tagorft.Tag);
                end
            end
        end
        
        function selectFigureTool(this, tagorft)
            % Method "selectFigureTool": 
            %
            %   selectFigureTool(this, FT) programmatically selects a
            %   document in the FigureToolManager, based on the handle of
            %   the FigureTool.
            %
            %   selectFigureTool(this, tag) programmatically selects a
            %   document in the FigureToolManager, based on the tag of the
            %   FigureTool.
            if ischar(tagorft) || isstring(tagorft)
                if this.ToolMap.isKey(tagorft)
                    ft = this.getFigureTool(tagorft);
                    if isvalid(ft.Document)
                        ft.Document.Selected = true;
                    end
                end
            else
                if this.hasDocument(tagorft.Tag)
                    if isvalid(tagorft.Document)
                        tagorft.Document.Selected = true;
                    end
                end
            end
        end
        
    end
    
    methods(Access = protected)
        
        function this = FigureToolManager(tag, appcontainer)
            % Constructor "FigureToolManager": 
            %
            %   FigureToolManager(tag, appcontainer) creates DocumentGroup
            %   and contextual TabGroup.  It must be called in the subclass
            %   constructor.
            %
            %   A sub-class of FigureToolManager can be created after
            %   AppContainer is rendered but it cannot be deleted until
            %   AppContainer is deleted.
            %% super
            this = this@controllib.ui.internal.figuretool.AbstractManager(tag, appcontainer);
            %% Add listener
            weakThis = matlab.lang.WeakReference(this);
            this.DGListener = addlistener(this.DocumentGroup, 'PropertyChanged', @(es, ed) cbDocumentSwitched(weakThis.Handle, es, ed));
            this.TGListener = addlistener(this.TabGroup, 'SelectedTabChanged', @(es,ed) cbSaveLastSelectedTab(weakThis.Handle, es, ed));
        end
        
    end
    
    methods(Access = private)
        
        function cbDocumentSwitched(this, src, data)
            % handle tab selection based on memory after document switches.
            switch data.PropertyName
                case 'LastSelected'
                    % automatic tab swapping
                    tag = src.LastSelected.tag;
                    if this.hasFigureTool(tag)
                        % switch tab
                        ft = this.getFigureTool(tag);
                        this.replaceTabs_Switching(ft);
                        % update panel
                        this.refreshPanel(ft);
                    end
            end
        end
        
        function cbSaveLastSelectedTab(this, src, data)
            % Save selected tab in FigureTool.LastSelectedTab.
            if isvalid(this.AppContainer)
                % workaround a bug in AppContainer
                try
                    documents = this.AppContainer.getDocuments;
                catch ME
                    return
                end
                for ct=1:length(documents)
                    if this.isDocumentSelected(documents{ct}.Tag)
                        ft = this.getFigureTool(documents{ct}.Tag);
                        if ~isempty(ft)
                            if isempty(data.EventData.NewValue)
                                % a global tab
                                ft.LastSelectedTab = this.AppContainer.SelectedToolstripTab;
                            else
                                % a contextual tab
                                ft.LastSelectedTab = data.EventData.NewValue;
                            end
                        end
                        break
                    end
                end
            end
        end
        
        function cbDocumentDeleted(this, tag)
            % when a FigureDocument is deleted by user, remove its
            % FigureTool from the hashmap, delete all the contextual tabs
            % and delete FigureTool itself as well.
            if isvalid(this)
                if hasFigureTool(this, tag)
                    ft = this.getFigureTool(tag);
                    this.ToolMap.remove(tag);
                    if ~isempty(ft.Tabs)
                        delete(ft.Tabs);
                    end
                    delete(ft);
                end
            end
        end
        
        function replaceTabs_Creation(this, ft)
            % add new tabs
            for ct=1:length(ft.Tabs)
                this.addTab(ft.Tabs(ct));
            end
            % select the first new tab
            if ~isempty(ft.Tabs)
                this.TabGroup.SelectedTab = ft.Tabs(1);
                ft.LastSelectedTab = ft.Tabs(1);
            end
            % remove old tabs
            for ct=(length(this.TabGroup.Children)-length(ft.Tabs)):-1:1
                this.TabGroup.remove(this.TabGroup.Children(ct));
            end
        end
    
        function replaceTabs_Switching(this, ft)
            % add new tabs
            for ct=1:length(ft.Tabs)
                this.addTab(ft.Tabs(ct));
            end
            % select the tab in memory
            if ~isempty(ft.Tabs)
                if isstruct(ft.LastSelectedTab)
                    this.AppContainer.SelectedToolstripTab = ft.LastSelectedTab;
                else
                    this.TabGroup.SelectedTab = ft.LastSelectedTab;
                end
            end
            % remove old tabs
            for ct=(length(this.TabGroup.Children)-length(ft.Tabs)):-1:1
                this.TabGroup.remove(this.TabGroup.Children(ct));
            end
        end
        
    end
    
end