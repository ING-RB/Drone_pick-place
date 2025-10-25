classdef MEViewManager < dynamicprops & matlab.mixin.SetGet & matlab.mixin.Copyable & DAStudio.AbstractTreeNode % & DAStudio.Object
%DAStudio.MEViewManager class
%   DAStudio.MEViewManager extends DAStudio.Object.
%

%    DAStudio.MEViewManager properties:
%       Path - Property is of type 'ustring'  (read only) 
%       Explorer - Property is of type 'handle'  
%       ActiveDomainName - Property is of type 'string'  
%       Domains - Property is of type 'handle vector'  
%       SuggestionMode - Property is of type 'string'  
%       VMProxy - Property is of type 'handle'  
%       PrefFileName - Property is of type 'ustring'  
%       ShowObjectInfo - Property is of type 'bool'  
%       DialogTitle - Property is of type 'ustring'  
%       EnableViewDomainMode - Property is of type 'bool'  
%       EnablePropertyScope - Property is of type 'bool'  
%       ShowFilterGUI - Property is of type 'bool'  
%       Serialize - Property is of type 'bool'  
%
%    DAStudio.MEViewManager methods:
%       addInternalName - Adds the internal name tag to the View. This is used to
%       collapse - the View Manager UI
%       copyView -  Check message if newView is empty.
%       createDomain -  Creates a new domain
%       disableLiveliness -  keep changes on this view hierarchy from being propagated
%       enableLiveliness -  ensure changes on this view hierarchy propagate
%       expand - the View Manager UI
%       getActiveView -  Return active view of the view manager.
%       getActiveViewName -  Return active view of the view manager.
%       getDialogSchema -  Dialog schema for view management.
%       getDomainString -  Return domain string for the passed object. It is roughly a package
%       getStandaloneDialogSchema -  Standalone dialog for view management. Supports high level operations
%       install -  Attach to ModelExplorer
%       moveAfter -  Rearranges the given views
%       moveBefore -  Rearranges the given views
%       refresh - View Manager UI
%       registerViewFilterTypes -  Return active view of the view manager.
%       removeView -  Remove the given view


properties (SetObservable)
    %EXPLORER Property is of type 'handle' 
    Explorer 
    %ACTIVEDOMAINNAME Property is of type 'string' 
    ActiveDomainName char = '';
    %DOMAINS Property is of type 'handle vector' 
    Domains 
    %SUGGESTIONMODE Property is of type 'string' 
    SuggestionMode char = 'auto';
    %VMPROXY Property is of type 'handle' 
    VMProxy 
    %PREFFILENAME Property is of type 'ustring' 
    PrefFileName char = [ prefdir, filesep, 'modelexplorerviews.mat' ];
    %SHOWOBJECTINFO Property is of type 'bool' 
    ShowObjectInfo logical = false;
    %DIALOGTITLE Property is of type 'ustring' 
    DialogTitle char = '';
    %ENABLEVIEWDOMAINMODE Property is of type 'bool' 
    EnableViewDomainMode logical = false;
    %ENABLEPROPERTYSCOPE Property is of type 'bool' 
    EnablePropertyScope logical = false;
    %SHOWFILTERGUI Property is of type 'bool' 
    ShowFilterGUI logical = false;
    %SERIALIZE Property is of type 'bool' 
    Serialize logical = true;
end

properties (SetObservable, Hidden)
    %ACTIVEVIEW Property is of type 'handle'  (hidden)
    ActiveView 
    %ISCOLLAPSED Property is of type 'bool'  (hidden)
    IsCollapsed logical = true;
    %TIMER Property is of type 'handle'  (hidden)
    Timer 
    %METREESELECTIONCHANGEDLISTENER Property is of type 'handle'  (hidden)
    METreeSelectionChangedListener 
    %MELISTSELECTIONCHANGEDLISTENER Property is of type 'handle'  (hidden)
    MEListSelectionChangedListener 
    %MEVIEWMODECHANGEDLISTENER Property is of type 'handle'  (hidden)
    MEViewModeChangedListener 
    %MESEARCHPROPERTIESADDEDLISTENER Property is of type 'handle'  (hidden)
    MESearchPropertiesAddedListener 
    %MECLOSEDLISTENER Property is of type 'handle'  (hidden)
    MEClosedListener 
    %MEDELETELISTENER Property is of type 'handle'  (hidden)
    MEDeleteListener 
    %ACTIVEVIEWLISTENER Property is of type 'handle'  (hidden)
    ActiveViewListener 
    %ISCOLLAPSEDLISTENER Property is of type 'handle'  (hidden)
    IsCollapsedListener 
    %MEVIEWADDEDLISTENER Property is of type 'handle'  (hidden)
    MEViewAddedListener 
    %MEVIEWREMOVEDLISTENER Property is of type 'handle'  (hidden)
    MEViewRemovedListener 
    %MESORTCHANGEDLISTENER Property is of type 'handle'  (hidden)
    MESortChangedListener 
    %MESCOPECHANGEDLISTENER Property is of type 'handle'  (hidden)
    MEScopeChangedListener 
    %MATLABVERSION Property is of type 'string'  (hidden)
    MATLABVersion char = release_version;
    %MEHEADERSIZECHANGEDLISTENER Property is of type 'handle'  (hidden)
    MEHeaderSizeChangedListener 
