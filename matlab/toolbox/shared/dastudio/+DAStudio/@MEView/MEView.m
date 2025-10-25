classdef MEView < dynamicprops & matlab.mixin.SetGet & matlab.mixin.Copyable & DAStudio.AbstractTreeNode
%DAStudio.MEView class
%    DAStudio.MEView properties:
%       Name - Property is of type 'ustring'  
%       ViewManager - Property is of type 'handle'  
%       Properties - Property is of type 'handle vector'  
%       Description - Property is of type 'ustring'  
%       ReleaseChanges - Property is of type 'string'  
%       GroupName - Property is of type 'string'  
%       SortName - Property is of type 'string'  
%       SortOrder - Property is of type 'string'  
%
%    DAStudio.MEView methods:
%       addProperty -  Adds the given property to the view
%       disableLiveliness -  keep changes on this view from being propagated to the view manager
%       enableLiveliness -  ensure changes on this view propagate to the view manager
%       getProperty -  Returns  property if it exists, empty handle otherwise
%       hasProperty -  Returns index of the property if it exists, 0 otherwise
%       removeProperty -  Remove the given property fro a view


properties (SetObservable)
    %NAME Property is of type 'ustring' 
    Name char = '';
    %VIEWMANAGER Property is of type 'handle' 
    ViewManager 
    %PROPERTIES Property is of type 'handle vector' 
    Properties 
    %DESCRIPTION Property is of type 'ustring' 
    Description char = '';
    %RELEASECHANGES Property is of type 'string' 
    ReleaseChanges char = '';
    %GROUPNAME Property is of type 'string' 
    GroupName char = '';
    %SORTNAME Property is of type 'string' 
    SortName char = '';
    %SORTORDER Property is of type 'string' 
    SortOrder char = '';
end

properties (SetObservable, Hidden)
    %PROPERTIESLISTENER Property is of type 'handle'  (hidden)
    PropertiesListener
    %MEVIEWPROPERTYLISTENERS Property is of type 'handle vector'  (hidden)
    MEViewPropertyListeners 
    %GROUPCHANGEDLISTENER Property is of type 'handle'  (hidden)
    GroupChangedListener 
    %FILTERTYPES Property is of type 'string vector'  (hidden)
    FilterTypes char = {  };
    %INTERNALNAME Property is of type 'ustring'  (hidden)
    InternalName char = '';
    %ISFACTORYVIEW Property is of type 'bool'  (hidden)
    IsFactoryView logical = false;
