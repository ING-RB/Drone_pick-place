classdef ClearRuntime < handle
%

%   Copyright 2018-2019 The MathWorks, Inc.

    properties
        activeTimerBasedSFXInstances = {}
        
    end
    
    methods(Access=private)
        function obj = ClearRuntime
        end
    end
    
    methods (Static)
        %% singleton instance
        function retval = instance
            persistent obj
            if isempty(obj)
                obj = Stateflow.App.Cdr.RuntimeShared.R2020b.ClearRuntime;
            end
            retval = obj;
        end
    end
    methods(Access=public)
        %% delete
        function delete(this)
            for i = 1:length(this.activeTimerBasedSFXInstances)
                if isa(this.activeTimerBasedSFXInstances{i}, 'handle') && isvalid(this.activeTimerBasedSFXInstances{i})
                    delete(this.activeTimerBasedSFXInstances{i});
                end
            end
            this.activeTimerBasedSFXInstances = {};
            Stateflow.App.Cdr.RuntimeShared.R2020b.InstanceIndRuntime.clearCache();
        end
    end
end

