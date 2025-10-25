classdef ScrollableDispatcher < matlab.uiautomation.internal.dispatchers.DispatchDecorator...
        ... Get Access to getNodesById
        & matlab.ui.internal.componentframework.services.optional.ControllerInterface
    % This class is undocumented and subject to change in a future release
    
    % Copyright 2020 - 2024 The MathWorks, Inc.
    properties(Access=private, Hidden)
        NonScrollToComponents = ["matlab.ui.container.toolbar.PushTool", "matlab.ui.container.toolbar.ToggleTool",...
            "matlab.ui.container.Menu", "matlab.ui.container.internal.AccordionPanel",...
            "matlab.ui.container.internal.AppContainer"];
    end
    
    methods
        
        function dispatch(decorator, model, varargin)
            
            if ~any(strcmp(class(model), decorator.NonScrollToComponents))
                scrollComponentIntoView(decorator, model, varargin{:});
            end
            
            dispatch@matlab.uiautomation.internal.dispatchers.DispatchDecorator( ...
                decorator, model, varargin{:});
            
        end
    end
    
    methods(Access='private')

        function scrollComponentIntoView(~, targetComponent, varargin)
            % scroll target component into application's viewport
            
            % find top ancestor container of the target component
            parentContainer = getTopAncestorContainer(targetComponent);
            function container = getTopAncestorContainer(component)
                while ~isa(component.Parent, 'matlab.ui.Root')
                    component = component.Parent;
                end
                container = component;
            end

            scroll(parentContainer, targetComponent);
            
            % if the target component belongs to the following class
            % further scroll to target is needed
            switch class(targetComponent)

                case "matlab.ui.control.Table"
                    % If last parameter is a struct, indicating that the
                    % gesture being performed is on a non-cell area, then
                    % return without scrolling
                    if isstruct(varargin{end})
                        return;
                    end
                    p = inputParser;
                    p.addRequired("gesture");
                    p.addRequired("row");
                    p.addRequired("rowNumber");
                    p.addRequired("column");
                    p.addRequired("columnNumber");
                    p.parse(varargin{1:5});
                    argsStruct = p.Results;
                    scroll(targetComponent, "cell", [argsStruct.rowNumber argsStruct.columnNumber]);

                case "matlab.ui.control.ListBox"
                    if varargin{1} == "uicontextmenu"
                        return;
                    end
                    p = inputParser;
                    p.addRequired("gesture");                    
                    p.addRequired("index");
                    p.addRequired("indexNumber");
                    p.parse(varargin{1:3});
                    argsStruct = p.Results;
                    scroll(targetComponent, targetComponent.Items{argsStruct.indexNumber});

                case {"matlab.ui.container.Tree", "matlab.ui.container.CheckBoxTree"}
                    p = inputParser;
                    p.addRequired("gesture");
                    p.addRequired("nodeId");
                    p.addRequired("Id");
                    p.parse(varargin{1:3});
                    argsStruct = p.Results;
                    id = string(argsStruct.Id);
                    treenode = targetComponent.getNodesById(id);
                    scroll(targetComponent, treenode);

                otherwise
                    return;
            end
            
        end
    end
end