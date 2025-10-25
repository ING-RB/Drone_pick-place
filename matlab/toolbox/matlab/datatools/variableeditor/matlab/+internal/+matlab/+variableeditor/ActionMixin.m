classdef ActionMixin < handle
    % ActionMixin

    % Copyright 2013-2024 The MathWorks, Inc.


    methods(Access='public')
        % getSupportedActions
        function actionList = getSupportedActions(~,varargin)
            actionList = [];
        end

        % isActionAvailable
        function isAvailable = isActionAvailable(~,~,varargin)
            isAvailable = false;
        end
    end
end
