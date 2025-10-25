% This class is unsupported and might change or be removed without notice in a
% future version.

% This is the base class for defining a rich editor UI to associate with a
% property in the Property Inspector.

% Copyright 2022 The MathWorks, Inc.

classdef UserRichEditorUI < matlab.ui.componentcontainer.ComponentContainer & handle

    properties
        InspectorID = '/PropertyInspector'
        Value
        PropertyName (1,1) string
        ProxyClass
    end

    methods
        function this = UserRichEditorUI(NameValueArgs)
            % Construct a UserRichEditorUI

            arguments
                NameValueArgs.?matlab.ui.componentcontainer.ComponentContainer
                NameValueArgs.Parent = uifigure
                NameValueArgs.Value = [];
                NameValueArgs.PropertyName (1,1) string = "";
                NameValueArgs.ProxyClass = [];
            end

            this@matlab.ui.componentcontainer.ComponentContainer(NameValueArgs);

            this.Value = NameValueArgs.Value;
            this.PropertyName = NameValueArgs.PropertyName;
            this.ProxyClass = NameValueArgs.ProxyClass;
            this.BackgroundColor = [1,1,1]; 
        end

        function setValue(this, newValue)
            % Set the new value for the property associated with this Rich
            % Editor.

            arguments
                this
                newValue
            end

            if isa(newValue, "internal.matlab.editorconverters.datatype.UserRichEditorUIType")
                % Save the actual value as the value which is set
                newValue = newValue.Value;
            end

            this.Value = newValue;
            this.update();
        end

        function setState(this, state)
            % Set the state for the property associated with this Rich Editor.

            arguments
                this %#ok<*INUSA> 
                state
            end
        end

        function richEditorClosed(this) %#ok<MANU> 
            % Called when the UserRichEditorUI's popup is closed.  Override this
            % function if there is action to take.
        end
    end

    methods(Sealed)
        function notifyValueChanged(this, value)
            % Can be called to notify the Property Inspector infrastructure that
            % the value of a property has changed.

            arguments
                this

                % The new value of the property
                value
            end

            try
                m = internal.matlab.inspector.peer.InspectorFactory.getInspectorInstances;
                if any(contains(keys(m), this.InspectorID))
                    inspector = m(this.InspectorID);
                    vm = inspector.Documents.ViewModel;

                    st = struct;
                    st.property = this.PropertyName;
                    st.value = value;
                    vm.clientSetData(st);
                end
            catch
                % Ignore errors here, it can be the result of callbacks firing
                % after objects are reinspected
            end
        end
    end

    methods(Hidden)
        function figureData = getFigureData(this)
            % Called by the inspector infrastructure to get the figure data from
            % the divfigure UI.
            figureData = matlab.ui.internal.FigureServices.getDivFigurePacket(ancestor(this, "figure"));
            figureData = jsonencode(figureData);
        end
    end

    methods(Abstract)
        % Called to get the property label to show in the main inspector
        % display.  Label should be a string.
        label = getPropertyLabel(this);

        % Called to get the rich editor size.  Size must be an array
        % [width,height].
        size = getEditorSize(this);
    end
end
