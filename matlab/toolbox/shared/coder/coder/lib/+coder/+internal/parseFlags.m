function [f,bad] = parseFlags(flagNames,varargin)
%MATLAB Code Generation Private Function
%
%   Parse flag inputs in a varargin list using case-insensitive partial
%   matching. The FLAGNAMES input is a (constant) cell array of possible
%   flag inputs. The output f is a constant-preserving struct with the flag
%   names for its field names and logicals for its field values. If flag
%   'abc' was supplied in varargin, f.abc is true, otherwise false. This
%   function does not require flags to be constant. If you do not wish to
%   support non-constant flag inputs, consider using
%   coder.internal.parseConstantFlags directly.
%
%   If nargout <= 1, coder.internal.parseFlags uses validatestring to
%   generate appropriate error messages for unmatched, ambiguous, and
%   invalid inputs.
%
%   If nargout == 2, errors are suppressed. If there were no unmatched,
%   ambiguous, or otherwise invalid inputs, then BAD = 0, otherwise
%   varargin{BAD} is (one of) the bad inputs. If any inputs are statically
%   known to be unmatched, ambiguous, or otherwise invalid, then
%   varargin{BAD} will be the first input that is known to be bad at
%   compile time. When there are no known bad inputs at compile time,
%   varargin{BAD} will be the first bad run-time input. As a consequence,
%   coder.internal.isConst(BAD) is equivalent to checking that all the char
%   row and scalar string inputs are constant.
%
%   Note that while the BAD index itself is straightforward to use whether
%   or not it is constant, it is nevertheless tricky to use it in contexts
%   that require constant indexing in code generation, such as,
%   unfortunately, varargin{BAD}. To make use of the bad input
%   varargin{BAD} in your own error messaging when BAD is potentially
%   non-constant, you can use a loop:
%
%   if bad > 0
%       coder.unroll;
%       for k = 1:length(varargin)
%           if k == bad
%               % Use varargin{k}, not varargin{bad}.
%               validatestring(varargin{k},flagNames,mfilename);
%           end
%       end
%   end

%   Copyright 2021 The MathWorks, Inc.
%#codegen

narginchk(1,inf);
coder.internal.prefer_const(flagNames,varargin);
FLAGS = coder.const(stringsToChars(flagNames));
if coder.target('MATLAB')
    % Everything is constant in MATLAB, and at the same time, nothing is.
    % Just use the simple runtime parser.
    if nargout == 2
        [f,bad] = parseRuntimeFlags(FLAGS,varargin{:});
    else
        f = parseRuntimeFlags(FLAGS,varargin{:});
    end
    return
end
coder.internal.allowHalfInputs;
coder.internal.allowEnumInputs;
% Compile-time parsing.
[cf,cinfo] = coder.const(@coder.internal.parseConstantFlags, ...
    FLAGS,varargin{:});
if coder.const(~isempty(cinfo.ambiguousInputs))
    bad = cinfo.ambiguousInputs(1);
else
    bad = coder.internal.indexInt(0);
end
nNF = coder.const(coder.internal.indexInt(numel(cinfo.nonFlagInputs)));
nNC = coder.const(coder.internal.indexInt(numel(cinfo.nonConstantTextInputs)));
if coder.const(nNF > nNC)
    % There's at least one non-flag input that is not a candidate for being
    % a run-time match.
    NF = coder.const(cinfo.nonFlagInputs);
    NC = coder.const(cinfo.nonConstantTextInputs);
    nonflag = coder.const(findFirstMissing(NF,NC));
    if coder.const(bad == 0 || nonflag < bad)
        bad = nonflag;
    end
end
% Run-time parsing.
if nargout <= 1
    if bad > 0
        % Since we have suppressed errors from parseConstantFlags, we need
        % to go ahead and throw the error now.
        validatestring(varargin{bad},FLAGS,mfilename);
    end
    rf = parseRuntimeFlags(FLAGS,varargin{cinfo.nonConstantTextInputs});
else
    [rf,rbad] = parseRuntimeFlags(FLAGS,varargin{cinfo.nonConstantTextInputs});
    if bad == 0 && rbad > 0
        bad = cinfo.nonConstantTextInputs(rbad);
    end
end
coder.unroll;
for k = 1:numel(FLAGS)
    flag = coder.const(FLAGS{k});
    p = coder.const(cf.(flag)) || rf.(flag);
    if k == 1
        % Folding the k = 1 case into the loop is currently required for
        % successful compilation.
        f = coder.internal.constantPreservingStruct(flag,p);
    else
        f = f.set(flag,p);
    end
end

%--------------------------------------------------------------------------

function [f,bad] = parseRuntimeFlags(flagNames,varargin)
narginchk(1,inf);
coder.internal.allowHalfInputs;
coder.internal.allowEnumInputs;
coder.internal.prefer_const(flagNames);
bad = coder.internal.indexInt(0);
p = false(1,numel(flagNames));
nin = coder.internal.indexInt(nargin - 1);
coder.unroll;
for k = 1:nin
    j = findFlag(flagNames,varargin{k});
    if j > 0
        p(j) = true;
    elseif nargout <= 1
        % Use validatestring to construct the error message.
        validatestring(varargin{k},flagNames,mfilename);
    elseif bad == 0
        bad = k;
    end
end
coder.unroll;
for k = 1:numel(flagNames)
    f.(flagNames{k}) = p(k);
end

%--------------------------------------------------------------------------

function d = findFirstMissing(xset,xsubset)
% Find the first element of xset that is not a member of xsubset.
% Assumes both sets are sorted ascending and xsubset is a subset of xset.
% Returns d = 0 if the sets are equal.
nx = coder.internal.indexInt(numel(xset));
ny = coder.internal.indexInt(numel(xsubset));
if nx == ny
    % Includes the case where x is empty.
    d = coder.internal.indexInt(0);
else
    d = xset(ny + 1);
    for k = 1:ny
        if xset(k) ~= xsubset(k)
            d = xset(k);
            break
        end
    end
end

%--------------------------------------------------------------------------
