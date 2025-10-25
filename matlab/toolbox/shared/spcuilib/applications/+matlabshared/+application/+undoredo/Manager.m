classdef Manager < handle
    %Manager - undo/redo manager
    
    %   Copyright 2017 The MathWorks, Inc.
    properties (SetAccess = protected, Hidden)
        
        % Use cell arrays for the stack so the manager can use any object
        % with undo and redo methods.
        UndoStack = matlabshared.application.undoredo.Edit.empty;
        RedoStack = matlabshared.application.undoredo.Edit.empty;
    end
    
    properties
        Enabled = true;
    end
    
    methods
        function execute(this, newEdit)
            %execute Perform the edit and add it to the undo stack.
            execute(newEdit);
            
            % Set the stacks last in case the execute on the transaction
            % errors out.
            add(this, newEdit);
        end
        
        function add(this, newEdit)
            %add Add an edit to the undo stack without executing it.  This
            %   is typically used when the edit has already been done
            %   elsewhere, for instance, drag and drop, the drag may
            %   continuously edit the data, and drop will add a single edit
            %   to the manager.
            this.RedoStack        = matlabshared.application.undoredo.Edit.empty;
            this.UndoStack(end+1) = newEdit;
        end
        
        function undo(this)
            
            if ~this.Enabled
                return;
            end
            %undo Revert the last edit and move it to the redo stack.
            undoStack = this.UndoStack;
            
            % If there is nothing to undo, return early.
            if isempty(undoStack)
                return;
            end
            
            % Undo and redo should always happen without error.
            edit = undoStack(end);
            this.UndoStack(end) = [];
            this.RedoStack(end+1) = edit;
            undo(edit)
        end
        
        function redo(this)
            
            if ~this.Enabled
                return;
            end
            
            %redo Redo the last undone edit.
            redoStack = this.RedoStack;
            
            % If there is nothing to redo, return early.
            if isempty(redoStack)
                return;
            end
            
            % Undo and redo should always happen without error.
            edit = redoStack(end);
            this.RedoStack(end) = [];
            this.UndoStack(end+1) = edit;
            redo(edit)
        end
        
        function clear(this)
            %CLEAR - Remove all edits from the undo and redo stacks.
            this.UndoStack = matlabshared.application.undoredo.Edit.empty;
            this.RedoStack = matlabshared.application.undoredo.Edit.empty;
        end
        
        function b = canUndo(this)
            %CANUNDO Returns true if there is an edit to undo
            b = this.Enabled && ~isempty(this.UndoStack);
        end
        
        function b = canRedo(this)
            %CANREDO Returns true if there is an edit to redo
            b = this.Enabled && ~isempty(this.RedoStack);
        end
        
        function str = getUndoDescription(this)
            undo = this.UndoStack;
            if isempty(undo)
                str = '';
            else
                str = getDescription(undo(end));
            end
        end
        
        function str = getRedoDescription(this)
            redo = this.RedoStack;
            if isempty(redo)
                str = '';
            else
                str = getDescription(redo(end));
            end
        end
    end
end

% [EOF]
