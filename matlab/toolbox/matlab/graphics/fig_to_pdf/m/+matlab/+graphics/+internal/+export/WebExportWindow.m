classdef WebExportWindow < handle
    % WebExportWindow class maintaining cef window for exporting with exportapp
    %   Create web export window: 
    %       webExportWindow = WebExportWindow();
    %   Insert dom:
    %       webExportWindow.insertDom(dom);

    % Copyright 2023 The MathWorks, Inc.

    properties(Access=public)
        channelID = '/gbt/figure/WebExportWindow/'
        debug = false;
        connectDone
        insertedDone
        cef
    end

    properties(Access=private)
        URL = 'toolbox/matlab/graphics/fig_to_pdf/index.html'
        URL_Debug = 'toolbox/matlab/graphics/fig_to_pdf/index-debug.html'
    end
    
    methods(Access=public)
        function this = WebExportWindow()
            % Create standalone invisible cef web window
            connector.ensureServiceOn;
            url = '';
            if this.debug
                url = connector.getUrl(this.URL_Debug);
            else
                url = connector.getUrl(this.URL);
            end
            this.cef = matlab.internal.cef.webwindow(url);
            
            sub = message.subscribe([this.channelID 'connected'], @(msg) onConnectDone(msg));

            % Wait for the cef window to establish a connection.
            this.connectDone = false;
            waitfor(this, 'connectDone', true);
            function onConnectDone(~)
                message.unsubscribe(sub);
                this.connectDone = true;
            end
        end

        function insertDom(this, dom)
            sub = message.subscribe([this.channelID 'insertDomDone'], @(msg) onDomInserted(msg));
            % Send dom to cef window to be inserted
            message.publish([this.channelID 'insertDom'], struct("dom",dom));

            % Wait for the dom to be inserted.
            this.insertedDone = false;
            waitfor(this, 'insertedDone', true);
            function onDomInserted(~)
                message.unsubscribe(sub);
                this.insertedDone = true;
            end
        end

        function delete(this)
            if ~isempty(this.cef) && isvalid(this.cef)
                this.cef.FocusGained = [];
                this.cef.FocusLost = [];
                delete(this.cef);
            end
        end
    end
end
