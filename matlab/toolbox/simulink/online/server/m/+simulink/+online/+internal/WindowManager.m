classdef WindowManager < handle
% This singleton class manages the windows on the client side

    % Copyright 2023 The MathWorks, Inc.

    properties (Access = private)
        % client side browser size
        % will set when we initialize client side and will be updated whenever the browser size changes
        browserSize
    end

    methods (Access = private)
        function obj = WindowManager()
            obj.browserSize = struct();

            % handle window message from client side
            message.subscribe('/slonline/client2server', @(msg) obj.handleCLientMessage(msg));
        end
    end

    methods (Static)
        function singleObj = getInstance()
            persistent windowMgr;
            
            if isempty(windowMgr) || ~isvalid(windowMgr)
                windowMgr = simulink.online.internal.WindowManager();
            end
            
            singleObj = windowMgr;
        end
    end

    methods
        % maximize the Simulink model
        % can accept model name or studio as the input argument
        function maximize(obj, varargin)
            studio = obj.parseInput(varargin{:});
            msg = struct('type','operations', 'action', 'maximize');
            obj.sendMessage(studio, msg);
        end
        
        % set the position of Simulink model
        % @modelName: Simulink Model name
        % @position: 4 element array indicates the position in the format of [w, y, w, h]
        function setPosition(obj, modelName, position)
            arguments
                obj
                modelName (1,1) string
                position (1,4) {mustBeNumeric,mustBeReal}
            end

            studio = obj.getStudio(modelName);
            msg = struct('type','operations', 'action', 'setPosition', 'position', position);
            obj.sendMessage(studio, msg);
        end

        function size = getBrowserSize(obj)
            size = obj.browserSize;
        end

        % update the client side browser data we cached
        % the browser data will be updated in the following 2 cases
        %     1. when simulink online client side initialize with boostrap
        %     2. when client side browser resize
        function updateCachedBrowserSizeData(obj, browserSize)
            % make sure the browserSize is a struct with the w and h fields
            parser = inputParser();
            addRequired(parser, 'browserSize', @(x) isstruct(x) && ...
                isfield(x, 'w') && isfield(x, 'h'));
            parse(parser, browserSize);

            obj.browserSize.width = browserSize.w;
            obj.browserSize.height = browserSize.h;
        end

    end

    methods (Access = private)

        function studio = getStudio(obj, modelName)
            studio = [];
            studios = DAS.Studio.getAllStudiosSortedByMostRecentlyActive();

            for i = 1 : length(studios)
                st = studios(i);
                if st.App.topLevelDiagram.getName == modelName
                    studio = st;
                    break;
                end
            end

        end

        function studio = parseInput(obj, varargin)
            studio = [];
            p = inputParser;
            p.CaseSensitive = true;
            addOptional(p,'studio',[]);
            addOptional(p, 'modelName', '');
            parse(p, varargin{:});

            if ~isempty(p.Results.studio)
                studio = p.Results.studio;
            elseif ~isempty(p.Results.modelName)
                studio = obj.getStudio(p.Results.modelName);
            end

        end

        % send message to client side
        function sendMessage(~, studio, msg)
            if ~isempty(studio)
                studioTitle = studio.getStudioTitle();
                windowId = slonline.getWindowId(studioTitle);
                serverToClientChannel = ['/mg2web/' windowId];
                message.publish(serverToClientChannel, msg);
            end
        end

        % handle the message send from client side
        function handleCLientMessage(obj, msg)
            if (~isempty(msg) && strcmp(msg.action, 'browserSizeChange')) 
                obj.updateCachedBrowserSizeData(msg.data);
            end
        end
    end

end