end


    methods  % constructor block
        function this = MEViewManager()
        %
        this.ActiveDomainName = 'Other';
        % This is default domain.
        this.Domains = DAStudio.MEViewDomain(this, 'Other');
        this.SuggestionMode = 'auto';
        this.ShowFilterGUI = true;
        
        
        end  % MEViewManager
        
    end  % constructor block

    methods 
    end   % set and get functions 

    methods  % public methods
        %----------------------------------------
       function addInternalName(this, view)
       %ADDINTERNALNAME Adds the internal name tag to the View. This is used to
       %distinguish between factory views and  custom views.
       
       
       if view.IsFactoryView
           view.InternalName = ['TMW_' view.Name '_' this.MATLABVersion];
       end
       
       
       end  % addInternalName
       
        %----------------------------------------
       function collapse(h)
       % Collapse the View Manager UI
       
       h.IsCollapsed = true;
       end  % collapse
       
        %----------------------------------------
       function [newView message] = copyView(h, source, target)
       % Check message if newView is empty.
       
       
       newView = [];
       message = '';
       % Check if source exists, if not return false.
       sourceView = findobj(h, '-isa', 'DAStudio.MEView', 'Name', source);
       if isempty(sourceView)
           message = 'Source view does not exist.';
           return;
       end
       % Check if view with target name already exists, if it exists return false
       targetView = findobj(h, '-isa', 'DAStudio.MEView', 'Name', target);
       if ~isempty(targetView)
           message = 'Target view already exists.';
           return;
       end
       % Create a new view.
       newView = DAStudio.MEView(target, sourceView.Description);
       % Set properties
       if ~isempty(sourceView.Properties)
           h.disableLiveliness;
           newView.Properties = copy(sourceView.Properties);
           if ~isempty(sourceView.Properties)
               % Set matching properties.
               properties = findobj(sourceView.Properties, 'isMatching', true);
               % Any shortcut?
               for i = 1:length(properties)
                   prop = findobj(newView.Properties, 'Name', properties(i).Name);
                   prop.isMatching = true;
               end
           end
           h.enableLiveliness;
       end
       
       
       end  % copyView
       
        %----------------------------------------
       function  domain = createDomain(this, domainName)
       % Creates a new domain
       
       
       % It should not exist already.
       domain = findobj(this.Domains, 'Name', domainName);
       % Check if this domain really exists. If not, create it at run time.
       if isempty(domain)
           % Create it now and give it to the manager.
           domain = DAStudio.MEViewDomain(this, domainName);
           if isempty(this.Domains)
               this.Domains = domain;
           else
               this.Domains(end + 1) = domain;
           end
       end
       end  % createDomain
       
        %----------------------------------------
       function disableLiveliness(h)
       % keep changes on this view hierarchy from being propagated
       
       
       % disable liveliness for all managed views
       views = findobj(h, '-isa', 'DAStudio.MEView');
       for i = 1:length(views)
           views(i).disableLiveliness;
       end
       
       h.ActiveViewListener             = [];
       h.MEViewAddedListener            = [];
       h.MEViewRemovedListener          = [];
       h.IsCollapsedListener            = [];
       h.MEViewModeChangedListener      = [];
       h.MESearchPropertiesAddedListener = [];
       h.MESortChangedListener          = [];
       
       end  % disableLiveliness
       
        %----------------------------------------
       function enableLiveliness(h)
       % ensure changes on this view hierarchy propagate
       
       
       % enable liveliness for all managed views
       if ~isempty(h.Explorer) % exclude proxy view manager
           views = findobj(h, '-isa', 'DAStudio.MEView');
           for i = 1:length(views)
               views(i).enableLiveliness;
           end
       
           % add listeners to keep MEViewManager in sync with view ME selection
           % h.MEListSelectionChangedListener = addlistener(h.Explorer, 'MEListSelectionChanged', {@syncMEViewManagerFromME, h});
           h.MEListSelectionChangedListener = handle.listener(h.Explorer, 'MEListSelectionChanged', {@syncMEViewManagerFromME, h});
           h.MEViewModeChangedListener = handle.listener(h.Explorer, 'MEViewModeChanged', {@syncMEViewManagerFromME, h});
           h.MESearchPropertiesAddedListener = handle.listener(h.Explorer, 'MESearchPropertiesAdded', {@syncMEViewManagerFromME, h});
           h.MESortChangedListener = handle.listener(h.Explorer, 'MESortChanged', {@syncMEViewManagerFromME, h});
           h.MEScopeChangedListener = handle.listener(h.Explorer, 'MEScopeChanged', {@syncMEViewManagerFromME, h});
           h.MEHeaderSizeChangedListener = handle.listener(h.Explorer, 'MEHeaderSizeChanged', {@syncMEViewManagerFromME, h});
       
           % add listeners to enable persistence on ME close/delete
           h.MEClosedListener = handle.listener(h.Explorer, 'MEPostClosed', {@modelExplorerClosed, h});
           h.MEDeleteListener = handle.listener(h.Explorer, 'ObjectBeingDestroyed', {@modelExplorerClosed, h});
       
           % add listener to keep ME & MEViewManager in sync with active view changes
           p = findprop(h, 'ActiveView');
           h.ActiveViewListener = event.proplistener(h, p, 'PostSet', @(h,evt) syncUI(h,evt));
       
           % add listeners to keep MEViewManager in sync with view addition/removal
           % h.MEViewAddedListener   = handle.listener(h, 'ObjectChildAdded',   @syncMEViewManager);
           h.MEViewAddedListener = addlistener(h, 'ObjectChildAdded',   @syncMEViewManager);
           % h.MEViewRemovedListener = handle.listener(h, 'ObjectChildRemoved', @syncMEViewManager);
           h.MEViewRemovedListener = addlistener(h, 'ObjectChildRemoved', @syncMEViewManager);
       
           % add listener to keep MEViewManager in sync with property changes
           p = findprop(h, 'IsCollapsed');
           h.IsCollapsedListener = event.proplistener(h, p, 'PostSet', @syncMEViewManager);
       end
       end  % enableLiveliness
       
       

        %----------------------------------------
       function expand(h)
       % Expand the View Manager UI
       
       h.IsCollapsed = false;
       end  % expand
       
        %----------------------------------------
       function activeView = getActiveView(h)
           % Return active view of the view manager.
           
           activeView = [];
           if ~isempty(h.ActiveView) && isvalid(h.ActiveView)
               % It could be empty. Called needs to check that.
               activeView = h.ActiveView;
           end
       
       end  % getActiveView
       
        %----------------------------------------
       function activeViewName = getActiveViewName(h)
       % Return active view of the view manager.
       
           activeViewName = '';
           % It could be empty. Called needs to check that.
           if ~isempty(h.ActiveView) && isvalid(h.ActiveView)
               activeViewName = h.ActiveView.Name;
           end
       
       end  % getActiveViewName
       
        %----------------------------------------
       %
       % Dialog schema for view management.
       %
       function dlg = getDialogSchema(h, type)
       
       
       switch (type)
         case 'manage'
           dlg = h.getStandaloneDialogSchema();
         case {'export' 'import'}
           dlg = h.getExportImportDialogSchema(type);
         case 'details'
           dlg = h.getDetailsDialogSchema(type);
         otherwise
           dlg = h.getEmbeddedDialogSchema();    
       end
       
       end  % getDialogSchema
       
        %----------------------------------------
       function domainName = getDomainString(this, obj)
       % Return domain string for the passed object. It is roughly a package
       % name except for some special cases.
       
       
       % By default it is 'Other'
       domainName = 'Other';
       % Check for Shortcuts
       if isa(obj, 'DAStudio.Shortcut')
           obj = obj.getForwardedObject;
           if isa(obj,"DAStudio.DAObjectProxy")
               obj = obj.getMCOSObjectReference;
           end
       end
       % Get Package information.
       packageName = '';
       if isa(obj,"handle.handle")
           %udd
           classH = classhandle(obj);
           if ~isempty(classH)
               packageName = classH.Package.Name;
           end
       else
          %mcos
          classH = metaclass(obj);
          if ~isempty(classH)
              packageName = classH.ContainingPackage.Name;
              dotIdx = findstr(packageName, '.');
              if ~isempty(dotIdx)
                  packageName = packageName(1:dotIdx(1)-1);
              end
          end
          
       end
       
       if ~isempty(packageName)
           domainName = packageName;
           % Special case for Workspace
           if isa(obj, 'DAStudio.WorkspaceNode')
               domainName = 'Workspace';
           elseif isa(obj, 'Simulink.ModelAdvisor') ...
                   || isa(obj, 'Simulink.ConfigSet') ...
                   || isa(obj, 'Simulink.Directory')
               domainName = 'Other';
           elseif isa(obj, 'Simulink.Configurations') || (isa(obj, 'DAStudio.DAObjectProxy') && (isa(obj.getMCOSObjectReference, 'Simulink.Configurations')))
               domainName = 'Configurations';
           elseif isa(obj, 'Simulink.DataDictionaryRootNode')
               domainName = 'DataDictionary';
           elseif isa(obj, 'Simulink.DataDictionaryScopeNode')
               domainName = 'DataDictionary';
               nodeName = obj.getNodeName;
               if strcmp(nodeName, 'Other')
                   domainName = [domainName '_' nodeName];
               end
           elseif isa(obj, 'Simulink.SlidDASectionNode')
               domainName = 'Workspace';
           elseif isa(obj, 'Simulink.SlidDAContainerNode')
               domainName = 'DataDictionary';
           elseif isa(obj, 'Simulink.Root')
               domainName = 'Other';
               %Special case for DAObejctProxy
           elseif isa(obj, 'DAStudio.DAObjectProxy') && (isa(obj.getMCOSObjectReference, 'Simulink.BlockDiagram')||isa(obj.getMCOSObjectReference, 'Simulink.ModelReference')|| isa(obj.getMCOSObjectReference, 'Simulink.Root'))
               domainName = 'Simulink';
           end
           % TODO: Add more special cases if needed.
       end
       
       % Get actual domain by this name.
       domainInfo = findobj(this.Domains, 'Name', domainName);
       % Check if this domain really exists. If not, create it at run time.
       if isempty(domainInfo)
           this.createDomain(domainName);
       end
       
       end  % getDomainString
       function dlg = showDialog(this, option, tag)
            dlg = DAStudio.ToolRoot.getOpenDialogs(this);
            found = false;
            for i = 1:length(dlg)
                if strcmp(dlg(i).dialogTag, tag)
                    found = true;
                    dlg(i).show;
                    dlg = dlg(i);
                    break;
                end
            end
            if ~found
                dlg = DAStudio.Dialog(this, option, 'DLG_STANDALONE');
            end
       end
        %----------------------------------------
       %
       % Standalone dialog for view management. Supports high level operations
       % on all the views.
       %
       function dlg = getStandaloneDialogSchema(h)
       
       
       newViewButton.Type               = 'pushbutton';
       newViewButton.Tag                = 'new_view_button';
       newViewButton.Name               = DAStudio.message('modelexplorer:DAS:NewAction');
       newViewButton.MatlabMethod       = 'feval';
       newViewButton.MatlabArgs         = {@DAStudio.MEViewManager_cb, '%dialog', 'doNewView'};   
       newViewButton.RowSpan            = [1 1];
       newViewButton.ColSpan            = [1 1];
       
       copyViewButton.Type             = 'pushbutton';
       copyViewButton.Tag              = 'copy_view_button';
       copyViewButton.Name             = DAStudio.message('modelexplorer:DAS:CopyAction');
       copyViewButton.MatlabMethod     = 'feval';
       copyViewButton.MatlabArgs       = {@DAStudio.MEViewManager_cb, '%dialog', 'doCopyView'};
       copyViewButton.RowSpan          = [1 1];
       copyViewButton.ColSpan          = [2 2];
       
       deleteViewButton.Type           = 'pushbutton';
       deleteViewButton.Tag            = 'delete_view_button';
       deleteViewButton.Name           = DAStudio.message('modelexplorer:DAS:DeleteAction');
       deleteViewButton.MatlabMethod   = 'feval';
       deleteViewButton.MatlabArgs     = {@DAStudio.MEViewManager_cb, '%dialog', 'doDeleteView'};
       deleteViewButton.RowSpan        = [1 1];
       deleteViewButton.ColSpan        = [3 3];
       % Do not allow to delete last view.
       deleteViewButton.Enabled       = length(findobj(h.VMProxy, '-isa', 'DAStudio.MEView')) > 1;
           
       exportViewButton.Type           = 'pushbutton';
       exportViewButton.Tag            = 'export_view_button';
       exportViewButton.Name           = DAStudio.message('modelexplorer:DAS:ExportAction');
       exportViewButton.MatlabMethod   = 'feval';
       exportViewButton.MatlabArgs     = {@DAStudio.MEViewManager_cb, '%dialog', 'doExportView'};
       exportViewButton.RowSpan        = [1 1];
       exportViewButton.ColSpan        = [4 4];
           
       importViewButton.Type           = 'pushbutton';
       importViewButton.Tag            = 'import_view_button';
       importViewButton.Name           = DAStudio.message('modelexplorer:DAS:ImportAction');
       importViewButton.MatlabMethod   = 'feval';
       importViewButton.MatlabArgs     = {@DAStudio.MEViewManager_cb, '%dialog', 'doImportView'};
       importViewButton.RowSpan        = [1 1];
       importViewButton.ColSpan        = [5 5];
       
       optionsViewButton.Type          = 'pushbutton';
       optionsViewButton.Tag           = 'options_view_button';
       optionsViewButton.Name          = DAStudio.message('modelexplorer:DAS:OptionsButton');
       optionsViewButton.Menu          = getManageOptionsMenu(h);    
       optionsViewButton.RowSpan       = [1 1];
       optionsViewButton.ColSpan       = [6 6];
           
       spacerView.Type                 = 'panel';
       spacerView.RowSpan              = [1 1];
       spacerView.ColSpan              = [7 7];
       
       viewManagerButtonBar.Type       = 'panel';
       viewManagerButtonBar.Tag        = 'view_manager_button_bar';
       viewManagerButtonBar.Visible    = true;
       viewManagerButtonBar.Items      = {newViewButton, copyViewButton, ...
                                          deleteViewButton, exportViewButton, ...
                                          importViewButton, optionsViewButton, ...
                                          spacerView};
       
       viewManagerButtonBar.LayoutGrid = [1 7];
       viewManagerButtonBar.ColStretch = [0 0 0 0 0 0 1];
       viewManagerButtonBar.RowSpan    = [1 1];
       viewManagerButtonBar.ColSpan    = [1 1];
       
       data = {};
       allViews = h.VMProxy.getAllViews;
       totalRows = length(allViews);
       for i = 1:totalRows
           data{i, 1}.Type = 'edit';
           data{i, 2}.Type = 'edit';
           data{i, 1}.Value = '';
           data{i, 2}.Value = '';
           if i <= length(allViews)
               data{i, 1}.Value = allViews(i).Name;                
               data{i, 2}.Value = allViews(i).Description;
           end
       end
       
       viewManagerTable.Type             = 'table';
       viewManagerTable.Tag              = 'view_manager_table';
       viewManagerTable.Source           = h;
       viewManagerTable.Graphical        = true;
       viewManagerTable.Grid             = true;
       viewManagerTable.ColHeader        = {DAStudio.message('modelexplorer:DAS:ViewID'), ...
                                           DAStudio.message('modelexplorer:DAS:DescriptionID')};
       viewManagerTable.HeaderVisibility = [0 1];
       viewManagerTable.ReadOnlyColumns  = [];
       viewManagerTable.MultiSelect      = true;
       viewManagerTable.Editable         = true;
       viewManagerTable.Data             = data;
       viewManagerTable.Size             = size(data);
       viewManagerTable.ValueChangedCallback  = @onTableValueChanged;
       viewManagerTable.CurrentItemChangedCallback = @onTableCurrentChanged;
       viewManagerTable.RowSpan          = [1 4];
       viewManagerTable.ColSpan          = [1 1];
       viewManagerTable.SelectionBehavior= 'Row';
       viewManagerTable.AutoTranslateStrings = 0;
       viewManagerTable.TableKeyPressCallback = @onTableKeyPress;
       
       spacerTop.Type                 = 'panel';
       spacerTop.RowSpan              = [1 1];
       spacerTop.ColSpan              = [2 2];
       
       viewButtonUp.Type              = 'pushbutton';
       viewButtonUp.Tag               = 'up_view_button';
       viewButtonUp.ToolTip           = '';
       viewButtonUp.FilePath          = fullfile(matlabroot, 'toolbox', ...
                                           'shared', 'dastudio', 'resources', ...
                                           'move_up.gif');
       viewButtonUp.MatlabMethod      = 'feval';
       viewButtonUp.MatlabArgs        = {@DAStudio.MEViewManager_cb, '%dialog', 'doViewUp'};
       viewButtonUp.RowSpan           = [2 2];
       viewButtonUp.ColSpan           = [2 2];
       viewButtonUp.Enabled           = false;
       
       viewButtonDown.Type            = 'pushbutton';
       viewButtonDown.Tag             = 'down_view_button';
       viewButtonDown.ToolTip         = '';
       viewButtonDown.FilePath        = fullfile(matlabroot, 'toolbox', ...
                                           'shared', 'dastudio', 'resources', ...
                                           'move_down.gif');
       viewButtonDown.MatlabMethod    = 'feval';
       viewButtonDown.MatlabArgs      = {@DAStudio.MEViewManager_cb, '%dialog', 'doViewDown'};
       viewButtonDown.RowSpan         = [3 3];
       viewButtonDown.ColSpan         = [2 2];
           
       spacerDown.Type                = 'panel';
       spacerDown.RowSpan             = [4 4];
       spacerDown.ColSpan             = [2 2];
       
       viewManagerTabelPanel.Type     = 'panel';
       viewManagerTabelPanel.Items    = {viewManagerTable, spacerTop, ...
                                         viewButtonUp, viewButtonDown, ...
                                         spacerDown};
       viewManagerTabelPanel.LayoutGrid = [4 2];
       viewManagerTablePanel.RowStretch = [1 0 0 1];
       viewManagerTablePanel.RowStretch = [1 0];
       viewManagerTablePanel.RowSpan    = [2 2];
       viewManagerTablePanel.ColSpan    = [1 1];
           
                   
       dlg.DialogTitle         = h.DialogTitle;
       dlg.DialogTag           = 'me_view_manager_dialog_ui';    
       dlg.CloseCallback       = 'viewManagerDialogCallback';    
       dlg.CloseArgs           = {h, '%closeaction'};
       dlg.HelpMethod          = 'helpview';
       dlg.HelpArgs            = {'simulink', 'ModelExplorer_ViewManager_HelpButton'};
       dlg.StandaloneButtonSet = {'Ok', 'Cancel', 'Help'};
       dlg.Items               = {viewManagerButtonBar, viewManagerTabelPanel};
       dlg.LayoutGrid          = [2 1];
       dlg.RowStretch          = [0 1];
       end  % getStandaloneDialogSchema
       
       
       %
       % Table selection changed callback handler
       %

        %----------------------------------------
       function install(h, me, installmenus)
       % Attach to ModelExplorer
            
       if nargin == 2
           installmenus = false;
       end
       
       if ~isempty(me)
           % me.addChildren(h); % ME prop is reference to MEViewManager
           h.Explorer = me;
           % Install on ModelExplorer
           h.Explorer.installViewManager(h, installmenus);
           % keep the ME in sync with MEView changes and vice versa
           h.enableLiveliness;
       else
           h.Explorer.installViewManager('', installmenus);
       end
       
       end  % install
       
        %----------------------------------------
       function moveAfter(h, viewToMove, viewAfter)
       % Rearranges the given views
       
       
       v1 = h.getView(viewToMove);
       % disconnect it from the hierarchy.
       v1.disconnect;
       v2 = h.getView(viewAfter);
       % v1.connect(v2, 'left');
       v2.insertAfter(v1);
       end  % moveAfter
       
        %----------------------------------------
       function moveBefore(h, viewToMove, viewBefore)
       % Rearranges the given views
       
       v1 = h.getView(viewToMove);
       % disconnect it from the hierarchy.
       v1.disconnect;
       
       v2 = h.getView(viewBefore);
       % v1.connect(v2, 'right');
       v2.insertBefore(v1);
       end  % moveBefore
       
        %----------------------------------------
       function refresh(h)
       % Refresh View Manager UI
       
       managerUI = DAStudio.ToolRoot.getOpenDialogs(h);
       
       for i = 1:length(managerUI)
           managerUI(i).refresh;
       end
       end  % refresh
       
        %----------------------------------------
       function registerViewFilterTypes(obj, viewName, filterTypes)
       % Return active view of the view manager.
       
       view = obj.getView(viewName);
       if ~isempty(view)        
           if ~isempty(obj.Explorer)
               % Register with Explorer
               obj.Explorer.registerViewFilterTypes(viewName, filterTypes)
               view.FilterTypes = filterTypes;
           end
       end
       end
        %----------------------------------------
       function success = removeView(h, viewName)
       % Remove the given view
       
       
       success = true;
       % Check if views exists, if not return false.
       targetView = findobj(h, '-isa', 'DAStudio.MEView', 'Name', viewName);
       if isempty(targetView)
           success = false;
           return;
       end
       
       % Delete the view.
       try 
           targetView.delete;
           success = true;
       catch e
           success = false;
       end
       
       end  % removeView
       
