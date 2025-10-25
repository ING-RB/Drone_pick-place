classdef AxesKeyboardInteractionManager < handle
%

%   Copyright 2024 The MathWorks, Inc.
    
    properties (SetObservable)
        Interactions = {}
    end

    properties 
        AxesStateBeforeInteraction
        Fig
    end

    methods
        function obj = AxesKeyboardInteractionManager()
        end
        
        function handleKeyDown(obj, ax, evd)
            if ~isempty(obj.Fig) && isvalid(obj.Fig)
                matlab.graphics.interaction.internal.toggleAxesLayoutManager(obj.Fig, ax, false);
            end

            arrowKeyFcn = {};
            plusMinusKeyFcn = {};
            
            if obj.contains(obj.Interactions, @matlab.graphics.interaction.keyboardinteraction.rotateKeyPressFcn)
                arrowKeyFcn = @matlab.graphics.interaction.keyboardinteraction.rotateKeyPressFcn;
            elseif obj.contains(obj.Interactions, @matlab.graphics.interaction.keyboardinteraction.panKeyPressFcn)
                arrowKeyFcn = @matlab.graphics.interaction.keyboardinteraction.panKeyPressFcn;
            end

            if obj.contains(obj.Interactions, @matlab.graphics.interaction.keyboardinteraction.zoomKeyPressFcn)
                plusMinusKeyFcn = @matlab.graphics.interaction.keyboardinteraction.zoomKeyPressFcn;

                if(isempty(arrowKeyFcn))
                    arrowKeyFcn = plusMinusKeyFcn;
                end
            end
            
            evd.Key = obj.getKey(evd.Key);

            oldState = obj.getAxesState(ax); 

            keyconsumed = false;

            switch evd.Key

                case {'uparrow', 'downarrow', 'leftarrow', 'rightarrow'}
                    if ~isempty(arrowKeyFcn)
                        keyconsumed = arrowKeyFcn(ax, evd);
                    end
                case {'plus', 'minus'}
                    if ~isempty(plusMinusKeyFcn)
                       keyconsumed = plusMinusKeyFcn(ax, evd);
                    end
            end

            if keyconsumed && isempty(obj.AxesStateBeforeInteraction)
                obj.AxesStateBeforeInteraction = oldState; 
            end

        end

        function handleKeyUp(obj, ax, ~)

            if(isempty(obj.AxesStateBeforeInteraction))
                return; 
            end
            
            obj.generateLiveCode(ax); 
            obj.addToUndoRedoStack(ax);

            % Once the interaction has generated code and added to the
            % undo/redo stack, remove the axes' old state. 
            obj.AxesStateBeforeInteraction = struct([]);

            if ~isempty(obj.Fig) && isvalid(obj.Fig)
                matlab.graphics.interaction.internal.toggleAxesLayoutManager(obj.Fig, ax, true);
            end
        end

        function generateLiveCode(obj, ax)
            old_state = obj.AxesStateBeforeInteraction; 

            old_view = old_state.View;

            if(~isequal(ax.View, old_view))
                % If the view property has changed, a rotate interaction has occurred.
                matlab.graphics.interaction.generateLiveCode(ax, ...
                    matlab.internal.editor.figure.ActionID.ROTATE);
            else
                % Otherwise, a pan or zoom interaction has occurred.
                matlab.graphics.interaction.generateLiveCode(ax, ...
                    matlab.internal.editor.figure.ActionID.PANZOOM);
            end
        end

        function addToUndoRedoStack(obj, ax)
            old_state = obj.AxesStateBeforeInteraction; 
            
            old_xlim = old_state.XLim;
            old_ylim = old_state.YLim;
            old_zlim = old_state.ZLim;
            old_view = old_state.View;

            new_xlim = ax.XLim;
            new_ylim = ax.YLim;
            new_zlim = ax.ZLim;
            new_view = ax.View;

            % Get the axes proxy to protect against axes deletion
            axProxy = plotedit({'getProxyValueFromHandle', ax});

            fig = ancestor(ax, 'figure');

            % Add to the figure's undo/ redo stack
            cmd.Name = '';

            cmd.Function = @changeAxesState;
            cmd.Varargin = {fig, axProxy, new_xlim, new_ylim, new_zlim, new_view};

            cmd.InverseFunction = @changeAxesState;
            cmd.InverseVarargin = {fig, axProxy, old_xlim, old_ylim, old_zlim, old_view};

            uiundo(fig, 'function', cmd);
        end

    end

    methods (Hidden)
        % Helper functions 
        
        function tf = contains(~, interactions, i)
            tf = false; 

            for idx = 1:numel(interactions)
                interaction = interactions{idx};

                if isequal(interaction, i)
                    tf = true;
                    break;
                end
            end
        end

        function key = getKey(~, jsKey)
            % The key that JS gives us is not what MATLAB expects. So
            % convert the JS key into MATLABese. 
            
            switch jsKey
                case 'ArrowLeft'
                    key = 'leftarrow';
                case 'ArrowRight'
                    key = 'rightarrow';
                case 'ArrowUp'
                    key = 'uparrow';
                case 'ArrowDown'
                    key = 'downarrow';
                case {'+', '='}
                    key = 'plus';
                case '-'
                    key = 'minus';
                otherwise
                    key = jsKey;
            end

        end

        function state = getAxesState(~, ax)
            state.XLim = ax.XLim;
            state.YLim = ax.YLim;
            state.ZLim = ax.ZLim;
            state.View = ax.View; 
        end
    end
end


function changeAxesState(fig, axProxy, xlim, ylim, zlim, view)

ax = plotedit({'getHandleFromProxyValue', fig, axProxy});

if(~ishghandle(ax))
    return;
end

ax.XLim = xlim;
ax.YLim = ylim;
ax.ZLim = zlim;
ax.View = view;

end

