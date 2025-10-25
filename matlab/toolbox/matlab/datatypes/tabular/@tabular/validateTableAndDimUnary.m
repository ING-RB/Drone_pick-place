function validateTableAndDimUnary(a, dim)
%

% Utility for validating the input table and dim arguments against each
% other for unary tabular math functions.

%   Copyright 2022-2024 The MathWorks, Inc.

if (~isnumeric(dim) && startsWith("all",dim,IgnoreCase=true)) || any(dim > 1)
    a_data = a.data;
    for i = 1:numel(a_data)
        % Reduction in any dimension but 1 is not well-defined for tabular variables.
        a_i = a_data{i};
        if isa(a_i,'tabular')
            error(message("MATLAB:table:math:TabularVarAmbiguous"));
        end

        % Reduction in any dimension but 1 is not well-defined for non-column variables.
        if ~iscolumn(a_i)
            error(message("MATLAB:table:math:MultiColumnVarAmbiguous"));
        end
    end
end
