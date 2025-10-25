classdef MAppInitializationInfo < handle
    %MAPPINITIALIZATIONINFO handle class containing plain-text app initialization data, used to pass
    % references and data around the various plain-text app internal APIs without worrying about memory behaviors

%   Copyright 2024 The MathWorks, Inc.

    properties
        AppHandle
        AppOptions appdesigner.internal.apprun.AppOptions
        FileContent string
        ComponentXMLString string
        RunConfigXMLString string
        LayoutDocument matlab.io.xml.dom.Document
        RunConfigDocument matlab.io.xml.dom.Document
        XMLEvaluator matlab.io.xml.xpath.Evaluator  = matlab.io.xml.xpath.Evaluator();

        AppManagementService appdesigner.internal.service.AppManagementService
        CacheService appdesigner.internal.cacheservice.CacheService
        ContentUID string
        CacheBucket appdesigner.internal.cacheservice.FilesystemBucket
    end
end
