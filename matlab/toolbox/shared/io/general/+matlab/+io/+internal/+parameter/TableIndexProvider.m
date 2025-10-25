classdef TableIndexProvider < matlab.io.internal.FunctionInterface
%

% Copyright 2021 The MathWorks, Inc.

    properties (Parameter)
        %TableIndex  Which table to extract
        % TableIndex must be a positive integer scalar.
        % Mutually exclusive with TableSelector.
        TableIndex = 1;
    end

    methods
        function obj = set.TableIndex(obj,rhs)
            validateattributes(rhs,{'numeric'},{'integer','positive','scalar'},'',"TableIndex");
            obj.TableIndex = rhs;
        end
    end
end
