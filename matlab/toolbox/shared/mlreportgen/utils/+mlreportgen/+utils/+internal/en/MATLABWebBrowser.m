classdef MATLABWebBrowser< handle
%mlreportgen.utils.internal.MATLABWebBrowser  Wraps MATLAB Web Browser
%
%   mlreportgen.utils.internal.MATLABWebBrowser(URL) creates a MATLAB web 
%       browser showing URL. MATLABWebBrowser destroys itself when it goes 
%       out of scope.
%
%   MATLABWebBrowser Properties:
%
%       URL             - URL of MATLAB web browser.
%       ShowAddressBox  - Shows address box.
%
%   MATLABWebBrowser Methods:
%
%       show        - Shows MATLAB web browser.
%       hide        - Hides MATLAB web browser.
%       close       - Close MATLAB web browser.
%       isVisible   - Is MATLAB web browser visible?
%       isOpen      - Is MATLAB web browser valid?

 
    %   Copyright 2018-2020 The MathWorks, Inc.

    methods
        function out=MATLABWebBrowser
        end

        function out=close(~) %#ok<STOUT>
            %isVisible  Close MATLAB Web Browser
            %   close(matlabWebBrowser) closes MATLAB Web Browser.  MATLAB Web 
            %   Browser cannot be reopened.  A new matlabWebBrowser must be created.
        end

        function out=delete(~) %#ok<STOUT>
        end

        function out=hide(~) %#ok<STOUT>
            %hide   MATLAB Web Browser 
            %   hide(matlabWebBrowser) hides matlabWebBrowser by making it 
            %   invisible.
        end

        function out=isOpen(~) %#ok<STOUT>
            %isOpen    Is MATLAB Web Browser opened?
            %   tf = isOpen(matlabWebBrowser) returns true if matlabWebBrowser
            %   has not been closed and false if matlabWebBrowser is closed.
        end

        function out=isVisible(~) %#ok<STOUT>
            %isVisible  Is MATLAB Web Browser visible?
            %   tf = isVisible(matlabWebBrowser) returns true if visible and 
            %   returns false if invisible.
        end

        function out=show(~) %#ok<STOUT>
            %show   Show MATLAB Web Browser
            %   show(matlabWebBrowser) shows matlabWebBrowser by making it 
            %   visible.
        end

    end
    properties
        ShowAddressBox;

        URL;

    end
end
