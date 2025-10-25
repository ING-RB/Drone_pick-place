classdef (Sealed, Hidden) CasualDiagnosticDecorator < matlab.unittest.internal.constraints.ConstraintDecorator
    % This class is undocumented.
    
    % CasualDiagnosticDecorator - Decorates Constraint's diagnostics
    %
    %   The CasualDiagnosticDecorator is a means to provide casual
    %   diagnostics from a Constraint.
    %
    %   This decorator may only be appled to Constraint instances which
    %   provide casual diagnostics by mixing in CasualDiagnosticMixin
    %   and implementing getCasualDiagnosticFor().
    %   
    %   See also
    %       matlab.unittest.internal.constraints.ConstraintDecorator
    %       matlab.unittest.internal.constraints.CasualDiagnosticMixin
    
    %  Copyright 2013-2017 The MathWorks, Inc. 
    
    properties(Hidden, SetAccess=immutable)
        % CasualMethodName
        %   Char array containing full name of the casual method.
        %   For example: 'matlab.unittest.TestCase.verifyEqual'
        CasualMethodName (1,:) char;
        
        % AdditionalArguments
        %   Cell array containing input arguments provided to casual method
        %   besides the actual value and optional test diagnostic.
        %   For example, for tC.verifyEqual(31,31.5,'AbsTol',1,'dummyTestDiag')
        %   the AdditionalArguments value would be: {31.5,'AbsTol',1}
        AdditionalArguments (1,:) cell;
    end
    
    methods
        function decorator = CasualDiagnosticDecorator(constraint,casualMethodName,additionalArgs)
            assert(isa(constraint,'matlab.unittest.internal.constraints.CasualDiagnosticMixin')); % sanity check
            decorator@matlab.unittest.internal.constraints.ConstraintDecorator(constraint);     
            decorator.CasualMethodName = casualMethodName;
            decorator.AdditionalArguments = additionalArgs;
        end
        
        function bool = satisfiedBy(decorator, actual)
            bool = decorator.Constraint.satisfiedBy(actual);
        end
        
        function diag = getDiagnosticFor(decorator, actual)
            diag = decorator.Constraint.getCasualDiagnosticFor(...
                decorator.CasualMethodName,...
                actual,...
                decorator.AdditionalArguments);
        end
    end        
end