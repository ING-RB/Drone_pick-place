classdef ComponentDataAdjuster < handle
    %COMPONENTDATAADJUSTER A base class of all pre save data adjusters

    % Copyright 2021 The MathWorks, Inc.

    methods (Abstract)
        componentsStruct = adjustComponentDataPreSave(obj);
        adjustComponentDataPostSave(obj, componentsStruct);
    end
end
