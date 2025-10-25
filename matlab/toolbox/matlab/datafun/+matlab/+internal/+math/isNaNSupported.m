function TF = isNaNSupported(values)
% Helper function for code generation for discretize to determine if the
% datatype supports NaN

TF = true;
try
    v1 = [values(:);NaN]; %#ok<NASGU>
catch
    TF = false;
end