classdef LinkData
    %LINKDATA Link data required by Hardware Manager app

    % Copyright 2021 The MathWorks, Inc.

    properties
        %Title
        %   Title of the documentation/information web page
        Title

        %Url
        %   Url of the documentation/information web page
        Url
    end

    methods (Access = {?matlab.hwmgr.internal.data.DataFactory, ?matlab.unittest.TestCase})
        function obj = LinkData(title, url)
            arguments
                title (1, 1) string
                url (1, 1) string
            end

            obj.Title = title;
            obj.Url = url;
        end
    end
end