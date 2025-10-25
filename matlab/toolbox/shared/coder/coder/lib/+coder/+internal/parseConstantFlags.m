function [f,info] = parseConstantFlags(flagNames,varargin)
%MATLAB Code Generation Private Function
%
%   Parse flag inputs in a varargin list using case-insensitive partial
%   matching. The flagNames input is a (constant) cell array of possible
%   flag inputs. The output f is a struct with flagNames for its field
%   names and logicals for its field values. If flag 'abc' was supplied
%   AS A CONSTANT in varargin, f.abc is true, otherwise false.
%
%   If nargout < 2, then coder.internal.parseConstantFlags uses
%   validatestring to generate an appropriate error messages for unmatched,
%   ambiguous, and invalid inputs.
%
%   If nargout == 2, errors are suppressed. The info output gives
%   diagnostic information. The fields are:
%
%   * nonFlagInputs: a vector integers. varargin{info.nonFlagInputs} are
%       inputs that did not statically match to any of the flag names.
%   * ambiguousInputs: a vector of integers. varargin{info.ambiguousInputs}
%       are the inputs that partially matched more than one flag name.
%   * nonConstantTextInputs: a vector of integers.
%       varargin{info.nonConstantTextInputs} are the non-constant text
%       (char row or scalar string) inputs, i.e. the inputs that might
%       match one of the flag names at run-time. nonConstantTextInputs is a
%       subset of nonFlagInputs.
%   * anyDuplicatedFlags: a logical indicating whether any duplicate flags
%       were statically matched.
%   * flagDuplicated: a struct of logical values indicating which flag
%       names were statically matched more than once.
%
%   Since info.nonFlagInputs is constant, you can use two-stage parsing
%   when flags and optional numeric inputs can be interspersed since
%   varargin{info.nonFlagInputs} will have the statically-matched flags
%   removed. Likewise, since info.nonConstantTextInputs is constant,
%   run-time flags can be parsed separately from
%   varargin{info.nonConstantTextInputs} (see coder.internal.parseFlags).
%
%   EXAMPLE
%     The EIG function accepts several possible flag inputs. We could parse
%     the optional inputs as follows:
%
%         f = coder.internal.parseConstantFlags( ...
%            {'vector','matrix','chol','qz','balance','nobalance'}, ...
%            varargin{:});
%
%     Since some of the flag inputs to EIG are mutually exclusive, we would
%     follow up with checks like
%
%         coder.internal.assert(~(f.vector && f.matrix), ...);
%
%     If we wished to use our own error messages:
%
%         [f,info] = coder.internal.parseConstantFlags( ...
%            {'vector','matrix','chol','qz','balance','nobalance'}, ...
%            varargin{:});
%         coder.internal.assert(isempty(info.nonConstantTextInputs), ...
%             'Coder:toolbox:OptionInputsMustBeConstant','eig');
%         coder.internal.assert(isempty(info.nonFlagInputs), ...
%             'MATLAB:eig:unknownArgumentStandard');
%         coder.internal.assert(~info.anyDuplicatedFlags, ...
%             'MATLAB:eig:unknownArgumentCombinationStandard');

%   Copyright 2021 The MathWorks, Inc.
%#codegen

narginchk(1,inf);
coder.internal.allowHalfInputs;
coder.internal.allowEnumInputs;
coder.internal.prefer_const(flagNames,varargin);
FLAGS = coder.const(stringsToChars(flagNames));
if nargout <= 1
    f = coder.const(parseFlagsThrow(FLAGS,varargin{:}));
else
    [f,NF,nNF,NC,nNC,AM,nAM,anyDups,flagDup] = ...
        coder.const(@parseFlagsInfo,FLAGS,varargin{:});
    info = coder.const(struct( ...
        'nonFlagInputs',NF(1:nNF), ...;
        'nonConstantTextInputs',NC(1:nNC), ...
        'ambiguousInputs',AM(1:nAM), ...
        'anyDuplicatedFlags',anyDups, ...
        'flagDuplicated',flagDup));
end

%--------------------------------------------------------------------------

function f = parseFlagsThrow(flagNames,varargin)
% Parse flags and throw an error if appropriate.
coder.internal.allowHalfInputs;
coder.internal.allowEnumInputs;
coder.internal.prefer_const(flagNames,varargin);
ZERO = coder.internal.indexInt(0);
f = makeFlagStruct(flagNames);
coder.unroll;
for k = 1:coder.internal.indexInt(nargin - 1)
    CONST = coder.internal.isConst(varargin{k});
    TEXT = coder.internal.isTextRow(varargin{k});
    if coder.const(CONST && TEXT)
        j = coder.const(findFlag(flagNames,varargin{k}));
    else
        j = ZERO;
    end
    if coder.const(j > 0)
        f.(flagNames{j}) = true;
    elseif coder.const(j < 0)
        validatestring(varargin{k},flagNames,mfilename);
    else
        coder.internal.assert(CONST || ~TEXT, ...
            'Coder:toolbox:FlagMustBeConst');
        validatestring(varargin{k},flagNames,mfilename);
    end
end

%--------------------------------------------------------------------------

function [f,NF,nNF,NC,nNC,AM,nAM,anyDups,flagDup] = ...
    parseFlagsInfo(flagNames,varargin)
% Parse flags and return diagnostic information.
coder.internal.allowHalfInputs;
coder.internal.allowEnumInputs;
coder.internal.prefer_const(flagNames,varargin);
ZERO = coder.internal.indexInt(0);
anyDups = false; % indicates whether any flags were supplied more than once
% Allocate fixed-size arrays to contain diagnostic information.
NF = zeros(1,nargin-1,'like',ZERO); % non-flags
AM = zeros(1,nargin-1,'like',ZERO); % ambiguous inputs
NC = zeros(1,nargin-1,'like',ZERO); % non-constant text inputs.
% Initialize counters for diagnostic arrays.
nNF = ZERO; % number of non-flags
nAM = ZERO; % number of inputs with ambiguous partial matches
nNC = ZERO; % number of non-constant text inputs
f = makeFlagStruct(flagNames);
flagDup = f;
nin = coder.internal.indexInt(nargin - 1);
coder.unroll;
for k = 1:nin
    CONST = coder.internal.isConst(varargin{k});
    TEXT = coder.internal.isTextRow(varargin{k});
    if coder.const(CONST && TEXT)
        j = coder.const(findFlag(flagNames,varargin{k}));
    else
        j = ZERO;
    end
    if coder.const(j > 0)
        if f.(flagNames{j})
            anyDups = true;
            flagDup.(flagNames{j}) = true;
        else
            f.(flagNames{j}) = true;
        end
    elseif coder.const(j < 0)
        nAM = nAM + 1;
        AM(nAM) = k;
    else
        if coder.const(~CONST && TEXT)
            nNC = nNC + 1;
            NC(nNC) = k;
        end
        nNF = nNF + 1;
        NF(nNF) = k;
    end
end

%--------------------------------------------------------------------------

function f = makeFlagStruct(flagNames)
coder.internal.prefer_const(flagNames);
coder.unroll;
for k = 1:numel(flagNames)
    f.(flagNames{k}) = false;
end

%--------------------------------------------------------------------------