end


    methods  % constructor block
        function this = MEView(name, desc)
        % 
        this.Name        = name;
        this.Description = desc;
        this.InternalName = '';
        this.GroupName = '';
        this.SortName = '';
        this.SortOrder = '';
        % keep the ME & MEViewManager in sync with MEView changes
        %this.enableLiveliness;
        end  % MEView
        
    end  % constructor block

    methods 
    end   % set and get functions 

    methods  % public methods
        %----------------------------------------
       function addProperty(h, propstoadd, proptoaddafter)
       % Adds the given property to the view
       
       
       if nargin > 1
           if isstring(propstoadd)
               propstoadd = cellstr(propstoadd);
           end
       end
       
       if nargin > 2
           proptoaddafter = convertStringsToChars(proptoaddafter);
       end
       
       if isempty(propstoadd)
           return;
       end
       % Take care of default cases
       if nargin == 2    
           proptoaddafter = '';    
       end
       for i=1:length(propstoadd)    
           if  h.hasProperty(propstoadd{i})
               property = h.getProperty(propstoadd{i});        
               if property.isTransient || ~property.isVisible
                   h.removeProperty({property.Name});
               else
                   propstoadd{i} = '';
               end
           end
       end
       propstoadd(ismember(propstoadd,''))='';
       if isempty(propstoadd)
           return;
       end
       viewProperties = [];
       if isempty(h.Properties)
           % Take shortcut        
           for i = 1:length(propstoadd)
              viewProperties = [viewProperties; DAStudio.MEViewProperty(propstoadd{i})];       
           end
           % refresh the ME
           h.Properties = viewProperties;
           return;
       end
       % Remove properties which need reordering
       h.disableLiveliness;
       viewProperties = h.Properties;
       propNames = get(viewProperties, 'Name');
       for i = 1:length(propstoadd)
           id = strmatch(lower(propstoadd{i}), lower(propNames), 'exact');
           if ~isempty(id)
               for m = 1:length(id)
                   k = id(m);
                   if ~viewProperties(k).isVisible || viewProperties(k).isTransient
                       viewProperties(k) = [];
                       propNames = get(viewProperties, 'Name');
                       if isempty(propNames)
                           break;
                       end
                   end
               end
           end
       end
       % Now add requested properties
       index = length(viewProperties);
       propNames = get(viewProperties, 'Name');
       if ~isempty(proptoaddafter)
          index = strmatch(lower(proptoaddafter), lower(propNames), 'exact');
          if isempty(index)
              % Add at the end.
              index = length(viewProperties);
          end
       end
       vProps = viewProperties(1:index);
       for j = 1:length(propstoadd)
           k = strmatch(lower(propstoadd{j}), lower(propNames), 'exact');
           if isempty(k)
               vProps = [vProps; DAStudio.MEViewProperty(propstoadd{j})];
           end
           % Make sure we do not add duplicate.
           propNames = get(vProps, 'Name');
       end
       vProps = [vProps; viewProperties(index+1:end)];
       % refresh the ME
       h.enableLiveliness;
       h.Properties = vProps;
       end  % addProperty
       
        %----------------------------------------
       function disableLiveliness(h)
       % keep changes on this view from being propagated to the view manager
       
       
       h.PropertiesListener      = [];
       h.MEViewPropertyListeners = [];
       h.GroupChangedListener    = [];
       end  % disableLiveliness
       
        %----------------------------------------
       function enableLiveliness(h)
       % ensure changes on this view propagate to the view manager
       
       
       % add listener to keep ME & MEViewManager in sync with Properties
       p = findprop(h, 'Properties');
       h.PropertiesListener = event.proplistener(h, p, 'PostSet', @syncUIFromMEView);
       p = findprop(h, 'GroupName');
       h.GroupChangedListener = event.proplistener(h, p, 'PostSet', @(~, evt) syncUIFromMEViewProperty(h, h));
       
       updateMEViewPropertyListeners(h);
       end  % enableLiveliness
       
       
       

        %----------------------------------------
       function property = getProperty(h, prop)
       % Returns  property if it exists, empty handle otherwise
       
       if nargin > 1
           prop = convertStringsToChars(prop);
       end
       
       property = [];
       if ~h.hasProperty(prop)
           return;
       end
       index = find(strcmpi(get(h.Properties, 'Name'), prop));
       if ~isempty(index)
           property = h.Properties(index);
       end
       end  % getProperty
       
        %----------------------------------------
       function result = hasProperty(h, propToCheck)
       % Returns index of the property if it exists, 0 otherwise
       
       result = false;
       if isempty(propToCheck) || isempty(h.Properties)
           return;
       end
       result = ~isempty(find(strcmpi(get(h.Properties,'Name'), propToCheck), 1));
       end  % hasProperty
       
        %----------------------------------------
       function removeProperty(h, propstoremove)
       % Remove the given property fro a view
       
       if isempty(h.Properties)
           return;
       end
       h.disableLiveliness;
       viewProperties = copy(h.Properties);
       for i = 1:length(propstoremove)
           property = h.getProperty(propstoremove{i});
           if ~isempty(property)
               if strcmp(property.Name, h.GroupName)
                   h.GroupName = '';
               end
               index = strcmpi(get(viewProperties, 'Name'), property.Name);
               viewProperties(index) = [];
           end
       end
       h.enableLiveliness;
       h.Properties = viewProperties;
       
       end  % removeProperty

               %----------------------------------------
       function schema = getDialogSchema(h)
       %
       
       
       %% Property Selector
       search_edit.Type            = 'edit';
       search_edit.Tag             = 'view_search_edit';
       search_edit.ToolTip         = DAStudio.message('modelexplorer:DAS:FindPropertiesSearch');
       search_edit.Graphical       = true;
       search_edit.RespondsToTextChanged = true;
       search_edit.PlaceholderText = DAStudio.message('modelexplorer:DAS:FindProperties');
       search_edit.Clearable       = true;
       search_edit.MatlabMethod    = 'feval';
       search_edit.MatlabArgs      = {@DAStudio.MEView_cb, '%dialog', 'doFilterProperties'};
       search_edit.RowSpan         = [1 1];
       if h.ViewManager.EnablePropertyScope
           search_edit.ColSpan     = [1 1];
       else
           search_edit.ColSpan     = [1 3];
       end
       search_edit.MinimumSize     = [128 -1];
       
       search_from_text.Type       = 'text';
       search_from_text.Name       = DAStudio.message('modelexplorer:DAS:PropertiesFrom');
       search_from_text.RowSpan    = [1 1];
       search_from_text.ColSpan    = [2 2];
       search_from_text.Visible    = h.ViewManager.EnablePropertyScope;
       
       search_from_combo.Type      = 'combobox';
       search_from_combo.Tag       = 'view_search_from_combo';
       search_from_combo.Entries   = {DAStudio.message('modelexplorer:DAS:ObjectsInListView'), ...
                                      DAStudio.message('modelexplorer:DAS:ObjectsSelected')};
       search_from_combo.Graphical    = true;
       search_from_combo.Editable     = false;
       search_from_combo.DialogRefresh = true;
       search_from_combo.RowSpan      = [1 1];
       search_from_combo.ColSpan      = [3 3];
       search_from_combo.Visible      = h.ViewManager.EnablePropertyScope;
       
       % determine all properties in scope
       entries   = {};
       filterStr = getValueFromDialog(h, search_edit.Tag);
       if ~h.ViewManager.IsCollapsed
           entries = calculatePossibleProperties(h, filterStr);
       end
       
       properties_list.Type        = 'listbox';
       properties_list.Tag         = 'view_properties_list';
       properties_list.Graphical   = true;
       properties_list.Entries     = entries;
       properties_list.RowSpan     = [2 2];
       properties_list.ColSpan     = [1 3];
       properties_list.AutoTranslateStrings = 0;
       properties_list.ListDoubleClickCallback = @listDoubleClicked;
       
       selector.Type               = 'panel';
       selector.LayoutGrid         = [2 3];
       selector.RowSpan            = [1 1];
       selector.ColSpan            = [1 1];
       selector.Items              = {search_edit, search_from_text, search_from_combo, properties_list};
       
       %% Add to columns and delete columns
       spacer_top.Type             = 'panel';
       spacer_top.RowSpan          = [1 1];
       spacer_top.ColSpan          = [1 1];
       
       add_button.Type             = 'pushbutton';
       add_button.Tag              = 'view_add_button';
       add_button.ToolTip          = DAStudio.message('modelexplorer:DAS:DisplayProperty');
       add_button.FilePath         = fullfile(matlabroot, 'toolbox', 'shared', 'dastudio', 'resources', 'add_row.gif');
       add_button.MatlabMethod     = 'feval';
       add_button.MatlabArgs       = {@DAStudio.MEView_cb, '%dialog', 'doAdd', h};
       add_button.RowSpan          = [2 2];
       add_button.ColSpan          = [1 1];
       add_button.PreferredSize    = [28 24];
       
       delete_button.Type          = 'pushbutton';
       delete_button.Tag           = 'view_delete_button';
       delete_button.ToolTip       = DAStudio.message('modelexplorer:DAS:ColumnDelete');
       delete_button.FilePath      = fullfile(matlabroot, 'toolbox', 'shared', 'dastudio', 'resources', 'TTE_delete.gif');
       delete_button.MatlabMethod  = 'feval';
       delete_button.MatlabArgs    = {@DAStudio.MEView_cb, '%dialog', 'doRemove', h};
       delete_button.RowSpan       = [3 3];
       delete_button.ColSpan       = [1 1];
       delete_button.PreferredSize = [28 24];
       
       spacer_bottom.Type          = 'panel';
       spacer_bottom.RowSpan       = [4 4];
       spacer_bottom.ColSpan       = [1 1];
       
       add.Type                    = 'panel';
       add.Items                   = {spacer_top, add_button, delete_button, spacer_bottom};
       add.LayoutGrid              = [4 1];
       add.RowStretch              = [1 0 0 1];
       add.RowSpan                 = [1 1];
       add.ColSpan                 = [2 2];
       
       %% Display columns
       columns_text.Type           = 'text';
       columns_text.Name           = DAStudio.message('modelexplorer:DAS:DisplayColumns');
       columns_text.RowSpan        = [1 1];
       columns_text.ColSpan        = [1 2];
       
       % determine all visible properties
       data = {};
       if ~isempty(h.Properties) && ~h.ViewManager.IsCollapsed
           props = findobj(h.Properties, 'isVisible', true, ...
               'isTransient', false, ...
               'isReserved', false);   
           for i = 1:length(props)
               % This is a temporary solution for g589744.
               name = props(i).Name;
               dotLocation = strfind(name, '.');
               if ~isempty(dotLocation)
                   nameToAppend = name(dotLocation(end)+1:end);
                   name = [name ' (' nameToAppend ')'];
               end
               data{i, 1} = name;        
           end
       end
       
       columns_table.Type                  = 'table';
       columns_table.Tag                   = 'view_columns_table';
       columns_table.Source                = h;
       columns_table.Graphical             = true;
       columns_table.Grid                  = false;
       columns_table.ColHeader             = {DAStudio.message('modelexplorer:DAS:HeaderName'),...
                                              DAStudio.message('modelexplorer:DAS:HeaderFilter')};
       columns_table.HeaderVisibility      = [0 1];
       columns_table.ReadOnlyColumns       = [0];
       columns_table.MultiSelect           = false;
       columns_table.Editable              = true;
       columns_table.Data                  = data;
       columns_table.Size                  = size(data);
       columns_table.ValueChangedCallback  = 'onTableValueChanged';
       columns_table.CurrentItemChangedCallback = 'onTableCurrentChanged';
       columns_table.RowSpan               = [2 2];
       columns_table.ColSpan               = [1 1];
       columns_table.SelectionBehavior     = 'Row';
       columns_table.AutoTranslateStrings = 0;
       columns_table.TableKeyPressCallback    = 'onTableKeyPress';
       
       % table buttons to reorder
       columns_spacer_top.Type                 = 'panel';
       columns_spacer_top.RowSpan              = [1 1];
       columns_spacer_top.ColSpan              = [1 1];
       
       up_button.Type              = 'pushbutton';
       up_button.Tag               = 'view_up_button';
       up_button.ToolTip           = DAStudio.message('modelexplorer:DAS:ColumnLeft');
       up_button.FilePath          = fullfile(matlabroot, 'toolbox', 'shared', 'dastudio', 'resources', 'move_up.gif');
       up_button.MatlabMethod      = 'feval';
       up_button.MatlabArgs        = {@DAStudio.MEView_cb, '%dialog', 'doUp', h};
       up_button.Enabled           = false;
       up_button.RowSpan           = [2 2];
       up_button.ColSpan           = [1 1];
       up_button.PreferredSize     = [28 24];
       
       down_button.Type            = 'pushbutton';
       down_button.Tag             = 'view_down_button';
       down_button.ToolTip         = DAStudio.message('modelexplorer:DAS:ColumnRight');
       down_button.FilePath        = fullfile(matlabroot, 'toolbox', 'shared', 'dastudio', 'resources', 'move_down.gif');
       down_button.MatlabMethod    = 'feval';
       down_button.MatlabArgs      = {@DAStudio.MEView_cb, '%dialog', 'doDown', h};
       down_button.RowSpan         = [3 3];
       down_button.ColSpan         = [1 1];
       down_button.PreferredSize   = [28 24];
       down_button.Enabled         = false;

       % Disable if only one property
       if ~isempty(h.Properties) && length(h.Properties) > 1
           mapEnabled = doEnableDisableButtons(h);
           up_button.Enabled = mapEnabled('up_button');
           down_button.Enabled = mapEnabled('down_button');
       end

       columns_spacer_bottom.Type                 = 'panel';
       columns_spacer_bottom.RowSpan              = [4 4];
       columns_spacer_bottom.ColSpan              = [1 1];
       
       columns_buttons.Type        = 'panel';
       columns_buttons.Items       = {columns_spacer_top, up_button, down_button, columns_spacer_bottom};
       columns_buttons.LayoutGrid  = [4 1];
       columns_buttons.RowStretch  = [1 0 0 1];
       columns_buttons.RowSpan     = [2 2];
       columns_buttons.ColSpan     = [2 2];
       
       columns.Type                = 'panel';
       columns.Items               = {columns_text, columns_table, columns_buttons};
       columns.LayoutGrid          = [2 2];
       columns.RowSpan             = [1 1];
       columns.ColSpan             = [3 3];
       
       %% Button bar
       spacer.Type             = 'panel';
       spacer.RowSpan          = [1 1];
       spacer.ColSpan          = [1 1];
           
       optionsButton.Type        = 'pushbutton';
       optionsButton.Tag         = 'views_options_button';
       optionsButton.Menu        = getViewOptionsMenu(h);
       optionsButton.Name        = DAStudio.message('modelexplorer:DAS:OptionsButton');
       optionsButton.RowSpan     = [1 1];
       optionsButton.ColSpan     = [2 2];
       
       button_bar.Type         = 'panel';
       button_bar.Tag          = 'views_button_bar';
       button_bar.Items        = {spacer, optionsButton};
       button_bar.LayoutGrid   = [1 2];
       button_bar.ColStretch   = [1 0];
       button_bar.RowSpan      = [2 2];
       button_bar.ColSpan      = [1 3];
       
       %% Top level schema
       schema.Type                 = 'panel';
       schema.Items                = {selector, add, columns, button_bar};
       schema.LayoutGrid           = [2 3];
       schema.ColStretch           = [1 0 1];
       end  % getDialogSchema
       