end  % public methods 


    methods (Hidden) % possibly private or hidden
        %----------------------------------------        
       
       function addChildren(h, varargin)
           h.addChildren@matlab.mixin.internal.TreeNode(varargin{:});
       end

       function added = addView(h, view)
       
       % addView
       %
       % Adds a new view to the view manager. If successful returns true,
       % false otherwise.
       
       
       % add view to the view management hierarchy
       added = false;
       if ~isempty(view) && ~isempty(h)
           % Check valid view names and if it already exists or not.
           v = findobj(h, '-isa', 'DAStudio.MEView', 'Name', view.Name);
           if isempty(v)
               view.ViewManager = h;
               addChildren(h, view);
               % view.connect(h, 'up');
               view.enableLiveliness;
               added = true;
           end
       end
       
       end  % addView
       
        %----------------------------------------
       function proxy = createProxy(h) 
           h.VMProxy = [];
           % Create view manager's proxy.
           proxy = feval(class(h)); 
           % Create views for proxy
           allViews = copy(findobj(h, '-isa', 'DAStudio.MEView'));
           for i = 1:length(allViews)
               view = allViews(i);
               proxy.addView(view);
           end
           % Active view information
           if ~isempty(h.getActiveView)
               proxy.ActiveView = copy(h.ActiveView);
           end
           % Active domain name
           if ~isempty(h.ActiveDomainName)
               proxy.ActiveDomainName = h.ActiveDomainName;
           end
           % Domain info
           proxy.Domains = copy(h.Domains);
           % The views in these domains still refer to old views. Update.
           for i = 1:length(proxy.Domains)
               domainInfo = proxy.Domains(i);
               domainInfo.ViewManager = proxy;
               if ~isempty(domainInfo)
                   dView = domainInfo.getActiveView();
                   if ~isempty(dView)
                       % find actual view
                       view = proxy.getView(dView.Name);
                       if ~isempty(view)
                           domainInfo.setActiveView(view);
                       end
                   end
               end
           end
           % Suggestion mechanism
           proxy.SuggestionMode = h.SuggestionMode;
           %
           addprop(proxy, 'BufferedViews');
       end  % createProxy
       
        %----------------------------------------
       function customize(h)
       %
       
       h.ShowObjectInfo = true;
       h.DialogTitle = DAStudio.message('modelexplorer:DAS:ViewManagerDialogTitle');
       h.EnableViewDomainMode = true;
       h.EnablePropertyScope = true;
       end  % customize
       
        %----------------------------------------
       function customizeView(h, on)
       %
       
       
       h.IsCollapsed = ~on;
       
       end  % customizeView
       
        %----------------------------------------
       function handled = eventHandler(h, eventType, obj)
       %
       handled = false;
       if isa(obj,"DAStudio.DAObjectProxy")
           obj = obj.getMCOSObjectReference;
       end
       
       exp = h.Explorer;
       switch eventType
           case 'TreeSelectionChanged'
               if h.ShowObjectInfo
                   dlg = DAStudio.ToolRoot.getOpenDialogs(h);
                   for i = 1:length(dlg)
                       if strcmp(dlg(i).dialogTag, 'me_view_manager_ui')
                           if strcmp(exp.ViewMode,'Content')
                               dlg(i).setVisible('views_details_link', true);  
                           else
                               dlg(i).setVisible('views_details_link', false);  
                           end                
                           dlg(i).setWidgetValue('views_details_link', ...
                                             DAStudio.message('modelexplorer:DAS:LoadingDotDotDot'));                
                           break;                
                       end
                   end
               end
               % Decide domain here.
               h.ActiveDomainName = h.getDomainString(obj);
               if strcmp(h.SuggestionMode, 'auto')
                   % Switch views if auto switch is on
                   [suggestedView, reason] = h.getSuggestedView(); %#ok
                   if ~isempty(suggestedView)
                       if ~strcmp(suggestedView.Name, h.ActiveView.Name)
                           h.ActiveView = suggestedView;
                           handled = false;
                       end
                   end
               end
               
               if strcmp(obj.getDisplayLabel, DAStudio.message('SLDD:sldd:ArchDataSectionName'))
                   % Hide the spreadsheet widget if the Architectural Data is 
                   % selected in the tree component
                   exp.showListView(false);
               else
                   % Show the spreadsheet component
                   exp.showListView(true);
               end
               
           otherwise
               handled = false;
       end
       
       % LocalWords:  DAS SLDD sldd
       
       end  % eventHandler
       
        %----------------------------------------
       function export(this, views, filename)
       % 
       % Export to an external file the given views.
       
       
       if nargin > 1
           views = convertStringsToChars(views);
       end
       
       if nargin > 2
           filename = convertStringsToChars(filename);
       end
       
       this.save(views, filename);
       end  % export
       
        %----------------------------------------
       %
       %
       %
       function exportViewsCallback(h, callbackArgs)
       
       
       if strcmp(callbackArgs, 'ok')
           [filename, pathname] = uiputfile({'*.mat','MAT-files (*.mat)';}, ...
                                            DAStudio.message('modelexplorer:DAS:ExportViewsDialogTitle'));
           if ~isequal(filename, 0) && ~isequal(pathname, 0)
               fullFile = [pathname filename];    
               % Get file name and export all views.
               h.export(h.VMProxy.BufferedViews, fullFile);
           end
       end
       
       end  % exportViewsCallback
       
        %----------------------------------------
       function views = getAllViews(h)
       %
       
       
       % Returns the current views with this manager.
           
       views = findobj(h, '-isa', 'DAStudio.MEView');
       
       end  % getAllViews
       
        %----------------------------------------
       function dlgstruct = getDetailsDialogSchema(h, ~)
       %
       
       view = h.getActiveView;
       % Visible objects
       visible = h.VisibleCount;
       % Possible objects
       possible = h.PossibleCount;
       % Number of hidden objects
       hidden = possible - visible;
       % 
       settingsStr = calculateSettingsString(h);
       % construct the message to display
       infoString = DAStudio.message('modelexplorer:DAS:ViewDetails',...
                       visible, possible, hidden, settingsStr);
       im = DAStudio.imExplorer(h.Explorer);
       filterString = im.getListFilterString();
       if ~isempty(filterString)
           filterMessage = DAStudio.message('modelexplorer:DAS:FilterDetails', filterString);               
           infoString = sprintf('%s\n\n%s', infoString, filterMessage);
       end
       
       % Prepare dialog schema
       spacer_top_text.Type       = 'panel';
       spacer_top_text.RowSpan    = [1 1];
       spacer_top_text.ColSpan    = [1 2];
       
       info_icon.Type        = 'image';
       info_icon.Tag         = 'count_details_info_icon';
       info_icon.FilePath    = fullfile(matlabroot, 'toolbox', 'shared', ...
                                        'dastudio', 'resources', 'dialog_info_32.png');    
       info_icon.RowSpan     = [2 2];
       info_icon.ColSpan     = [1 1];
           
       message.Type = 'text';
       message.Name = infoString;
       message.Tag = 'details_message_item';
       message.ColSpan = [2 2];
       message.RowSpan = [2 2];
       
       spacer_right_text.Type       = 'panel';
       spacer_right_text.RowSpan    = [2 2];
       spacer_right_text.ColSpan    = [3 3];
       
       info.Type        = 'panel';
       info.Items       = {spacer_top_text, info_icon, message, spacer_right_text};
       info.LayoutGrid  = [2 3];
       info.RowSpan     = [1 1];
       info.ColSpan     = [1 1];
       
       dlgstruct.DialogTitle = view.Name;
       dlgstruct.LayoutGrid = [1 1];
       dlgstruct.StandaloneButtonSet = {'Ok'}; % no button bar
       dlgstruct.Sticky = true; % modal
       dlgstruct.DialogTag = 'me_view_manager_view_details';
       dlgstruct.Items = {info};
       end  % getDetailsDialogSchema
       
       
       %
       %
       %

        %----------------------------------------
       function dlg = getEmbeddedDialogSchema(h)
       %
       
       
       [names index]           = calculateInstalledViews(h);
       
       views.Type              = 'combobox';
       views.Tag               = 'views_combo';
       views.Name              = [DAStudio.message('modelexplorer:DAS:SelectView') ' '];
       views.Graphical         = true;
       views.SaveState         = false;
       views.Entries           = names;
       views.Value             = index;
       views.MatlabMethod      = 'feval';
       views.MatlabArgs        = {@DAStudio.MEViewManager_cb, '%dialog', 'doViewChange', '%value'};
       views.RowSpan           = [1 1];
       views.ColSpan           = [1 1];
       views.MinimumSize       = [128 -1];
       
       more.Type               = 'hyperlink';
       more.Tag                = 'views_show_hide_details_link';
       more.MatlabMethod       = 'feval';
       more.MatlabArgs         = {@DAStudio.MEViewManager_cb, '%dialog', 'doExpandCollapse'};
       more.RowSpan            = [1 1];
       more.ColSpan            = [2 2];
       more.Name               = '';
       more.ToolTip            = '';
       
       if h.IsCollapsed
           more.Name = DAStudio.message('modelexplorer:DAS:ShowDetails');
           more.ToolTip  = DAStudio.message('modelexplorer:DAS:ExpandViewManager');
       else
           more.Name = DAStudio.message('modelexplorer:DAS:HideDetails');
           more.ToolTip  = DAStudio.message('modelexplorer:DAS:CollapseViewManager');
       end
       
       [visible, possible] = countObjectsInView(h);
       
       spacer.Type             = 'panel';
       spacer.RowSpan          = [1 1];
       spacer.ColSpan          = [3 3];
       
       details.Type            = 'hyperlink';
       details.Tag             = 'views_details_link';
       details.MatlabMethod    = 'feval';
       details.MatlabArgs      = {@DAStudio.MEViewManager_cb, '%dialog', 'doDetails', visible, possible};
       details.RowSpan         = [1 1];
       details.ColSpan         = [4 4];
       
       if visible == possible
           details.Name    = DAStudio.message('modelexplorer:DAS:NumberInScope', visible);
           details.ToolTip = DAStudio.message('modelexplorer:DAS:NumberInScopeFilteredTT');
       else
           if visible < possible
               details.Name    = DAStudio.message('modelexplorer:DAS:NumberInScopeFiltered', visible, possible);
               details.ToolTip = DAStudio.message('modelexplorer:DAS:NumberInScopeFilteredTT');
           else
               % sometimes refresh goes out of sync. We need to wait for
               % next refresh.
               details.Name    = DAStudio.message('modelexplorer:DAS:NumberInScope', visible);
               details.ToolTip = DAStudio.message('modelexplorer:DAS:NumberInScopeFilteredTT');
           end
       end
       
       % Hide it in search mode
       if ishandle(h.Explorer)
           details.Visible = h.ShowObjectInfo && strcmp(h.Explorer.ViewMode, 'Content');
       end
       
       % Remove filter in search mode
       if ishandle(h.Explorer) & strcmp(h.Explorer.ViewMode, 'Search')
           h.ShowFilterGUI = false;
       else 
           h.ShowFilterGUI = true; 
       end
       
       if h.ShowFilterGUI
           filterOptions.Type       = 'pushbutton';
           filterOptions.Tag        = 'filter_options_button';
           filterOptions.ToolTip    = DAStudio.message('modelexplorer:DAS:ShowHideFilterObjects');
           filterOptions.Flat       = true;
           filterOptionsMenu = getFilterOptionsMenu(h);
           filterOptions.FilePath   = fullfile(matlabroot, 'toolbox', 'shared', 'dastudio', 'resources', 'FilterFunnel.png');
           % It is possible that during me deletion process menu is deleted
           % first - it was attached to ToolRoot hierarhcy. In that case, 
           % do not return anything
           filterOptions.Menu = [];
           if isvalid(filterOptionsMenu)
               filterOptions.Menu = filterOptionsMenu;
           end
           filterOptions.RowSpan    = [1 1];
           filterOptions.ColSpan    = [5 5];
           filterOptions.MaximumSize = [28 24];
           filterOptions.MinimumSize = [28 24];
       end
       
       views_bar.Type          = 'panel';
       views_bar.Tag           = 'views_bar';
       if h.ShowFilterGUI
           views_bar.Items         = {views, more, spacer, details, filterOptions};
           views_bar.LayoutGrid    = [1 5];
           views_bar.ColStretch    = [0 0 1 0 0];
       else
           views_bar.Items         = {views, more, spacer, details};
           views_bar.LayoutGrid    = [1 4];
           views_bar.ColStretch    = [0 0 1 0 ];
       end
       
       %% dynamic content based on active view visible when view manager is expanded
       content.Type            = 'panel';
       content.Tag             = 'views_content';
       content.Items           = {};
       content.Visible         = ~h.IsCollapsed;
       
       view_schema = [];
       if ~isempty(h.getActiveView) && ~h.IsCollapsed
           view_schema = h.ActiveView.getDialogSchema();
       end
       
       if ~isempty(view_schema)
           content.Items = {view_schema};
       end
       
       %% Suggestion GUI
       view_suggestion_panel.Type            = 'panel';
       view_suggestion_panel.Tag             = 'views_suggestion_panel';
       view_suggestion_panel.Items           = {};
       
       % Decide whether to generate suggestion GUI or not.
       showSuggestion = false;
       suggestedView = [];
       reason        = '';
       if h.EnableViewDomainMode & strcmp(h.SuggestionMode, 'show')
           % Get suggested view.
           [suggestedView reason] = h.getSuggestedView();
           if ~isempty(suggestedView)
               % Sometimes, may be during initial launch it appears empty?            
               if ~isempty(h.getActiveView)
                   % If views are different, make suggestion.
                   if ~strcmp(suggestedView.Name, h.ActiveView.Name)  
                       showSuggestion = true;
                   end
               end
           end
       end
       view_suggestion_panel.Visible        = showSuggestion ;
       if showSuggestion
           suggestion_info_icon.Type        = 'image';
           suggestion_info_icon.Tag         = 'suggestion_info_icon';
           suggestion_info_icon.ToolTip     = '';
           suggestion_info_icon.FilePath    = fullfile(matlabroot, 'toolbox', 'shared', 'dastudio', 'resources', 'info_suggestion.png');    
           suggestion_info_icon.RowSpan     = [1 1];
           suggestion_info_icon.ColSpan     = [1 1];
           
           suggestion_try_view.Type   = 'text';
           suggestion_try_view.Name   = DAStudio.message('modelexplorer:DAS:TryViewTip');
           suggestion_try_view.Tag    = 'suggestion_try_view';
           suggestion_try_view.RowSpan = [1 1];
           suggestion_try_view.ColSpan = [2 2];
           
           % Which view was suggested?
           suggestion_view.Type            = 'hyperlink';
           suggestion_view.Tag             = 'views_suggestion_link';
           suggestion_view.MatlabMethod    = 'feval';
           suggestion_view.MatlabArgs      = {@DAStudio.MEViewManager_cb, '%dialog', 'doSuggestion'};
           suggestion_view.RowSpan         = [1 1];
           suggestion_view.ColSpan         = [3 3];
           suggestion_view.Name            = suggestedView.Name;
           
           % Why the view was suggested?
           suggestion_view_reason.Type     = 'text';
           suggestion_view_reason.Tag      = 'views_suggestion_reason';
           suggestion_view_reason.RowSpan  = [1 1];
           suggestion_view_reason.ColSpan  = [4 4];
           suggestion_view_reason.Name = reason;
           
           suggestion_spacer.Type             = 'panel';
           suggestion_spacer.RowSpan          = [1 1];
           suggestion_spacer.ColSpan          = [5 5];
           
           suggestion_close_icon.Type          = 'pushbutton';
           suggestion_close_icon.Tag           = 'suggestion_close_button';
           suggestion_close_icon.MaximumSize   = [15 15];
           suggestion_close_icon.BackgroundColor = [255 255 225];
           suggestion_close_icon.Menu          = getViewSuggestionsMenu(h);
           suggestion_close_icon.Name          = '';
           suggestion_close_icon.ToolTip       = '';
           suggestion_close_icon.FilePath      = fullfile(matlabroot, 'toolbox', 'shared', 'dastudio', 'resources', 'down_arrow.png');
           suggestion_close_icon.Flat          = true;
           suggestion_close_icon.RowSpan       = [1 1];
           suggestion_close_icon.ColSpan       = [6 6];    
           
           view_suggestion_panel.BackgroundColor = [255 255 225];
           view_suggestion_panel.LayoutGrid      = [1 6];
           view_suggestion_panel.ColStretch      = [0 0 0 0 1 0];
           view_suggestion_panel.Items           = {suggestion_info_icon, suggestion_try_view, ...
                               suggestion_view, suggestion_view_reason, ...
                               suggestion_spacer, suggestion_close_icon};
       end
       
       %% top level UI specification dialog
       dlg.DialogTitle         = '';
       dlg.DialogTag           = 'me_view_manager_ui';
       dlg.EmbeddedButtonSet   = {''};
       dlg.IsScrollable        = false;
       dlg.Items               = {views_bar, content, view_suggestion_panel};
       end  % getEmbeddedDialogSchema
       
       

        %----------------------------------------
       function dlg = getExportImportDialogSchema(h, type)
       %
       
       
       exportType = false;
       if strcmp(type, 'export')
           exportType = true;
       end
       % Get all views which are currently with export-import manager.
       if exportType
           meViews = h.VMProxy.getAllViews;
       else
           meViews = h.VMProxy.BufferedViews;
       end
       
       selectedRow = 0;
       data = {};
       for i = 1:length(meViews)
           data{i, 1}.Type = 'checkbox';
           if exportType && ~isempty(h.VMProxy.BufferedViews)
               isSelected = findobj(h.VMProxy.BufferedViews, '-isa', 'DAStudio.MEView', ...
                                   'Name', meViews(i).Name);
               data{i, 1}.Value = ~isempty(isSelected);
               if ~isempty(isSelected)
                   selectedRow = i - 1;
               end
           else
               data{i, 1}.Value = true;
           end
           data{i, 2} = meViews(i).Name;
           data{i, 3} = meViews(i).Description;
       end
       
       exportImportTable.Type             = 'table';
       if exportType
           exportImportTable.Tag          = 'view_export_table';
       else
           exportImportTable.Tag          = 'view_import_table';
       end
       exportImportTable.Source           = h;
       exportImportTable.Graphical        = true;
       exportImportTable.Grid             = true;
       if exportType
           exportImportTable.ColHeader    = {DAStudio.message('modelexplorer:DAS:ExportID'), ...
                                               DAStudio.message('modelexplorer:DAS:ViewID'), ...
                                               DAStudio.message('modelexplorer:DAS:DescriptionID')};
       else
           exportImportTable.ColHeader    = {DAStudio.message('modelexplorer:DAS:ImportID'), ...
                                               DAStudio.message('modelexplorer:DAS:ViewID'), ...
                                               DAStudio.message('modelexplorer:DAS:DescriptionID')};
       end
       exportImportTable.HeaderVisibility = [0 1 1];
       exportImportTable.ReadOnlyColumns  = [1 2];
       exportImportTable.MultiSelect      = false;
       exportImportTable.Editable         = true;
       exportImportTable.Data             = data;
       exportImportTable.Size             = size(data);
       if exportType
           exportImportTable.ValueChangedCallback  = @onExportTableValueChanged;
       else
           exportImportTable.ValueChangedCallback  = @onImportTableValueChanged;
       end
       exportImportTable.RowSpan          = [1 1];
       exportImportTable.ColSpan          = [1 1];
       exportImportTable.SelectionBehavior= 'Row';
       exportImportTable.SelectedRow      = selectedRow;
               
       exportImportTablePanel.Type     = 'panel';
       exportImportTablePanel.Items    = {exportImportTable};
       exportImportTablePanel.LayoutGrid = [1 1];
       exportImportTablePanel.RowSpan    = [1 1];
       exportImportTablePanel.ColSpan    = [1 1];
       
       % TODO: Button bar and apply button.
       if exportType
           dlg.DialogTitle         = DAStudio.message('modelexplorer:DAS:ExportViewsID');
           dlg.DialogTag           = 'me_view_manager_export_dialog_ui';
           dlg.CloseCallback       = 'exportViewsCallback';    
       else
           dlg.DialogTitle         = DAStudio.message('modelexplorer:DAS:ImportViewsID');
           dlg.DialogTag           = 'me_view_manager_import_dialog_ui';
           dlg.CloseCallback       = 'importViewsCallback';
       end
       dlg.CloseArgs           = {h, '%closeaction'};
       dlg.StandaloneButtonSet = {'Ok', 'Cancel'};
       dlg.IsScrollable        = true;
       dlg.Items               = {exportImportTablePanel};
       dlg.DefaultOk           = false;
       dlg.Sticky              = true;
       end  % getExportImportDialogSchema
       
       
       % 
       % Handle changes in export dialog.
       %

        %----------------------------------------
       function factoryViews = getFactoryViews(h, name)
       % getFactoryViews
       % This method provides the fixed list of pre-defined views.
       
       
       factoryMap   = ...
       {...
           'Default',                  @getDefaultView
           'Data Objects',             @getDataObjectsView
           'Data Type Objects'         @getDataTypeObjectsView
           'Dictionary Objects'        @getDataDictionaryView 
           'Dictionary Other Data'     @getDataDictionaryOtherDataView
           'Block Data Types',         @getBlockDataTypesView
           'System I/O',               @getSystemIOView
           'Signals',                  @getSignalsView
           'Storage Class',            @getStorageClassView
           'Model Reference',          @getModelReferenceView
           'Stateflow',                @getStateflowView
           'Subsystem Code',           @getSubsystemCode
           'Configurations',           @getConfigurationsView
           'Files',                    @getFileView
       };    
       
       factoryViews = [];
       switch nargin
           case 2
               % Return the requested factory view
               index = find(strcmp(name, factoryMap(:, 1)),1);
               if ~isempty(index)
                   factoryViews = feval(factoryMap{index, 2}, h);
               end
               
           otherwise
               % Return all factory views
               for i = 1:length(factoryMap)
                   factoryViews = [factoryViews feval(factoryMap{i, 2}, h)]; %#ok<AGROW>
               end
       end
       end  % getFactoryViews
        
       
       
       %=====================================================================
       % FACTORY VIEW DEFINITIONS
       %=====================================================================

        %----------------------------------------
       function filename = getFileName(this)
       % getFileName
       % This method gives the views preference file
       % name.
       
       filename = this.PrefFileName;
       end  % getFileName
       
        %----------------------------------------
       function menu = getHeaderContextMenu(h, header)    

           if ~isempty(h.ActiveView) && isvalid(h.ActiveView)
               menu = h.ActiveView.getHeaderContextMenu(header);
           else
               menu = [];
           end

       end  % getHeaderContextMenu
       
        %----------------------------------------
       function labelInfo = getHeaderLabels(h)

           if ~isempty(h.ActiveView) && isvalid(h.ActiveView)
               labelInfo = h.ActiveView.getHeaderLabels();
           else  
               info = struct('name','Name', 'width', -1, 'icon', '');
               labelInfo = jsonencode(struct('columns', info));
           end

       end  % getHeaderLabels
       
        %----------------------------------------
       function acceptedColumns = getHeaderOrder(h, proposedColumns)     
           if ~isempty(h.ActiveView) && isvalid(h.ActiveView)
               acceptedColumns = h.ActiveView.getHeaderOrder(proposedColumns);
           else
               acceptedColumns = proposedColumns;
           end
       end  % getHeaderOrder
       
        %----------------------------------------
       function [view reason] = getSuggestedView(this)
       
       % Return suggestion. This is ViewManager's method. It will
       % check for its active domain and will ask MEViewDomain to
       % return an appropriate view.
       
       
       view = [];
       reason = '';
       if ~isempty(this.Domains)
           % Get domain info.
           domainInfo = findobj(this.Domains, 'Name', this.ActiveDomainName);
           if ~isempty(domainInfo)
               % Get domain's active view.
               [view reason] = domainInfo.getActiveView();
           end
       end
       end  % getSuggestedView
       
        %----------------------------------------
       function view = getView(h, viewName)
       %
       
       
       % Returns the view with the given name.
           
       view = findobj(h, '-isa', 'DAStudio.MEView', 'Name', viewName);
       
       end  % getView
       
        %----------------------------------------
       function importedViews = import(h, filename, conflictOption)
       %
       
       
       if nargin > 1
           filename = convertStringsToChars(filename);
       end
       
       importedViews = [];
       
       if exist(filename, 'file')
           try
               % Read from file
               readData = load(filename);
               meViewFields = fields(readData);
               if ~isempty(find(cellfun(@(x) contains(x,'meViews'), meViewFields) == 1, 1))
                   meViews  = readData.meViews;
                   for i = 1:length(meViews)
                       if ~isempty(meViews(i)) && ~isnumeric(meViews(i))
                           % Create view
                           view = DAStudio.MEView(meViews(i).Name, meViews(i).Description);
                           if ~isempty(meViews(i).Properties)
                               view.Properties = meViews(i).Properties;
                           end
                           % Take care of domains.
                           if ~isempty(meViews(i).Domain)
                               domainName = meViews(i).Domain;
                               % Create domain and make this view default view.
                               h.createDomain(domainName);                     
                           end            
                           if isempty(importedViews)
                               importedViews = view;
                           else
                               importedViews(end + 1) = view;
                           end
                       end
                   end        
               else
                   % disp(['Invalid view definition in file: ' filename]);
               end
           catch loadError                
               disp(['Unable to import: ' loadError.message]);        
           end
       end
       
       end  % import
       
        %----------------------------------------
       %
       %
       %
       function importViewsCallback(h, callbackArgs)
       
       
       if strcmp(callbackArgs, 'ok')
           viewsToImport = h.VMProxy.BufferedViews;
           for i = 1:length(viewsToImport)
               importedView = viewsToImport(i);
               view = findobj(h.VMProxy, '-isa','DAStudio.MEView','Name', importedView.Name);       
               if isempty(view)
                   % No conflict. Create a new one.
                    newView = DAStudio.MEView(importedView.Name, importedView.Description);            
               else
                   % Create a unique name. Start with Copy (%d) pattern.
                   count = 1;
                   while ~isempty(view)
                       newViewName = sprintf('%s (%d)', importedView.Name, count);
                       view = findobj(h.VMProxy, '-isa','DAStudio.MEView','Name', newViewName);
                       count = count + 1;
                   end
                   newView = DAStudio.MEView(newViewName, importedView.Description);            
               end
               h.VMProxy.addView(newView);
               % Do we need this?
               h.disableLiveliness;
               newView.Properties = importedView.Properties;            
               h.enableLiveliness;        
           end
           % Refresh dialog.        
           dlg = DAStudio.ToolRoot.getOpenDialogs(h);
       
           for i = 1:length(dlg)
              if strcmp(dlg(i).dialogTag, 'me_view_manager_dialog_ui')
                   dlg(i).refresh;
                   break;
              end
           end
       end
       end  % importViewsCallback
       
        %----------------------------------------
       function load(h)
       % load
       %
       % Load ModelExplorer views.
       %
       
       
       % remove any existing views w/o side effects
       h.disableLiveliness;
       delete(findobj(h, '-isa', 'DAStudio.MEView'));
       h.enableLiveliness;
       
       if ~exist(h.getFileName(), 'file')
           h.reset;
       else
           try
               % Read from file
               readData = load(h.getFileName);
               meViews  = readData.meViews;
               prevRelease = readData.viewsVersion(2:6); % e.g 2016b        
               % Construct views w/o side effects
               h.disableLiveliness;
               for i = 1:length(meViews)
                   % Create view
                   addDefaultName = false;
                   view = DAStudio.MEView(meViews(i).Name, meViews(i).Description);
                   % Since 18a, 'Name' is now a part of default views.
                   if numel(meViews(i).Properties) > 1
                       if ~strcmp(meViews(i).Properties(1).Name, 'Name')
                           addDefaultName = true;
                       end
                   else
                       if ~strcmp(meViews(i).Properties.Name, 'Name')
                           addDefaultName = true;
                       end
                   end
                   if addDefaultName
                       view.Properties = DAStudio.MEViewProperty('Name');
                       savedProperties = meViews(i).Properties;
                       for j = 1:numel(savedProperties)                    
                           propertySaved = savedProperties(j).Name;
                           if ~strcmp(propertySaved, 'Name')
                               view.Properties = [view.Properties; savedProperties(j)]; 
                           end
                       end
                   else
                       view.Properties = meViews(i).Properties;
                   end
                   % Take care of domains.
                   if ~isempty(meViews(i).Domain)
                       domainName = meViews(i).Domain;
                       % Create domain and make this view default view.
                       domain = h.createDomain(domainName);
                       % Make this view an active view for that domain.
                       domain.setActiveView(view);
                   end
                   % New addition in this release. If previous release, default values
                   % already set in constructor.
                   if strcmp(readData.viewsVersion,h.MATLABVersion)
                       view.GroupName = meViews(i).GroupName;
                       view.SortName = meViews(i).SortName;
                       view.SortOrder = meViews(i).SortOrder;            
                   end
                   
                   % Adjust reference migration, e.g, 'Argument' property is newly
                   % added in R2017a and is critical for model reference workflow.So if 
                   % old preference is dated before R2017a we should add back this column.
                   for garbage=1:1                    
                       tempFactoryView = h.getFactoryViews(view.Name);
                       if isempty(tempFactoryView)
                           break
                       end
                       if isempty(tempFactoryView.ReleaseChanges)
                           break
                       end
                       
                       % get the rules for preference migration
                       Deltas = jsondecode(tempFactoryView.ReleaseChanges);
                       releases = fieldnames(Deltas);
                       for relInd = 1:length(releases)
                           sinceRel = releases{relInd}; 
                           if loc_CompareRelease(prevRelease, sinceRel(2:6)) >= 0
                               continue;
                           end
                           
                           relRules = getfield(Deltas, sinceRel);
                           % Handle newly removed columns first
                           if isfield(relRules, 'Delete')
                               toDel = relRules.Delete;
                               colNames = view.Properties.get('Name');
                               indToDel = (ismember(colNames, toDel));
                               view.Properties(indToDel) = [];
                           end
                           % Handle newly added columns next
                           if isfield(relRules, 'Add')
                               % get column names of the view of preference
                               existedProps = cell(1, length(view.Properties));
                               for ind = 1:length(view.Properties)
                                   existedProps{ind} = view.Properties(ind).Name;
                               end                        
                               propsToAdd = setdiff(relRules.Add, existedProps); % ensure no duplicates due to additions
                               for newProp = propsToAdd
                                   view.Properties = [view.Properties; DAStudio.MEViewProperty(newProp{1})]; 
                               end
                           end
                           
                       end
                   end
                   % View construction completed. Give it to the view manager.
                   h.addView(view);
                   if isfield(meViews(i),'FilterTypes')
                       if isprop(view,'FilterTypes')
                           if ~isempty(meViews(i).FilterTypes)                                                
                               h.registerViewFilterTypes(view.Name, meViews(i).FilterTypes);                        
                           end
                       end
                   end                        
                   % Internal name
                   if ~isempty(meViews(i).InternalName)
                       view.InternalName = meViews(i).InternalName;
                   end                
               end
               h.enableLiveliness;
               if isempty(h.ActiveView)            
                   h.ActiveView = h.getSuggestedView();
                   % If domain stuff fails, just assign last view.
                   if isempty(h.ActiveView)
                       h.ActiveView = h.getView(readData.activeView);
                   end
               end
               % Set auto-suggest
               h.SuggestionMode = readData.suggestionMode;        
           catch ME
               % Default to factory views if the preferences are unavailable
               h.reset;
               disp(ME)
               MSLDiagnostic('modelexplorer:DAS:ErrorReadingViewDefinitions').reportAsWarning;
           end
       end
       end  % load
       
       
       %=====================================================================
       % HELPER SUBFUNCTIONS
       %=====================================================================

        %----------------------------------------
       function reset(h)
       % reset
       % Reset the view manager to its factory state overriding any preferences.
       %
       
       
       % remove any existing views and install the factory ones w/o side effects
       h.disableLiveliness;
       delete(findobj(h, '-isa', 'DAStudio.MEView'));
       factoryViews = h.getFactoryViews();
       for i = 1:length(factoryViews)
           h.addView(factoryViews(i));
           
       end
       h.enableLiveliness;
       
       % update the ActiveView. Use the first view by default. clients can change
       % the active view after the views have been loaded.
       h.ActiveView = findobj(h, '-isa', 'DAStudio.MEView', 'Name', 'Default');
       if isempty(h.ActiveView)
       h.ActiveView = factoryViews(1);
       end
       
       % save the new configuration to preferences
       h.save(h);
       
       end  % reset
       
        %----------------------------------------
       function resetView(h)
       %
       
       
           % reset the current view to its factory settings w/o side effects
           if ~isempty(h.getActiveView)        
               % If this is our factory view.
               if ~isempty(h.ActiveView.InternalName)
                   % insert the new view where the old view was        
                   oldView = h.ActiveView;
                   internalName = h.ActiveView.InternalName;
                   viewName = regexp(internalName, '_', 'split');
                   viewName = char(viewName(2));    
                   newView = h.getFactoryViews(viewName);
                   if ~isempty(newView)
                       h.disableLiveliness;
                       position = 'left';
                       viewPosition = [];            
                       if ~isempty(oldView.getPrevious) && isvalid(oldView.getPrevious)
                           viewPosition = oldView.getPrevious;                
                       elseif ~isempty(oldView.getNext) && isvalid(oldView.getNext)
                           viewPosition = oldView.getNext;
                           position = 'right';
                       end
                       % h.addView(newView);
                       oldView.delete;
                       if ~isempty(viewPosition) && isvalid(viewPosition)
                           if strcmp(position, 'left')
                               % newView.connect(viewPosition, position);
                               viewPosition.insertAfter(newView); 
                           elseif strcmp(position, 'right')
                               viewPosition.insertBefore(newView);
                           else % nothing here
                           end
                       else
                           addChildren(h, newView);
                       end
                       newView.ViewManager = h;
                       newView.enableLiveliness;
                       h.enableLiveliness;
                       h.setActiveView(newView);
                   end
               end
           end
       end  % resetView
           
       %----------------------------------------
       function save(h, viewsToSave, fileName)
       % save
       %
       % Save ModelExplorer views.
       %

           if nargin > 2
               fileName = convertStringsToChars(fileName);
           end
           
           if ~h.Serialize
               % If not to serialize, return.
               return;
           end
           
           views = [];
           
           switch nargin
               case 2
                   % Find all the views.
                   views = findobj(h, '-isa', 'DAStudio.MEView');
                   fileName = h.getFileName();
               case 3
                   views = viewsToSave;      
           end
           
           allDomains = h.Domains;
           
           % Start filling attributes.
           if ~isempty(views) && isa(views(1), 'DAStudio.MEView') && isvalid(views(1))
               for i = 1:length(views)
                   meViews(i).Name = views(i).Name; 
                   meViews(i).Domain = '';
                   meViews(i).Description = views(i).Description;
                   meViews(i).InternalName = '';
                   meViews(i).GroupName = '';
                   meViews(i).SortName = '';
                   meViews(i).SortOrder = '';
                   % fill domain name for this view if any.
                   for j = 1:length(allDomains)
                       domainActView = allDomains(j).getActiveView();
                       
                       if ~isempty(domainActView) && strcmp(domainActView.Name, views(i).Name)
                           meViews(i).Domain = allDomains(j).Name;
                       end
                   end
                   meViews(i).Properties = [];
                   if ~isempty(views(i).Properties)
                       meViews(i).Properties = findobj(views(i).Properties, 'isVisible', true);
                       meViews(i).GroupName = views(i).GroupName;
                       meViews(i).SortName = views(i).SortName;
                       meViews(i).SortOrder = views(i).SortOrder;        
                   end
                   if ~isempty(views(i).InternalName)
                       meViews(i).InternalName = views(i).InternalName;
                   end
                   if isprop(views(i),'FilterTypes')
                       if ~isempty(views(i).FilterTypes)
                           meViews(i).FilterTypes = views(i).FilterTypes;
                       end
                   end
               end
           end

           try
               % Save as meViews.
               save(fileName, 'meViews');
               % These are preferences if filename is same.
               if strcmp(h.getFileName, fileName)
                   % Save release version.
                   viewsVersion = h.MATLABVersion;
                   save(h.getFileName(), 'viewsVersion', '-append');
                   % Save active view.
                   if ~isempty(h.ActiveView)
                       activeView = h.ActiveView.Name;
                   else
                       if ~isempty(views)
                           activeView = views(1).Name;
                       end
                   end
                   save(h.getFileName(), 'activeView', '-append');
                   % Save suggestions settings.
                   suggestionMode = h.SuggestionMode;
                   save(h.getFileName(), 'suggestionMode', '-append');
               end
           catch ME    
               MSLDiagnostic('modelexplorer:DAS:ErrorWritingViewDefinitions').reportAsWarning;
           end
       
       end  % save
       
        %----------------------------------------
       function setActiveView(h, view)
       
       %
       % setActiveView
       %
       % Sets the given view as the active view of the view manager.
       
       
       % Sets the given view as an active view.
       if ~isempty(view) && ~isempty(h) && isa(view, 'DAStudio.MEView')
           % Check valid view names and if it already exists or not.
           v = findobj(h, '-isa', 'DAStudio.MEView', 'Name', view.Name);
           if ~isempty(v) && h.ActiveView ~= v
               h.ActiveView = v;
           end
       end
       
       end  % setActiveView
       
        %----------------------------------------
       function setFileName(this, filename)
       % setFileName
       % 
       % Set external file name.
       
       
       this.ExternalFilename = filename;
       end  % setFileName
       
        %----------------------------------------
       function show = shouldShow(h, obj)
       %
       
       show = true;
       
       end  % shouldShow
       
        %----------------------------------------
       function viewManagerDialogCallback(h, callbackArgs)
       %
       
       if strcmp(callbackArgs, 'ok')
       %     message = sprintf('Do you want to reset this view to it''s factory settings?');
       %     message = sprintf('%s \n\n Yes - resets this view to it''s factory settings.', message);
       %     message = sprintf('%s \n No - do not reset this view to factory settings.', message);
       %     dp = DAStudio.DialogProvider;
       %     dp.questdlg(message, 'Close - Warning',{'Yes', 'No'}, 'No', {@viewChangesCallback, h});
           applyChanges(h);
       end
       end  % viewManagerDialogCallback
       
       
       
       %
       % Reset single or all views to factory settings.
       %

