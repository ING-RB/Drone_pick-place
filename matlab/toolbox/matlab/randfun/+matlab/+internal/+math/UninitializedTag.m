classdef UninitializedTag
    % Internal tag to allow RandStream to create an uninitialized object.

    % Copyright 2024 The MathWorks, Inc.

    methods (Access = {?RandStream})
        function obj = UninitializedTag
        end
    end
end

