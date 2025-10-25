function processedArgs = processSetMembershipFlags(varargin) %#codegen
%PROCESSSETMEMBERSHIPFLAGS Utility for table set function methods.

%   Copyright 2019 The MathWorks, Inc.

idx = zeros(1,nargin);
sz = 0;

for i = 1:nargin
    coder.internal.assert(coder.internal.isCharOrScalarString(varargin{i}),...
                          'MATLAB:table:setmembership:UnknownInput2');
                      
    coder.internal.assert(coder.internal.isConst(varargin{i}),...
                          'MATLAB:table:NonconstantParameterName');
                      
    % Do not accept 'R2012a' or 'legacy'.
    coder.internal.errorIf(strcmpi('legacy',varargin{i}) || strcmpi('R2012a',varargin{i}),...
                           'MATLAB:table:setmembership:BehaviorFlags');
    
    % 'rows' is always implied. Accept it, but do not include it in processed args
    if ~startsWith('rows',varargin{i},'IgnoreCase',true)
        sz = sz + 1;
        idx(sz) = i;
    end
end

processedArgs = cell(1,sz);

for i = 1:sz
    processedArgs{i} = convertStringsToChars(varargin{idx(i)});
end