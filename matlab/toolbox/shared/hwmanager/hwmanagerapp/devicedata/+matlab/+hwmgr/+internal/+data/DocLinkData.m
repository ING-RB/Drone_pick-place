classdef DocLinkData
    %DOCLINKDATA Link data required by Hardware Manager app

    % Copyright 2021-2022 The MathWorks, Inc.

    properties
        %ShortName
        %   Short name for a product or installed support package used by
        %   helpview
        ShortName

        %TopicId
        %    The topic_id is an identifying string in the documentation
        %    source for the HTML section to open used by helpview
        TopicId

        %Title
        %   Title of the documentation/information web page
        Title

        %Url
        %   URL of the documentation/information web page
        Url
    end

    methods (Access = {?matlab.hwmgr.internal.data.DataFactory, ?matlab.unittest.TestCase})
        function obj = DocLinkData(shortName, topicId, title, url)
            arguments
                shortName (1, 1) string
                topicId (1, 1) string
                title (1, 1) string
                url (1, 1) string = ""
            end

            obj.ShortName = shortName;
            obj.TopicId = topicId;
            obj.Title = title;
            obj.Url = url;
        end
    end
end