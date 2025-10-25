classdef (Abstract) AbstractAppTypeDataSynchronizer < handle
    %ABSTRACTAPPTYPEDATASYNCHRONIZER Abstract class with API for CodeDataController
    %to synchronize app type data into code model structure

    % Copyright 2021, MathWorks Inc.

    methods (Abstract)
        syncAppTypeData(obj, codeModel, codeData)
    end
end

