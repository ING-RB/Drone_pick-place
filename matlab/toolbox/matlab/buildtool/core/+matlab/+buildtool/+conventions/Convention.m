classdef (Hidden) Convention < matlab.mixin.Heterogeneous
    % This class is unsupported and might change or be removed without notice
    % in a future version.

    %   Copyright 2024 The MathWorks, Inc.

    methods (Abstract)
        plan = apply(convention, plan)
    end
end