%

% Copyright 2022-2024 The MathWorks, Inc.

classdef ResultBuilder

    properties (Access=private)
        CodeCollectorAccessor
        StaticData
        RuntimeData
        DataProvider
    end

    methods
        %% Method: ResultBuilder ------------------------------------------
        %  Abstract:
        %    Constructor
        function this = ResultBuilder(arg1, arg2)
            narginchk(1, 2);

            if nargin == 1
                if isa(arg1, 'matlab.coverage.internal.CodeCovDataProvider')
                    % SIL/PIL case
                    this.DataProvider = arg1;
                else
                    % Code Coverage Collector case
                    validateattributes(arg1, {'function_handle'}, {'scalar', 'nonempty'}, 1);

                    % Check validity
                    alloowedAccessors = [...
                        "matlab.lang.internal.CodeCoverageCollectorWithMCDC", ...
                        "matlab.lang.internal.BasicCodeCoverageCollector"...
                        ];
                    accessorDetails = functions(arg1);
                    if ~contains(accessorDetails.function, alloowedAccessors)
                        error(message('MATLAB:coverage:result:UnsupportedCodeCoverageCollector'));
                    end

                    this.CodeCollectorAccessor = arg1;
                end
            else
                % static and runtime case
                validateattributes(arg1, {'cell'}, {'vector', 'nonempty'}, 1);
                validateattributes(arg2, {'uint64'}, {'column', 'nonempty'}, 2);

                this.StaticData = arg1;
                this.RuntimeData = arg2;
            end
        end

        %% Method: create -------------------------------------------------
        %  Abstract:
        %    "Main" method for constructing matlab.coverage.Result objects.
        function resObjs = create(this)
            if ~isempty(this.DataProvider)
                % Convert each MATLAB Coder module
                resObjs = matlab.coverage.Result.empty;
                for ii = 1 : numel(this.DataProvider)
                    % Aggregate results (will combine common custom code files!)
                    resObj = this.createFromXILCodeCoverage(this.DataProvider(ii));
                    if ~isempty(resObj)
                        resObjs = resObjs + resObj;
                    end
                end

            elseif ~isempty(this.CodeCollectorAccessor)
                if this.CodeCollectorAccessor('status')
                    % Early return if the coverage collector is still
                    % collecting coverage data
                    resObjs = matlab.coverage.Result.empty;
                    return
                end
                resObjs = this.createFromCodeCoverageCollector(this.CodeCollectorAccessor);

            else
                resObjs = this.createFromCodeCoverageCollectorData(this.StaticData, this.RuntimeData);
            end
        end
    end

    methods (Static, Access=private)
        resObjs = createFromCodeCoverageCollector(ccDataAccessor)
        resObjs = createFromCodeCoverageCollectorData(staticData, runtimeData)
        resObjs = createFromXILCodeCoverage(mcModuleName)
    end
end