end  % public methods 

    methods (Hidden) % possibly private or hidden
  
       %
       % Get properties for listbox using scope options selected.
       %

       %----------------------------------------
       function menu = getHeaderContextMenu(h, header)
       %
       
       
       % Hold on to the allocated options menu per MEViewManager instance
       if isempty(findprop(h.ViewManager, 'HeaderContextMenu'))
           addprop(h.ViewManager, 'HeaderContextMenu');
       end
       
       % Clean up any previously allocated menu along with its actions & submenus
       if ~isempty(h.ViewManager.HeaderContextMenu) && isobject(h.ViewManager.HeaderContextMenu)
           % submenu
           sub = findobj(h.ViewManager.Explorer, '-isa', 'DAStudio.PopupMenu',...
                                              'label', DAStudio.message('modelexplorer:DAS:InsertHidden'));
           if ~isempty(sub)
               delete(sub.getChildren);
               delete(sub);
           end    
           % top level menu
           delete(h.ViewManager.HeaderContextMenu.getChildren);
           delete(h.ViewManager.HeaderContextMenu);
           h.ViewManager.HeaderContextMenu = [];
       end
       
       menu = [];
       %header = strtrim(header);
       
       am   = DAStudio.ActionManager;
       menu = am.createPopupMenu(h.ViewManager.Explorer);
       prop = [];
       
       if ~isempty(h.Properties)
           prop = findobj(h.Properties, 'Name', header);
       
           if ~isempty(prop) && ~strcmp(prop.Name, 'Name')
               % Hide
               action = getHideAction(am, h);
               % add some useful information for processing this action
               action = addCallbackData(action, {'hide', prop, '', h});
               menu.addMenuItem(action);
               menu.addSeparator();
               
               % Insert Path
               action = getPathAction(am, h, header);
               menu.addMenuItem(action);
               
               % Insert Hidden if necessary
               sub = getInsertHidden(am, h, header);     
               menu.addSubMenu(sub, DAStudio.message('modelexplorer:DAS:InsertHidden'));
               menu.addSeparator();
               
               if ~isempty(strtrim(header))
                   menu.addSeparator();
                   action = getGroupByAction(am, h, header);
                   menu.addMenuItem(action);
               end
               if ~isempty(h.GroupName)
                   action = getRemoveGroupAction(am, h, header);
                   menu.addMenuItem(action);
               end
               action = getShowGroupColumnAction(am, h);
               if ~isempty(action)
                  menu.addMenuItem(action);
               end        
       
               % Add expand/collapse all groups
               if ~isempty(h.GroupName)
                   action = getExpandAllGroups(am, h);
                   menu.addMenuItem(action);
                   action = getCollapseAllGroups(am, h);
                   menu.addMenuItem(action);
               end
                       
               menu.addSeparator();
               % Show details of this view
               action = getDetailsAction(am, h);
               menu.addMenuItem(action);
           else
               % Insert Path
               action = getPathAction(am, h, header);
               menu.addMenuItem(action);
               
               % Insert Hidden if necessary
               sub = getInsertHidden(am, h, header);     
               menu.addSubMenu(sub, DAStudio.message('modelexplorer:DAS:InsertHidden'));
               menu.addSeparator();
               
               menu.addSeparator();
               action = getGroupByAction(am, h, header);
               menu.addMenuItem(action);
               
               if ~isempty(h.GroupName)            
                   action = getRemoveGroupAction(am, h, header);
                   menu.addMenuItem(action);            
               end
               action = getShowGroupColumnAction(am, h);
               if ~isempty(action)
                  menu.addMenuItem(action);
               end        
               if ~isempty(h.GroupName)
                   action = getExpandAllGroups(am, h);
                   menu.addMenuItem(action);
                   action = getCollapseAllGroups(am, h);
                   menu.addMenuItem(action);
               end
               menu.addSeparator();
               % Show details of this view
               action = getDetailsAction(am, h);
               menu.addMenuItem(action);
           end
       else
           % Insert Path
           action = getPathAction(am, h, header);
           menu.addMenuItem(action);
       
           menu.addSeparator();
           % Show details of this view
           action = getDetailsAction(am, h);
           menu.addMenuItem(action);
       end
       
       h.ViewManager.HeaderContextMenu = menu;
       
       end
       
       %
       % Hide action item on listview columns
       %

        %----------------------------------------
       function headerLabels = getHeaderLabels(h)
       %
       
       info = [];
       % no need to do any work if the view has no properties
       info = [info struct('name','Name', 'width', -1, 'icon', '')];
       if ~isempty(h.Properties)
           props   = findobj(h.Properties, 'isVisible', true);
           columns = get(props, 'Name');
           widths = get(props, 'Width');
           if ~isempty(columns)
               if (~iscell(columns))
                   columns = { columns };
               end
               if (~iscell(widths))
                   widths = { widths };
               end
               if numel(columns) > 0
                   info = [];
                   for i=1:numel(columns)
                       info = [info struct('name',columns{i}, 'width', widths{i}, 'icon', '')];
                   end
               end
           end
       end
       headerLabels = jsonencode(struct('columns', info));
       
       end  % getHeaderLabels
       
        %----------------------------------------
       function acceptedOrder = getHeaderOrder(h, proposedOrder)
       
       dlgs = DAStudio.ToolRoot.getOpenDialogs(h.ViewManager);
       DAStudio.MEView_cb(dlgs(1), 'doReorderProperties', h, proposedOrder);
       
       acceptedOrder = h.getHeaderLabels;
       end  % getHeaderOrder
       
        %----------------------------------------
       function setHeaderWidth(h, widthInfo)
       %
       
       % no need to do any work if the view has no properties
       if ~isempty(h.Properties)
           h.disableLiveliness;
           sizeInfo = jsondecode(widthInfo);
           sizefields = fields(sizeInfo);
           for i= 1:numel(sizefields)
               propertyName = strrep(sizefields{i},'_','.');
               index = find(strcmpi(get(h.Properties, 'Name'), propertyName));
               if ~isempty(index)
                    property = h.Properties(index);
                    property.Width = sizeInfo.(sizefields{i});
               end
           end
           h.enableLiveliness;
       end
       end  % setHeaderWidth
       
        %----------------------------------------
       function show = shouldShow(h, obj)
       
       show = true;
       
       % no need to do any work if the view has no properties
       if ~isempty(h.Properties)
           % if the object has at least 1 matching property, show it
           matching = findobj(h.Properties, 'isMatching', true);
           for i = 1:length(matching)
               % TODO: need to account for aliased property names
               show = obj.isValidProperty(matching(i).Name);
               if show
                   return;
               end
           end
       end
       end  % shouldShow
       
