classdef (Abstract) UIDispatcher < handle
    % This class is undocumented and subject to change in a future release
    
    % Copyright 2016-2024 The MathWorks, Inc.
    
    
    methods (Abstract)
        dispatch(dispatcher, model, evtName, varargin)
    end
    
    methods (Static)
        
        function dispatcher = forComponent(H)
            import matlab.uiautomation.internal.UIDispatcher;
  
            fig = ancestor(H, 'figure');
            if ~matlab.ui.internal.isUIFigure(fig)
                error( message('MATLAB:uiautomation:Driver:MustBelongToUIFigure') );
            end
            
            dispatcher = UIDispatcher.forWeb();
        end
        
        function dispatcher = forWeb()
            import matlab.uiautomation.internal.UIDispatcher;
            import matlab.uiautomation.internal.dispatchers.ScrollableDispatcher;
            import matlab.uiautomation.internal.dispatchers.ActiveFigureDispatcher;
            import matlab.uiautomation.internal.dispatchers.ViewModelSynchronizer;

            dispatcher = UIDispatcher.forClient();
            dispatcher = ScrollableDispatcher(dispatcher);
            dispatcher = ActiveFigureDispatcher(dispatcher);
            dispatcher = ViewModelSynchronizer(dispatcher);
        end

        function dispatcher = forUILock()
            import matlab.uiautomation.internal.UIDispatcher;
            import matlab.uiautomation.internal.dispatchers.ViewModelSynchronizer;
            import matlab.uiautomation.internal.dispatchers.ThrowableDispatchDecorator;

            dispatcher = UIDispatcher.forClient();
            dispatcher = ViewModelSynchronizer(dispatcher);
            dispatcher = ThrowableDispatchDecorator(dispatcher);
        end

        function dispatcher = forClient()
            import matlab.uiautomation.internal.dispatchers.WebDispatcher;
            import matlab.uiautomation.internal.dispatchers.WaitForWebReply;

            dispatcher = WebDispatcher;
            dispatcher = WaitForWebReply(dispatcher);
        end

    end
end