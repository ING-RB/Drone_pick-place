function mustBeConst(x, messageId, varargin)
%CODER.MUSTBECONST Validate that value is a compile-time constant
%   CODER.MUSTBECONST(X) throws an error during code generation if X
%   is not a compile-time constant.
%   This validator has no effect in MATLAB execution.
%
%   If additional inputs are passed to the validator, those 
%   must be a message ID and its argument holes.

%#codegen
if ~isempty(coder.target)
    narginchk(1, inf);
    coder.internal.allowEnumInputs;
    coder.internal.allowHalfInputs;
    eml_allow_mx_inputs;
    coder.internal.prefer_const(x);
    coder.internal.prefer_const(varargin);
    if nargin == 1
        messageId = 'Coder:builtins:MustBeConst';
    end
    coder.internal.assert(coder.internal.isConst(messageId), "Coder:builtins:InputMustBeConst", 2, mfilename);

    for idx = 1:numel(varargin)
        coder.internal.assert(coder.internal.isConst(varargin{idx}), "Coder:builtins:InputMustBeConst", idx+2, mfilename);
    end
    coder.internal.assert(coder.internal.isConst(x), messageId, varargin{:});
end
