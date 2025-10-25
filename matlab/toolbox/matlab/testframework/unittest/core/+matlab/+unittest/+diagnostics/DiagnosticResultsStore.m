classdef(Hidden) DiagnosticResultsStore
    % This class is undocumented and may change in a future release
    
    % Copyright 2016-2020 The MathWorks, Inc.
    
    properties(Access=private)
        DiagnosticResultCache (1,:) matlab.unittest.internal.diagnostics.DiagnosticResultCache;
        DiagnosticDataPrototype (1,1) matlab.unittest.diagnostics.DiagnosticData;
    end
    
    methods
        function diagResults = getResults(store,varargin)
            formattableDiagResults = store.getFormattableResults(varargin{:});
            diagResults = formattableDiagResults.toDiagnosticResults();
        end
    end
    
    methods(Hidden)
        function formattableDiagResults = getFormattableResults(store,varargin)
            import matlab.unittest.internal.diagnostics.FormattableDiagnosticResult;
            
            diagData = store.DiagnosticDataPrototype.createDiagnosticDataFromPrototype(varargin{:});

            cellOfDiagResults = arrayfun(@(cache) cache.getFormattableResultFor(diagData), ...
                store.DiagnosticResultCache, 'UniformOutput',false);
            formattableDiagResults = [FormattableDiagnosticResult.empty(1,0),...
                cellOfDiagResults{:}];
        end
    end
    
    methods(Hidden, Static)
        function store = fromDiagnostics(diags, defaultDiagData)
            import matlab.unittest.internal.diagnostics.DiagnosticResultCache;
            import matlab.unittest.diagnostics.DiagnosticResultsStore;
            
            diagnosticResultCacheCell = arrayfun(@DiagnosticResultCache,diags,...
                'UniformOutput',false);
            diagnosticResultCacheArray = [DiagnosticResultCache.empty(1,0) ...
                diagnosticResultCacheCell{:}];
            store = DiagnosticResultsStore(diagnosticResultCacheArray, defaultDiagData);
        end
    end
    
    methods(Access=private)
        function store = DiagnosticResultsStore(diagnosticResultCacheArray, diagData)
            store.DiagnosticResultCache = diagnosticResultCacheArray;
            store.DiagnosticDataPrototype = diagData;
        end
    end
end

% LocalWords:  namedargs diags
