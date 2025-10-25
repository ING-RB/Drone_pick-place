% DisplayableItemBaseFactory - Base factory for creating different types of displayable items.

% Copyright 2020-2021 The MathWorks, Inc.

classdef (Hidden) DisplayableItemBaseFactory
    properties (SetAccess = 'immutable', GetAccess = 'protected')
        DisplayHelper
    end
    methods
        function obj = DisplayableItemBaseFactory(displayHelper)
            obj.DisplayHelper = displayHelper;
        end
    end
    methods
        function defaultItem = createDefaultItem(obj, value)
            defaultItem = parallel.internal.display.Default(obj.DisplayHelper, value);
        end
        
        % Calculating the running duration for a job or task
        function durationItem = createDurationItem(obj, duration)
            durationItem = parallel.internal.display.Duration(obj.DisplayHelper, duration);
        end
        
        function taskErrorItem = createRequestErrorItem(obj, error, pool)
            taskErrorItem = parallel.internal.display.RequestError(obj.DisplayHelper, error, pool);
        end
        
        % This function is called by the objects to make multiple displayable items
        function values = makeMultipleItems(obj, creator, x)
            % The creator must be a handle to a function in this class.
            % If NOT then the  behaviour of this function is undefined.
            values = cellfun(@(x) creator(obj, x), x, 'UniformOutput', false);
        end
    end
end
