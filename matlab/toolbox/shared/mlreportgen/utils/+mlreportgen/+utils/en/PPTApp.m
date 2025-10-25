classdef PPTApp< mlreportgen.utils.internal.OfficeApp
%mlreportgen.utils.PPTApp  Wraps a PowerPoint presentation application
%   mlreportgen.utils.PPTApp wraps a PowerPoint application NET object.  There
%   can be only one PowerPoint application NET object active.  To get the active
%   PPTApp object, use the instance method.
%
%   PPTApp methods:
%
%       instance    - Return active PPTApp object
%       show        - Show Powerpoint application
%       hide        - Hide Powerpoint application
%       close       - Close Powerpoint application
%       isOpen      - Is Powerpoint open?
%       isVisible   - Is PPTApp visible?
%       netobj      - Return a NET Powerpoint application object
%
%   Reference:
%
%       https://docs.microsoft.com/en-us/office/vba/api/overview/powerpoint
%
%   See also powerpoint, PPTPres, pptview

     
    %   Copyright 2018-2020 The MathWorks, Inc.

    methods
        function out=close(~) %#ok<STOUT>
            %close   Close Powerpoint application
            %   tf = close(pptApp) closes Powerpoint application only if there are
            %   no unsaved presentations. Returns true if Powerpoint application
            %   is closed and false if Powerpoint application is opened.
            %
            %   tf = close(pptApp, true) closes Powerpoint application only if
            %   there are no unsaved presentations. Returns true if Powerpoint
            %   application is closed and false if Powerpoint application is opened.
            %
            %   tf = close(pptApp, false) closes Powerpoint application even if
            %   there are opened presentations. Returns true if Powerpoint
            %   application is closed and false if Powerpoint application is opened.
            %
            %   See also powerpoint
        end

        function out=hide(~) %#ok<STOUT>
            %hide Hide Powerpoint application
            %   hide(pptApp) hides Powerpoint application by making it minimizing
            %   it.  Powerpoint NET API does not allow application to be
            %   invisible once it is visible.
        end

        function out=instance(~) %#ok<STOUT>
            %mlreportgen.utils.PPTApp.instance     Return active PPTApp object
            %   PPTApp = mlreportgen.utils.PPTApp.instance() gets the active
            %   PPTApp object. If Powerpoint application is not started, start it
            %   and then return the acitve PPTApp object.
            %
            %   See also powerpoint
        end

        function out=isVisible(~) %#ok<STOUT>
            %isVisible  Is PPTApp visible?
            %   tf = isVisible(PPTApp) returns true if visible and returns
            %   false if invisible.
        end

        function out=show(~) %#ok<STOUT>
            %show Show Powerpoint application
            %   show(pptApp) shows Powerpoint application by making it visible.
        end

    end
end