end  % possibly private or hidden 

end  % classdef

function updateMEViewPropertyListeners(view)

    % remove any existing listeners
    view.MEViewPropertyListeners = [];
    
    % add property listeners for the MEViewProperty properties
    for i = 1:length(view.Properties)
        cls = metaclass(view.Properties(i));
        lnr = event.proplistener(view.Properties(i), cls.Properties, 'PostSet', @(h,evt) syncUIFromMEViewProperty(h,view));         
        view.MEViewPropertyListeners = [view.MEViewPropertyListeners; lnr];
    end
end  % updateMEViewPropertyListeners



function syncUIFromMEView(~, eventData)

view = eventData.AffectedObject;
% Setting properties. Make sure name is first
index = find(strcmpi(get(view.Properties, 'Name'), 'Name'));

if ~isempty(index) && index ~= 1
    tempProperty = view.Properties(1);
    view.Properties(1) = view.Properties(index);
    view.Properties(index) = tempProperty;
end
refreshUIs(view);
updateMEViewPropertyListeners(view);
end  % syncUIFromMEView



function syncUIFromMEViewProperty(h, view)

refreshUIs(view);
end  % syncUIFromMEViewProperty


%
% Refresh ModelExplorer list.
%
function refreshUIs(view)
if ~isempty(view.ViewManager)
    exp = view.ViewManager.Explorer;
    % Set group property if any
    exp.GroupColumn = view.GroupName;
    if ~isempty(view.SortName)
        exp.SortColumn = view.SortName;
        exp.SortOrder = view.SortOrder;
    end
