function hasStrictlyIncreasingFinites(A)
    % helper function to test sorted vectors
    
    %   Copyright 2022 The MathWorks, Inc.
    
    %#codegen

    af = allfinite(A);
    coder.internal.assert(af, 'MATLAB:griddedInterpolant:NonFiniteInputPtsErrId');
    
    notnan = @(a) ~isnan(a);
    allsorted = coder.internal.scalarizedAll(notnan, A(:).', 2);
    allsorted = allsorted & issorted(A(:).', 2);
    coder.internal.assert(allsorted, 'MATLAB:griddedInterpolant:NonMonotonicCompVecsErrId');
    
    hasdups = ~coder.internal.allUnique(A, true);
    coder.internal.errorIf(hasdups, 'MATLAB:griddedInterpolant:NonUniqueCompVecsPtsErrId');

end