end  % possibly private or hidden 

end  % classdef

function syncUI(~, event)
    % Keep domain in sync
    % Set domain active view here. Get domain first.
    
    manager = event.AffectedObject;
    % domain = find(manager.Domains, 'Name', manager.ActiveDomainName);
    domain = findobj(manager.Domains, 'Name', manager.ActiveDomainName);
    
    % Get active domain view first.
    domainView = domain.getActiveView();
    % If it is not already selected, Make it active view for that domain.
    activeView = manager.ActiveView;
    if isempty(domainView) || (~isempty(activeView) && ~strcmp(domainView.Name, activeView.Name))
        domainView = manager.ActiveView;
    end
    domain.setActiveView(domainView);        
    % Clear transient properties if any.
    clearTransientProperties(domainView);
    % Set group property if any
    if (~isempty(domainView))
        manager.Explorer.GroupColumn = domainView.GroupName;
        manager.Explorer.SortColumn = domainView.SortName;
        if ~isempty(domainView.SortOrder)
            manager.Explorer.SortOrder = domainView.SortOrder;
        else
            manager.Explorer.SortOrder = 'Asc';
        end
    end
    % refresh the ME
    ed = DAStudio.EventDispatcher;
    ed.broadcastEvent('ListChangedEvent');
end  % syncUI

