classdef Inspector < internal.matlab.variableeditor.MLManager & ...
        internal.matlab.variableeditor.MLWorkspace & dynamicprops
    
    % This class is unsupported and might change or be removed without
    % notice in a future version.
    
    % The main property inspector class.  This class can be instantiated
    % and used to inspect an object.
    
    % Copyright 2015-2024 The MathWorks, Inc.
    
    properties
        Application;
        InspectorID;
        CurrentObjects;
        Adapter;
        
        % Specifies how to handle properties when multiple objects are
        % selected
        MultiplePropertyCombinationMode internal.matlab.inspector.MultiplePropertyCombinationMode;
        
        % Specifies how to handle values when multiple objects are selected
        MultipleValueCombinationMode internal.matlab.inspector.MultipleValueCombinationMode;

        % Specifies if the a timer should be used to detect changes in handle objects
        UseTimerForHandleObjects = true;
        
        ShowObjectBrowser = false;
    end
    
    properties(Hidden = true)
        DeletionListeners = {};
    end
    
    properties(Constant)
        DEFAULT_INSPECTOR_ID = '/PropertyInspector';
        INTERNAL_REF_NAME = 'handleVariable';
    end
    
    properties(Hidden = true, Access = {?internal.matlab.inspector.Inspector, ...
            ?internal.matlab.inspector.peer.PeerInspectorManager, ?matlab.unittest.TestCase })
        % Store any proxy objects created for inspecting, and try to reuse them
        % for inspecting the same object again
        ProxyMaps = containers.Map('KeyType', 'double', 'ValueType', 'Any'); %#ok<MCHDP> 
    end
    
    methods
        % Constructor - creates a new Inspector object.
        function this = Inspector(Application, InspectorID)
            this@internal.matlab.variableeditor.MLManager(false);
            if nargin == 0
                this.Application = 'PropertyInspector';
                this.InspectorID = this.DEFAULT_INSPECTOR_ID;
            elseif nargin == 1
                this.Application = Application;
                this.InspectorID = this.DEFAULT_INSPECTOR_ID;
            else
                this.Application = Application;
                this.InspectorID = InspectorID;
            end
            this.Adapter = [];
        end

        function useTimer = useTimerForObjects(this, objects)
            useTimer = this.UseTimerForHandleObjects;

            try
                if isa(objects, 'internal.matlab.inspector.EmptyObject')
                    % Don't start the timer if we are inspecting the
                    % EmptyObject. This is an internally created object that has
                    % no properties that we need to monitor with the timer.
                    useTimer = false;
                elseif isa(objects, 'internal.matlab.inspector.InspectorProxyMixin') && ...
                        isa(objects.OriginalObjects, 'internal.matlab.inspector.EmptyObject')
                    useTimer = false;
                elseif isa(objects, 'handle') && any(~isvalid(objects), "all")
                    useTimer = false;
                end
            catch
                % Handle errors... and assume timer won't be needed
                useTimer = false;
            end
        end

        % Called to inspect an object or array of objects.  If the
        % workspace is not provided, it defaults to caller.  name is
        % optional, and is required only for non-handle (value) objects.
        % Returns the Document if an output argument is specified.
        function varargout = inspect(this, objects, ...
                multiplePropertyCombinationMode, ...
                multipleValueCombinationMode, ws, name, parentObject, childIndex)
            internal.matlab.datatoolsservices.logDebug("pi", "Inspector.inspect: (" + class(objects) + ")");
            if nargin < 2 || isempty(objects)
                objects = internal.matlab.inspector.EmptyObject;
            end
            
            % Setup MultiplePropertyCombinationMode
            if nargin < 3 || isempty(multiplePropertyCombinationMode)
                this.MultiplePropertyCombinationMode = ...
                    internal.matlab.inspector.MultiplePropertyCombinationMode.getDefault;
            else
                this.MultiplePropertyCombinationMode = ...
                    internal.matlab.inspector.MultiplePropertyCombinationMode.getValidMultiPropComboMode(...
                    multiplePropertyCombinationMode);
            end
            
            % Setup MultipleValueCombinationMode
            if nargin < 4 || isempty(multipleValueCombinationMode)
                this.MultipleValueCombinationMode = ...
                    internal.matlab.inspector.MultipleValueCombinationMode.getDefault;
            else
                this.MultipleValueCombinationMode = ...
                    internal.matlab.inspector.MultipleValueCombinationMode.getValidMultiValueComboMode(...
                    multipleValueCombinationMode);
            end
            
            if nargin < 5 || isempty(ws)
                ws = 'debug';
            end
            
            if nargin < 7 
                parentObject = [];
            end
            if nargin < 8
                childIndex = NaN;
            end
            
            % Get the mapped workspace
            workspace = this.getWorkspace(ws);
            
            % Check whether to use the timer for redisplay of the object (it
            % will be disabled if the time taken to check the object's
            % properties is too long).  Use the parent object if it is set,
            % since the children may be value objects or structs.
            if isempty(parentObject)
                useTimer = this.useTimerForObjects(objects);
            else
                useTimer = this.useTimerForObjects(parentObject);
            end
            
            % Create the DataModel
            DataModel = internal.matlab.inspector.MLInspectorDataModel(...
                'inspector', workspace, useTimer);
            
            % If the object is not an InspectorProxyMixin, create one to
            % wrap it in
            if ~isa(objects, 'internal.matlab.inspector.InspectorProxyMixin')
                % Create a DefaultInspectorProxyMixin for the objects.  It
                % doesn't matter if there is a single object or multiple
                % objects
                defaultProxy = this.getProxyForObjects(objects);
                if ~isa(objects, 'handle')
                    % Value objects need to provide a workspace and the
                    % name of the variable
                    defaultProxy.setWorkspace(workspace);
                    DataModel.Workspace = workspace;
                    DataModel.Name = name;
                end
                objectsToInspect = defaultProxy;
            elseif isscalar(objects)
                objectsToInspect = objects;
            else
                % For multiple objects which are already
                % InspectorProxyMixins, combine them into one
                objectsToInspect = ...
                    internal.matlab.inspector.InspectorProxyMixinArray(...
                    objects, this.MultiplePropertyCombinationMode, ...
                    this.MultipleValueCombinationMode);
            end
            
            if nargin > 5 && ~isempty(name) && ~isempty(workspace)
                DataModel.VariableWorkspace = workspace;
                DataModel.VariableName = name;
            end
            
            if isa(objects, 'handle')
                if ~isprop(this, this.INTERNAL_REF_NAME)
                    addprop(this, this.INTERNAL_REF_NAME);
                end
                this.handleVariable = objectsToInspect;
                objectsToInspect.setWorkspace(this);
                DataModel.Workspace = this;
                DataModel.Name = this.INTERNAL_REF_NAME;
                
                this.DeletionListeners{end+1} = event.listener(...
                    objectsToInspect, 'ObjectBeingDestroyed', ...
                    @this.deletionCallback);
            else
                % Value objects need the name set in order to be
                % functional, so use it if it is set.  Only under test
                % conditions we may see it be empty.
                if ~isempty(name)
                    DataModel.Name = name;
                else
                    DataModel.Name = this.INTERNAL_REF_NAME;
                end
            end
            DataModel.Data = objectsToInspect;
            DataModel.updateListeners(objectsToInspect);

            % Save the previous MetaDataHandler (which provides the object
            % browser information), so we can reuse it if this new inspection
            % shares the same figure as the previously inspected object.
            [previousMetaDataHandler, previousFigAncestors] = this.getPreviousMetaDataInfo();

            % create MetaDataHandler for graphics objects, it is enough to check
            % if one object is an hg object because hg object are homogeneous.
            % Only show the object browser for the desktop inspector for now.
            if ~isa(objectsToInspect.OriginalObjects, "internal.matlab.inspector.EmptyObject") && ...
                    (strcmp(this.InspectorID, this.DEFAULT_INSPECTOR_ID) || this.ShowObjectBrowser)
                try
                    allGraphics = internal.matlab.inspector.Utils.isAllGraphics(objectsToInspect.OriginalObjects);
                    if allGraphics
                        figAncestors = ancestor(objectsToInspect.OriginalObjects, 'figure');
                    else
                        figAncestors = [];
                    end

                    if iscell(figAncestors)
                        parentedToFigure = any(~cellfun(@isempty, figAncestors));
                        isUIFigure = parentedToFigure && any(cellfun(@(x) matlab.ui.internal.FigureServices.isUIFigure(x),figAncestors));
                    else
                        parentedToFigure = any(~isempty(figAncestors));
                        isUIFigure = parentedToFigure && matlab.ui.internal.FigureServices.isUIFigure(figAncestors);
                    end

                    internal.matlab.datatoolsservices.logDebug("pi", "Parented to figure: " + parentedToFigure)
                    internal.matlab.datatoolsservices.logDebug("pi", "isUIFigure: " + isUIFigure)
                    internal.matlab.datatoolsservices.logDebug("pi", "allGraphics: " + allGraphics)

                    if ~isempty(previousMetaDataHandler) && parentedToFigure && isequal(figAncestors, previousFigAncestors)
                        % Reuse the previous MetaDataHandler, since this object
                        % shares the same figure ancestor, and will have the
                        % same top level object in the hierarchy.  Just update
                        % the RefObject (object being inspected)
                        internal.matlab.datatoolsservices.logDebug("pi", 'Reusing previous meta data handler')
                        DataModel.MetaDataHandler = this.Documents.ViewModel.DataModel.MetaDataHandler;
                        DataModel.MetaDataHandler.RefObject = objectsToInspect.OriginalObjects;
                        DataModel.metaDataChanged();
                    else
                        if  ~isUIFigure && (allGraphics || parentedToFigure)
                            % Any graphics object, or any object parented to a graphics
                            % object will show the graphics object hierarchy
                            if internal.matlab.datatoolsservices.getSetCmdExecutionTypeIdle
                                this.initMetaDataHandler(DataModel, objectsToInspect, true);
                            else
                                builtin('_dtcallback', @() this.initMetaDataHandler(DataModel, objectsToInspect, true));
                            end
                        elseif ~allGraphics
                            if ~isempty(parentObject)
                                % This needs to happen inline to avoid flashing
                                internal.matlab.datatoolsservices.logDebug("pi", "creating meta data for parented object: parent: " + class(parentObject) + ", objToInspect: " + class(objectsToInspect))
                                DataModel.MetaDataHandler = internal.matlab.inspector.ObjectHierarchyMetaData(parentObject, objectsToInspect, childIndex, DataModel.VariableName);
                                DataModel.MetaDataHandler.VariableName = DataModel.VariableName;
                                DataModel.MetaDataHandler.VariableWorkspace = DataModel.VariableWorkspace;
                            else
                                if internal.matlab.datatoolsservices.getSetCmdExecutionTypeIdle
                                    internal.matlab.datatoolsservices.logDebug("pi", "initMetaDataHandler inline")
                                    this.initMetaDataHandler(DataModel, objectsToInspect, false);
                                else
                                    internal.matlab.datatoolsservices.logDebug("pi", "initMetaDataHandler background")
                                    builtin('_dtcallback', @() this.initMetaDataHandler(DataModel, objectsToInspect, false));
                                end
                            end
                        end
                    end
                catch ex %#ok<NASGU> 
                    internal.matlab.datatoolsservices.logDebug("pi", "Exception caught")
                end
            else
                internal.matlab.datatoolsservices.logDebug("pi", 'not showing object browser')
            end
            
            % Create the ViewModel and Adapter
            ViewModel = internal.matlab.inspector.InspectorViewModel(...
                DataModel);
            this.Adapter = internal.matlab.inspector.MLInspectorAdapter(...
                DataModel.Name, DataModel.Workspace, DataModel, ViewModel);

            % Remove any existing Inspectors.  By default, the inspector is
            % a singleton, although multiple instances can be created
            % through the factory, by using different application IDs.
            if ~isempty(this.Documents) && isvalid(this.Documents)
                try
                    delete(this.Documents(1));
                catch
                end
                this.Documents = [];
            end
            
            % Call the super openvar to open the inspector object
            varDocument = openvar(this, DataModel.Name, ...
                DataModel.Workspace, objectsToInspect);
            DataModel.startTimer();
            if nargout == 1
                varargout = {varDocument};
            end
        end
        
        function proxy = getProxyForObjects(this, objects)
            proxy = ...
                internal.matlab.inspector.DefaultInspectorProxyMixin(...
                objects, this.MultiplePropertyCombinationMode, ...
                this.MultipleValueCombinationMode);
        end
        
        % Override the getVariableAdapter method to always return the
        % Inspector Adapter (there's no choices, like in the super class)
        function veVar = getVariableAdapter(this, ~, ~, ~, ~, ~, ~)
            veVar = this.Adapter;
        end

        function stopAutoRefresh(this)
            % Stop the inspector timer, which provides the auto-refresh
            % functionality.
            if ~isempty(this.Documents) && isvalid(this.Documents)
                try
                    internal.matlab.datatoolsservices.logDebug('ve::timer', 'stopAutoRefresh()');
                    vm = this.Documents.ViewModel;
                    vm.DataModel.UseTimer = false;
                    vm.DataModel.stopTimer();
                catch
                    internal.matlab.datatoolsservices.logDebug('ve::timer', 'stopAutoRefresh() error');
                end
            end
        end

        function startAutoRefresh(this)
            % Starts the inspector timer, which provides the auto-refresh
            % functionality.
            if ~isempty(this.Documents) && isvalid(this.Documents)
                try
                    internal.matlab.datatoolsservices.logDebug('ve::timer', 'startAutoRefresh()');
                    vm = this.Documents.ViewModel;
                    vm.DataModel.UseTimer = true;
                    vm.DataModel.restartTimer();
                catch
                    internal.matlab.datatoolsservices.logDebug('ve::timer', 'startAutoRefresh() error');
                end
            end
        end

        function refresh(this)
            % Called to do a one-shot refresh of the inspector display.  This is
            % done by triggering the timer callback.
            if ~isempty(this.Documents) && isvalid(this.Documents)
                try
                    internal.matlab.datatoolsservices.logDebug('ve::timer', 'refresh()');
                    vm = this.Documents.ViewModel;
                    vm.DataModel.timerClb();
                catch
                    internal.matlab.datatoolsservices.logDebug('ve::timer', 'refresh() error');
                end
            end
        end

        function initMetaDataHandler(~, dataModel, objectsToInspect, isGraphics)
            try
                if isvalid(dataModel)
                    if isGraphics
                        dataModel.MetaDataHandler = internal.matlab.inspector.GraphicsMetaData(objectsToInspect);
                    else
                        dataModel.MetaDataHandler = internal.matlab.inspector.ObjectHierarchyMetaData(objectsToInspect, [], NaN, dataModel.VariableName);
                    end

                    dataModel.MetaDataHandler.VariableName = dataModel.VariableName;
                    dataModel.MetaDataHandler.VariableWorkspace = dataModel.VariableWorkspace;

                    dataModel.metaDataChanged();
                end
            catch
                % This can error during test
                internal.matlab.datatoolsservices.logDebug("pi", "Error caught in initMetaDataHandler");
            end
        end
    end
        
    methods(Access = private)
        function removeDeletionListeners(this)
            if ~isempty(this.DeletionListeners)
                cellfun(@(x) delete(x), this.DeletionListeners);
            end
            this.DeletionListeners = {};
        end
        
        function deletionCallback(this, varargin)
            if ~isempty(this.Documents) && isvalid(this.Documents)
                % If the inspector is open, reopen it with an empty object
                try                    
                    % If the object exists in the ProxyMaps map, remove it when
                    % it is deleted
                    obj = varargin{1};
                    if isscalar(obj.OriginalObjects) && all(ishghandle(obj.OriginalObjects))
                        mapKey = double(obj.OriginalObjects);
                        if isKey(this.ProxyMaps, mapKey)
                            remove(this.ProxyMaps, mapKey);
                        end
                    end
                    
                    % If the object that was inspected and deleted was a
                    % graphics object, see if it has a figure ancestor
                    allGraphics = all(ishghandle(obj.OriginalObjects));
                    if allGraphics
                        parents = ancestor(obj.OriginalObjects, 'figure');
                    else
                        parents = [];
                    end
                    
                    if (allGraphics && all(isempty(parents))) || ~allGraphics
                        % If this is a graphics object, and it has a figure as a
                        % parent, a new object will be selected when one is
                        % deleted, so there's nothing to do here.  Otherwise,
                        % inspect the empty object for non-graphics objects or
                        % non-parented objects.
                        o = internal.matlab.inspector.EmptyObject;
                        this.inspect(o);
                    elseif allGraphics && ~all(isempty(parents)) && ...
                            internal.matlab.inspector.Utils.isComponentInUIFigure(obj.OriginalObjects) && ...
                            ~isequal(parents(1), obj.OriginalObjects) && isvalid(parents(1))
                        % If this is a graphics object, and it has a parent, and
                        % it is a component in a uifigure, inspect it.  (Due to
                        % selection differences in figure vs. uifigure, the
                        % parent won't automatically be selected on deletion)
                        this.inspect(parents(1));
                    end
                catch
                end
            end
        end

        function [previousMetaDataHandler, previousFigAncestors] = getPreviousMetaDataInfo(this)
            previousMetaDataHandler = [];
            previousFigAncestors = [];
            if ~isempty(this.Documents)
                try
                    previousMetaDataHandler = this.Documents.ViewModel.DataModel.MetaDataHandler;
                    inspectedObjects = this.Documents.ViewModel.DataModel.Data.OriginalObjects;
                    if internal.matlab.inspector.Utils.isAllGraphics(inspectedObjects)
                        previousFigAncestors = ancestor(inspectedObjects, 'figure');
                    else
                        previousFigAncestors = [];
                    end
                catch
                end
            end
        end
    end
end
