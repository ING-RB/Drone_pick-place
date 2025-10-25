classdef CoverageResultAccessor < matlab.coverage.Result
    % Class is undocumented and may change in a future release.

     % Copyright 2024 The MathWorks, Inc.

     methods (Static)
         % Access methods from matlab.coverage.Result class

         function outResultArray = access_filterResultsForDuplicateSourceFiles(resultArray)
             outResultArray = resultArray.filterResultsForDuplicateSourceFiles();
         end

         function [staticData, runtimeData] = access_createCodeCoverageCollectorData(varargin)
             [staticData, runtimeData] = matlab.coverage.Result.createCodeCoverageCollectorData(varargin{:});
         end

     end
end