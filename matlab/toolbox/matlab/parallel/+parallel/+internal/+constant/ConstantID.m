%ConstantID Trivial helper class for parallel.pool.Constant
%   This class only exists as a marker so that parallel.pool.Constant
%   can mimic a private constructor.

% Copyright 2015-2021 The MathWorks, Inc.
classdef (Hidden) ConstantID
    properties (SetAccess = immutable)
        ID
    end
    methods (Access = ?parallel.pool.Constant)
        function obj = ConstantID(id)
            obj.ID = id;
        end
    end
end
    
