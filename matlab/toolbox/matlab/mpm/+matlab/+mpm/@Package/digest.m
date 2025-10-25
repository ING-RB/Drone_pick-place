function dgst = digest(pkg)
arguments (Input)
    pkg matlab.mpm.Package
end

arguments (Output)
    dgst string
end

if isempty(pkg)
    dgst = strings(size(pkg));
else
    try
        dgst = arrayfun(@(p) string(matlab.mpm.internal.digest(p)), pkg);
    catch ex
        throw(ex);
    end
end

% Copyright 2024 The MathWorks, Inc.
