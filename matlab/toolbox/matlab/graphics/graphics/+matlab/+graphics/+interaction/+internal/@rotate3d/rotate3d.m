classdef (CaseInsensitiveProperties = true) rotate3d < matlab.graphics.interaction.internal.exploreaccessor
    %matlab.graphics.interaction.internal.rotate3d class extends matlab.graphics.interaction.internal.exploreaccessor
    %
    %    rotate3d properties:
    %       ButtonDownFilter - Property is of type 'MATLAB callback'
    %       ActionPreCallback - Property is of type 'MATLAB callback'
    %       ActionPostCallback - Property is of type 'MATLAB callback'
    %       Enable - Property is of type 'on/off'
    %       FigureHandle - Property is of type 'MATLAB array' (read only)
    %       ContextMenu - Property is of type 'MATLAB array'
    %
    %    graphics.rotate3d methods:
    %       isAllowAxesRotate -  Given an axes, determine whether panning is allowed
    %       setAllowAxesRotate -  Given an axes, determine whether rotate3d is allowed
    
    %   Copyright 2013-2024 The MathWorks, Inc.
    
    properties (AbortSet, SetObservable, GetObservable)
        %ROTATESTYLE Property is no longer supported. Leaving property to
        %avoid sudden errors, but this property no longer has any use.
        RotateStyle = 'orbit';
    end
    
    properties(Hidden, AbortSet, SetObservable, GetObservable)
        UIContextMenu = [];
    end

    properties (Dependent, AbortSet, SetObservable, GetObservable)
        %CONTEXTMENU Property is of type 'MATLAB array'
        ContextMenu;      
    end
    
    methods  % constructor block
        function [hThis] = rotate3d(hMode)
            % Constructor for the rotate3d mode accessor
            hThis = hThis@matlab.graphics.interaction.internal.exploreaccessor(hMode);
            
            % Syntax: matlab.graphics.internal.rotate3d(mode)
            if ~isvalid(hMode) || ~isa(hMode,'matlab.uitools.internal.uimode')
                error(message('MATLAB:graphics:rotate3d:InvalidConstructor'));
            end
            if ~strcmpi(hMode.Name,'Exploration.Rotate3d')
                error(message('MATLAB:graphics:rotate3d:InvalidConstructor'));
            end
            if isfield(hMode.ModeStateData,'accessor') && ...
                    ishandle(hMode.ModeStateData.accessor)
                error(message('MATLAB:graphics:rotate3d:AccessorExists'));
            end
            
            set(hThis,'ModeHandle',hMode);
            
            % Add a listener on the figure to destroy this object upon figure deletion
            addlistener(hMode.FigureHandle,'ObjectBeingDestroyed',@(obj,evd)(delete(hThis)));
        end  % rotate3d
        
    end  % constructor block
    
    methods
        function value = get.RotateStyle(~)
            value = 'orbit';
        end
        function set.RotateStyle(~,~)
            warning((message('MATLAB:graphics:rotate3d:FunctionToBeRemoved')));
        end
        
        function value = get.ContextMenu(obj)
            value = obj.UIContextMenu;
        end
        function set.ContextMenu(obj,value)
            obj.UIContextMenu = value;
        end
        
        function value = get.UIContextMenu(obj)
            value = localGetContextMenu(obj,obj.UIContextMenu);
        end
        function set.UIContextMenu(obj,value)
            if matlab.ui.internal.isUIFigure(obj.FigureHandle)
                enableLegacyExplorationModes(obj.FigureHandle);
            end
            obj.UIContextMenu = localSetContextMenu(obj,value);
        end
        
    end   % set and get functions
    
    methods  %% public methods
        res = isAllowAxesRotate(hThis,hAx)
        setAllowAxesRotate(hThis,hAx,flag)
    end  %% public methods
    
end  % classdef

%------------------------------------------------------------------------%
function valueToCaller = localGetContextMenu(hThis,~)
valueToCaller = hThis.ModeHandle.ModeStateData.CustomContextMenu;
end  % localGetContextMenu


%-----------------------------------------------%
function newValue = localSetContextMenu(hThis,valueProposed)
if strcmpi(hThis.Enable,'on')
    error(message('MATLAB:graphics:rotate3d:ReadOnlyRunning'));
end
if ~isempty(valueProposed) && ~ishghandle(valueProposed,'uicontextmenu')
    error(message('MATLAB:graphics:rotate3d:InvalidContextMenu'));
end
newValue = valueProposed;
hThis.ModeHandle.ModeStateData.CustomContextMenu = valueProposed;
end  % localSetContextMenu