end
% Update the ME
ed = DAStudio.EventDispatcher;
ed.broadcastEvent('ListChangedEvent');
end  % refreshUIs

function props = calculatePossibleProperties(h, filterStr)
    me    = h.ViewManager.Explorer;
    props = {};
    if ishandle(me)
        scopeValue = getValueFromDialog(h, 'view_search_from_combo');    
        if ~isempty(scopeValue)
            switch scopeValue
                case 0                
                    props = me.getProperties('VisibleObjects');
                    % props = get(findobj(h.Properties, 'isVisible', true, 'isReserved', true), 'Name');
                case 1
                    props = me.getProperties('SelectedObjects');        
            end
        else
            % Get default
            props = me.getProperties('VisibleObjects');
            % props = get(findobj(h.Properties, 'isVisible', true), 'Name');
            % props = get(findobj(h.Properties, 'isVisible', true, 'isReserved', true), 'Name');
        end
        
        % filter the property list if a filter string is supplied
        if ~isempty(filterStr)
            % make sure that the filter string doesn't contain useless whitespace
            filterStr = strtrim(filterStr);
            if ~isempty(filterStr)
                % use a case sensitive match if the filter string is mixed case
                % otherwise use a case insensitive match
                if strcmp(lower(filterStr), filterStr)
                    matchingProperties = strfind(lower(props), filterStr);
                else
                    matchingProperties = strfind(props, filterStr);
                end
    
                % filter!
                props = props(~cellfun('isempty', matchingProperties));
            end
        end
        
        % remove 'Name' from the list
        index = strmatch('Name', props, 'Exact');
        if ~isempty(index)
            props(index) = [];
        end
    end
