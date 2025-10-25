classdef AbstractTC < handle & matlab.mixin.Heterogeneous & ctrluis.component.MixedInDataListeners
    % Super class for any TC component in a TC/GC pair.
    
    % Author(s): Rong Chen
    % Copyright 2014 The MathWorks, Inc.
    
    % ----------------------------------------------------------------------------
    events
        % Event sent upon component data change.  No event data.
        ComponentChanged
    end
    
    % ----------------------------------------------------------------------------
    % User-defined methods
    methods (Access = protected)
        
        function mCheckConsistency(this) %#ok<*MANU>
            % Check component data consistency.  Error out here if changes
            % are inconsistent with the current state of the component.
            %   mCheckConsistency(this)
        end
        
        function mUpdate(this)
            % Update component data.
            %   mUpdate(this)
        end
        
    end
    
    % ----------------------------------------------------------------------------
    % Component state management
    methods (Sealed)
        
        function this = update(this)
            % Updates component data.
            %   update(this)
            % it calls "mCheckConsistency" and "mUpdate" before updating UI
            
            % Check joint property consistency.
            try
                mCheckConsistency(this);
            catch E
                throwAsCaller(E)
            end
            % Update component state.
            mUpdate(this);
            % Component is now up-to-date.
            notify(this, 'ComponentChanged')
        end
        
    end
    
    %% Abstract methods
    methods(Abstract = true)
        createView(this);
    end
    
end
