classdef OfficeApp< handle
%mlreportgen.utils.internal.OfficeApp   Wraps an Office application
%
%   Abstract base class for WordApp and PPTApp
%
%   OfficeApp properties:
%   
%       Name        - Name of Office application
%
%   OfficeApp methods:
%
%       instance    - Returns an instance of OfficeApp
%       show        - Show Office application
%       hide        - Hide Office application
%       close       - Close Office application
%       isOpen      - Is OfficeApp open?
%       isVisible   - Is OfficeApp visible?
%       netobj      - Return NET application object
%
%   See also WordApp, PPTApp

     
    %   Copyright 2018-2023 The MathWorks, Inc.

    methods
        function out=OfficeApp
        end

        function out=delete(~) %#ok<STOUT>
        end

        function out=isOpen(~) %#ok<STOUT>
            %isOpen    Is OfficeApp open?
            %   tf = isOpen(officeApp) returns true if Office application
            %   is opened and returns false if Office application is 
            %   closed.
        end

        function out=netobj(~) %#ok<STOUT>
            %netobj     Return a NET Office application object
            %   netObj = netobj(officeApp) returns NET Office application
            %   object. If Office application is closed, then throw an error.
        end

        function out=reset(~) %#ok<STOUT>
        end

    end
    properties
        Name;

    end
end