end  % calculatePossibleProperties



%
% Table value changed callback.
%
function onTableValueChanged(dlg, r, ~, value)
manager = dlg.getSource();
view    = manager.ActiveView;
name    = dlg.getTableItemValue('view_columns_table', r, 0);
prop = findobj(view.Properties, 'Name', name);
prop.isMatching = value;
end  % onTableValueChanged


%
% Table selection changed callback handler
%
function onTableCurrentChanged(dlg, ~, ~)
% Enable disable buttons
DAStudio.MEView_cb(dlg, 'doEnableDisableButtons');
end  % onTableCurrentChanged


%
% Key press event on table
%
function onTableKeyPress(dlg, tag, key)
% Process only del key
if strcmp(tag, 'view_columns_table') && strcmp(key, 'Del')
    manager = dlg.getSource();
    DAStudio.MEView_cb(dlg, 'doRemove', manager.ActiveView);
end
end  % onTableKeyPress


% helper functions --------------------------------------------------------
function value = getValueFromDialog(h, tag)
value  = [];
dialog = DAStudio.ToolRoot.getOpenDialogs(h.ViewManager);
if ~isempty(dialog) && dialog(1).isWidgetValid(tag)
    value = dialog(1).getWidgetValue(tag);
end
end  % getValueFromDialog

% Set the up/down button enabled state for the detailed view
function mapEnabled = doEnableDisableButtons(h)

    mapEnabled = containers.Map({'up_button', 'down_button'}, {false, true});
    dlgs = DAStudio.ToolRoot.getOpenDialogs(h);
    dlg = dlgs.find('dialogTag', 'me_view_manager_ui');
    
    if (~isempty(dlg) && dlg.isWidgetValid('view_columns_table'))
        allProps = findobj(h.Properties, 'isVisible', true, ...
                       'isTransient', false, 'isReserved', false);
        rows = dlg.getSelectedTableRows('view_columns_table');

        % Enable disable up/down buttons
        tempRows = int32(rows) - 1;
        mapEnabled('up_button') = isempty(find(tempRows < 0, 1));
        tempRows = rows + 1;
        mapEnabled('down_button') = isempty(find(tempRows > (length(allProps) - 1), 1));
    end
