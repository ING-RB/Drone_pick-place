classdef MenuPropertyView < ...
        internal.matlab.inspector.InspectorProxyMixin & ...
        matlab.ui.internal.componentframework.services.optional.ControllerInterface
    
    % This class provides the property definition and groupings for UIMenu
    
    % It deviates from the architectural convention of subclassing from AppDesignerPropertyView
    % This is because AppDesignerPropertyView mixes in PositionMixin that
    % expects Position property to be of type matlab.graphics.datatype.Position
    % but UIMenu has a Position property that means something completely
    % different
    
    % Copyright 2017-2021 The MathWorks, Inc.
    
    properties(SetObservable = true)
        Accelerator char {matlab.internal.validation.mustBeVector(Accelerator)}
        Separator
        Checked
        
        ForegroundColor matlab.internal.datatype.matlab.graphics.datatype.RGBAColor
        BusyAction
        Interruptible matlab.lang.OnOffSwitchState
        
        Visible matlab.lang.OnOffSwitchState
        Enable matlab.lang.OnOffSwitchState
        Tooltip matlab.internal.datatype.matlab.graphics.datatype.NumericOrString
        
        Tag char {matlab.internal.validation.mustBeVector(Tag)}
        HandleVisibility matlab.internal.datatype.matlab.graphics.datatype.HandleVisibility
    end
    
    % The UIMenu component's API was updated to have a Text
    % property but there is still tech debt remaining to update
    % the view property (on peer-node) to reflect this
    %
    % The following configuration works around this by using the
    % Label property to look up and update the peer-node
    % but display 'Text' in the inspector
    %
    % When this work is completed, this workaround can be removed
    properties(SetObservable = true)
        Label char {matlab.internal.validation.mustBeVector(Label)}
    end
    
    methods
        function obj = MenuPropertyView(componentObject)
            obj = obj@internal.matlab.inspector.InspectorProxyMixin(componentObject);
            
            inspector.internal.CommonPropertyView.createPropertyInspectorGroup(obj, 'MATLAB:ui:propertygroups:MenuGroup',...
                'Label', 'Accelerator', 'Separator',...
                'Checked','ForegroundColor');

            % Set up the inspector to show "Text" for the display name of the
            % Label property
            obj.setPropertyDisplayName("Label", "Text");
            
            % Other menu properties
            % Do not create CommonInspectorGroup as it adds a FontGroup with
            % ForegroundColor property. For Menu, ForegroundColor is listed
            % as part of 'Menu' group itself.
            inspector.internal.CommonPropertyView.createInteractivityGroup(obj);
            inspector.internal.CommonPropertyView.createCallbackExecutionControlGroup(obj);
            inspector.internal.CommonPropertyView.createParentChildGroup(obj);
            inspector.internal.CommonPropertyView.createIdentifiersGroup(obj);
        end
        
    end
end
