function Name = validateName(Name,calledFrom)
%

% Copyright 2021 The MathWorks, Inc.
%#codegen
coder.internal.assert(matlab.internal.coder.isValidNameType(Name), ['MATLAB:graphfun:' calledFrom ':InvalidNameType']);
coder.internal.assert(noDuplicates(Name), ['MATLAB:graphfun:' calledFrom ':NonUniqueNames']);
Name = reshape(Name,[numel(Name),1]);
end

function tf = noDuplicates(in)
coder.inline('always')
ONE = coder.internal.indexInt(1);
tf = true;
for ii = ONE:(numel(in) - 1)
    for jj = (ii + ONE):numel(in)
        tf = tf && ~strcmp(in{ii},in{jj});
    end
end
end