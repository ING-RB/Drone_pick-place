classdef FigureEventManager < controllib.app.managers.eventmanager.internal.AbstractEventManager
    % Class that manages the display of status messages in a UIcontrol
    
    % Copyright 2014 The MathWorks, Inc.
    properties (Access = private)
        UIControl
    end
    
    methods (Access = public)
        % Public API
        
        function this = FigureEventManager(UIControl, varargin)
            % Superclass constructor
            this = this@controllib.app.managers.eventmanager.internal.AbstractEventManager;
            
            if nargin < 1
                % Needs atleast one input
                return;
            elseif nargin == 2
                this.UIControl = UIControl;
                this.createWidgets(varargin{:});
            else
                this.UIControl = UIControl;
            end
        end
        
        function postStatus(this, text)
            % Set the status bar text
            set(this.UIControl, 'String', text);
        end
    end
end
