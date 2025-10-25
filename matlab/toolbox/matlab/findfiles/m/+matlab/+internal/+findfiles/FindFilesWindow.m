%

% Copyright 2015-2020 The MathWorks, Inc.

classdef (Sealed = true) FindFilesWindow < handle
    
    properties (Access=public)
        window
        DebugPort
        messageService
    end
    
    methods (Access = private)
        function newObj = FindFilesWindow()
        end
    end
    
    methods (Static)
        function obj = getInstance()
            persistent uniqueFindFilesWindow;
            if (isempty(uniqueFindFilesWindow))
                obj = matlab.internal.findfiles.FindFilesWindow();
                uniqueFindFilesWindow = obj;
                obj.messageService = message.internal.MessageService('findfiles');
            else
                obj = uniqueFindFilesWindow;
            end
        end
    end
    
    methods (Access = public)
        function launchWindow(obj, width, height)
            if (~obj.findFilesExists())
                path = '/toolbox/matlab/findfiles/js/index.html';
                url = connector.getUrl(path);
                obj.DebugPort = matlab.internal.getDebugPort;
                obj.window = matlab.internal.webwindow(url, obj.DebugPort);
                obj.window.CustomWindowClosingCallback = @obj.close;
                obj.window.MATLABWindowExitedCallback = @obj.onWindowClose;
                obj.window.addlistener('ObjectBeingDestroyed', @obj.onWindowClose);
                obj.setPosition([(ceil([width, height]/2) - [425 210]) 854 450]);
                obj.window.show();
                obj.window.bringToFront();
            else
                obj.bringToFront();
            end
        end
        
        function exists = findFilesExists(obj)
            exists = ~(isempty(obj.window) || ~obj.window.isWindowValid);
        end
        
        function setMinSize(obj, size)
            obj.window.setMinSize(size);
        end
        
        function setPosition(obj, position)
            obj.window.Position = position;
        end
        
        function close(obj, ~, ~)
            obj.window.close();
            obj.onWindowClose();
        end

        function onWindowClose(obj, ~, ~)
            obj.window = [];
            % Tell backend to stop search process
            obj.messageService.publish('/matlab/findFiles/toJavaFromMLOnline', struct('action', 'stop'));
        end
        
        function bringToFront(obj)
            obj.window.bringToFront();
        end
        
        function setTitle(obj, title)
            obj.window.Title = char(title);
        end

        function minimize(obj)
            obj.window.minimize;
        end

        function restore(obj)
            obj.window.restore;
        end

        function updateUrl(obj, url)
        end
        
        function dialogUrl = getUrl(obj)
            dialogUrl = obj.window.URL;
        end
        
        function debugPort = getDebugPort(obj)
           debugPort = obj.DebugPort; 
        end
    end
end
