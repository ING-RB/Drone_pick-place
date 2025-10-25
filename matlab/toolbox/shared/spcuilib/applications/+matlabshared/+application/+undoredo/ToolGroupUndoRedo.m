classdef ToolGroupUndoRedo < handle
    %ToolGroupUndoRedo mixin for toolgroup applications to add undoredo
    
    %   Copyright 2017 The MathWorks, Inc.
    properties (SetAccess = protected, Hidden)
        UndoRedo
        CleanLocation = 0;
        IsUndoUsingName = false;
    end
    
    methods
        function this = ToolGroupUndoRedo
            addQabButton(this, 'redo', @this.redoCallback);
            addQabButton(this, 'undo', @this.undoCallback);
            
            addApplicationKeyPress(this, 'z', @this.undoCallback, {'control'});
            addApplicationKeyPress(this, 'y', @this.redoCallback, {'control'});
        end
        
        function manager = get.UndoRedo(this)
            manager = this.UndoRedo;
            
            % The manager is lazy loaded.
            if isempty(manager)
                manager = matlabshared.application.undoredo.Manager;
                this.UndoRedo = manager;
            end
        end
        
        function disableUndoRedo(this)
            this.UndoRedo.Enabled = false;
            updateUndoRedo(this);
        end
        
        function enableUndoRedo(this)
            this.UndoRedo.Enabled = true;
            updateUndoRedo(this);
        end
    end
    
    methods (Hidden)
        function new(this)
            clear(this.UndoRedo);
            this.CleanLocation = 0;
            updateUndoRedo(this);
        end
        
        function success = openFile(this, ~)
            success = true;
            clear(this.UndoRedo);
            this.CleanLocation = 0;
            updateUndoRedo(this);
        end
        
        function success = saveFile(this, ~)
            success = true;
            this.CleanLocation = 0;
        end
        
        function applyEditInCallback(this, newEdit, varargin)
            callbackHandler(this, @() applyEdit(this, newEdit), varargin{:});
        end
        
        function applyEdit(this, newEdit)
            execute(this.UndoRedo, newEdit);
            
            updateClean(this);
        end
        
        function addEditNoApply(this, newEdit)
            add(this.UndoRedo, newEdit);
            
            updateClean(this);
        end
        
        function undoCallback(this, ~, ~)
            if canUndo(this)
                this.CleanLocation = this.CleanLocation - 1;
                undo(this.UndoRedo);
                updateUndoRedo(this);
                updateDirtyStateForCleanLocation(this);
            end
        end
        
        function redoCallback(this, ~, ~)
            if canRedo(this)
                this.CleanLocation = this.CleanLocation + 1;
                redo(this.UndoRedo);
                updateUndoRedo(this);
                updateDirtyStateForCleanLocation(this);
            end
        end
    end
    
    methods (Access = protected)
        function updateClean(this)
            
            % If we have done undoes to get back to this point and add
            % another action, it will be impossible do use undo/redo to get
            % back to a clean location
            if this.CleanLocation < 0
                this.CleanLocation = inf;
            end
            this.CleanLocation = this.CleanLocation + 1;
            updateUndoRedo(this);
        end
        
        function updateUndoRedo(this)
            
            if ~this.IsUndoUsingName
                this.IsUndoUsingName = enableQabNaming(this, 'undo', 'redo');
            end
            
            setQabEnabled(this, 'undo', canUndo(this));
            setQabEnabled(this, 'redo', canRedo(this));
            setQabName(this, 'undo', getUndoDescription(this));
            setQabName(this, 'redo', getRedoDescription(this));
        end
        
        function updateDirtyStateForCleanLocation(this)
            if this.CleanLocation == 0
                removeDirty(this);
            else
                setDirty(this)
            end
            updateTitle(this);
        end
        
        function b = canUndo(this)
            b = canUndo(this.UndoRedo);
        end
        
        function b = canRedo(this)
            b = canRedo(this.UndoRedo);
        end
        
        function str = getUndoDescription(this)
            str = getString(message('Spcuilib:application:UndoActionLabel', getUndoDescription(this.UndoRedo)));
        end
        
        function str = getRedoDescription(this)
            str = getString(message('Spcuilib:application:RedoActionLabel', getRedoDescription(this.UndoRedo)));
        end
    end
end

% [EOF]
