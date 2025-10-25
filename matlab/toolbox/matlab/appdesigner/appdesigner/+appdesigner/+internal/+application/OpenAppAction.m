classdef OpenAppAction < appdesigner.internal.application.DesktopAction
% OPENAPPACTION A class representing the action of opening an existing app.

% Copyright 2018-2020 The MathWorks, Inc.
    properties (Access = private)
        FilePath char
        % A list of client-side actions to take
        % once the app is done opening.
        PostAppLoadActions cell
    end

    methods
        function obj = OpenAppAction(filePath)
            obj.FilePath = filePath;
            obj.PostAppLoadActions = {};
        end

        function runAction(obj, proxyView)
            % Send an event notifying the client to open the app.
            proxyView.sendEventToClient('openAppModel', {'FilePath', obj.FilePath, 'PostAppLoadActions', obj.PostAppLoadActions});
        end

        function filePath = getFilePath(obj)
            filePath = obj.FilePath;
        end

        function whenAppLoaded(obj, action)
            % Adds an action to be run when the app has fully loaded
            % on the client side.
            if any(strcmpi(action, obj.PostAppLoadActions))
                return;
            end

            obj.PostAppLoadActions{end + 1} = action;
        end
    end
end
