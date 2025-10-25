classdef HTMXDoc< handle
%mlreportgen.utils.HTMXDoc  Wraps an HTMXDoc file for viewing
%
%   h = mlreportgen.utils.HTMXDoc(FILENAME) creates a HTMXDoc for
%   FILENAME. HTMXDoc is not visible on construction.  To make it visible,
%   call the "show" method.
%
%   HTMXDoc properties
%
%       FileName    - Full path to a HTMTX file
%
%   HTMXDoc methods:
%
%       show        - Show HTMX file
%       hide        - Hide HTMX file
%       isVisible   - Is HTMX file visible?

     
    %   Copyright 2018-2022 The MathWorks, Inc.

    methods
        function out=HTMXDoc
        end

        function out=close(~) %#ok<STOUT>
            %close  Close HTMTX file
            %   close(htmtxViewer) closes HTMTX file.  HTMLDoc cannot be
            %   reopened.  A new HTMLDoc must be created.
        end

        function out=delete(~) %#ok<STOUT>
        end

        function out=hide(~) %#ok<STOUT>
            %hide Hide HTMTX file
            %    hide(htmtxViewer) hides HTMTX file by making it invisible.
        end

        function out=isOpen(~) %#ok<STOUT>
            %isOpen    Is HTMTX file opened?
            %   tf = isOpen(htmtxViewer) returns true if htmtxViewer has not
            %   been closed and false if htmtxViewer is closed.
        end

        function out=isVisible(~) %#ok<STOUT>
            %isVisible Is HTMTX file visible in a viewer?
            %   tf = isVisible(htmtxViewer) returns true if visible and returns
            %   false if invisible.
        end

        function out=show(~) %#ok<STOUT>
            %show Show HTMTX file
            %    show(htmtxViewer) shows HTMTX file by making it visible.
        end

    end
    properties
        FileName;

    end
end
