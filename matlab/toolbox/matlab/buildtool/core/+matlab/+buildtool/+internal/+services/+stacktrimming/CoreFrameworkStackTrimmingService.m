classdef CoreFrameworkStackTrimmingService < matlab.automation.internal.services.stacktrimming.StackTrimmingService
    % This class is unsupported and might change or be removed without 
    % notice in a future version.

    % Copyright 2022 The MathWorks, Inc.

    methods (Access = protected)
        function trimStackStart(~, liaison)
            liaison.Stack = matlab.buildtool.internal.trimStackStart(liaison.Stack);
        end

        function trimStackEnd(~, liaison)
            liaison.Stack = matlab.buildtool.internal.trimStackEnd(liaison.Stack);
        end
    end

end