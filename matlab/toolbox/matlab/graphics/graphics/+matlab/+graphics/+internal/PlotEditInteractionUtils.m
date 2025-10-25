classdef PlotEditInteractionUtils < handle
    % Utility class for managing the relationship between selected objects
    % in plot edit mode and the Interaction framework
    
    %   Copyright 2023-2025 The MathWorks, Inc.
    

    methods (Static)
                  
        function interactionArray = removeInteractionsFromObject(fig, objs)
            % Remove all the interaction objects associated with the
            % specifed object and return them so that they can be cached
            interactionArray = [];
            can = fig.getCanvas;
            if ~isprop(can,'InteractionsManager') || isempty(can.InteractionsManager)
                return
            end

            % There is no need to remove interactions from axes and charts
            % because they are already suspended because of the hardware
            % events
            objs = findobj(objs,'flat','-not','type','figure','-and','-not','-isa','matlab.graphics.axis.AbstractAxes');
            if isempty(objs) 
                return
            end
            interactionsManager = can.InteractionsManager;
            for k=1:length(objs)
                objId = getObjectID(objs(k));
                if interactionsManager.ObjectInteractionsMap.isKey(objId)
                    id = interactionsManager.ObjectInteractionsMap(objId);
                    if ~isempty(id)
                        for q= 1:length(id)
                            if interactionsManager.InteractionsMap.isKey(id(q))
                                interactionArray = interactionsManager.InteractionsMap(id(q));
                                interactionsManager.unregisterInteraction(interactionArray);
                            end
                        end
                    end
                end
            end
        end

        function reregisterInteractions(fig, interactionArray)
            % Reregister the cached interaction objects
            can = fig.getCanvas;
            if ~isprop(can,'InteractionsManager') || isempty(can.InteractionsManager)
                return
            end
            for k=1:length(interactionArray)
                if ~isempty(interactionArray{k}) && isvalid(interactionArray{k})
                    can.InteractionsManager.registerInteraction([],interactionArray{k});
                end
            end
        end

        function cachePreviousModes(hMode, fig)
            % Store the previous modes for each axes to be reenabled in StopFcn
            hMode.ModeStateData.PlotSelectMode.ModeStateData.PreviousModes = dictionary;
            
            if matlab.ui.internal.isUIFigure(fig) && ~(isprop(fig,'UseLegacyExplorationModes') && fig.UseLegacyExplorationModes)
                allAxes = findobjinternal(fig, {'-isa', 'matlab.graphics.axis.AbstractAxes'});
                for k = 1:numel(allAxes)
                    hMode.ModeStateData.PlotSelectMode.ModeStateData.PreviousModes(allAxes(k)) = allAxes(k).InteractionContainer.CurrentMode;
                end
            end
        end

        function reenableAxesModes(modeStateData)
            % Restores the axes to previous modes before entering plot edit
            % mode. Must be called after activateuimode finishes or else
            % will be stuck in a recursive loop.
            if isfield(modeStateData,'PreviousModes') && isConfigured(modeStateData.PreviousModes)
                allAxes = keys(modeStateData.PreviousModes);
                for k=1:length(allAxes)
                    if isvalid(allAxes(k))
                        allAxes(k).InteractionContainer.CurrentMode = char(modeStateData.PreviousModes(allAxes(k)));
                    end
                end
            end
        end

        function generateCodeForSuspendedInteraction(selectedObjects, actionID)

            % Generates code for selected objects for move, click
            % operations in plot edit mode on objects which have had their
            % default interactions temporarily suspended. For example, the
            % interaction that supports legend move is suspended to allow
            % legend moves to be handled by plot eduit mode hardware
            % events. generateCodeForSuspendedInteraction() can be called
            % on selected Legends to allow plot edit move operations to
            % generate code
            leg = findobj(selectedObjects,'flat','-isa','matlab.graphics.illustration.Legend',...
                '-or','-isa','matlab.graphics.illustration.ColorBar');
            for k=1:length(leg)
                matlab.graphics.interaction.generateLiveCode(leg(k),actionID);
            end
        end
       
        function contextMenuConstructPropertyUndo(hFig,hMode,Name,propName,oldValue,newValue)
            % Create undo/redo entries for the GUI setters
            % If the old value and new values are equal, return early:
            oldValue=reshape(oldValue,1,[]);
            newValue=reshape(newValue,1,[]);
            if isequal(oldValue,newValue)
                return;
            end
            % Create the command structure:
            opName = sprintf('Change %s',Name);
            % Create the proxy list:          
            hObjs = hMode.ModeStateData.SelectedObjects;
            cmd = matlab.uitools.internal.uiundo.UndoRedoCommandStructureFactory.createUndoRedoStruct(hObjs, ...
                hMode, opName, propName, oldValue, newValue);
            % Register with undo/redo
            uiundo(hFig,'function',cmd);
        end

        function contextMenuSetFont(hObjs,fontStrut,fontProp)
            if isfield(fontStrut, fontProp)
                set(hObjs, fontProp, fontStrut.(fontProp));
                matlab.graphics.internal.propertyinspector.generatePropertyEditingCode(hObjs, {fontProp});
            end
        end
    end
end