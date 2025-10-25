function [X,M] = stdVarHelper(a,f,args)
%

%   Copyright 2024 The MathWorks, Inc.

switch numel(args)
    case 0 % f(A)
        w = 0;
    case 1
        if isnumeric(args{1}) % f(A,w)
            w = args{1};
            args={};
        else % f(A,missingFlag)
            w = 0;
        end
    otherwise % f(A,w,dim), f(A,w,vecDim), f(A,w,"all") or f(A,w,_,missingFlag)
        w = args{1};
        args = args(2:end);
end

fun = @(a,varargin)f(a,w,varargin{:});

if nargout > 1
    % Preserve units for the second output (weighted mean).
    [X, M] = tabular.reductionFunHelper(a,fun,args,FunName=func2str(f));
    M.varDim = M.varDim.setUnits(X.varDim.units);
else
    X = tabular.reductionFunHelper(a,fun,args,FunName=func2str(f));
end