end

%
% Add property on double click
%
function listDoubleClicked(h, ~, ~)
manager = h.getSource;
DAStudio.MEView_cb(h, 'doAdd',manager.ActiveView);
end  % listDoubleClicked


%
% Create Options menu for options button
%
function menu = getViewOptionsMenu(h)
    manager = h.ViewManager;
    % Hold on to the allocated menu per MEViewManager instance
    if isempty(findprop(manager, 'OptionsMenu'))
         addprop(manager, 'OptionsMenu');
    end
    
    % Clean up any previously allocated menu along with its actions
    if ~isempty(manager.OptionsMenu) && isobject(manager.OptionsMenu)
        delete(manager.OptionsMenu.getChildren);
        delete(manager.OptionsMenu);
        manager.OptionsMenu = [];
    end
    am   = DAStudio.ActionManager;
    menu = am.createPopupMenu(manager.Explorer);
    
    action = am.createAction(manager.Explorer);
    action.Tag      = 'views_options_manageViews';
    action.Text     = DAStudio.message('modelexplorer:DAS:ManageViews');
    action.Callback = ['DAStudio.MEViewManager_action_cb(' num2str(action.id) ')'];
    action = addCallbackData(action, {'manageView', manager} );
    menu.addMenuItem(action);
    menu.addSeparator();
    
    action = am.createAction(manager.Explorer);
    action.Tag      = 'views_options_export';
    action.Text     = DAStudio.message('modelexplorer:DAS:ExportDotDotDot');
    action.Callback = ['DAStudio.MEViewManager_action_cb(' num2str(action.id) ')'];
    action = addCallbackData(action, {'exportView', manager} );
    menu.addMenuItem(action);
    menu.addSeparator();
    
    % Enable or show only if changed factory view /or a factory view
    if ~isempty(manager.getActiveView)        
        % Check if this is really a factory view.
        if ~isempty(manager.ActiveView.InternalName)        
            % Get factory view settings.
            factoryView = manager.getFactoryViews(manager.ActiveView.Name);
            if ~isempty(factoryView)
                % This is a factory view.
                action = am.createAction(manager.Explorer);
                action.Tag      = 'views_options_resettofactory';
                action.Text     = DAStudio.message('modelexplorer:DAS:ResetToFactoryDotDotDot');
                % Enable if changed
                if AreSameViews(manager.ActiveView, factoryView)
                    action.enabled = 'off';
                else
                    action.enabled = 'on';
                end
                action = addCallbackData(action, {'resetToFactory', manager} );
                action.callback = ['DAStudio.MEViewManager_action_cb(' num2str(action.id) ')'];
                menu.addMenuItem(action);
                menu.addSeparator();
                factoryView.delete;
            end
        end    
    end
    manager.OptionsMenu = menu;
end  % getViewOptionsMenu


%
% Compare views: Name, Properties
% We will need to compare other attributes too.
%
function same = AreSameViews(v1, v2)
same = strcmp(v1.Name, v2.Name) ...
        && strcmp(v1.Description, v2.Description) ...
        && strcmp(v1.GroupName, v2.GroupName) && strcmp(v1.SortName, v2.SortName) ...
        && strcmp(v1.SortOrder, v2.SortOrder);
if same       
    % Both empty.
    if isempty(v1.Properties) && isempty(v2.Properties)
        same = true;
        return;
    end
    % One does not have any properties.
    if isempty(v1.Properties) && ~isempty(v2.Properties)
        same = false;
        return;
    end
    if ~isempty(v1.Properties) && isempty(v2.Properties)
        same = false;
        return;
    end
    % Quickly check length to decide.
    same = length(v1.Properties) == length(v2.Properties);
    % Compare properties.
    if same
        p1 = get(v1.Properties, 'Name');
        p2 = get(v2.Properties, 'Name');
        same = isequal(p1, p2);
        % Visibility/Hidden
        if same
            p1Visible = get(findobj(v1.Properties, 'isVisible', true), 'Name');
            p2Visible = get(findobj(v2.Properties, 'isVisible', true), 'Name');
            same = isequal(p1Visible, p2Visible);
        end
    end
end
end  % AreSameViews


%
% TODO: Why addCallbackData in pvt folder not being called?
%
function action = addCallbackData(action, data)
addprop(action, 'callbackData');
action.callbackData = data;
end  % addCallbackData


function action = getHideAction(am, h)
    action = am.createAction(h.ViewManager.Explorer);
    action.Tag      = 'views_cm_hide';
    action.text     = DAStudio.message('modelexplorer:DAS:HideID');
    action.callback = ['DAStudio.MEView_action_cb(' num2str(action.id) ')'];
end

