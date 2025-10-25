function y = datetimeMean(d,dim,omitnan) %#codegen
%DATETIMEMEAN

%   Copyright 2020 The MathWorks, Inc.

[m,n] = size(d);

% Create reduction result.
reductionSz = size(d);
reductionSz(1) = 1;

if coder.internal.isConst(isempty(d)) && isempty(d)
    y = complex(NaN,0);
    return
end

y = complex(zeros(reductionSz));

for j = 1:n
    numNonNaN = 0;
    
    for k = 1:m
        x = d(k,j);
        [y(j), x_was_nonnan] = matlab.internal.coder.doubledouble.AddToSum(y(j),x,omitnan);
        
        if x_was_nonnan
            numNonNaN = numNonNaN + 1;
        end
    end
    
    y(j) = matlab.internal.coder.doubledouble.divide(y(j),numNonNaN);
    
end


end