function varargout = sameSizeBinaryOp(functionHandle, x, y, varargin)
%CODER.SAMESIZEBINARYOP checks that the 2 data inputs have the same size
% and calls a binary function with those 2 arguments and varargin.

% This may be used to avoid implicit expansion branches in the generated
%     code, such as x+y where x has size 2xM and y has size 2xN,
%     M and N are runtime values, but known to be equal by the programmer:
% coder.sameSizeBinaryOp(@plus, 1:m, 1:n);
%
% Without coder.sameSizeBinaryOp, and implicit expansion enabled,
% x+y generates checks for M=1 and N=1 to expand along those dimensions.

%#codegen
coder.internal.allowEnumInputs;
coder.internal.allowHalfInputs;
coder.noImplicitExpansionInFunction;

coder.internal.assert(isa(functionHandle,'function_handle'), 'Coder:builtins:ExpectedFunctionHandle', class(functionHandle));
coder.unroll;
for i = 1:max(coder.internal.ndims(x),coder.internal.ndims(y))
    szX = size(x, i);
    szY = size(y, i);
    coder.internal.assert(szX == szY, 'EMLRT:runTime:SizesMismatchOnDim', i, szX, szY);
end

[varargout{1:nargout}] = functionHandle(x, y, varargin{:});
