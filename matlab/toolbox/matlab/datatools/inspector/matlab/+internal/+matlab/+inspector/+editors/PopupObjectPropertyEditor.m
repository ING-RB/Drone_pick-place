classdef PopupObjectPropertyEditor < handle
    %POPUPOBJECTPROPERTYEDITOR Popup Propery Editor Using uivariableeditor
    %   This is a popup editor used to edit a property in an object.  It is
    %   built using the uivariableeditor.

    % Copyright 2020-2025 The MathWorks, Inc.

    properties (Constant)
        DEFAULT_POSITION = [100 100 640 480];
    end

    properties (Access = {?internal.matlab.inspector.editors.PopupObjectPropertyEditor, ?matlab.unittest.TestCase })
        UIFigure
        UIVariableEditor
        UIGridLayout

        Workspace;

        Debug (1,1) logical = false;
        InspectorID string {mustBeScalarOrEmpty};
    end

    properties (Dependent)
        InspectedObject
        PropertyName
        Position
        Visible
        Name
    end

    methods
        function obj = get.InspectedObject(this)
            obj = this.Workspace.InspectedObject;
        end

        function set.InspectedObject(this, obj)
            this.Workspace.InspectedObject = obj;
        end

        function val = get.PropertyName(this)
            val = this.Workspace.PropertyName;
        end

        function set.PropertyName(this, newName)
            oldName = this.Workspace.PropertyName;
            this.Workspace.PropertyName = newName;
            if strlength(this.Name) == 0 || strcmp(this.Name, oldName)
                this.Name = newName;
            end
        end

        function setObjectAndProperty(this, obj, prop)
            this.Workspace.setObjectAndProperty(obj, prop);
        end

        function pos = get.Position(this)
            pos = this.DEFAULT_POSITION;
            if ~isempty(this.UIFigure) && isvalid(this.UIFigure)
                pos = this.UIFigure.Position;
            end
        end

        function set.Position(this, newPos)
            this.UIFigure.Position = newPos;
        end

        function visible = get.Visible(this)
            visible = [];
            if ~isempty(this.UIFigure) && isvalid(this.UIFigure)
                visible = this.UIFigure.Visible;
            end
        end

        function set.Visible(this, newVis)
            this.UIFigure.Visible = newVis;
        end

        function name = get.Name(this)
            name = "";
            if ~isempty(this.UIFigure) && isvalid(this.UIFigure)
                name = this.UIFigure.Name;
            end
        end

        function set.Name(this, newName)
            this.UIFigure.Name = newName;
        end
    end

    properties
        PropertyValueChangFcn function_handle = function_handle.empty;
        DialogClosedFcn function_handle = function_handle.empty;
    end

    methods
        function this = PopupObjectPropertyEditor(NVPairs)
            %POPUPOBJECTPROPERTYEDITOR Construct an instance of the popup
            %object property editor
            arguments
                NVPairs.InspectedObject = []
                NVPairs.PropertyName string = string.empty
                NVPairs.Position = internal.matlab.inspector.editors.PopupObjectPropertyEditor.DEFAULT_POSITION
                NVPairs.PropertyValueChangFcn function_handle = function_handle.empty
                NVPairs.DialogClosedFcn function_handle = function_handle.empty
                NVPairs.Visible (1,1) logical = false
                NVPairs.Name string = string.empty
                NVPairs.Debug (1,1) logical = false
                NVPairs.Editable (1,1) logical = true
                NVPairs.InspectorID string = string.empty
                NVPairs.InfiniteGrid (1,1) logical = false
            end

            this.Workspace = internal.matlab.inspector.editors.ObjectPropertyWorkspace;
            this.Debug = NVPairs.Debug;
            this.InspectorID = NVPairs.InspectorID;
            this.setObjectAndProperty(NVPairs.InspectedObject, NVPairs.PropertyName);
            this.setupComponents(NVPairs.Editable, NVPairs.InfiniteGrid);

            this.PropertyValueChangFcn = NVPairs.PropertyValueChangFcn;
            this.DialogClosedFcn = NVPairs.DialogClosedFcn;

            if ~isempty(NVPairs.Name)
                this.Name = NVPairs.Name;
            else
                this.Name = NVPairs.PropertyName;
            end
            this.Position = NVPairs.Position;
            this.Visible = NVPairs.Visible;
        end

        function delete(this)
            try
                delete(this.UIVariableEditor.Parent.Parent)
            catch
            end
        end
    end

    methods (Access = protected)
        function setupComponents(this, editable, infiniteGrid)
            arguments
                this
                editable (1,1) logical
                infiniteGrid (1,1) logical
            end

            import matlab.internal.capability.Capability;

            if ~this.Debug
                % Set the tag to the Property Name, and UserData to the
                % InspectorID, so this can be identified later on
                this.UIFigure = uifigure('Position', this.DEFAULT_POSITION, ...
                    'Visible', false, ...
                    'CloseRequestFcn', @(es,ed)this.figureClosedCallback(es,ed), ...
                    'Tag', this.PropertyName, ...
                    'UserData', this.InspectorID);

                if ~Capability.isSupported(Capability.LocalClient)
                    % Only set the popup as modal in MATLAB Online.  In the
                    % other configurations they are only modal to themselves,
                    % and not the main desktop or inspector.
                    this.UIFigure.WindowStyle = "modal";
                end
            else
                this.UIFigure = uifigure_debug();
            end

            this.UIGridLayout = uigridlayout(this.UIFigure);
            this.UIGridLayout.ColumnWidth = {'1x'};
            this.UIGridLayout.RowHeight = {'1x'};

            % Infinite grid requires selectable to be true.  By default it is
            % off, because there's nothing you can do with selection in the
            % popup VE anyway.
            if infiniteGrid
                selectable = true;
            else
                selectable = false;
            end
            this.UIVariableEditor = matlab.ui.control.internal.VariableEditor(...
                "Parent", this.UIGridLayout, ...
                "Workspace", this.Workspace, ...
                "Variable", "PropertyData", ...
                "DataSelectable", selectable, ...
                "DataEditable", editable, ...
                "DataSortable", false, ...
                "RowHeadersVisible", true, ...
                "DataFilterable", false, ...
                "InfiniteGrid", infiniteGrid);
            this.UIVariableEditor.DataEditCallbackFcn = @(d)this.propertyChangeCallback(d);
            this.Workspace.ErrorCallbackFcn = @(p,ex) this.propertyChangeErrCallback(p,ex);
        end

        function figureClosedCallback(this, fig, ed)
            this.UIFigure.Visible = false;
            if ~isempty(this.DialogClosedFcn)
                try
                    this.DialogClosedFcn(this, ed);
                catch e
                    disp(e);
                end
            end
            % Need to delete a modal window, otherwise it can remain blocking interaction
            delete(fig)
        end

        function propertyChangeCallback(this, ed)
            if ~isempty(this.PropertyValueChangFcn)
                try
                    this.PropertyValueChangFcn(this, ed);
                catch e
                    disp(e);
                end
            end
        end

        function propertyChangeErrCallback(this, propName, ex)
            % Called when there is an error assigning the property value.
            % Deletes the UIVariableEditor and display the error in a error
            % window (uialert).  When the error is closed, also close the
            % UIVariableEditor's figure window
            fig = this.UIVariableEditor.Parent.Parent;
            delete(this.UIVariableEditor.Parent);
            uialert(fig, regexprep(ex.message, '<.*?>', ''), propName, ...
                'CloseFcn', @(varargin) delete(fig));
        end
    end
end
