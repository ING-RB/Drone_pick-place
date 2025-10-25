classdef ComponentContainerView < internal.matlab.inspector.InspectorProxyMixin
    % This class is unsupported and might change or be removed without notice in
    % a future version.
    
    % This class defines the proxy view for user authored components, which
    % extend from matlab.ui.componentcontainer.ComponentContainer.  It maps the
    % inherited properties into the same groupings as other graphics components,
    % and then all of the properties it defines itself are put in a single
    % group, which has the name of the component as its group name.
    
    % Copyright 2020 The MathWorks, Inc.

    properties
        % These are all of the properties inherited from ComponentContainer
        BackgroundColor
        BeingDeleted
        BusyAction
        ButtonDownFcn
        Children
        Clipping
        ContextMenu
        CreateFcn
        DeleteFcn
        HandleVisibility
        InnerPosition
        Interruptible
        Layout
        OuterPosition
        Parent
        Position
        SizeChangedFcn
        Tag
        Type
        Units
        UserData
        Visible
    end
    
    methods
        function this = ComponentContainerView(obj)
            this@internal.matlab.inspector.InspectorProxyMixin(obj);
            
            % Build up a list of properties which are not inherited, by
            % comparing properties of the passed in object to those defined
            % above for the proxy view.
            p = properties(obj);
            propsToAdd = strings(0);
            for idx = 1:length(p)
                if ~isprop(this, p{idx})
                    propsToAdd(end + 1) = p{idx}; %#ok<AGROW>
                end
            end
            
            if ~isempty(propsToAdd)
                % There are properties which are not inherited.  Create a group
                % for them,  using the component name as the group name, and add
                % all of them to the group.
                classname = class(obj);
                if contains(classname, ".")
                    classname = reverse(extractBefore(reverse(classname), "."));
                end
                g1 = this.createGroup(classname, "", "");
                for idx = 1:length(propsToAdd)
                    pi = this.addprop(propsToAdd(idx));
                    this.(pi.Name) = obj.(pi.Name);
                    
                    g1.addProperties(propsToAdd(idx));
                end
                
                % Set this first group to be expanded by default
                g1.Expanded = true;
            end
            
            % For all properties which are inherited from ComponentContainer,
            % add them to pre-defined groups.  These groups more or less match
            % those of other components -- but I combined a couple into logical
            % groups so that there were no groups with just one property in it.
            g2 = this.createGroup("MATLAB:propertyinspector:ColorandStyling", "", "");
            g2.addProperties("BackgroundColor", "Clipping", "Layout");
            g2.Expanded = true;
            
            g3 = this.createGroup("MATLAB:propertyinspector:Position", "", "");
            g3.addEditorGroup("OuterPosition");
            g3.addEditorGroup("InnerPosition");
            g3.addEditorGroup("Position");
            g3.addProperties("Units");
            g3.Expanded = true;
            
            g4 = this.createGroup("MATLAB:propertyinspector:Interactivity", "", "");
            g4.addProperties("Visible", "ContextMenu");
            
            g5 = this.createGroup("MATLAB:propertyinspector:Callbacks", "", "");
            g5.addProperties("ButtonDownFcn", "CreateFcn", "DeleteFcn", "SizeChangedFcn");
            
            g6 = this.createGroup("MATLAB:propertyinspector:CallbackExecutionControl", "", "");
            g6.addProperties("Interruptible", "BusyAction", "BeingDeleted");
            
            g7 = this.createGroup("MATLAB:propertyinspector:ParentChild", "", "");
            g7.addProperties("Parent", "Children", "HandleVisibility");
            
            g8 = this.createGroup("MATLAB:propertyinspector:Identifiers", "", "");
            g8.addProperties("Type", "Tag", "UserData");
        end
    end
end