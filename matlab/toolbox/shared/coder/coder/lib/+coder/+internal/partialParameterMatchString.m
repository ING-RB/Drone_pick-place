function s = partialParameterMatchString(fname,ostruct,casesens)
%MATLAB Code Generation Private Function
%
%   MATLAB (not to be compiled) function used extrinsically in error
%   reporting for coder.internal.parseParameterInputs.  Returns a string
%   containing the list of possible matches to an ambiguous parameter name.
 
%   Copyright 2009-2019 The MathWorks, Inc.

if isstruct(ostruct)
    namelist = fieldnames(ostruct);
else
    namelist = ostruct;
end
nparms = length(namelist);
s = '';
for k = 1:nparms
    if parameter_names_match(namelist{k},fname,casesens)
        if isequal(s,'')
            s = namelist{k};
        else
            s = [s,', ',namelist{k}]; %#ok<AGROW>
        end
    end
end

%--------------------------------------------------------------------------

function p = parameter_names_match(mstrparm,userparm,casesens)
% Compare parameter names using partial matching, optionally with case
% sensitivity.
if isempty(userparm)
    p = false;
elseif casesens
    p = strncmp(mstrparm,userparm,length(userparm));
else
    p = strncmpi(mstrparm,userparm,length(userparm));
end

%--------------------------------------------------------------------------
