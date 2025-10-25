function quotedArgs = quoteUnixCmdArg(varargin)
% Algorithm: Start and end each argument with a single quote (squote).
%            Within each argument:
%            1. squote -> squote '\' squote squote
%            2. '!'    -> squote '\' '!' squote
%            3. '*'    -> squote '*' squote	(MATLAB globbing character)
%

% Copyright 2020-2022 The MathWorks, Inc.

if isempty(varargin)
    quotedArgs = '';
    return;
end

% Do any tilde expansion first
ix = find(strncmp(varargin,'~',1));
if ~isempty(ix)
    varargin(ix) = builtin('_unix_tilde_expansion', varargin(ix));
end

% Special cases to maintain as literal: single quote or ! with '\thing_I_found'
quotedArgs= regexprep(varargin,'[''!]','''\\$&''');

% Special cases to maintain as NOT literal: Replace * with 'thing_I_found'
quotedArgs= regexprep(quotedArgs,'[*]','''$&''');

quotedArgs = strcat(' ''', quotedArgs, '''');
quotedArgs = [quotedArgs{:}];