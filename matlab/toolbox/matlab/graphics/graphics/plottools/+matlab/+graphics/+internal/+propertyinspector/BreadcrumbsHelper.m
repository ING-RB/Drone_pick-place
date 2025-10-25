classdef BreadcrumbsHelper < handle
    
    % This class provides a set of helper functions for the Inspector
    % Object browser
    
    % Copyright 2018-2023 The MathWorks, Inc.    
    
    properties (Constant)
        MAX_NUMBER_OF_AXESCHILDREN = 1000;
      end
    
    methods (Static)
        
        % Event handler for client-side actions events
        function actionEventHandler(ed, metaDataHandler)                      
            switch ed.actionType
                case 'objectSelectionChanged'
                    selectedObject = matlab.graphics.internal.propertyinspector.BreadcrumbsHelper.selectObject(ed);
                    % Force the tree data to update when selecting an
                    % object from the ObjectBrowser where the "Selected"
                    % property is not used in plot edit mode. This is needed
                    % because in this case there is no rev of the figure
                    % UpdateToken so the GraphicsMetaData will not update
                    % the TreeData
                    if nargin>=2 && matlab.graphics.internal.PlotEditModeUtils.isExcludedFromPlotEditInteractivity(selectedObject)
                        metaDataHandler.forceTreeDataRefresh;
                    end
                case 'propertyChanged'
                    matlab.graphics.internal.propertyinspector.BreadcrumbsHelper.setProperty(ed);
                case 'delete'
                    matlab.graphics.internal.propertyinspector.BreadcrumbsHelper.deleteObject(ed);
                case 'dnd'
                    matlab.graphics.internal.propertyinspector.BreadcrumbsHelper.dnd(ed);
            end
        end
        
        % Reordering the axes children based on the drag and drop
        function dnd(evt)
            hCurrentObject = local_getInspectedObject(evt.channel);
            % finds the ancestor of the selected object if its an axes,
            % group or transform.
            if isa(hCurrentObject(1),"matlab.graphics.primitive.Group") || isa(hCurrentObject(1),"matlab.graphics.primitive.Transform")
                ax = ancestor(hCurrentObject(1), {'matlab.graphics.axis.AbstractAxes'}); % if its a group object, ancestor will return group if thats an option
            else
                ax = ancestor(hCurrentObject(1), {'matlab.graphics.axis.AbstractAxes','hggroup','hgtransform'});
            end
            if ~isempty(ax)
                % saving the old order of the axes
                oldOrder = double(ax.Children);
                % setting up the undo function
                dndUndo(ax,evt,oldOrder,hCurrentObject)
                % changing the order of the axes children
                changeOrder(ax,evt)
            end
        end



        function hSelected = selectObject(ed)
            hSelected = [];            
            switch ed.selectionCriteria
                % numeric id is passed from the client
                case 'index'
                    hSelected = matlab.graphics.internal.propertyinspector.BreadcrumbsHelper.selectObjectByID(ed.objectToSelect, ed.channel);
                case 'propertyName'
                    %propertyName is passed from the client - hyperlink
                    %editor
                    hSelected = matlab.graphics.internal.propertyinspector.BreadcrumbsHelper.selectPropertyObject(ed.objectToSelect, ed.channel);
                case 'childOrder'
                    % Seelct based on the child order in the tree
                    hSelected = matlab.graphics.internal.propertyinspector.BreadcrumbsHelper.selectChild(ed.affectedNodes, ed.channel);
            end           
        end
        
        %Builds the tree data reqiured by the Tree Object browser in the
        %form of:
        %
        %  [{"id": "node1", "label": "Figure", parent: null,'selected','off'},
        %          {"id": "node2", "label": "Axes", parent: 'node1','selected','off'},
        %          {"id": "node3", "label": "Line", parent: 'node2','selected','on'}];
        function treeData = getTreeData(hObj)
            treeData = {};
            if isa(hObj,'internal.matlab.inspector.InspectorProxyMixin')
                hObj = hObj.OriginalObjects;
            end
            
            if isempty(hObj)
                return
            end
            
            if isscalar(hObj)
                % 'matlab.mixin.internal.Scalar' does not allow indexing g1981504
                hFig = ancestor(hObj,'figure');
            else
                hFig = ancestor(hObj(1),'figure');
            end
            
            if isempty(hFig)
                return
            end
            % Get valid graphics children to be represented in the tree
            hObjs = localGetAllGraphicChildren(hFig);     
            
            for i= 1:numel(hObjs)
                
                parentID = find(hObjs == hObjs(i).Parent,1);
                if isempty(parentID)
                    parentID = NaN;
                end
                objID = local_getIdSingleObject(hObjs(i));
                
                % Editable labels are labels with a custom display name
                isReadOnly = ~(isprop(hObjs(i),'DisplayName') && strcmp(objID,hObjs(i).DisplayName));
                
                % not all objects have the selected/visible property, e.g. uitab
                isSelected = 'off';
                if ismember(hObjs(i),getselectobjects(hFig))
                    % Objects without a selected property (e.g. uicontainer
                    % can be selected in the Object Browser)
                    isSelected = 'on';
                end

                isVisible = 'on';
                 if isprop(hObjs(i),'Visible')
                     try
                       %in case the visible property cannt be cast
                        isVisible = char(matlab.lang.OnOffSwitchState(hObjs(i).Visible));
                     catch
                     end
                 end
                 % intializing iconProps which is a structure containing edgeColor,
                 % faceColor and shape information
                 iconProps = struct('faceColor',[],'edgeColor',[],'shape',[]);

                 % getting the proxy class name for each object in the graphics tree   
                 proxyName = internal.matlab.inspector.peer.InspectorFactory.getInspectorViewName(class(hObjs(i)), 'default', hObjs(i));                 
                 % getting the metaclass for each object
                 if ~isempty(proxyName)
                     metaclass = eval(['?' proxyName]);
                     % checking if its a legendable object by checking if it inherits from IconDataMixin
                     hasIcon = any(arrayfun(@(x)isequal(x.Name ,'matlab.graphics.internal.propertyinspector.views.IconDataMixin'),metaclass.SuperclassList));
                     if hasIcon 
                         iconProps = mls.internal.toJSON(eval([proxyName '.getIconProperties(hObjs(i))']));
                     end
                 end

                 % assigning an axes ID for axes and group children
                 if isa(hObjs(i).Parent,"matlab.graphics.axis.AbstractAxes") || isa(hObjs(i).Parent,"matlab.graphics.primitive.Group") || isa(hObjs(i).Parent,"matlab.graphics.primitive.Transform")
                     axesID = find(hObjs(i).Parent.Children == hObjs(i));
                 else
                     axesID = 0;
                 end         

                 % assigning true to everything that is an axes, group or transform
                 isParent = isa(hObjs(i),'matlab.graphics.axis.AbstractAxes')|| isa(hObjs(i),"matlab.graphics.primitive.Group") || isa(hObjs(i),"matlab.graphics.primitive.Transform");
                      
                % Create a JSON representaion of the current tree node               
                treeData{end+1} = internal.matlab.legacyvariableeditor.peer.PeerUtils.toJSON(...
                    true, ...
                    struct( ...
                    'axesID', axesID,...
                    'isSelectable', ~plotedit({'isUIComponentInUIFigure',hObjs(i)}), ...
                    'id',i,...
                    'label', objID,...
                    'parent',parentID,...                    
                    'selected',isSelected,...
                    'visible',isVisible,...
                    'isParent',isParent,...
                    'isReadOnly',isReadOnly,...                   
                    'iconProps',iconProps));                   
            end
        end
        
                
        % Select a child based on its position in the tree
        function hSelected = selectChild(childIndex, channel, hObj)      
            
            if nargin == 2
                hCurrentObject = local_getInspectedObject(channel);
            else
                hCurrentObject = hObj; % for unit test purposes
            end
            
            id = double(childIndex);
            hObjs = localGetAllGraphicChildren(ancestor(hCurrentObject(1),'figure'));
            hSelected = hObjs(id);
            local_registerSelectionUndo(hCurrentObject,hSelected,channel);
            local_changeSelection(hObjs(id), channel);
        end        
        
        % Sets a property of the specified children
        function setProperty(ed, hObj)
            
            if nargin == 1
                hCurrentObject = local_getInspectedObject(ed.channel);
            else
                hCurrentObject = hObj; % for unit test purposes
            end

            id = double(ed.affectedNodes);
            hObjs = localGetAllGraphicChildren(ancestor(hCurrentObject(1),'figure'));
            local_registerPropSetUndo(hObjs(id),ed.propertyName,ed.value);
            localPropSet(hObjs(id),ed.propertyName,ed.value);
        end        
        
        %deletes object/s
        function deleteObject(ed, hObj)
            
            if nargin == 1
                hCurrentObject = local_getInspectedObject(ed.channel);
            else
                hCurrentObject = hObj; % for unit test purposes
            end
            id = double(ed.affectedNodes);
            hFig = ancestor(hCurrentObject(1),'figure');
            
            hObjs = localGetAllGraphicChildren(hFig);
            id = id(id~=1); % delete all but the figure
            
            hAxes = ancestor(hCurrentObject,'axes');
            
            delete(hObjs(id));

            %Refresh the code generator in case of deletion of an object
            matlab.graphics.interaction.generateLiveCode(hFig, matlab.internal.editor.figure.ActionID.PROPERTY_EDITED);

            %TODO : to add undo/redo logic - this reqiures refactoring of
            %scribeccp.m
            objtoSelect = hAxes;
            if  (isobject(objtoSelect) && ~isvalid(objtoSelect)) ||  isempty(objtoSelect)
                objtoSelect = hFig;
            end
           
            local_changeSelection(objtoSelect, ed.channel);                            
        end
        
        
        % Creates the datastructure for the mw-breadcrumbs widget in the
        % following form :
        %
        % breadCrumbObjectsArray: [{textToDisplay: "Figure", pathToNavigateOnClick: 2},
        % {textToDisplay: 'Axes', pathToNavigateOnClick: 1},
        % {textToDisplay: 'Line', pathToNavigateOnClick: 0}]        
        %
        function breadCrumbsData = getBreadCrumbsData(hObj)
            
            if isa(hObj,'internal.matlab.inspector.InspectorProxyMixin')
                hObj = hObj.OriginalObjects;
            end
            
            breadCrumbsData = {};    
            % Early return if :
            % 1)  internal.matlab.inspector.EmptyObject - can be passed by the
            %   Inspector on clearing
            % 2) Objects without the Parent proeprty
            % 3) Unparented objects         
            if  local_IsNotValidBreadcrumb(hObj)
                return
            end
            
            %relativeIndex is the position of each one of the breadcrumbs
            % relative to the first object. This index is sent back to the
            % server to select the specified breadcrumb
            relativeIndex = 0;            
            
            %Loop through the grapgics hierarchy starting from hObj and construct the
            %breadcrumbs data
            while true
                if isempty(hObj) || local_IsRoot(hObj)
                    % stop when we've reached the root object or an empty
                    % parent
                    break
                end
                
                if numel(hObj) > 1
                    % Multiple objects selected
                    breadCrumbText = local_getIdMultipleObjects(hObj);
                else
                    % Single object
                    breadCrumbText = local_getIdSingleObject(hObj);
                end
                
                %Add only valid breadcrumbs objects, otherwise keep going
                %and increment the index
                if local_isValidBreadcrumb(hObj)
                    % Create a JSON representaion of the current breadcrumb
                    breadCrumbsData{end+1} = internal.matlab.legacyvariableeditor.peer.PeerUtils.toJSON(...
                        true, ...
                        struct( ...
                        'textToDisplay', breadCrumbText, ...
                        'pathToNavigateOnClick',relativeIndex)); %#ok<AGROW>
                end
                %Move up to the next parent, hObj can be multiple objects,
                %take the parent of the first object and make sure the
                %parent is unique
               
                if numel(hObj) > 1
                    hParent = local_getParent(hObj(1));
                    %If the parent is not the same for multiple objects - stop here.
                    %The breadcrumbs in this sate will show "graphics(3 selected)" without specifiyng the ancestors
                    isSameParent = all(arrayfun(@(x)(x.Parent == hParent),hObj));
                    if ~isSameParent
                        break
                    end
                else
                     hParent = local_getParent(hObj);
                end
                
                hObj = hParent;
                
                relativeIndex = relativeIndex + 1;
            end % End of loop
            
            breadCrumbsData = flip(breadCrumbsData);
        end
        
         % Selects the object based on his id, callback function for the
        % BreadCrumbs
        function hSelected = selectObjectByID(ancestorId, channel)
            obj = local_getInspectedObject(channel);
            hSelected = [];
            
            if ischar(ancestorId)
                ancestorId = str2double(ancestorId);
            end
            
            if ancestorId < 1
                return
            end
            
            hSelected = obj;
            % get the nth parent of the currently inspected object
            for i = 1:ancestorId
                hSelected = local_getParent(hSelected);
            end

            local_registerSelectionUndo(obj,hSelected,channel);
            local_changeSelection(hSelected, channel);
            
            % If the object is not selectable we cant use select object, in
            % this case call inpect on the object, e.g. NumericRuler
            if ~isprop(obj,'Selected')
                inspectObj(hSelected, channel);
            end

            local_focusInspector(channel);
        end
        
        
        % Callback for the object editor to select an object stored in
        % the specific property (propName)
        function hSelected = selectPropertyObject(propName, channel, hObj)
            
            if nargin == 2
                hCurrentObject = local_getInspectedObject(channel);
            else
                hCurrentObject = hObj; % for unit test purposes
            end
            
            hSelected = hCurrentObject.(propName);
            
            % Make sure we are selecting a object
            if ~any(isobject(hSelected)) || isempty(hCurrentObject)
                return
            end
            
            local_registerSelectionUndo(hCurrentObject,hSelected, channel); 
            if isa(hSelected,'matlab.graphics.primitive.Text') && isempty(hSelected.String)
                % for empty text objects, set the Text property to
                % reflect the current property, e.g. Title will show
                % if an empty title is selected. the reason to do it is
                % so that the actual object will be selected in the
                % figure
                local_registerTextAddedUndo(hSelected,propName);
                hSelected.String = propName;
                localRegisterCodeGeneration(hSelected,'String');
            end
            
            local_changeSelection(hSelected, channel);
            
            % If the object is not selectable we cant use select object, in
            % this case call inpect() on the object, e.g. NumericRuler
            % to change the inspected object
            localSelObject = local_getInspectedObject(channel);
            if  ~isequal(size(localSelObject), size(hSelected')) ...
                    || any(localSelObject ~= hSelected')
                inspectObj(hCurrentObject.(propName), channel);
                local_focusInspector(channel);
            end
        end
    end
end

%Returns the breadcrumbs idetifier for multiple objects
function id = local_getIdMultipleObjects(hObj)

typeOfObject = {};

for i = 1: numel(hObj)
    if isprop(hObj,'Type')
        typeOfObject{end+1} = hObj(i).Type; %#ok<AGROW>
    else
        % Objects such as NumericRulers dont have the Type
        % property, use class instead
        c = split(class(hObj(i)),'.');
        typeOfObject{end+1} = c{end};  %#ok<AGROW>
    end  
end
typeOfObject = unique(typeOfObject);

if numel(typeOfObject) == 1
    %Objects of the same type will use that type in the
    %breadcrumbs
    id = typeOfObject{1};
    id(1) = upper(id(1));
else
    % Objects of different types will show 'graphics'
    id = 'graphics';
end
% graphics(N selected)
id  =  [id , ' (' , num2str(numel(hObj)) , ' selected)'];  

end

%Returns the breadcrumbs idetifier for a single object
function id = local_getIdSingleObject(hObj)
% get the class name
id = class(hObj);
ind = find(id =='.',1,'last');
if ~isempty(ind)
    id = id(ind+1:end);
end

% if there are properties such as
% Name/Title/DisplayName and not empty, use them as
% idetifiers in the breadcrumbs
if isa(hObj,'matlab.ui.Figure')
    if ~isempty(hObj.Name)
        id = hObj.Name;
    elseif  ~isempty(hObj.Number)
        id = [id,' ', num2str(hObj.Number)];
    end
elseif isa(hObj,'matlab.graphics.axis.AbstractAxes')
        t = '';
        if ~isempty(hObj.Title_IS)
             t = string(hObj.Title_IS.String_I).join(' ');
             t = t.char();
        end
        % Title can be an empty cell aray when it is being edited
        if ~isempty(t)
            id = t;
        end       
elseif isa(hObj,'matlab.ui.container.Panel') && ~isempty(hObj.Title)
    % Uipanel's Title property is a char and
    % not an object like in Axes
    id = hObj.Title;
elseif isa(hObj,'matlab.graphics.mixin.Legendable') && ~isempty(hObj.DisplayName)
    id = hObj.DisplayName;
end
end

function local_registerTextAddedUndo(hText,val)
cmd = matlab.uitools.internal.uiundo.FunctionCommand;
cmd.Name = 'SetLabel';
cmd.Function = @local_AddText; 
cmd.Varargin = {hText,val};
cmd.InverseFunction = @local_ClearText;
cmd.InverseVarargin = {hText}; 

% Register with undo/redo
% get the current figure always from the object to be selected (hNewObject)
hCurrentFigure = ancestor(hText(1),'figure','node');
uiundo(hCurrentFigure,'function',cmd);

end


% Undo and Redo function for the drag and drop feature
function dndUndo(ax,evt,oldOrder,hCurrentObject)
    cmd = matlab.uitools.internal.uiundo.FunctionCommand;
    cmd.Name = getString(message('MATLAB:propertyinspector:ChildOrder'));
    cmd.Function = @changeOrder;
    cmd.Varargin = {ax,evt};
    cmd.InverseFunction = @revertOrder;
    cmd.InverseVarargin = {ax,oldOrder};
    hCurrentFigure = findFigureInTheHeirarchy(hCurrentObject(1));
    uiundo(hCurrentFigure,'function',cmd);
end
        
% Reorder the axes children
function changeOrder(ax,evt)
    ax.Children = ax.Children(evt.newOrder);
    % trigger update of generated code
    matlab.graphics.interaction.generateLiveCode(ax, matlab.internal.editor.figure.ActionID.PROPERTY_EDITED);
end

% Revert the order of the axes children
function revertOrder(ax,oldOrder)
    oldOrder = handle(oldOrder);
    oldOrder(arrayfun(@(x) ~isvalid(x) || isa(x,'matlab.graphics.GraphicsPlaceholder'),oldOrder)) = [];
    if ~isempty(oldOrder)
        ax.Children = oldOrder;
    end
end           
         

function local_ClearText(hText)
    hText.String = '';
end

function local_AddText(hText,val)
hText.String = val;
end


%Undo registration for property sets
function local_registerPropSetUndo(hObj, propName,newValue)

cmd = matlab.uitools.internal.uiundo.FunctionCommand;
cmd.Name = [getString(message('MATLAB:propertyinspector:SetProperty')),':', propName];
cmd.Function = @localPropSet;
cmd.Varargin = {hObj, propName,newValue};
cmd.InverseFunction = @localPropSet;
cmd.InverseVarargin = {hObj, propName, get(hObj(1),propName)};

% Register with undo/redo
hCurrentFigure = ancestor(hObj(1),'figure','node');
uiundo(hCurrentFigure,'function',cmd);
end

function localPropSet(hObj, propName,newValue)
 set(hObj,propName,newValue);
 localRegisterCodeGeneration(hObj,propName);

end

function localRegisterCodeGeneration(hObj, propName)
 ev = internal.matlab.inspector.PropertyEditedEventData;
 propName(1) = upper(propName(1));
 ev.Property = propName;
 ev.Object = hObj;
 cg = matlab.graphics.internal.propertyinspector.PropertyEditingCodeGenerator.getInstance();
 cg.propertyChanged([],ev);
end

%Undo registration for selection changes
function local_registerSelectionUndo (hCurrrentObj, hNewObject, channel)
% get the current figure always from the object to be selected (hNewObject)
hCurrentFigure = findFigureInTheHeirarchy(hNewObject(1));

%In uifigures there is no uistack
if ~matlab.ui.internal.isUIFigure(hCurrentFigure)
    cmd = matlab.uitools.internal.uiundo.FunctionCommand;
    cmd.Name = getString(message('MATLAB:propertyinspector:ChangeSelection'));
    cmd.Function = @local_changeSelection;
    cmd.Varargin = {hNewObject,channel};
    cmd.InverseFunction = @local_changeSelection;
    cmd.InverseVarargin = {hCurrrentObj,channel};
    
    % Register with undo/redo
    uiundo(hCurrentFigure,'function',cmd);
end
end

function local_changeSelection(hObj, channel)

if isempty(hObj)
    return
end

hObj = hObj(isvalid(hObj));

if ~isempty(hObj)    
    hFig = ancestor(hObj(1),'figure');   
    

    % Get the current selection and attempt to select the objects.
    % If the selection is the same then is means that we need just to
    % inspect the objects because they are not selectable
    oldSelection = getselectobjects(hFig);
    selectobject(hObj,'replace');
    %hObj.Position(1)=hObj.Position(1)+.01;
    %hObj.Position(1)=hObj.Position(1)-.01;
    currentSelection = getselectobjects(hFig);
    
    if (isempty(currentSelection) || isequal(oldSelection,currentSelection)) || ...
            ~isequal(channel, internal.matlab.inspector.Inspector.DEFAULT_INSPECTOR_ID)
        inspectObj(hObj, channel);
    end

        local_focusInspector(channel);
end
end



%Returns the currently inspected object (e.g Axes)
function hObj = local_getInspectedObject(channel)
    hInspectorInstance  = local_getInspectorInstance(channel);
    hObj = [];
    % hInspectorInstance.handleVariable may be invalid in tests if an
    % object was not previosly inspected. For example, tBreadCrumbsHelper/uiPanelinUiFigures
    % calls BreadcrumbsHelper.selectPropertyObject which no longer calls 
    % inspectObj in BreadCrumbsHelper/local_changeSelection because the 
    % uipanel object can be selected in selectobjects()
    if isprop(hInspectorInstance, 'handleVariable') && ~isempty(hInspectorInstance.handleVariable) && isvalid(hInspectorInstance.handleVariable)
        hObj = hInspectorInstance.handleVariable;
        % Since we use
        % internal.matlab.inspector.MultipleValueCombinationMode.LAST as the
        % intersection rule when we create the Inspector it is safe to always return the last object
        if isscalar(hObj)
            hObj = hObj.OriginalObjects;
        else
            hObj = hObj.OriginalObjects(end);
        end
    end
end

function  hInspectorInstance = local_getInspectorInstance(channel)
    hInspectorInstance = internal.matlab.inspector.peer.InspectorFactory.createInspector('default', channel); %'/PropertyInspector');
end

function inspectObj(hObj, channel)
hInspectorInstance = local_getInspectorInstance(channel);
try
    if isa(hObj,'matlab.graphics.datatip.DataTipTemplate')
        % DataTipTemplate is using a custom code currently to
        % identify which proxy class to use. If the DataTipTemplate
        % is customizable, then use DataTipTemplatePropertyView otherwise use
        % DataTipTemplateReadOnlyPropertyView.
        % This code ensures, we selected the data tips on the data
        % annotatable object if any, and inspect datatiptemplate
        % property view.
        allTips = hObj.getAllPointDataTips();
        hObj = hObj.getInspectorProxy();
        selectobject(allTips,'replace');
    end
    hInspectorInstance.inspect(hObj);
catch
end
end

function hCurrentFigure = findFigureInTheHeirarchy(hObj)
hCurrentFigure = ancestor(hObj,'figure','node');
% For objects not in the graphics tree (e.g. DataTipTemplate), check if their parent is in the
% graphics tree, then fetch the currentFigure to make the selection
% undoable
% TODO: Assumption: the heirarchy always starts with a figure
while isempty(hCurrentFigure)    
    hObj = hObj.Parent;
    % Once we can't find a parent to object, we can break the loop.
    if isempty(hObj)
        break;
    end
    hCurrentFigure = ancestor(hObj,'figure','node');
end
end

% List of objects that wont be shown in the breadcrumbs. These objects are
% mainly internal and should not be exposed to the user via the navigation bar 
function ret = local_isValidBreadcrumb(hObj)
ret = ~(isa (hObj,'matlab.graphics.axis.colorspace.MapColorSpace') ||...
        isa(hObj,'matlab.graphics.shape.internal.AnnotationPane') ||...
        isa(hObj,'matlab.graphics.axis.dataspace.UniformCartesianDataSpace') ||...
        isa(hObj,'matlab.graphics.axis.camera.Camera2D') || ...
        isa(hObj,'matlab.graphics.axis.camera.Camera3D') || ...
        isa(hObj,'matlab.graphics.axis.dataspace.CartesianDataSpace') || ...
        isa(hObj,'matlab.graphics.primitive.world.ClipNode') || ...
        isa(hObj,'matlab.graphics.axis.HintConsumer'));
end


function hGraphicChildren = localGetAllGraphicChildren(hFig)

% Find all the trackable objects in the scene (including axes/uipanels, excluding uicontext menu which is a direct child of the figure)
hContainers = findobj(hFig.Children,'flat',...,
    '-not',{'-isa','matlab.graphics.mixin.AxesParentable',...
    '-or','-isa','matlab.ui.container.ContextMenu',...
    '-or','-isa','matlab.ui.container.Menu',...
    '-or','-isa','matlab.graphics.shape.internal.AnnotationPane'});

%This is done for perfomrnace optimization, if there are no
%uipanels/tabs/groups/transforms
%(the most common case) in the figure than the upper query which is super fast will be sufficient,
%otherwise we need to go deeper and grab all the possible cotnainers 
if ~isempty(findobj(hContainers,'-depth',1,'-isa','matlab.graphics.layout.TiledChartLayout','-or','-isa','matlab.ui.container.internal.UIContainer','-or','-isa'...,
        ,'matlab.ui.container.TabGroup','-or','-isa','matlab.graphics.primitive.Group','-or','-isa','matlab.graphics.primitive.Transform','-or','-isa','matlab.ui.container.Tree'))
    hContainers = findobj(hFig.Children,...,
        '-not',{'-isa','matlab.ui.container.ContextMenu','-or', '-isa','matlab.ui.container.Menu'},...
         '-or','-isa','matlab.ui.container.internal.UIContainer','-isa','matlab.graphics.layout.TiledChartLayout','-or','-isa'...,
        ,'matlab.ui.container.TabGroup','-or','-isa','matlab.graphics.primitive.Group','-or','-isa','matlab.graphics.primitive.Transform');
end

hGraphicChildren = [];
for k=1:length(hContainers)
    if isa(hContainers(k),'matlab.graphics.axis.AbstractAxes')
        % get Handle visible axes children only
        axChildren = findobj(hContainers(k).Children);   
        axChildren(matlab.graphics.internal.propertyinspector.BreadcrumbsHelper.MAX_NUMBER_OF_AXESCHILDREN:end) = []; 
        hGraphicChildren = [hGraphicChildren;axChildren(:)]; %#ok<AGROW>
    end
end

% concat all including the figure
hContainers = setdiff(hContainers,hGraphicChildren,'stable');
% Note that both hContainers and hGraphicChildren should be flipped because
% the ideal behavior is for the Object Browser to show its nodes in reverse
% child order so that axes children display in the same order that they do
% in legends. This is not the case currently for figure childen
% (hContainers) and the behavior is locked down in tests. TODO: Resolve
% this
hGraphicChildren = [hFig;hContainers;flip(hGraphicChildren)];

end

function hParent = local_getParent(hObj)
if isa(hObj,'matlab.graphics.datatip.DataTipTemplate')
    % DataTipTemplate for the data tips on a primitive line
    % shows LineAdaptor as its Parent which is
    % undocumented. As a result, in the below code, we are
    % fetching annotationTarget which always returns the
    % actual primitive line g1936710.
    hParent = hObj.Parent.getAnnotationTarget();
else
    hParent = hObj.Parent;
end
end



function ret = local_IsRoot(hObj)
if isscalar(hObj)
    ret = isa(hObj,'matlab.ui.Root');
else
    ret = any(arrayfun(@(x) isa(x,'matlab.ui.Root'),hObj));
end
end


function ret = local_IsNotValidBreadcrumb(hObj)
% 1)  internal.matlab.inspector.EmptyObject - can be passed by the
%   Inspector on clearing
% 2) Objects without the Parent property
% 3) Unparented objects
if isscalar(hObj)
        % 'matlab.mixin.internal.Scalar' does not allow indexing g1981504
    ret = isa(hObj,'internal.matlab.inspector.EmptyObject') ||...
        ~isprop(hObj,'Parent') || ...
        isempty(ancestor(hObj,'figure'));    
else
    ret =  any(arrayfun(@(x) isa(x,'internal.matlab.inspector.EmptyObject'),hObj)) ||...
        any(any(arrayfun(@(h) ~isprop(h,'Parent'),hObj))  ) || ...
        any(arrayfun(@(h) isempty(ancestor(h,'figure')),hObj));    
end
end

function local_focusInspector(channel)
    % If this is the desktop inspector, request focus on the inspector when
    % MATLAB is idle
    arguments
        channel string
    end

    import matlab.internal.capability.Capability;

    if ~matlab.internal.feature('webui') && Capability.isSupported(Capability.LocalClient)
        % If this is the desktop inspector, request focus on the inspector when
        % MATLAB is idle
        if isequal(channel, internal.matlab.inspector.Inspector.DEFAULT_INSPECTOR_ID)
            f = @com.mathworks.page.plottool.propertyinspectormanager.PropertyInspectorManager.requestFocus;
            builtin('_dtcallback', f, internal.matlab.datatoolsservices.getSetCmdExecutionTypeIdle);
        end
    end
end




