classdef MATLABCoberturaPublishingService < matlab.unittest.internal.services.coverage.CoberturaPublishingService
%

%   Copyright 2018-2022 The MathWorks, Inc.

    
    methods 
        function obj = MATLABCoberturaPublishingService()
            obj.Formatter = matlab.unittest.internal.coverage.CoberturaFormatter;
        end
        function publish(~,fileName,~,coverageResult)
            coverageResult.generateCoberturaReport(fileName);
        end
    end
    methods (Static)
        function tf = supports(theSources)
            tf = isa(theSources,'matlab.unittest.internal.coverage.MATLABSource');
        end
    end
end
