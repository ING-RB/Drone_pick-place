classdef(Abstract) BaseSelector < handle
    % BASESELECTOR Abstract base class for objects that handle the
    % selection of actions from the figure toolstrip
    
    % Copyright 2021-2024 The MathWorks, Inc.       
    properties(Constant)
        SELECTOR_TAG = "ML_TS_Selector";
        
        CATALOG_KEY = "MATLAB:uistring:figuretoolbar";
        
        BACKDROP_COLOR =  [0, 153/255, 1];
        
        TEXT_COLOR = [36/255,36/255,36/255];
        
        HOVER_COLOR = [0, 153/255, 1];
    end

    properties(Access=protected)
        % Target Object for the Selection
        Target;

        % The Control Object that represents the selection button
        % affordance
        Control;

        % The BackDrop object is a billboard for rendering the Control
        BackDrop;
        
        % Listener for the BackDrop when the Control becomes Visible
        ControlVisibleListener;
        
        % Listener for hit events on the Control
        HitListener;

        % Listener for click events that should dismiss the selectors
        DismissListener;
        
        % Listener for resize events that should dismiss the selectors
        ResizeListener;
        
        % Listener for when the object is hover upon
        HoverListener;

        % Listener for when the Target is deleted
        TargetDeletedListener;

        % Name of the feature the selector applies to. Used for isSupported
        % function
        FeatureName;

        % Flag for setting different properties 
        Flag
    end

    methods
        function obj = BaseSelector(gObj)

            obj.FeatureName = '';

            obj.Target = gObj;

            canvasContainer = ancestor(gObj, 'matlab.ui.internal.mixin.CanvasHostMixin');
            if ~isempty(canvasContainer) && isvalid(canvasContainer)
                
                obj.BackDrop = annotation(canvasContainer, "rectangle",...                    
                    "FaceColor", "white",...                    
                    "Units", "pixels",...                   
                    "EdgeColor", "none",...
                    'Visible',"off");
                
                obj.Control = annotation(canvasContainer, "textbox",...
                    "Tag", obj.SELECTOR_TAG,...                    
                    "FaceAlpha", .2,...
                    "BackgroundColor", obj.BACKDROP_COLOR,...
                    "Color", obj.TEXT_COLOR,... 
                    "FontAngle", "italic",...
                    "HorizontalAlignment", "center",...
                    "Units", "pixels",...
                    "VerticalAlignment", "middle",...
                    "EdgeColor", "none",...
                    'Visible',"off");

                obj.TargetDeletedListener = event.listener(obj.Target, 'ObjectBeingDestroyed',...
                    @(~,~)delete(obj));

                obj.ControlVisibleListener = event.proplistener(obj.Control,...
                    obj.Control.findprop('Visible'),'PostSet', @(~,~) obj.setBackDrop());
                
                % attach a listener to provide a highlighting when hovered
                % on
                obj.HoverListener = event.listener(canvasContainer.getCanvas(), 'ButtonMotion',...
                    @(evt,mouseData)obj.hoverCallback(evt, mouseData));
                
                % Attach a listener to the canvas so we can detect the hit
                % object
                obj.DismissListener = event.listener(canvasContainer.getCanvas(), 'ButtonDown',...
                    @(evt,mouseData)obj.dismissedCallback(evt, mouseData));

                % Upon a resize, dismiss the selector
                obj.ResizeListener = event.listener(canvasContainer, 'SizeChanged',...
                    @(~,~)delete(obj));
                                
                 obj.setInputState();
            end
        end

        function enable(obj)            
            if ~isempty(obj.Control) && obj.isSupported()
                obj.Control.Visible = 'on';
            end
        end
        
        function delete(obj)
            obj.Target = [];
                        
            delete(obj.BackDrop);
            delete(obj.Control);            
        end
    end

    methods(Abstract, Access=protected)

        % Get the Action Id for the Code to Generate
        getCodegenActionId(obj);
        
        % Set the position of the Control
        setPosition(obj);

        % The callback for the HitListener
        clickedCallback(obj);

        % Get the undo/redo metadata for this operation
        info = getUndoInfo(obj);                
    end

    methods(Access=protected)

        % returns true if this selector operation is supported on Target
        function result = isSupported(obj)
            service = matlab.plottools.service.MetadataService.getInstance();
            acc = service.getMetaDataAccessor(obj.Target);

            result = acc.isSupported(obj.FeatureName);
        end

        function str = getMessageString(obj, key)
            str = matlab.internal.Catalog(obj.CATALOG_KEY).getString(key);
        end
        
        function setInputState(obj)
            obj.HitListener = event.listener(obj.Control, 'Hit',...
                @(~,~)obj.BaseClickedCallback());

            obj.setPosition();
        end

        function BaseClickedCallback(obj)
            % Only response to left click
            fig = ancestor(obj.Target, 'figure');
            if strcmp(get(fig, 'SelectionType'), 'normal')
                obj.clickedCallback()
            end
        end

        function generateCode(obj)            
            % Trigger an InteractionOccured on the CodeGenerationProxy
            % so that the FigureCodeGenController will update the 
            % CodeGeneratorUI
            figObj = ancestor(obj.Target, 'figure');
            if isprop(figObj, "FigureCodeGenController")
                % Generate code
                matlab.graphics.interaction.generateLiveCode(obj.Target, obj.getCodegenActionId());                
                
                figObj.FigureCodeGenController.CodeGenerationProxy.notify('InteractionOccured');
            end
        end        
        
        function setBackDrop(obj)
            if isvalid(obj) && isvalid(obj.Control) && isvalid(obj.BackDrop)
                obj.BackDrop.Position = obj.Control.Position; 
                obj.BackDrop.Visible = obj.Control.Visible;
            end
        end
        
        function hoverCallback(obj, ~, mouseData)
            if ~isempty(mouseData.Primitive)
                anc = ancestor(mouseData.Primitive, class(obj.Control), 'node');
                
                if ~isempty(anc) && isequal(anc, obj.Control)
                    obj.Control.EdgeColor = obj.HOVER_COLOR;
                else
                    obj.Control.EdgeColor = 'none';
                end
            else
                 obj.Control.EdgeColor = 'none';
            end
        end
        
        function dismissedCallback(obj, ~, mouseData)
            % If I click anywhere outside of the Selectors, I should
            % dismiss all selectors
            if ~isempty(mouseData) && isprop(mouseData, 'Primitive') && ~isempty(mouseData.Primitive)...
                    && isvalid(mouseData.Primitive)

                selector = ancestor(mouseData.Primitive, 'matlab.graphics.shape.TextBox');

                % If I have a click event that landed outside of another
                % Selector object, I should dismiss all selector objects,
                % starting with this current object
                if isempty(selector) || ~strcmpi(selector.Tag, obj.SELECTOR_TAG)                
                    delete(obj);
                end
            else                
                delete(obj);
            end
        end

        function registerUndo(obj)
            % Register the fcn and its inverse to the undo stack
            undoData = obj.getUndoInfo();

            if ~isempty(undoData)
                cmd.Name = undoData.Name;
                cmd.Function = undoData.Fcn;
                cmd.InverseFunction  = undoData.InvFcn;
                cmd.Varargin = {undoData.Object};
                cmd.InverseVarargin = {undoData.Object};
                uiundo(ancestor(undoData.Object,'figure'),'function', cmd);
            end
        end
    end
end

