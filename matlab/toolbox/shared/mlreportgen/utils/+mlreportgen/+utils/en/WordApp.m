classdef WordApp< mlreportgen.utils.internal.OfficeApp
%mlreportgen.utils.WordApp  Wraps a Word application
%   mlreportgen.utils.WordApp wraps a Word application NET object.  There
%   can be only one Word application NET object active.  To get the active
%   WordApp object, use the instance method.
%
%   WordApp methods:
%
%       instance    - Return active WordApp object
%       show        - Show Word application
%       hide        - Hide Word application
%       close       - Close Word application
%       isVisible   - Is WordApp visible?
%       isOpen      - Is WordApp open?
%       netobj      - Return a NET Word application object
%
%   Reference:
%
%       https://docs.microsoft.com/en-us/office/vba/api/overview/word
%
%   See also word, WordDoc, docview

     
    %   Copyright 2018-2021 The MathWorks, Inc.

    methods
        function out=close(~) %#ok<STOUT>
            %close   Close Word application
            %   tf = close(wordApp) closes Word application only if there are no
            %   unsaved documents. Returns true if Word application is closed
            %   and false if Word application is opened.
            %
            %   tf = close(wordApp, true) closes Word application only if there are
            %   no unsaved documents. Returns true if Word application is closed
            %   and false if Word application is opened.
            %
            %   tf = close(wordApp, false) closes Word application even if there are
            %   opened documents. Returns true if Word application is closed
            %   and false if Word application is opened.
            %
            %   See also word
        end

        function out=hide(~) %#ok<STOUT>
            %hide	Hide Word application
            %   hide(wordApp) hides Word application by making it invisible.
        end

        function out=instance(~) %#ok<STOUT>
            %mlreportgen.utils.WordApp.instance     Return active WordApp object
            %   WordApp = mlreportgen.utils.WordApp.instance() gets the active
            %   WordApp object. If Word application is not started, start it
            %   and then return the acitve WordApp object.
            %
            %   See also word
        end

        function out=isVisible(~) %#ok<STOUT>
            %isVisible  Is WordApp visible?
            %   tf = isVisible(wordApp) returns true if visible and returns
            %   false if invisible.
        end

        function out=show(~) %#ok<STOUT>
            %show	Show Word application
            %   show(wordApp) shows Word application by making it visible.
        end

    end
end
