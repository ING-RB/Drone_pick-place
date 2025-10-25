% parallel.parfor.PoolOptions parforOptions for running on parallel.parfor.PoolEngine

% Copyright 2018-2024 The MathWorks, Inc.

classdef PoolOptions < parallel.parfor.Options
    properties (SetAccess = immutable)
        Pool          (1,1) {isa(Pool,'parallel.Pool')}
        MaxNumWorkers (1,1) double
    end

    methods
        function obj = PoolOptions(pool, maxNumWorkers, varargin)
            obj = obj@parallel.parfor.Options(varargin{:});
            obj.Pool = pool;
            % Resolve to the NumWorkers of the pool here.
            obj.MaxNumWorkers = min(obj.Pool.NumWorkers, maxNumWorkers);
        end

        function engine = createEngine(obj, initData, parforF, numIterates)
            % Throw if stored Pool object has gone stale at this point.
            mustBeValid(obj.Pool);

            % No point attempting to use more workers than the maximum
            % possible number of intervals.
            maxNumWorkers = min(obj.MaxNumWorkers, numIterates);

            engine = obj.Pool.hGetEngine().createParforEngine(obj.RangePartitionMethod, obj.SubrangeSize, ...
                maxNumWorkers, initData, parforF);
        end
    end


    methods (Access = protected)
        function group = getSpecificPropertyGroup(obj)
            group = struct('Pool', obj.Pool, ...
                           'MaxNumWorkers', obj.MaxNumWorkers);
            group = matlab.mixin.util.PropertyGroup(group);
        end
    end

    methods (Static, Hidden)
        function poolOpts = build(pool, varargin)
            if nargin == 3 && ...
                       isequal(varargin{1}, 'MaxNumWorkers') && ...
                       iIsValidMaxNumWorkers(varargin{2})
                % Short-circuit for commonest case
                poolOpts = parallel.parfor.PoolOptions(pool, varargin{2});
            else
                p = parallel.parfor.Options.getBaseOptionsParser();
                p.addParameter('MaxNumWorkers', Inf, @iIsValidMaxNumWorkers);
                p.parse(varargin{:});
                poolOpts = parallel.parfor.PoolOptions(pool, p.Results.MaxNumWorkers, ...
                                                       p.Results, p.UsingDefaults);
            end
        end
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function ok = iIsValidMaxNumWorkers(M)
    ok = isnumeric(M) && ...
         isscalar(M) && ...
         isreal(M) && ...
         (isinf(M) || (M > 0 && M == fix(M)));
    if ~ok
        error(message('MATLAB:parallel:parfor:InvalidMaxNumWorkers'));
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function mustBeValid(value)
if ~isvalid(value)
    error(message('MATLAB:class:InvalidHandle'));
end
end
