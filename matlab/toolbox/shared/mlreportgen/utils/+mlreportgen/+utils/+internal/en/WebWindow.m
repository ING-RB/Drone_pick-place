classdef WebWindow< handle
%mlreportgen.utils.internal.WebWindow  Web Window
%
%   mlreportgen.utils.internal.WebWindow(URL) creates a web window showing
%       URL. WebWindow has a custom close behavior where "close" means
%       hide, so it can "reopen" with the same state before it was "closed" by
%       the user.  WebWindow also destroys itself when it goes out of scope.
%
%   WebWindow Properties:
%
%       URL         - URL of web window.
%       Title       - Title of web window.
%       Position    - Position of web window.
%
%   WebWindow Methods:
%
%       show        - Shows web window.
%       hide        - Hides web window
%       isVisible   - Is web window visible?
%       isOpen      - Is web window valid?
%       executeJS   - Execute JavaScript code

 
    %   Copyright 2018-2024 The MathWorks, Inc.

    methods
        function out=WebWindow
            % Validate the input arguments
        end

        function out=addOnNamePool(~) %#ok<STOUT>
        end

        function out=close(~) %#ok<STOUT>
            %close  Close WebWindow
            %   close(webWindows) closes WebWindow.  WebWindow cannot be
            %   reopened.  A new WebWindow must be created.
        end

        function out=delete(~) %#ok<STOUT>
        end

        function out=executeJS(~) %#ok<STOUT>
            %executeJS    execute javascript query
            %   result = executeJS(webWindow, query) returns JS query result
            %   by executing the Javascript query passed as an input.
        end

        function out=hide(~) %#ok<STOUT>
            %hide   Hide WebWindow
            %   hide(webWindow) hides webwindow by making it invisible.
        end

        function out=isOpen(~) %#ok<STOUT>
            %isOpen    Is WebWindow opened?
            %   tf = isOpen(webWindow) returns true if WebWindow has not
            %   been closed and false otherwise.
        end

        function out=isVisible(~) %#ok<STOUT>
            %isVisible  Is WebWindow visible?
            %   tf = isVisible(webWindows) returns true if visible and returns
            %   false if invisible.
        end

        function out=show(~) %#ok<STOUT>
            %show   Show WebWindow
            %   show(webWindow) shows webwindow by making it visible.
        end

    end
    properties
        Position;

        Title;

        URL;

    end
end
