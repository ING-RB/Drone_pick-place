classdef DelegateFunctionString < matlab.automation.internal.diagnostics.CompositeFormattableString
    % This class is undocumented and may change in a future release.
    
    % Note: DelegateFunctionString(fcnHandle,...) accepts the same inputs as
    % fcnHandle(...) where it is expected that fcnHandle is a function handle
    % that outputs a scalar string or character vector.
    
    % Copyright 2018-2022 The MathWorks, Inc.
    
    properties (Dependent, SetAccess=private)
        Text string;
    end
    
    properties(Hidden, SetAccess=immutable)
        DelegateFunction
    end
    
    properties(GetAccess=private,SetAccess=immutable)
        OriginalArgs
        UpdateMask
    end
    
    methods
        function str = DelegateFunctionString(fcn,varargin)
            import matlab.automation.internal.diagnostics.FormattableString;
            
            mask = cellfun(@(x) builtin('isa',x,...
                'matlab.automation.internal.diagnostics.FormattableString'),...
                varargin);
            formattableStringArgs = varargin(mask);
            
            str = str@matlab.automation.internal.diagnostics.CompositeFormattableString(...
                [FormattableString.empty(1,0) formattableStringArgs{:}]);
            str.DelegateFunction = fcn;
            str.OriginalArgs = varargin;
            str.UpdateMask = mask;
        end
        
        function text = get.Text(str)
            args = str.OriginalArgs;
            args(str.UpdateMask) = num2cell(str.ComposedText);
            text = string(str.DelegateFunction(args{:}));
        end
    end
end