function syncMEViewManager(~, eventData)

    switch eventData.EventName
      case {'ObjectChildAdded', 'ObjectChildRemoved'}
        manager = eventData.Source;
        
      case 'PostSet'
        manager = eventData.AffectedObject;
        
      otherwise
        DAStudio.error('modelexplorer:DAS:UnknownEventType');
    end
    manager.refresh;
end  % syncMEViewManager



%
% Handle ME UI events.
%
function syncMEViewManagerFromME(~, eventData, manager)

switch eventData.Type
  case 'MEListSelectionChanged'
    doListSelectionChanged(eventData, manager);        
  case 'MEViewModeChanged'   
    doViewModeChanged(eventData, manager);    
  case 'MESearchPropertiesAdded'
    doSearchPropertiesAdded(eventData, manager);        
  case 'MESortChanged'
    doSortChanged(eventData, manager);       
  case 'MEScopeChanged'
    doScopeChanged(eventData, manager);      
  case 'MEHeaderSizeChanged'
    doHeaderSizeChanged(eventData, manager);
  otherwise
    DAStudio.error('modelexplorer:DAS:UnknownEventType');
end
end  % syncMEViewManagerFromME


%
% Model explorer is closed or deleted. Write views
% and close any open dialogs or do other cleanup.
%
function modelExplorerClosed(~, ~, manager)
managerUI = DAStudio.ToolRoot.getOpenDialogs(manager);

