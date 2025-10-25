classdef AppContainerWebDispatcher < matlab.uiautomation.internal.dispatchers.WebDispatcher & matlab.ui.container.internal.AppContainer
    % This class is undocumented and subject to change in a future release
    
    % Copyright 2023 The MathWorks, Inc.
    properties
        obj
    end

    methods(Access=?matlab.uiautomation.internal.dispatchers.WebDispatcher)
        function obj = AppContainerWebDispatcher()
        end
    end

    methods
        function dispatch(dispatcher, model, evtName, varargin)
                parser = dispatcher.parseInputs(varargin{:});
                channelUUID = string(model.ModelChannel).split('/app/');
                uitestChannel = '/uitest/' + channelUUID(2);

                evd = struct( ...
                    'Channel', uitestChannel, ...
                    'Name', evtName, ...
                    'Data', parser.Unmatched);
                message.publish(uitestChannel, evd);
        end
    end
end
