classdef WidgetRegistrator < handle
    %WidgetRegistrator Abstract Class for Web Widget Registration
    %

    % Copyright 2018 The MathWorks, Inc.

    methods (Abstract = true, Static = true)
        [filePath] = getWidgetRegistrationFile();
    end
end
