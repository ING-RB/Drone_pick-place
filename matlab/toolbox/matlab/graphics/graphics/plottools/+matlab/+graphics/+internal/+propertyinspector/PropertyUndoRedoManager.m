classdef PropertyUndoRedoManager < handle
    
    % PropertyUndoRedoManager - This class is used to perform undo/redo of
    % property editing actions performed via property inspector
    
    % Copyright 2017-2020 The MathWorks, Inc.
    
    methods (Static)
        
        function h = getInstance()
            
            mlock
            persistent hUndoRedoManager;
            
            if isempty(hUndoRedoManager)
                hUndoRedoManager = matlab.graphics.internal.propertyinspector.PropertyUndoRedoManager();
            end
            
            h = hUndoRedoManager;
        end
        
        % Execute Figure's Undo actions
        function performUndo(fig)
            uiundo(fig,'execUndo');
        end
        
        % Execute redo action
        function performRedo(fig)
            uiundo(fig,'execRedo');
        end
        
        function undoRedoChangeProperty(hMode,proxyList,propNames,value)
            % Given the proxy list, construct the object list:
            for i = numel(proxyList):-1:1
                hObjs(i) = hMode.ModeStateData.ChangedObjectHandles(hMode.ModeStateData.ChangedObjectProxy == proxyList(i));
            end
            
            % Change a property on an object
            % value can be a single value, a struct of PV pairs, or a cell array of values
            % where the ith row is the value of the ith property name
            if ~iscell(propNames)
                propNames = {propNames};
            end
            % Deal with a structure of values
            if isstruct(value)
                % Set all objects to the same structure of PV pairs
                set(hObjs(isobject(hObjs)),value)
            elseif iscell(value) && all(cellfun('isclass',value,'struct'))
                for k=1:length(value)
                    if isobject(hObjs(k))
                        set(hObjs(k), value{k});
                    end
                end
            else
                % Exclude deleted objects
                if isa(hObjs(1),'matlab.graphics.datatip.DataTipTemplate')
                    value(~isobject(hObjs)) = [];
                    hObjs(~isobject(hObjs)) = [];
                else
                    value(~ishghandle(hObjs)) = [];
                    hObjs(~ishghandle(hObjs)) = [];
                end
                
                for i=1:length(propNames)
                    % Set each property to the single value (or struct of PV pairs)
                    if ~iscell(value)
                        % Set each property to the single value (or struct of PV pairs)
                        set(hObjs,propNames{i},value);
                    elseif contains(lower(propNames{i}),'tick')
                        % Ticks sometimes contains a value which is a
                        % cellstr or a cell array. cellstr is sent for
                        % TickLabel and cell array for Ticks
                        if iscellstr(value)
                            set(hObjs,propNames{i},value);
                        else
                            set(hObjs,propNames{i},value{:});
                        end
                    else
                        % Set all the objects for the i-th property name to the i-th
                        % row of value
                        % Loop through all the objects and set the value.
                        % Logic below is needed when multiple objects are
                        % selected and their common property is changed. In
                        % that case, value is a cell array.
                        if numel(hObjs) > 1
                            for j=1:size(hObjs(:),1)
                                set(hObjs(j),propNames{i},value{j});
                            end
                        else
                            % For a single object, do not loop through and
                            % set the value
                            set(hObjs,propNames{i},value{i});
                        end
                    end
                end
                % If the object(s) are not selected and are selectable then
                % select them. Otherwise, no-op, because calling 
                % selectobject can add an additonal property set to the
                % undo stack, which can cause a flicker when undoing
                selectedObj = getselectobjects(hMode.FigureHandle);
                if all(isprop(hObjs,'Selected')) && ~isequal(selectedObj,hObjs)
                    selectobject(hObjs,'replace');
                end
            end
        end
    end
    
    methods (Access = public)
        
        % Add the figure's uiundo command to the stack on receiving
        % dataChange event from the PeerInspectorViewModel
        function addCommandToUiUndo(this,~,ed,fig)
            
            % Make sure only the DataChange event emitted on adding
            % UndoCommand is handled here. Other DataChange events should
            % be bypassed
            if isstruct(ed.Values) && isfield(ed.Values,'command')
                
                command = ed.Values.command;
                undoPropName = command.UndoPropertyInfo.PropertyName;
                redoPropName = command.RedoPropertyInfo.PropertyName;
                
                % Create the command structure:
                opName = sprintf('Change %s',redoPropName);
                prevValue = command.UndoPropertyInfo.PropertyValue;
                newValue = command.RedoPropertyInfo.AllPropertyValues;
                
                
                % TODO: DataChangeEvent is notified more than once if the
                % inspector window is closed and then reopened due to a bug
                % in Rob's PeerInspectorViewModel class
                if isequal(class(prevValue),class(newValue)) && isequal(prevValue,newValue)
                    return;
                end
                
                % For a mode property AffectedPropertyName is passed in the
                % undoPropertyInfo so that one undo action can reset both
                % XLimMode and XLim
                if isfield(command.UndoPropertyInfo,'AffectedPropertyName')
                    % Ordering matters when setting mode properties. Make
                    % sure to first set limits and then limitMode so that
                    % they are undone properly. On undo, if limits are set after
                    % limitMode, limitMode will reset back to 'manual'
                    undoPropName = {command.UndoPropertyInfo.AffectedPropertyName,undoPropName};
                    prevValue = {command.UndoPropertyInfo.AffectedPropertyValue,prevValue};
                end
                
                hObjs = command.EditedObject;
                
                % Whenever inspector is opened, plotedit mode is enabled.
                % Therefore, we can rely on
                % hPlotEdit.ModeStateData.PlotSelectMode to be not empty.
                hPlotEdit = plotedit(fig,'getmode');
                hMode = hPlotEdit.ModeStateData.PlotSelectMode;
                
                % Create the proxy list. This is important because the
                % hObjs might be deleted from the figure. To perform
                % undo/redo, we need to restore the handles from proxy list
                proxyList = strings(size(hObjs));
                for i = 1:length(hObjs)
                    proxyList(i) = hMode.ModeStateData.ChangedObjectProxy(hMode.ModeStateData.ChangedObjectHandles == hObjs(i));
                end
                
                cmd = matlab.uitools.internal.uiundo.FunctionCommand;
                cmd.Name = opName;
                cmd.Function = @this.undoRedoChangeProperty;
                cmd.Varargin = {hMode,proxyList,redoPropName,newValue};
                cmd.InverseFunction = @this.undoRedoChangeProperty;
                cmd.InverseVarargin = {hMode,proxyList,undoPropName,prevValue};
                
                % Register with undo/redo
                uiundo(fig,'function',cmd);
            end
        end
        
    end
    
    methods (Access = private)
        
        % Empty constructor
        function this = PropertyUndoRedoManager(~)
        end
    end
end