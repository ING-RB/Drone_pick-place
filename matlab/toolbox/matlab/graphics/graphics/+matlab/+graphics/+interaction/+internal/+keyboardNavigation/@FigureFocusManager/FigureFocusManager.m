classdef FigureFocusManager < handle
    %FIGUREFOCUSMANAGER handles indicating and transferring focus within
    %graphics objects in a figure.

    %

    %   Copyright 2021 The MathWorks, Inc.
    
    properties (AbortSet)
        Figure % Indicates the figure for which this class manages the focus
        
        FocusedObject % The handle to the object that is currently in focus
        ObjectList % The list of objects in the same level of the graphics hierarchy as FocusedObject
        
        KeyPressFcn % The handle to the keypressfcn that manages keyboard navigation
    end
    
    methods
        function this = FigureFocusManager(fig)
            this.Figure = fig;
            this.FocusedObject = [];
            this.ObjectList = this.getListOfChildren(fig);
            this.KeyPressFcn = event.listener(fig, 'KeyPress', ...
                @(fig, evd) this.keyboardNavigationKeyPressFcn(fig, evd));
            
        end
        
        function delete(this)
            % If the FigureFocusManager is deleted, and if an object within
            % the figure has focus indictors on it, remove it. This can
            % happen when, say, a line object has focus indictors on it,
            % but the user clicks on, say, the command window, then the
            % line's focus indicator must be removed. 
            
            if(~isempty(this.FocusedObject))
                this.removeFocusIndicator(this.FocusedObject);
            end
        end
        
    end
end

