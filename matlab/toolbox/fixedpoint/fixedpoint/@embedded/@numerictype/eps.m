function u = eps(T) %#codegen
% EPS Quantized relative accuracy for an embedded.numerictype object
%
%     See also embedded.fi/eps, embedded.quantizer/eps

%     Copyright 2017-2018 The MathWorks, Inc.
    if isscalingunspecified(T)
        error(message('fixed:numerictype:scalingRequired', 'EPS'));
    end
    u = eps(fi(1,T));
end