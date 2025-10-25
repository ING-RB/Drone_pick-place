classdef GridSelector < matlab.graphics.controls.selectors.BaseSelector
    %GRIDSELECTOR This class allows user to select which axes they want
    %   to apply their grid to from the Figure Toolstrip

    % Copyright 2021-2024 The MathWorks, Inc.
    properties
        GridType;        
    end

    methods
        function obj = GridSelector(ax, gridType)
            obj@matlab.graphics.controls.selectors.BaseSelector(ax);
            obj.FeatureName = 'Grid';
            obj.GridType = gridType;
            
            obj.Flag = [] ;

            service = matlab.plottools.service.MetadataService.getInstance();
            adapter = service.getMetaDataAccessor(ax);
            lastValue = adapter.get(obj.GridType);
            
            if  ~isempty(lastValue) && strcmpi(lastValue, 'off')
                obj.Flag = 'on';
                obj.Control.String = obj.getMessageString( "DefaultString_Selector_AddGrid" );
            elseif ~isempty(lastValue) && strcmpi(lastValue, 'on')
                obj.Flag = 'off';
                obj.Control.String = obj.getMessageString( "DefaultString_Selector_RemoveGrid" );
            end
        end

    end

    methods(Access=public)
        function enable(obj)
            if ~isempty(obj.Flag)
               obj.enable@matlab.graphics.controls.selectors.BaseSelector();
            end

        end
    end

    methods(Access=protected)
        function id = getCodegenActionId(obj)
            if strcmpi (obj.GridType, 'Grid') && strcmpi (obj.Flag, 'on')
                id = matlab.internal.editor.figure.ActionID.GRID_ADDED;
            elseif strcmpi (obj.GridType, 'Grid') && strcmpi (obj.Flag, 'off')
                id = matlab.internal.editor.figure.ActionID.GRID_REMOVED;
            elseif strcmpi (obj.GridType, 'XGrid') && strcmpi (obj.Flag, 'on')
                id = matlab.internal.editor.figure.ActionID.XGRID_ADDED;
            elseif strcmpi (obj.GridType, 'XGrid') && strcmpi (obj.Flag, 'off')
                id = matlab.internal.editor.figure.ActionID.XGRID_REMOVED;
            elseif strcmpi (obj.GridType, 'YGrid') && strcmpi (obj.Flag, 'on')
                id = matlab.internal.editor.figure.ActionID.YGRID_ADDED;
            elseif strcmpi (obj.GridType, 'YGrid') && strcmpi (obj.Flag, 'off')
                id = matlab.internal.editor.figure.ActionID.YGRID_REMOVED;
            elseif strcmpi (obj.GridType, 'ZGrid') && strcmpi (obj.Flag, 'on')
                id = matlab.internal.editor.figure.ActionID.ZGRID_ADDED;
            elseif strcmpi (obj.GridType, 'ZGrid') && strcmpi (obj.Flag, 'off')
                id = matlab.internal.editor.figure.ActionID.ZGRID_REMOVED;
            elseif strcmpi (obj.GridType, 'RGrid') && strcmpi (obj.Flag, 'on')
                id = matlab.internal.editor.figure.ActionID.RGRID_ADDED;
            elseif strcmpi (obj.GridType, 'RGrid') && strcmpi (obj.Flag, 'off')
                id = matlab.internal.editor.figure.ActionID.RGRID_REMOVED;
            elseif strcmpi (obj.GridType, 'ThetaGrid') && strcmpi (obj.Flag, 'on')
                id = matlab.internal.editor.figure.ActionID.THETAGRID_ADDED;
            elseif strcmpi (obj.GridType, 'ThetaGrid') && strcmpi (obj.Flag, 'off')
                id = matlab.internal.editor.figure.ActionID.THETAGRID_REMOVED;
            end
        end

        function setPosition(obj)
            % Get pixel position for object
             pos = getpixelposition(obj.Target);

            controlHeight = 20;
            controlWidth = 100;

            obj.Control.Position = [pos(1) + pos(3)/2 - controlWidth/2,...
                pos(2) + pos(4)/2 + 2,...
                controlWidth,...
                controlHeight,...
                ];
        end

        function info = getUndoInfo(obj)
            % Create the struct to add this info to the undo/redo stack
            % We need to use the MetaDataService to add to the stack as we
            % use it to update the state of the grid
            service = matlab.plottools.service.MetadataService.getInstance();
            adapter = service.getMetaDataAccessor(obj.Target);            
            currentValue =  adapter.get(obj.GridType);
            
            if strcmpi(currentValue, 'on')
                oldValue = 'off';
            else
                oldValue = 'on';
            end

            types = obj.GridType;

            info.Name = types;
            info.Object = obj.Target;
            info.Fcn = @(~,~) adapter.set(types, currentValue);
            info.InvFcn = @(~,~) adapter.set(types, oldValue);
        end

        function clickedCallback(obj, ~)
            % Turn off the Control first otherwise it looks like it didn't
            % work
            obj.Control.Visible = 'off';

            service = matlab.plottools.service.MetadataService.getInstance();
            adapter = service.getMetaDataAccessor(obj.Target);
            adapter.set(obj.GridType, obj.Flag);

            obj.registerUndo();

            obj.Control.Visible = 'off';

            obj.generateCode();

            delete(obj);
        end
    end
end

