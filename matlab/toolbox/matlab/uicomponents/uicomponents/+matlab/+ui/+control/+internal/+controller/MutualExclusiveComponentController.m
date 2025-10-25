classdef (Hidden) MutualExclusiveComponentController < ...
        matlab.ui.control.internal.controller.ComponentController    
    % MUTUALEXCLUSIVECOMPONENTCONTROLLER controller class for AbstractMutualExclusiveComponent   
    
    % Copyright 2014-2021 The MathWorks, Inc.
    
    methods
        function obj = MutualExclusiveComponentController(varargin)            
            obj = obj@matlab.ui.control.internal.controller.ComponentController(varargin{:});  
        end
    end
    
    methods(Access = 'protected')
        
        
        function handleEvent(obj, src, event)
            if(strcmp(event.Data.Name, 'ViewSelectionChanged'))
                try
                    % indicate button is selected interactively, not programatically
                    obj.Model.isInteractiveSelectionChanged = true;
                    
                    % set Value property
                    obj.Model.Value = event.Data.Value;
                catch ME %#ok<NASGU>
                    if ~isvalid(obj)
                        % If obj is deleted it likely happened in the callback, which
                        % gets invoked via the button group server-side code listening
                        % to the ValuePostSet event which gets fired by the assignment
                        % of obj.Model.Value above. Ignore the error because there are
                        % use cases for this. See g2567795 for details.
                        return;
                    else
                        rethrow ME;
                    end
                end
            end
            
            % Allow super classes to handle their events
            handleEvent@matlab.ui.control.internal.controller.ComponentController(obj, src, event);
        end    
    end
    
end
