classdef AbstractManager < handle
% AbstractManager is the super-class of "FigureToolManager" and "DocumentToolManager"    

% Author(s): Rong Chen
% Copyright 2019-2020 The MathWorks, Inc.

    properties (GetAccess = protected, SetAccess = private)
        % Property "Tag"
        %   Assigned to DocumentGroup.Tag and TabGroup.Tag
        %   It must be unique during the life cycle of the AppContainer
        %   It must be provided to the constructor.
        Tag                         
        % Property "DocumentGroup"
        %   Store the handle of "matlab.ui.internal.FigureDocumentGroup"
        %   It has a contextual TabGroup
        %   It is created by the constructor
        DocumentGroup
        % Property "TabGroup"
        %   Store the handle of "matlab.ui.internal.toolstrip.Tabgroup"
        %   It is the contextual TabGroup associated with DocumentGroup
        %   It is created by the constructor
        TabGroup     
        % Property "Panel" 
        %   Store the handle of " matlab.ui.internal.FigurePanel"
        %   It is the contextual panel associated with DocumentGroup
        %   It is optional and must be added using "addPanel" before
        %   AppContainer is rendered
        Panel
        % Property "ToolMap"
        %   A hashmap that stores the handles of tools added to the group.
        %   
        %   For a FigureToolManager
        %       Tools are "controllib.ui.internal.figuretool.FigureTool".
        %       They are managed by "addFigureTool" and "deleteFigureTool"
        %
        %   For a DocumentToolManager
        %       Tools are "controllib.ui.internal.figuretool.DocumentTool".
        %       They are managed by "addDocumentTool" and "deleteDocumentTool"
        %
        %   The hashmap is created by the constructor and the keys are tool
        %   tags.
        ToolMap
    end

    properties (GetAccess = protected, SetAccess = private, WeakHandle)
        % Property "AppContainer"
        %   Store the handle of "matlab.ui.container.internal.AppContainer"
        %   It must be provided to the constructor.
        AppContainer (1,1) matlab.ui.container.internal.AppContainer
    end

    methods(Access = public)
        
        %% Get/Set DocumentGroup title
        function val = getTitle(this)
            % Method "getTitle": 
            %   title = getTitle(this) returns the title of DocumentGroup
            %   before or after rendering.
            val = this.DocumentGroup.Title;
        end
        
        function setTitle(this, title)
            % Method "setTitle": 
            %   setTitle(this, title) sets the title of DocumentGroup
            %   before or after rendering.
            this.DocumentGroup.Title = title;
        end
        
    end
    
    methods(Access = protected)
        
        %% Tab management
        function addTab(this, tab, selected)
            % Method "addTab": 
            %
            %   addTab(this, tab) adds a tab to the contextual TabGroup,
            %   where "tab" is a "matlab.ui.internal.toolstrip.Tab" object.
            %
            %   addTab(this, tab, true) adds a tab to the contextual
            %   TabGroup and make it the selected tab.
            %
            %   Expected to use this method only in the sub-class of
            %   "DocumentToolManager" to add shared contextual tabs.
            this.TabGroup.add(tab);
            if nargin>2 && selected
                this.TabGroup.SelectedTab = tab;
            end
        end
        
        function removeTab(this, tagortab)
            % Method "removeTab": 
            %
            %   removeTab(this, tag) removes a tab from the contextual
            %   TabGroup, where "tag" is the Tag of the tab.
            %
            %   removeTab(this, tab) removes a tab from the contextual
            %   TabGroup, where "tab" is the Tab object.
            %
            %   Expected to use this method only in the sub-class of
            %   "DocumentToolManager" to remove shared contextual tabs.
            if ischar(tagortab) || isstring(tagortab)
                tab = this.TabGroup.find(tagortab);
                if ~isempty(tab)
                    this.TabGroup.remove(tab);
                end
            else
                if ~isempty(this.TabGroup.Children) && any(this.TabGroup.Children==tagortab)
                    this.TabGroup.remove(tagortab);
                end
            end
        end
        
        function val = hasTab(this, tagortab)
            % Method "hasTab": 
            %
            %   hasTab(this, tag) check whether a tab is part of contextual
            %   TabGroup, where "tag" is the Tag of the tab.
            %
            %   hasTab(this, tab) check whether a tab is part of contextual
            %   TabGroup, where "tab" is the Tab object.
            %
            %   Expected to use this method only in the sub-class of
            %   "DocumentToolManager" to remove shared contextual tabs.
            if ischar(tagortab) || isstring(tagortab)
                val = ~isempty(this.TabGroup.find(tagortab));
            else
                val = ~isempty(this.TabGroup.Children) && any(this.TabGroup.Children==tagortab);
            end
        end
        
        %% Document management
        function addDocument(this, document)
            % Method "addDocument": 
            %
            %   addDocument(this, document) adds a document to the
            %   DocumentGroup, where "document" is a
            %   "matlab.ui.internal.FigureDocument" object
            %
            %   Expected to use only in "FigureToolManager" and
            %   "DocumentToolManager" classes, not their sub-classes.
            document.DocumentGroupTag = this.Tag;
            this.AppContainer.add(document);
        end
        
        function removeDocument(this, tag)
            % Method "removeDocument": 
            %
            %   removeDocument(this, tag) removes a document from the
            %   DocumentGroup, where "tag" is the Tag of the document.
            %
            %   Expected to use only in "FigureToolManager" and
            %   "DocumentToolManager" classes, not their sub-classes.
            if this.hasDocument(tag)
                this.AppContainer.closeDocument(this.Tag, tag);
            end
        end
        
        function val = hasDocument(this, tag)
            % Method "hasDocument": 
            %
            %   hasDocument(this, tag) checks whether a document is part of
            %   the DocumentGroup, where "tag" is the Tag of the document.
            %
            %   Expected to use only in "FigureToolManager" and
            %   "DocumentToolManager" classes, not their sub-classes.
            val = hasDocument(this.AppContainer, string(this.Tag), string(tag));
        end
        
        function val = getDocument(this, tag)
            % Method "getDocument": 
            %
            %   document = getDocument(this, tag) returns a document from
            %   the DocumentGroup, where "tag" is the Tag of the document.
            %
            %   Expected to use only in "FigureToolManager" and
            %   "DocumentToolManager" classes, not their sub-classes.
            if this.hasDocument(tag)
                val = getDocument(this.AppContainer, string(this.Tag), string(tag));
            else
                val = [];
            end
        end
        
        function setDocumentTitle(this, tag, title)
            % Method "setDocumentTitle": 
            %
            %   setDocumentTitle(this, tag, title) sets the title of a
            %   document from the DocumentGroup, where "tag" is the Tag of
            %   the document and "title" is the new title in display.
            %
            %   Expected to use only in "FigureToolManager" and
            %   "DocumentToolManager" classes, not their sub-classes.
            if this.hasDocument(tag)
                document = this.getDocument(tag);
                document.Title = title; 
            end            
        end
        
        function val = isDocumentSelected(this, tag)
            % Method "isDocumentSelected": 
            %
            %   isDocumentSelected(this, tag) checks whether a document
            %   from the DocumentGroup is currently selected in the
            %   DocumentGroup, where "tag" is the Tag of the document.
            %
            %   Expected to use only in "FigureToolManager" and
            %   "DocumentToolManager" classes, not their sub-classes.
            if this.hasDocument(tag)
                if isempty(this.DocumentGroup.LastSelected)
                    val = false;
                else
                    val = strcmp(this.DocumentGroup.LastSelected.tag, tag);
                end
            else
                val = false;
            end            
        end
        
        function selectDocument(this, tag)
            % Method "selectDocument": 
            %
            %   selectDocument(this, tag) selects a document from the
            %   DocumentGroup, where "tag" is the Tag of the document.
            %
            %   Expected to use only in "FigureToolManager" and
            %   "DocumentToolManager" classes, not their sub-classes.
            if this.hasDocument(tag)
                document = this.getDocument(tag);
                document.Selected = true;
            end            
        end
        
        function addPanel(this, pnl, region, permitted_regions)
            % Method "addPanel": 
            %
            %   addPanel(this, pnl) adds a contextual panel "pnl" (a
            %   "matlab.ui.internal.FigurePanel" object) to the document
            %   group. By default it is added as a right-side panel and
            %   cannot be moved.
            %
            %   addPanel(this, pnl, region) adds a panel to a desired
            %   region ("left", "right" or "bottom").  It cannot be moved.
            %
            %   addPanel(this, pnl, region, permitted_regions) adds a penal
            %   to a default region and allows it to be moved to other
            %   permitted regions such as ["left"; "right"; "bottom"].
            %
            %   This method must be called before AppContainer is rendered. 
            % 
            %   Expect to use only in the constructor of a subclass of
            %   either "FigureToolManager" or "DocumentToolManager".
            %
            %   You can only add one contextual panel.
            if nargin<=2
                region = "right";
            end
            if nargin<=3
                permitted_regions = region;
            end
            % make sure the panel with proper contextual information
            pnl.Tag = [char(this.Tag) 'Panel']; 
            pnl.Region = region;
            pnl.PermissibleRegions = permitted_regions;
            pnl.Contextual = true;
            % add to AppContainer
            this.AppContainer.add(pnl);
            this.Panel = pnl;  
        end

    end
    
    methods(Access = protected)
        
        function this = AbstractManager(tag, appcontainer)
            % Constructor "AbstractManager": 
            %
            %   AbstractManager(tag, appcontainer) create DocumentGroup and
            %   contextual TabGroup in the desired order.
            %
            %   Sub-classes of AbstractManager can be created after rendering
            %   but they cannot be deleted until AppContainer is deleted.
            %
            %   DocumentGroup must be added to AppContainer after TabGroup
            %   is added to avoid rendering issue.
            %
            %   Expected to use only in "FigureToolManager" and
            %   "DocumentToolManager" classes, not their sub-classes.
            %% tag must be unique
            this.Tag = tag;
            this.AppContainer = appcontainer;
            %% Create document group
            options.Tag = this.Tag;
            options.Context = matlab.ui.container.internal.appcontainer.ContextDefinition();
            options.Context.ToolstripTabGroupTags = this.Tag;
            options.Context.PanelTags = [this.Tag 'Panel'];
            this.DocumentGroup = matlab.ui.internal.FigureDocumentGroup(options);
            %% Create contextual tab group
            tabGroup = matlab.ui.internal.toolstrip.TabGroup();
            tabGroup.Tag = this.Tag;
            tabGroup.Contextual = true;
            this.TabGroup = tabGroup;
            %% Add tab group to app container
            this.AppContainer.add(this.TabGroup);
            %% Add document group to app container
            this.AppContainer.add(this.DocumentGroup);
            %% Initialize hashmap
            this.ToolMap = containers.Map();
        end
        
        function refreshPanel(this, varargin)
            % Method "refreshPanel": 
            % 
            % Must be overloaded in the subclass where contextual panel is
            % enabled
            %
            %    refreshPanel(this, tool)
            %
            % It is called when a document is selected in the AppContainer,
            % where "tool" is the selected document (either a "FigureTool"
            % or a "DocumentTool" object).
        end

    end
    
end