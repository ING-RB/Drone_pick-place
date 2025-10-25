classdef FormattableDiagnosticResult
    % This class is undocumented and may change in a future release.
    
    %  Copyright 2016-2022 The MathWorks, Inc.
    properties(SetAccess=immutable)
        Artifacts matlab.automation.diagnostics.Artifact
        FormattableDiagnosticText matlab.automation.internal.diagnostics.FormattableString
    end
    
    methods
        function formattableResult = FormattableDiagnosticResult(artifacts,formattableDiagnosticText)
            formattableResult.Artifacts = artifacts;
            validateattributes(formattableDiagnosticText,...
                {'matlab.automation.internal.diagnostics.FormattableString'},{'scalar'});
            formattableResult.FormattableDiagnosticText = formattableDiagnosticText;
        end
    end
    
    methods(Sealed)
        function results = toDiagnosticResults(formattableResults)
            import matlab.automation.diagnostics.DiagnosticResult;
            cellOfDiagnosticResults = arrayfun(@toDiagnosticResult,...
                formattableResults, 'UniformOutput', false);
            results = [DiagnosticResult.empty(1,0),cellOfDiagnosticResults{:}];
        end
        
        function results = toDiagnosticResultsWithoutFormat(formattableResults)
            import matlab.automation.diagnostics.DiagnosticResult;
            cellOfDiagnosticResults = arrayfun(@toDiagnosticResultWithoutFormat,...
                formattableResults, 'UniformOutput', false);
            results = [DiagnosticResult.empty(1,0),cellOfDiagnosticResults{:}];
        end
        
        function formattableStrings = toFormattableStrings(formattableResults)
            import matlab.automation.internal.diagnostics.FormattableString;
            formattableStrings = [FormattableString.empty(1,0), ...
                formattableResults.FormattableDiagnosticText];
        end
    end
    
    methods(Access=private)
        function result = toDiagnosticResult(formattableResult)
            import matlab.automation.diagnostics.DiagnosticResult;
            result = DiagnosticResult(formattableResult.Artifacts,...
                char(formattableResult.FormattableDiagnosticText));
        end
        
        function result = toDiagnosticResultWithoutFormat(formattableResult)
            import matlab.automation.diagnostics.DiagnosticResult;
            result = DiagnosticResult(formattableResult.Artifacts,...
                char(formattableResult.FormattableDiagnosticText.Text));
        end
    end
end