for i = 1:length(managerUI)
    if strcmp(managerUI(i).dialogTag, 'me_view_manager_view_details')
        delete(managerUI(i));
    end
end

% Save manager data
manager.save(manager);
% Delete the standalone dialog.
dlg = DAStudio.ToolRoot.getOpenDialogs(manager);
for i = 1:length(dlg)
    if ~strcmp(dlg(i).dialogTag, 'me_view_manager_ui')
        dlg(i).delete;       
    end
end
if ~isempty(manager.Timer)
    manager.Timer.stop;
end
end  % modelExplorerClosed


%
% ModelExplorer list selection changed
%
function doListSelectionChanged(eventData, manager)

if ~manager.IsCollapsed
    % TODO: Refresh it only if option in Property-Scope combo is
    % 'Selected Objects in Spreadsheet/2'.
    manager.refresh;
end
end  % doListSelectionChanged


%
% ModelExploer view mode changed
%
function doViewModeChanged(~, manager)

dlg = DAStudio.ToolRoot.getOpenDialogs(manager);
exp = manager.Explorer;
for i = 1:length(dlg)
    if strcmp(dlg(i).dialogTag, 'me_view_manager_ui')
        if strcmp(exp.ViewMode,'Content')
            dlg(i).setVisible('views_details_link', true);  
        else
            dlg(i).setVisible('views_details_link', false);  
        end
        break;
    end
end
% If view mode is search, add transient 'Path' property if not
% there already.    
actView = manager.ActiveView;
if strcmpi(exp.ViewMode, 'Search')
    % Add Path as first property.
    property = DAStudio.MEViewProperty('Path');
    property.isTransient = true;
    DAStudio.MEView_cb([], 'doAddProperty', actView, {property}, 'prepend');
else
    % Remove existing transient properties
    clearTransientProperties(actView);
end
exp.GroupColumn = actView.GroupName;
end  % doViewModeChanged


%
% ModelExplorer search properties added
%
function doSearchPropertiesAdded(eventData, manager)
% Add any properties as transient properties
propsToAdd = eventData.EventData;
if ~isempty(propsToAdd)
    exp = manager.Explorer;
    if strcmpi(exp.ViewMode, 'Search')
        % Remove this special property.
        index = strmatch('Name', propsToAdd, 'exact');
        if ~isempty(index)
            propsToAdd(index) = [];
        end
        actView = manager.ActiveView;
        % No need to do anything is everything is same. This does
        % not allow any change if search is execute again for any 
        % action.
        if ~isempty(actView.Properties)
            t = get(findobj(actView.Properties, 'isTransient', true), 'Name');
            p = propsToAdd;
            % Add path first
            p{end+1} = 'Path';
            if isequal(sort(t), sort(p))
                return;
            end
        end
        % Remove existing transient properties
        clearTransientProperties(actView);
        actView.disableLiveliness;
        % Add Path as first property.
        property = DAStudio.MEViewProperty('Path');
        property.isTransient = true;
        DAStudio.MEView_cb([], 'doAddProperty', actView, {property}, 'prepend');
        property = cell(length(propsToAdd), 1);
        for i = 1:length(propsToAdd)
            propToAdd = char(propsToAdd{i});
            property{i} = DAStudio.MEViewProperty(propToAdd);
            property{i}.isTransient = true;
        end
        DAStudio.MEView_cb([], 'doAddProperty', actView, property, 'append');
        actView.enableLiveliness;                
    end
end
end  % doSearchPropertiesAdded



%
% ModelExplorer sort order changed
%
function doSortChanged(eventData, manager)
sortInfo = eventData.EventData;
% Update sort info for current view
actView = manager.ActiveView;
actView.SortName = char(sortInfo(1));
actView.SortOrder = char(sortInfo(2));
manager.refresh;
end  % doSortChanged


%
% ModelExplorer scope changed
%
function doScopeChanged(~, manager)
dlg = DAStudio.ToolRoot.getOpenDialogs(manager);
for i = 1:length(dlg)
    if strcmp(dlg(i).dialogTag, 'me_view_manager_ui')
       dlg(i).setWidgetValue('views_details_link', ...
           DAStudio.message('modelexplorer:DAS:LoadingDotDotDot'));
       break;
    end
end
end  % doScopeChanged


%
% ModelExplorer header size changed
%
function doHeaderSizeChanged(eventData, manager)
headerInfo = eventData.EventData;
% Update sort info for current view
actView = manager.ActiveView;
actView.setHeaderWidth(headerInfo);
end  % doHeaderSizeChanged


%
% Utility function to clear transient properties
%
function clearTransientProperties(view)
    % Clear transient properties
    if isa(view, 'DAStudio.MEView') && ~isempty(view.Properties)
        transProps = findobj(view.Properties, 'isTransient', true);
        if ~isempty(transProps)
            view.disableLiveliness;
            allProps = get(view.Properties, 'Name');
            for i = 1:length(transProps)
                index = find(strcmp(transProps(i).Name, allProps) == 1);
                if ~isempty(index)
                    % If it was a group property remove it. 
                    if strcmp(view.Properties(index).Name, view.GroupName)
                        view.GroupName = '';
                    end
                    view.Properties(index) = [];
                end
                allProps = get(view.Properties, 'Name');
            end
            view.enableLiveliness;
        end
    end
end  % clearTransientProperties


function settingsStr = calculateSettingsString(manager)
settingsStr = '';
if ishandle(manager.Explorer)
    actionArr = {'VIEW_SHOWMASKEDSUBSYSTEMS', DAStudio.message('modelexplorer:DAS:MaskedSubsystemsID'); ...                     
                 'VIEW_SHOWLINKEDSUBSYSTEMS', DAStudio.message('modelexplorer:DAS:LibraryLinksID'); ...                     
                 'NEWLINESEPARATOR', '\n'; ...
                 'VIEW_SLCONTAINERS', ''; ...
                 'VIEW_SLBLOCKS', ''; ...
                 'VIEW_SLNAMEDLINES', ''; ...
                 'VIEW_SLLINES', ''; ...
                 'VIEW_SLANNOTATIONS', ''; ...
                 'NEWLINESEPARATOR', '\n';
                 'VIEW_SFCONTAINERS', ''; ...
                 'VIEW_SFSTATES', ''; ...
                 'VIEW_SFTRANSITIONS', ''; ...
                 'VIEW_SFJUNCTIONS', ''; ...
                 'VIEW_SFEVENTS', ''; ...
                 'VIEW_DATA', '';};
    
    outStr = '';
    ac = DAStudio.ActionManager;
    for i = 1:length(actionArr)
        action = [];
        if strcmp(char(actionArr{i,1}), 'NEWLINESEPARATOR')
            if ~isempty(outStr)
                settingsStr = sprintf('%s\n   %s', settingsStr, outStr);
                outStr = '';
            end
        else
            action = ac.createDefaultAction(manager.Explorer, char(actionArr{i,1}));
        end
        if ~isempty(action) && strcmp(action.on, 'off')                              
            if isempty(char(actionArr{i,2}))
                text = strrep(action.text, '&','');
            else
                text = char(actionArr{i,2});
            end
            if isempty(outStr) && ~strcmp(text,'\n')
                outStr = sprintf('%s', text);
            else                    
                outStr = sprintf('%s, %s', outStr, text);                    
            end
        end
    end
    if ~isempty(outStr)
        settingsStr = sprintf('%s\n   %s', settingsStr, outStr);
    end
    % Set none if nothing is there
    if isempty(settingsStr)
        settingsStr = DAStudio.message('modelexplorer:DAS:NoneID');
    end
