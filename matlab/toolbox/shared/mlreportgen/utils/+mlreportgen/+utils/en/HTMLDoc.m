classdef HTMLDoc< handle
%mlreportgen.utils.HTMLDoc  Wraps an HTML file for viewing
%
%   h = mlreportgen.utils.HTMLDoc(FILENAME) creates a HTML Doc object for
%   FILENAME. HTMLDoc is not visible on construction.  To make it visible,
%   call the "show" method.
%
%   HTMLDoc properties
%
%       FileName    - Full path to a HTML file
%
%   HTMLDoc methods:
%
%       show        - Show HTML file
%       hide        - Hide HTML file
%       isVisible   - Is HTML file visible?

     
    %   Copyright 2017-2022 The MathWorks, Inc.

    methods
        function out=HTMLDoc
        end

        function out=close(~) %#ok<STOUT>
            %close  Close HTML file
            %   close(htmlDoc) closes HTML file.  HTMLDoc cannot be
            %   reopened.  A new HTMLDoc must be created.
        end

        function out=delete(~) %#ok<STOUT>
        end

        function out=hide(~) %#ok<STOUT>
            %hide Hide HTML file
            %    hide(htmlDoc) hides HTML file by making it invisible.
        end

        function out=isOpen(~) %#ok<STOUT>
            %isOpen    Is HTML file opened?
            %   tf = isOpen(htmlDoc) returns true if htmlDoc has not
            %   been closed and false if htmlDoc is closed.
        end

        function out=isVisible(~) %#ok<STOUT>
            %isVisible Is HTML file visible in a viewer?
            %   tf = isVisible(htmlDoc) returns true if visible and returns
            %   false if invisible.
        end

        function out=show(~) %#ok<STOUT>
            %show Show HTML file
            %    show(htmlDoc) shows HTML file by making it visible.
        end

    end
    properties
        FileName;

    end
end
