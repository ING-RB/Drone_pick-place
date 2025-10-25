function [A, E] = log2(A)
%

%   Copyright 2022-2024 The MathWorks, Inc.

    if nargout <= 1
        A = tabular.unaryFunHelper(A,@log2,false,{});
    else % nargout == 2
        E = tabular.unaryFunHelper(A,@log2SecondOutput,false,{},false,"log2");
        A = tabular.unaryFunHelper(A,@log2FirstOutput,false,{},false,"log2");
    end
end

function F = log2FirstOutput(X)
    % The first output of log2 differs for nargout <= 1 and nargout == 2,
    % so we must call core log2 with two outputs when nargout == 2.
    [F,~] = log2(X);
end

function E = log2SecondOutput(X)
    [~,E] = log2(X);
end
