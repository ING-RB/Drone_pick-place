classdef FigureWebDispatcher < matlab.uiautomation.internal.dispatchers.WebDispatcher
    % This class is undocumented and subject to change in a future release
    
    % Copyright 2023 The MathWorks, Inc.
    methods(Access=?matlab.uiautomation.internal.dispatchers.WebDispatcher)
        function obj = FigureWebDispatcher()
        end
    end

    methods
        function dispatch(dispatcher, model, evtName, varargin)
            import matlab.uiautomation.internal.IDService;
            import matlab.ui.internal.FigureServices;
            import matlab.uiautomation.internal.Buttons;
            
            parser = dispatcher.parseInputs(varargin{:});
            
            fig = ancestor(model, 'figure');
            figID = IDService.getId(fig);
            uitestChannel = ['/uitest/' figID];
            figChannel = FigureServices.getUniqueChannelId(fig);
            
            evd = struct( ...
                'Channel', figChannel, ...
                'figID', figID, ...
                'Name', evtName, ...
                'PeerNodeID', IDService.getId(model), ...
                'Options', dispatcher.mapOptions(parser.Results.Modifier, parser.Results.Button), ...
                'Data', parser.Unmatched);
            
            message.publish(uitestChannel, evd)
        end
    end
end