%
% Filter action item on listview columns
%
function action = getFilterAction(am, h)    
    action = am.createAction(h.ViewManager.Explorer);
    action.Tag          = 'views_cm_filter';
    action.text         = ['Filter (show objects with this property)'];
    action.toggleAction = 'on';
     action.callback = ['DAStudio.MEView_action_cb(' num2str(action.id) ')'];     
end

%
% Path action item on listview columns
%
function action = getPathAction(am, h, header)
    pathProperty = [];
    
    if ~isempty(h.Properties)
        pathProperty = findobj(h.Properties, 'Name', 'Path');
    end
    % Create one if we do not have this property already.
    if isempty(pathProperty)
        pathProperty = DAStudio.MEViewProperty('Path');
        pathProperty.isVisible = false;     
    end

    action = am.createAction(h.ViewManager.Explorer);
    action.Tag          = 'views_cm_insert_path';
    action.text         = DAStudio.message('modelexplorer:DAS:InsertPath');
    % action.callback = ['MEView_action_cb(' num2str(action.id) ')'];
     action.callback = ['DAStudio.MEView_action_cb(' num2str(action.id) ')'];     
    action = addCallbackData(action, {'insertPath', pathProperty, header, h});
    
    if pathProperty.isVisible
        action.enabled = 'off';
    end
end

%
%
function action = getGroupByAction(am, h, header)    
    action = am.createAction(h.ViewManager.Explorer);
    action.Tag          = 'views_cm_group_by';
    action.text         = DAStudio.message('modelexplorer:DAS:GroupByColumn');
    % action.callback = ['MEView_action_cb(' num2str(action.id) ')'];
     action.callback = ['DAStudio.MEView_action_cb(' num2str(action.id) ')'];     
    action = addCallbackData(action, {'groupBy', header, h});
end

%
%
%
function action = getRemoveGroupAction(am, h, ~)
    action = am.createAction(h.ViewManager.Explorer);
    action.Tag          = 'views_cm_ungroup_by';
    action.text         = DAStudio.message('modelexplorer:DAS:RemoveGrouping');
    % action.callback = ['MEView_action_cb(' num2str(action.id) ')'];
     action.callback = ['DAStudio.MEView_action_cb(' num2str(action.id) ')'];       
    action = addCallbackData(action, {'removeGrouping', h});
end        

%
% Show Group Column action for grouping.
%
function action = getShowGroupColumnAction(am, h)     
   action = am.createDefaultAction(h.ViewManager.Explorer, 'VIEW_SHOWGROUPCOLUMN');
end

%
% Expand all groups action.
%
function action = getExpandAllGroups(am,h)
    action = am.createDefaultAction(h.ViewManager.Explorer, 'EDIT_EXPANDALLGROUPS');
end

function action = getCollapseAllGroups(am,h)
    action = am.createDefaultAction(h.ViewManager.Explorer, 'EDIT_COLLAPSEALLGROUPS');
end
%
% Insert Recently Hidden
%
function menu = getInsertHidden(am, h, header)
    menu = am.createPopupMenu(h.ViewManager.Explorer);
    % Find the hidden properties.
    count = 0;
    hiddenProperties = findobj(h.Properties, 'IsVisible', false, ...
        'isTransient', false, 'isReserved', false);
    if ~isempty(hiddenProperties)
        for i = 1:length(hiddenProperties)
            % Path is not added to this list, it is a separate item.
            if ~strcmp(hiddenProperties(i).Name, 'Path')
                action = am.createAction(h.ViewManager.Explorer);
                action.text         = hiddenProperties(i).Name;        
                 action.callback = ['DAStudio.MEView_action_cb(' num2str(action.id) ')'];     
                action = addCallbackData(action, {'insertHidden',  hiddenProperties(i), header, h});
                menu.addMenuItem(action);
                count = count + 1;
                if count == 5
                    break;
                end
            end
        end
    end
    if count == 0
        action = am.createAction(h.ViewManager.Explorer);
        action.text         = DAStudio.message('modelexplorer:DAS:NoHiddenProperties');
        action.enabled      = 'off';
        menu.addMenuItem(action);
    end
end

% Search
% TODO: Disabled for now.
% action = am.createAction(h.ViewManager.Explorer);
% action.Tag         = 'views_cm_search_by_property';
% action.text         = 'Search by This Property';
% action.callback     = ['MEView_action_cb(' num2str(action.id) ')'];
% menu.addMenuItem(action);
%

%
% Show details of this view action.
%
function action = getDetailsAction(am, h)
action = am.createDefaultAction(h.ViewManager.Explorer, 'VIEW_SHOWDETAILSOFCURRENTVIEW');
% action = am.createAction(h.ViewManager.Explorer);
% action.Tag      = 'views_cm_customize';
% action.text     = DAStudio.message('modelexplorer:DAS:ShowDetailsCurrentView');
% action.callback = ['MEViewManager_action_cb(' num2str(action.id) ')'];
% action.toggleAction = 'on';
% 
% if h.ViewManager.IsCollapsed
%     action.on = 'off';
% else
%     action.on = 'on';
% end
% % add some useful information for processing this action
% action = addCallbackData(action, {'customizeView', h.ViewManager});
end
