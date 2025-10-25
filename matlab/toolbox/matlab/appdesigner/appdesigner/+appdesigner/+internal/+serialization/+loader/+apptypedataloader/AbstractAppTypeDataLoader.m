classdef (Abstract) AbstractAppTypeDataLoader < handle
    %ABSTRACTAPPTYPEDATALOADER  Interfaces how to load user methods 
    % specific to the app type.

    % Copyright 2021, MathWorks Inc.

    methods (Abstract, Access = public)
        codeData = load(obj, loadedData)
    end
end
