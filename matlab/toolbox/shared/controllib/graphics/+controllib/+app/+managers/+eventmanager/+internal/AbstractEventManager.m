classdef AbstractEventManager < handle
    % Abstract event manager class.
    
    % Copyright 2014 The MathWorks, Inc.
    
    properties (Access = protected)
        Recorder 
    end
    
    methods (Access = protected)
        function this = AbstractEventManager
            % create the recorder
            this.Recorder = controllib.app.managers.eventmanager.internal.Recorder;
        end
    end
    
    methods (Access = public)
        function record(this, T)
            % Record the transaction in the undo stack
            this.Recorder.pushUndo(T);
        end
        
        %% Undo and Redo        
        function undo(this)
           % Get the last transaction to undo
           LastT = this.Recorder.popUndo;

           % Set the status message
           this.postActionStatus('off',getString(message('Controllib:gui:strReverted',LastT.Name)));
           
           % Perform the undo
           LastT.undo;
        end
        
        function redo(this)
            % Get the last transaction to redo
            LastT  = this.Recorder.popRedo;
            
            % Set the status message
            this.postActionStatus('off',LastT.Name);
            
            % Perform the undo
            LastT.redo;
        end
    end  
    
    methods(Abstract = true)
        postActionStatus
    end
end