function [cData,ind] = minMaxUnary(aData,omitNan,isMax,linearFlag) %#codegen
%MAXUNARY

%   Copyright 2022 The MathWorks, Inc.

[m,n] = size(aData);
if (coder.internal.isConst(m) && m == 0)
    cData = complex(zeros(0,size(aData,2)));
    ind = zeros(0,size(aData,2));
    return
end
coder.internal.assert(m >= 1, ...
    'Coder:toolbox:eml_min_or_max_varDimZero');
cData = complex(zeros(1,size(aData,2)));
ind = zeros(1,size(aData,2));
for j = 1:n
    cData(j) = aData(1,j);
    if linearFlag
        ind(j) = 1*j;
    else
        ind(j) = 1;
    end
    for i = 2:m
        if isMax
            [cData(j),b_is_extrema] = matlab.internal.coder.doubledouble.max(cData(j),aData(i,j),omitNan);
        else
            [cData(j),b_is_extrema] = matlab.internal.coder.doubledouble.min(cData(j),aData(i,j),omitNan);
        end

        if b_is_extrema
            if linearFlag
                ind(j) = i*j;
            else
                ind(j) = i;
            end
        end
    end
end

end