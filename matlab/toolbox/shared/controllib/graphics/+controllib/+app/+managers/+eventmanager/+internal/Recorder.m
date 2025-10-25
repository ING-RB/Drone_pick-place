classdef Recorder < handle
    % Manages the undo and redo stack for transaction push and pop
    
    % Copyright 2014 The MathWorks, Inc.    
    properties (Access = private)
        UndoStack
        RedoStack
    end
    
    properties
        History
    end
    
    methods
        function pushUndo(this, T)
            % Add a new transaction to the undo stack and clear the invalid
            % redo stack
            
            % Maximum number of undos
            UndoStackLength = 20;
            
            % Delete redo stack
            if ~isempty(this.RedoStack)
                delete(this.RedoStack);
                this.RedoStack = [];
            end
            
            % Push transaction onto undo stack
            UndoStack = [this.UndoStack; T]; %#ok<*PROP>
            
            % Truncate undo stack if necessary
            if length(UndoStack) > UndoStackLength
                delete(UndoStack(1));
                UndoStack = UndoStack(2:end);
            end
            
            this.UndoStack = UndoStack;
        end
        
        function T = popUndo(this)
            % Return and remove the last transaction in the undo stack, and
            % add it to the redo stack
            
            % Get the last transaction to undo
            T = this.UndoStack(end);
            
            % Remove from undo stack
            this.UndoStack = this.UndoStack(1:end-1);
                        
            % Add to redo stack
            this.RedoStack = [this.RedoStack; T];
        end
        
        function T = popRedo(this)
            % Return and remove the last transaction from the redo stack
            % and add it to the undo stack
            
            % Get the last transaction to redo
            T = this.RedoStack(end);
            
            % Remove from redo stack
            this.RedoStack = this.RedoStack(1:end-1);
                        
            % Add to undo stack
            this.UndoStack = [this.UndoStack; T];
        end
        
        function len = getUndoStackLength(this)
            % Return the length of the undo stack
            len = length(this.UndoStack);
        end
        
        function len = getRedoStackLength(this)
            % Return the length of the redo
            len = length(this.RedoStack);
        end
        
        function set.UndoStack(this, NewValue)
            % Setter for UndoStack - throws a stack changed event
            this.UndoStack = NewValue;
            this.notify('UndoStackChanged');
        end
        
        function set.RedoStack(this, NewValue)
            % Setter for RedoStack - throws a stack changed event
            this.RedoStack = NewValue;
            this.notify('RedoStackChanged');
        end
        
        function History = getHistory(this)
            History = this.History;
        end
        
        function set.History(this, History)
            this.History = History;
        end
    end
    
    events
        UndoStackChanged
        RedoStackChanged
    end

end