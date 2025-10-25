classdef DecimalSeparatorInput < matlab.io.internal.FunctionInterface
%

%   Copyright 2018 The MathWorks, Inc.

    properties (Parameter)
        %DECIMALSEPARATOR
        %   The character to be used when importing times with fractional
        %   seconds.
        %
        %   See also matlab.io.DurationVariableImportOptions
        DecimalSeparator = '.';
    end 
    
    methods
        function obj = set.DecimalSeparator(obj,rhs)
        rhs = convertStringsToChars(rhs);
        if ~matlab.io.internal.validateScalarSeparator(rhs)
            error(message('MATLAB:textio:textio:InvalidDecimalSep'))
        end
        obj.DecimalSeparator = rhs;
        end
    end
end

