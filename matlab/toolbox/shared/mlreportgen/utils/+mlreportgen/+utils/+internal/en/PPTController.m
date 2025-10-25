classdef PPTController< mlreportgen.utils.internal.OfficeController
%mlreportgen.utils.internal.PPTController  Powerpoint Controller
%   Handles interactions between PPTApp and PPTPres
%
%   See also powerpoint

     
    %   Copyright 2018-2022 The MathWorks, Inc.

    methods
        function out=PPTController
        end

        function out=createApp(~) %#ok<STOUT>
        end

        function out=createDoc(~) %#ok<STOUT>
        end

        function out=instance(~) %#ok<STOUT>
        end

        function out=isAvailable(~) %#ok<STOUT>
            %isAvailable    Application available for use?
            %   tf = isAvailable(controller) returns true if the
            %   application is available and returns false if the
            %   application is unavailable.
        end

    end
    properties
        FileExtensions;

        Name;

    end
end
