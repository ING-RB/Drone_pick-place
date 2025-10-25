function p = matchStringParameter(str,param)
%MATLAB Code Generation Private Function
%
%   Compare string STR with string parameter PARAM using case insensitive
%   partial matching.

%   The function returns logical 1 (true) if the characters in STR are the
%   same as in PARAM and returns logical 0 (false) otherwise.

%   Copyright 2020-2021 The MathWorks, Inc.
%#codegen

if isempty(coder.target)
    numCharsToMatch = max(1,strlength(str));
else
    coder.inline('always');
    coder.internal.prefer_const(str,param);
    ONE = coder.internal.indexInt(1);
    len = coder.internal.indexInt(strlength(str));
    % eml_max infers much more quickly than the full max function.
    numCharsToMatch = eml_max(ONE,len);
end

p = strncmpi(str,param,numCharsToMatch);
