classdef PZMapOptions < handle
    % Class definition to load serialized objects

    %  Copyright 2021 The MathWorks, Inc.
    methods(Static)
        function this = loadobj(s)
            this = plotopts.PZOptions;
            for fn = fieldnames(s)'
                this.(fn{1}) = s.(fn{1});
            end
        end
    end
end