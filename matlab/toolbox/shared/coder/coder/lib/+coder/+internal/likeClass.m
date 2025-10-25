function out = likeClass(like, eg, funcName)
%MATLAB Code Generation Private Function
%helper function for func('like', eg) functions to dispatch to correct code
%and manage types
%like - should be constant string/char array "like"
%eg - example of output type
%funcName - function to call

%   Copyright 2021 The MathWorks, Inc.
%#codegen
coder.internal.allowHalfInputs;
coder.internal.prefer_const(like, funcName);
coder.internal.assert(coder.internal.isConst(like), 'Coder:toolbox:InputMustBeConstant', 1)
coder.internal.assert(strcmp(like, 'like'), 'Coder:toolbox:mustBeLike', 'IfNotConst','Fail');

if coder.internal.isBuiltInNumeric(eg) || islogical(eg) || isa(eg, 'half')
    func = str2func(funcName);
    outB = func(class(eg));
    if isreal(eg)
        outC = outB;
    else
        outC = complex(outB, zeros(1, 'like', real(eg)));
    end
    if issparse(eg)
        out = sparse(outC);
    else
        out = outC;
    end
else %isobject(eg)
    funcNameLike = [funcName, 'Like'];
    if coder.internal.isMethodAllowHidden(eg, funcNameLike)
        out = eg.(funcNameLike);
    elseif coder.internal.isMethodAllowHidden(eg, funcName)
        out = eg.(funcName);
    else
        coder.internal.assert(false, ['MATLAB:', funcName, ':invalidPrototype']);
    end

end
end