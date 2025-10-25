classdef ComponentKeyboard < matlabshared.application.Keyboard
    %
    
    %   Copyright 2020 The MathWorks, Inc.
    properties (SetAccess = protected)
        Component
    end
    
    methods
        function this = ComponentKeyboard(comp)
            this@matlabshared.application.Keyboard;
            
            % Allow 0 inputs to enable mixin usage.
            if nargin > 0
                initializeKeyboard(this, comp);
            end
        end
        
        function initializeKeyboard(this, comp)
            if ~isempty(this.Component)
                error(getMessage('Spcuilib:application:KeyboardAlreadyInitialized'));
            end
            initializeKeyboard@matlabshared.application.Keyboard(this, comp.Figure);
            this.Component = comp;
        end
    end
end
