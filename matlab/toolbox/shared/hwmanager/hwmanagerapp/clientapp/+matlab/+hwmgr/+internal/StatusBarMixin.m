classdef StatusBarMixin < handle
% StatusBarMixin - Mixin class to allow Hardware Manager Client Apps to be
% able to opt-in to using a status bar, provide the components to place in
% the status bar and to retrieve status bar component handles.

% Copyright 2022 Mathworks Inc.

    properties (Abstract, Access = protected)
        AppContainer
    end

    properties
        StatusBarEnabled (1,1) logical = false
    end

    methods

        function statusBarComponent = getStatusComponent(obj, tag)        
           statusBarComponent = obj.AppContainer.getStatusComponent(tag);
        end


        function components = createStatusComponents(~)
            components = [];
        end

    end

end