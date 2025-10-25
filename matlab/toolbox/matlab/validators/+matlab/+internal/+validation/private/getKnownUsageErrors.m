function KUE = getKnownUsageErrors
% getKnownUsageErrors Maintains a list of known usage errors.
%    Usage errors and validation errors are different. Validation errors
%    are results of correct uses of validation functions. Usage errors
%    are not. These errors often indicate function and class authors made
%    some mistakes in using the validation functions. For example, calling
%    a validator without passing enough inputs. Authors must fix their usage
%    errors before they can ship their products.
    
%   Copyright 2019-2020 The MathWorks, Inc.
    persistent known_usage_errors;
    
    if isempty(known_usage_errors)
        known_usage_errors = {
            'MATLAB:TooManyInputs';
            'MATLAB:minrhs';
            'MATLAB:maxrhs';
            'MATLAB:narginchk';
            'MATLAB:UndefinedFunction';
            'MATLAB:ISMEMBER:';
            'MATLAB:string:';
            'MATLAB:validation:';
            'MATLAB:validatorUsage:';
            'MATLAB:unrecognizedStringChoice';
                   };
    end

    KUE = known_usage_errors;
end
