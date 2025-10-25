% RequestError - Used for formatting the error message from a Request.

% Copyright 2013-2024 The MathWorks, Inc.
classdef RequestError < parallel.internal.display.AbstractError
    properties (SetAccess = immutable, GetAccess = private)
        Pool
    end
    methods
        function obj = RequestError(displayHelper, error, pool)
            obj@parallel.internal.display.AbstractError(displayHelper, error);
            obj.Pool = pool;
        end
    end
    methods (Access = protected)
        function list = listAttachedFilesAndPaths(obj)
            if ~isempty(obj.Pool) && ~(isa(obj.Pool, "parallel.internal.pool.NonClusterPoolMixin"))
                list = obj.Pool.AttachedFiles;
            else
                list = {};
            end
        end
    end
end
