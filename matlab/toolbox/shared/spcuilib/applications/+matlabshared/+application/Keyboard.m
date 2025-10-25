classdef Keyboard < handle
    % Create a keyboard object which will convert the key pressed event
    % into a method name. If that method is implemented by the subclasses,
    % it will be called. Modifiers are prefixed to the key, separated by
    % underscores.
    %
    %   Key(s) Hit    - Method Called
    %   f             - f()
    %   ctrl+f        - ctrl_f()
    %   alt+shift+f   - alt_shift_f()
    %   esc           - escape()
    %   enter         - return_()
    %   delete        - delete_()
    %
    %   Properties
    %
    %   PressedKey - The currently pressed key
    %   PressedModifier - Cell array of currently selected modifiers
    %   Debug - When set to true, the method a specific key press will call
    %           is printed to the command window
    
    %   Copyright 2020 The MathWorks, Inc.
    properties (SetAccess = protected)
        PressedKey = 'none'
        PressedModifier = {};
    end
    
    properties (Hidden)
        Debug = false;
    end
        
    methods
        function this = Keyboard(fig)
            if nargin > 0
                initializeKeyboard(this, fig);
            end
        end
        
        function initializeKeyboard(this, fig)
            set(fig, ...
                'WindowKeyPressFcn',   @this.onKeyPress, ...
                'WindowKeyReleaseFcn', @this.onKeyRelease);
        end
    end
    
    methods (Hidden)
        
        function onKeyPress(this, ~, ev)
            this.PressedKey = ev.Key;
            this.PressedModifier = ev.Modifier;
            fcn = this.convertKeyboardEventToString(ev);
            if this.Debug
                fprintf('%s\n',fcn);
            end
            if ismethod(this, fcn)
                feval(fcn, this);
            end
        end
        
        function onKeyRelease(this, ~, ev)
            this.PressedKey = 'none';
            this.PressedModifier = ev.Modifier;
        end
    end
    
    methods (Hidden, Static)
        
        % Make static for test-ability
        function str = convertKeyboardEventToString(event)
            mod = sort(event.Modifier);
            str = sprintf('%s_', mod{:});
            
            key = event.Key;
            switch key
                case {'return' 'delete'}
                    key = [key '_'];
                case {'1','2','3','4','5','6','7','8','9','0'}
                    key = ['num' key];
            end

            str = [str key];
            
            % Need to special case 1,2,3,4,5
        end
    end
end