end
end  % calculateSettingsString


function [names index] = calculateInstalledViews(h)
    views = h.getAllViews;
    names = get(views, 'Name');
    if ~iscell(names)
        names = {names};    
    end
    
    index = -1;
    
    if ~isempty(h.getActiveView)
        index = find(views == h.ActiveView) - 1;
    end
end  % calculateInstalledViews



function fPropsStr = calculateFilterPropertiesString(h)

fPropsStr = '';

if ~isempty(h.getActiveView)
    fProps = [];
    if ~isempty(h.ActiveView.Properties)
        fProps = get(findobj(h.ActiveView.Properties, 'isMatching', true), 'Name');
    end
    
    if isempty(fProps)
        return;
    end
    
    if ischar(fProps)
        fPropsStr = fProps;
    else
        fPropsStr = fProps{1};
        for i = 2:length(fProps)
            fPropsStr = [fPropsStr ' OR ' fProps{i}];
        end
    end
end
end  % calculateFilterPropertiesString


%
% Count possible and visible number of objects in listview.
%
function [visible possible] = countObjectsInView(h)
visible  = 0;
possible = 0;
if ishandle(h.Explorer)
    imme = DAStudio.imExplorer(h.Explorer);
    [visible possible] = imme.countListViewNodes;
    imme.delete;
end
end  % countObjectsInView


%
% Create menu - Filters
%
function menu = getFilterOptionsMenu(manager)
% Generate only once. This is a static menu.
if isempty(findprop(manager, 'FilterOptionsMenu'))
    p = addprop(manager, 'FilterOptionsMenu');
    p.Hidden = true;    
    % Get model explorer
    me = manager.Explorer;
    % Create action manager
    am  = DAStudio.ActionManager;
    % Filter options menu
    manager.FilterOptionsMenu = am.createPopupMenu(me);
    % Get default actions from ModelExplorer
    % Create and return View Manager's filter menu
    menu = manager.FilterOptionsMenu;
    menu.addMenuItem(am.createDefaultAction(me, 'VIEW_ALLSLOBJECTS'));
    menu.addMenuItem(am.createDefaultAction(me, 'VIEW_SLCONTAINERS'));
    menu.addMenuItem(am.createDefaultAction(me, 'VIEW_SLBLOCKS'));
    menu.addMenuItem(am.createDefaultAction(me, 'VIEW_SLNAMEDLINES'));
    menu.addMenuItem(am.createDefaultAction(me, 'VIEW_SLLINES'));
    menu.addMenuItem(am.createDefaultAction(me, 'VIEW_SLANNOTATIONS'));
    menu.addSeparator();
    menu.addMenuItem(am.createDefaultAction(me, 'VIEW_ALLSFOBJECTS'));
    menu.addMenuItem(am.createDefaultAction(me, 'VIEW_SFCONTAINERS'));
    menu.addMenuItem(am.createDefaultAction(me, 'VIEW_SFSTATES'));
    menu.addMenuItem(am.createDefaultAction(me, 'VIEW_SFTRANSITIONS'));
    menu.addMenuItem(am.createDefaultAction(me, 'VIEW_SFJUNCTIONS'));
    menu.addMenuItem(am.createDefaultAction(me, 'VIEW_SFEVENTS'));
    menu.addMenuItem(am.createDefaultAction(me, 'VIEW_DATA'));
end
menu = manager.FilterOptionsMenu;
end  % getFilterOptionsMenu



%
% Create menu on Filter Options.
%
function menu = getViewSuggestionsMenu(manager)

% Hold on to the allocated menu per MEViewManager instance
if isempty(findprop(manager, 'SuggestionsMenu'))
    p = addprop(manager,'SuggestionsMenu');
end

% Clean up any previously allocated menu along with its actions
if ~isempty(manager.SuggestionsMenu) && isobject(manager.SuggestionsMenu)
    delete(manager.SuggestionsMenu.getChildren);
    delete(manager.SuggestionsMenu);
    manager.SuggestionsMenu = [];
end

am   = DAStudio.ActionManager;
menu = am.createPopupMenu(manager.Explorer);

action = am.createAction(manager.Explorer);
action.Tag      = 'suggestion_option_hide';
action.text     = DAStudio.message('modelexplorer:DAS:HideSuggestion');
action.callback = ['DAStudio.MEViewManager_action_cb(' num2str(action.id) ')'];
action = addCallbackData(action, {'hideSuggestion', manager});        
menu.addMenuItem(action);        
menu.addSeparator();

action = am.createAction(manager.Explorer);        
action.Tag      = 'suggestion_option_hide_and_apply';
action.text     = DAStudio.message('modelexplorer:DAS:HideAndApplySuggestions');
action.callback = ['DAStudio.MEViewManager_action_cb(' num2str(action.id) ')'];
action.toggleAction = 'on';
if strcmp(manager.SuggestionMode, 'auto')
    action.on = 'on';
else
    action.on = 'off';
end
action = addCallbackData(action, {'hideApplySuggestions', manager});
menu.addMenuItem(action);

menu.addSeparator();

action = am.createAction(manager.Explorer);
action.Tag      = 'suggestion_whatis_this';
action.text     = 'What''s This?';
action.callback = ['DAStudio.MEViewManager_action_cb(' num2str(action.id) ')'];
action = addCallbackData(action, {'suggestionsWhatIsThis', manager});
menu.addMenuItem(action);

manager.SuggestionsMenu = menu;
end  % getViewSuggestionsMenu


%
% TODO: Why addCallbackData in pvt folder not being called?
%
function action = addCallbackData(action, data)
addprop(action, 'callbackData');
action.callbackData = data;
end  % addCallbackData

function onExportTableValueChanged(dlg, r, ~, value)

h = dlg.getSource();
export    = dlg.getTableItemValue('view_export_table', r, 0);
viewName  = dlg.getTableItemValue('view_export_table', r, 1);

if strcmp(export, '0')
    % Remove it from the list.
    view = findobj(h.VMProxy.BufferedViews, '-isa','DAStudio.MEView', 'Name', viewName);
    if ~isempty(view)
        for i=1:length(h.VMProxy.BufferedViews)
            if strcmp(h.VMProxy.BufferedViews(i).Name, viewName)
                h.VMProxy.BufferedViews(i) = [];
                break;
            end
        end
    end
else
    % Add it in the list.
    if ~isempty(h.VMProxy.BufferedViews)
        view = h.VMProxy.getView(viewName);
        if ~isempty(view)            
            h.VMProxy.BufferedViews = [h.VMProxy.BufferedViews; view;];
        end
    else
        h.VMProxy.BufferedViews = h.VMProxy.getView(viewName);
    end
end
end  % onExportTableValueChanged


%
% Handle changes in import dialog.
%
function onImportTableValueChanged(dlg, r, ~, value)
h = dlg.getSource();
import    = dlg.getTableItemValue('view_import_table', r, 0);
viewName  = dlg.getTableItemValue('view_import_table', r, 1);

if strcmp(import, '0')
    % Remove it from the list.
    view = findobj(h.VMProxy.BufferedViews, '-isa','DAStudio.MEView', 'Name', viewName);
    if ~isempty(view)
        for i=1:length(h.VMProxy.BufferedViews)
            if strcmp(h.VMProxy.BufferedViews(i).Name, viewName)
                h.VMProxy.BufferedViews(i) = [];
                break;
            end
        end
    end
else
    if ~isempty(h.VMProxy.BufferedViews)
        % Add it in the list.
        view = findobj(h.VMProxy.BufferedViews, '-isa','DAStudio.MEView', 'Name', viewName);
        if ~isempty(view)
            % Add at correct location
            h.VMProxy.BufferedViews = [h.VMProxy.BufferedViews(1:r); view; h.VMProxy.BufferedViews(r+1:end)];
        end
    else
        h.VMProxy.BufferedViews = findobj(h.VMProxy, '-isa', 'DAStudio.MEView', 'Name', viewName);
    end
end
end  % onImportTableValueChanged
function viewDef = getDefaultView(h)

viewDef = l_CreateView(h, ...
    'Default', ...
    {...
        'Name'
        'BlockType'
    }, ...
    '', ...
    'Generic view - select "Show Details" to add properties' ...
    );
end  % getDefaultView


%=====================================================================
function columns = getDataObjectViewColumns()

columns = {'Value'
           'DataType'
           'Dimensions'
           'Complexity'
           'Min'
           'Max'
           'Unit'
           'Argument'
           'StorageClass'};
end  % getDataObjectViewColumns


%=====================================================================
function viewDef = getDataObjectsView(h)

props = ['Name'; getDataObjectViewColumns()];

% After R2018a we should stop tweaking it
delta = struct();
delta.R2017a.Add = {'Argument'};

releaseChanges = jsonencode(delta);
viewDef = l_CreateView(h, ...
                       'Data Objects', ...
                       props, ...
                       releaseChanges, ...
                       'Show common properties for data objects and workspace variables' ...
                       );
end  % getDataObjectsView

%=====================================================================
function viewDef = getDataTypeObjectsView(h)

viewDef = l_CreateView(h, ...
    'Data Type Objects', ...
    {...
        'Name'
        'DataTypeMode'
        'Signedness'
        'WordLength'
        'FractionLength'
        'Slope'
        'Bias'
        'IsAlias'
        'HeaderFile'
        'BaseType'
        'DataTypeOverride'
     }, ...
    '', ...
    'Show common properties for data type objects' ...
);
end  % getDataTypeObjectsView


%=====================================================================
function viewDef = getDataDictionaryView(h)

% Data Dictionary View has the same columns sets as the data object 
% view, with additional dictionary-specific columns.
props = getDataObjectViewColumns();
props = ['Name'; 'Status'; props; 'DataSource'; 'LastModified'; 'LastModifiedBy'];

viewDef = l_CreateView(h, ...
                       'Dictionary Objects', ...
                       props, ...
                       '', ...
                       'Show common properties for data objects and variables in dictionaries' ...
                       );
end  % getDataDictionaryView


function viewDef = getSimulinkFunctionView(h)

props = {'Prototype';'Source'};
viewDef = l_CreateView(h, ...
                       'Functions', ...
                       props, ...
                       '', ...
                       'Show available Simulink Functions' ...
                       );
end  % getSimulinkFunctionView


function viewDef = getSimulinkFunctionTypeView(h)

props = {'Name';'Prototype';'Source'};
viewDef = l_CreateView(h, ...
                       'Function Types', ...
                       props, ...
                       '', ...
                       'Show available Simulink Function Types' ...
                       );
end  % getSimulinkFunctionTypeView


%=====================================================================
function viewDef = getDataDictionaryOtherDataView(h)

viewDef = l_CreateView(h, ...
    'Dictionary Other Data', ...
    {...
        'Name'
        'Status'
        'DataSource'
        'LastModified'
        'LastModifiedBy'
    }, ...
    '',  ...
    'Show properties for user-defined data objects in dictionaries' ...
);
end  % getDataDictionaryOtherDataView


%=====================================================================
function viewDef = getBlockDataTypesView(h)

viewDef = l_CreateView(h, ...
    'Block Data Types', ...
    {...
        'Name'
        'BlockType'
        'OutDataTypeStr'
        'OutMin'
        'OutMax'
        'LockScale'
        'DataType'
        'Min'
        'Max'
        'AccumDataTypeStr'
        'ParamDataTypeStr'
        'ParamMin'
        'ParamMax'                
    }, ...
    '', ...
    'Show properties related to setting block data types' ...
);
end  % getBlockDataTypesView


%=====================================================================
function viewDef = getSystemIOView(h)

