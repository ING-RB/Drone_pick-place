%FROMPACKAGE  returns a scalar matlab.lang.internal.IntrospectionContext
%   that captures the context determined by the package ID.
%
%   Copyright 2024 The MathWorks, Inc.
function context = fromPackage(packageID)
    arguments(Input)
          packageID (1, 1) matlab.mpm.Package
    end
    arguments(Output)
          context (1, 1) matlab.lang.internal.IntrospectionContext
    end
    context = matlab.lang.internal.IntrospectionContext.fromPackageImpl(packageID);
end