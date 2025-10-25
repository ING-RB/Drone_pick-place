classdef AbstractUI < handle & matlab.mixin.Heterogeneous & ctrluis.component.MixedInDataListeners & ctrluis.component.MixedInUIListeners
    % Master super class for all single-class implementation
    % Sub-classes include AbstractDialog, AbstractPanel and AbstractTab
    % It is also the super-class of AbstractGC.
    
    % Author(s): Rong Chen
    % Copyright 2014 The MathWorks, Inc.
    
    %% Public methods
    methods
        
        function updateUI(this)
            % Programmatically update/refresh UI.  
            %   updateUI(this)
            % Automatically called by the "show" method.  
            % To be overloaded by sub-class.
        end
    
        function delete(this)
            % delete all the data and UI listeners
            unregisterDataListeners(this);
            unregisterUIListeners(this);
            % force to clean up UI
            cleanupUI(this)
        end
        
    end
    
    %% Protected methods
    methods(Access = protected)
        
        function connectUI(this) %#ok<*MANU>
            % Add listeners to data events and UI widgets.  
            %   connectUI(this)
            % Automatically called during the ui building process.  
            % To be overloaded by sub-class.
        end
        
        function cleanupUI(this)
            % Cleanup UI widgets.  
            %   cleanupUI(this)
            % Automatically called when the object is being destroyed.  
            % To be overloaded by sub-class.
        end
        
    end
    
    %% Below this line are properties and methods for QE use only
    methods (Hidden)
       
        function widgets = getWidgets(this)
            % return widget references
            % To be overloaded by sub-class.
            widgets = [];
        end
        
    end
        
end