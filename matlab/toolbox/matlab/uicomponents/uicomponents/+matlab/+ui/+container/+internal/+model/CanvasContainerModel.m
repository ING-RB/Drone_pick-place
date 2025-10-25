classdef (Hidden) CanvasContainerModel < matlab.ui.container.internal.model.ContainerModel &...
        matlab.ui.internal.mixin.CanvasHostMixin
    %
    
    % Copyright 2020 The MathWorks, Inc.

    methods
        function obj = CanvasContainerModel(varargin)
            obj = obj@matlab.ui.container.internal.model.ContainerModel(varargin);
        end
        
        function controller = createController(obj, parentController, ~)
            controller = createController@matlab.ui.container.internal.model.ContainerModel(obj,...
                parentController);
            
            % Now call configureController on the CanvasHostMixin
            if (isprop(controller, 'Canvas'))
                obj.configureCanvasController(controller); 
            end
        end
    end
    
    methods(Hidden)
        function c = doCollectChildren(obj)
            % Defer to CanvasHostMixin for collection of Children
            c = obj.collectCanvasChildren();
        end
    end
    
    methods (Access = 'protected')
        function handleChildAdded(obj, childAdded)
            if isa(childAdded, 'matlab.graphics.primitive.canvas.HTMLCanvas')
                childAdded.addCanvasChildAddedObserver(obj);
                postCanvasChildAdded(obj, childAdded);
                obj.markDirty(true);
            elseif isa(childAdded, ...
                    'matlab.graphics.shape.internal.AxesLayoutManager')
                % If an AxesLayoutManager is added, this results in the
                % axes first getting unparented and then reparented to the
                % AxesLayoutManager. During unparenting, the occupancyCount
                % is decremented. When AxesLayoutManager is added to the
                % hierarchcy, the axes is a child of ALM, so the occupancy
                % count is not incremented by the handleChildAdded of
                % GridLayout, since ALM does not have a layout property.
                % Therefore, we need to update this manually. 
                axesChild = childAdded.Axes; 
                
                if ~isempty(axesChild)
                    % Get the axes like child.
                    row = axesChild.Layout.Row;
                    col = axesChild.Layout.Column;
                    obj.increaseOccupancyCount(row, col);
                    obj.updateImplicitGridSize();
                end 
            end
        end
        
        function redrawContents(obj)
            % Mark canvas dirty to be redrawn
            obj.markCanvasChildrenDirty(); 
        end
    end
    
    methods (Access = ?matlab.graphics.primitive.canvas.Canvas)
        function handleCanvasChildAdded(obj, ~, child)
            handleChildAdded(obj, child); 
        end
        
        function handleCanvasChildRemoved(obj, ~, child)
            if isa(child, 'matlab.graphics.shape.internal.AxesLayoutManager')
                if ~isempty(child.Axes)
                    child = child.Axes;
                end
            end
            handleChildRemoved(obj, child);
        end
    end
end