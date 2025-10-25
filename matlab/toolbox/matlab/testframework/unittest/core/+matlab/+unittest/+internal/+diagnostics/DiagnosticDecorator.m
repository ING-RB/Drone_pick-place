classdef(Hidden) DiagnosticDecorator < matlab.unittest.internal.diagnostics.CompositeDiagnostic & ...
                                       matlab.unittest.internal.diagnostics.GetConditionsSupplierMixin
    % This class is undocumented and may change in a future release.
    
    %  Copyright 2017 The MathWorks, Inc.
    properties(Hidden, Dependent, Access=protected)
        ComposedDiagnostic
    end
    
    methods
        function value = get.ComposedDiagnostic(wrapper)
            value = wrapper.ComposedDiagnostics;
        end
        
        function set.ComposedDiagnostic(wrapper,value)
            assert(isscalar(value)); % Sanity check
            wrapper.ComposedDiagnostics = value;
        end
    end
    
    methods(Hidden, Sealed)
        function conditionsSupplier = getConditionsSupplier(diag)
            import matlab.unittest.internal.diagnostics.DirectConditionsSupplier;
            import matlab.unittest.diagnostics.Diagnostic;
            composedDiag = diag.ComposedDiagnostic;
            if isa(composedDiag,'matlab.unittest.internal.diagnostics.ConditionsSupplier')
                conditionsSupplier = composedDiag;
            elseif isa(composedDiag,'matlab.unittest.internal.diagnostics.GetConditionsSupplierMixin')
                conditionsSupplier = composedDiag.getConditionsSupplier();
            else
                % Return a ConditionsSupplier that returns zero conditions
                conditionsSupplier = DirectConditionsSupplier(Diagnostic.empty(1,0));
            end
        end
    end
    
    methods(Hidden, Access=protected)
        function wrapper = DiagnosticDecorator(innerDiag)
            wrapper.ComposedDiagnostic = innerDiag;
        end
    end
end