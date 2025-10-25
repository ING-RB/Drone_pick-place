classdef AppCloseData
    %APPCLOSEDATA  Creates the data that is passed to the app's 
    % AppCloseDataFcn callback

    % Copyright 2021 The MathWorks, Inc.

    properties (SetAccess = immutable)
        Source
        EventName = 'Output';
        App
    end

    methods (Access = {?appdesigner.internal.service.AppManagementService})
        function obj = AppCloseData(source)
            obj.Source = source;
            obj.App = source;
        end
    end
end