viewDef = l_CreateView(h, ...
    'System I/O', ...
    {...
        'Name'
        'BlockType'
        'Port'
        'OutDataTypeStr'
        'LockScale'
        'OutMin'
        'OutMax'
        'PortDimensions'
        'Unit'
        'SampleTime'
        'SignalType'
        'IconDisplay'
        'InitialOutput'
        'OutputWhenDisabled'
    }, ...
    '', ...
    'Show properties of Inport/Outport blocks' ...
);
end  % getSystemIOView



%=====================================================================
function viewDef = getSignalsView(h)


props = {
    'Name'
    'SourcePort'
    'SignalPropagation'
    'MustResolveToSignalObject'
    'DataLogging'
    'TestPoint'
    'SignalObjectClass'
    'StorageClass'
};

viewDef = l_CreateView(h, ...
    'Signals', ...
    props, ...
    '', ...
    'Show properties of signals' ...
);
end  % getSignalsView


%=====================================================================
function viewDef = getStorageClassView(h)

% Based on feature control, determine what property name to get.
propertyName = 'CoderInfo.Identifier';

props = {
    'Name'
    propertyName
    'StorageClass'
    'HeaderFile'
    'CoderInfo.CustomAttributes.StructName'
    'CoderInfo.CustomAttributes.Latching'
    'CoderInfo.CustomAttributes.GetFunction'
    'CoderInfo.CustomAttributes.SetFunction'
    'CoderInfo.CustomAttributes.MemorySection'
    'CoderInfo.CustomAttributes.Owner'
    'CoderInfo.CustomAttributes.DefinitionFile'
    'CoderInfo.CustomAttributes.PersistenceLevel'
};

if (slfeature('LatchingViaCSCs') < 1)
    props(6) = [];
end

viewDef = l_CreateView(h, ...
    'Storage Class', ...
    props, ...
    '', ...
    'Show properties for configuring appearance of data in generated code' ...
  );
end  % getStorageClassView


%=====================================================================
function viewDef = getModelReferenceView(h)
delta = struct();
delta.R2017b.Delete = {'ParameterArgumentNames', 'ParameterArgumentValues'};
relChanges = jsonencode(delta);

viewDef = l_CreateView(h, ...
    'Model Reference', ...
    {...
        'Name'
        'BlockType'
        'ModelName'
        'SimulationMode'
    }, ...
    relChanges, ...
    'Show properties for model reference blocks' ...
);
end  % getModelReferenceView


%=====================================================================
function viewDef = getStateflowView(h)

viewDef = l_CreateView(h, ...
    'Stateflow', ...
    {...
        'Name'
        'Scope'
        'Port'
        'Props.ResolveToSignalObject'
        'DataType'
        'Props.Array.Size'
        'Props.InitialValue'
        'CompiledType'
        'CompiledSize'
        'Trigger'
    }, ...
    '', ...
    'Show properties for Stateflow data and events' ...
);
end  % getStateflowView


%=====================================================================
function viewDef = getSubsystemCode(h)

viewDef = l_CreateView(h, ...
    'Subsystem Code', ...
    {...
        'Name'
        'BlockType'
        'TreatAsAtomicUnit'
        'SystemSampleTime'
        'RTWSystemCode'
        'RTWFcnNameOpts'
        'RTWFcnName'
        'RTWFileNameOpts'
        'FunctionWithSeparateData'
        'RTWMemSecFuncInitTerm'
        'RTWMemSecFuncExecute'
        'RTWMemSecDataConstants'
        'RTWMemSecDataInternal'
        'RTWMemSecDataParameters'
    }, ...
    '', ...
    'Show SubSystem block code generation properties' ...
);
end  % getSubsystemCode


%=====================================================================
function viewDef = getConfigurationsView(h)

viewDef = l_CreateView(h, ...
    'Configurations', ...
    {...
        'Name'
        'Description'
    }, ...
    '', ...
    'Show properties of configurations' ...
);
end  % getConfigurationsView


%=====================================================================
function viewDef = getFileView(h)

viewDef = l_CreateView(h, ...
                       'Files', ...
                       {...
                           'Name'
                           'Dirty'
                           'LastSaved'
                           'Created'
                           'FileName'
                       }, ...
                       '', ...
                       'Show properties for files' ...
                       );
end  % getFileView


%=====================================================================
% HELPER SUBFUNCTIONS
%=====================================================================
function viewDef = l_CreateView(h, name, props, ReleaseChanges, desc)
% ReleaseChanges is a json map of 3 levels, corresponding to Matlab release, action(add or delete),
% and the column names
viewDef = DAStudio.MEView(name, desc);
viewDef.ReleaseChanges = ReleaseChanges;
for idx = 1:size(props,1)
  thisProp = props{idx};
  if (idx == 1)
    viewDef.Properties = DAStudio.MEViewProperty(thisProp);
  else
    % viewDef.Properties(idx) = DAStudio.MEViewProperty(thisProp);
    viewDef.Properties = [viewDef.Properties; DAStudio.MEViewProperty(thisProp)];
  end
end
viewDef.IsFactoryView = true;
h.addInternalName(viewDef);
end  % l_CreateView

    

function onTableCurrentChanged(dlg, ~, ~)
    % Enable disable buttons
    DAStudio.MEViewManager_cb(dlg, 'doEnableDisableButtons');
end  % onTableCurrentChanged


%
% Handle changes in view management dialog
%
function onTableValueChanged(dlg, r, c, ~)
    h = dlg.getSource();
    
    viewName  = dlg.getTableItemValue('view_manager_table', r, 0);
    viewDesc  = dlg.getTableItemValue('view_manager_table', r, 1);
    
    % Validate rename if any change in view name, description is ok.
    if c == 0
        ignoreChange = isempty(strtrim(viewName));
        if ignoreChange == false
            oldView = h.VMProxy.getView(viewName);
            if isempty(oldView)
                allViews = h.VMProxy.getAllViews;
                % TODO: Reordering of views might change this logic.
                view = allViews(r+1);
                if ~isempty(view)            
                    % If this was active view, change it
                    if ~isempty(h.VMProxy.getActiveView)
                        if strcmp(view.Name, h.VMProxy.ActiveView.Name)
                            h.VMProxy.ActiveView = view;
                        end
                    end
                    % This will no more be an internal factory view.
                    if ~isempty(view.InternalName)
                        view.InternalName = '';
                    end
                    view.Name = viewName;
                end
            else
                ignoreChange = true;
            end
        end
        % Ignore any change
        if ignoreChange
            allViews = h.VMProxy.getAllViews;
            % TODO: Reordering of views might change this logic.
            view = allViews(r+1);
            dlg.setTableItemValue('view_manager_table', r, 0, view.Name);
        end
    else
        allViews = h.VMProxy.getAllViews;
        view = allViews(r+1);
        if ~isempty(view)            
            view.Description = viewDesc;    
        end
    end
end  % onTableValueChanged


%
% Key press event on table
%
function onTableKeyPress(dlg, tag, key)
    % Process only del key
    if strcmp(tag, 'view_manager_table') && strcmp(key, 'Del')    
        DAStudio.MEViewManager_cb(dlg, 'doDeleteView');    
    end
end  % onTableKeyPress
    
%
% Create menu on options button in view management dialog.
%
function menu = getManageOptionsMenu(manager)

    % Hold on to the allocated menu per MEViewManager instance
    if isempty(findprop(manager, 'StandaloneOptionsMenu'))
        p = addprop(manager, 'StandaloneOptionsMenu');
    end

    % Clean up any previously allocated menu along with its actions
    if ~isempty(manager.StandaloneOptionsMenu) && isobject(manager.StandaloneOptionsMenu)
        delete(manager.StandaloneOptionsMenu.getChildren);
        delete(manager.StandaloneOptionsMenu);
        manager.StandaloneOptionsMenu = [];
    end

    am   = DAStudio.ActionManager;
    menu = am.createPopupMenu(manager.Explorer);
    
    if manager.EnableViewDomainMode
        action = am.createAction(manager.Explorer);
        action.Tag      = 'manage_options_hide_and_apply';
        action.text     = DAStudio.message('modelexplorer:DAS:HideAndApplySuggestions');
        action.toggleAction = 'on';
        if strcmp(manager.SuggestionMode, 'auto')
            action.on = 'on';
        else
            action.on = 'off';
        end
        action = addCallbackData(action, {'hideApplySuggestions', manager.VMProxy});
        action.callback = ['DAStudio.MEViewManager_action_cb(' num2str(action.id) ')'];
        if ~manager.EnableViewDomainMode
            action.visible = 'off';
        end
        menu.addMenuItem(action);
        menu.addSeparator();
    end

    action = am.createAction(manager.Explorer);
    action.Tag      = 'manage_options_resetAll';
    action.text     = DAStudio.message('modelexplorer:DAS:ResetAllToFactoryDotDotDot');
    action.callback = ['DAStudio.MEViewManager_action_cb(' num2str(action.id) ')'];
    action = addCallbackData(action, {'resetAllToFactory', manager});
    menu.addMenuItem(action);

    manager.StandaloneOptionsMenu = menu;
end  % getManageOptionsMenu
        
%
% TODO: Why addCallbackData in pvt folder not being called?
%
%{
function action = addCallbackData(action, data)

schema.prop(action, 'callbackData', 'mxArray');
action.callbackData = data;
end  % addCallbackData
%}

function result = loc_CompareRelease(rel1, rel2)
    % if rel1 predates rel2, return -1; if rel1 is same as rel2 return 0; else, return 1
    year1 = str2double(rel1(1:4));
    year2 = str2double(rel2(1:4));
    if year1 < year2
        result = -1;
    elseif year1 > year2
        result = 1;
    else
        minor1 = rel1(5);
        minor2 = rel2(5);
        if minor1 < minor2
            result = -1;
        elseif minor1 == minor2
            result = 0;
        else
            result = 1;
        end
    end
end  % loc_CompareRelease

        
function viewChangesCallback(h, proceed)
    if strcmp(proceed, 'Yes')    
        applyChanges(h);
    end
    % Clear it.
    h.VMProxy = [];
end  % viewChangesCallback
 
function applyChanges(h)
    h.disableLiveliness;
    activeViewName = '';
    if isa(h.VMProxy.ActiveView, 'DAStudio.MEView') && isvalid(h.VMProxy.ActiveView)
        activeViewName = h.VMProxy.ActiveView.Name;
    end
    % Replace everything from Proxy view manager.
    delete(findobj(h, '-isa', 'DAStudio.MEView'));
    h.ActiveView = [];
    activeView = [];
    % Get views from proxy.
    allViews = findobj(h.VMProxy, '-isa', 'DAStudio.MEView');
    for i = 1:length(allViews)
        view = DAStudio.MEView(allViews(i).Name, allViews(i).Description);
        if ~isempty(allViews(i).Properties)
            view.Properties = copy(allViews(i).Properties);
            % Set matching properties.
            properties = findobj(allViews(i).Properties, 'isMatching', true);
            % Any shortcut?
            for k = 1:length(properties)
                prop = findobj(view.Properties, 'Name', properties(k).Name);
                prop.isMatching = true;
            end
        end    
        view.InternalName = allViews(i).InternalName;
        view.GroupName = allViews(i).GroupName;
        view.SortName = allViews(i).SortName;
        view.SortOrder = allViews(i).SortOrder;
        h.addView(view);
        % Active view
        if strcmp(activeViewName, view.Name)        
             activeView = view;
        end
    end
    % Domain info. Domains updated above. So correct views.
    h.Domains = copy(h.VMProxy.Domains);
    % The views in these domains still refer to old views. Update.
    for i = 1:length(h.Domains)
        domainInfo = h.Domains(i);
        if ~isempty(domainInfo)
            dView = domainInfo.getActiveView();
            if ~isempty(dView)
                % find actual view
                view = h.getView(dView.Name);
                if ~isempty(view)
                    domainInfo.setActiveView(view);
                end
            end
        end
    end
    
    % Suggestion mode
    h.SuggestionMode = h.VMProxy.SuggestionMode;
    h.enableLiveliness;
    % If active view was deleted, set first in the list?
    if isempty(activeView)
        allViews = findobj(h, '-isa', 'DAStudio.MEView');
        h.ActiveView = allViews(1);
    else
        h.ActiveView = activeView;
    end
    
    % Delete all proxy views
    delete(h.VMProxy.getAllViews);
    managerUI = DAStudio.ToolRoot.getOpenDialogs(h);
     
    for i = 1:length(managerUI)
      managerUI(i).refresh;
    end
end  % applyChanges