function t = addprop(t, pnames, ptypes)
%

%   Copyright 2018-2024 The MathWorks, Inc.


import matlab.internal.datatypes.isText
if nargout == 0
    error(message('MATLAB:table:addrmprop:NoLHS',upper(mfilename),',PNAMES,PTYPES'));
end

[tfp, pnames] = isText(pnames);
[tfd, ptypes] = isText(ptypes);

% Validate that inputs are text.
if ~tfp
    error(message('MATLAB:table:addrmprop:PropNamesMustBeText'))
end
if ~tfd
    error(message('MATLAB:table:addrmprop:MultiplicityMustBeText'))
end

% Validate that there are the same number of property names and types.
nprops = numel(pnames);
if nprops ~= numel(ptypes)
    error(message('MATLAB:table:addrmprop:NumDimsMismatch'))
end

% Validate that dims are 'Variable' or 'Table'.
dimid = getChoices(ptypes,["Table", "Variable"],'MATLAB:table:InvalidCustomPropDim');

% Make sure that new custom property names don't conflict with existing ones or
% with each other.
[uPnames, iPnames] = unique(pnames);
if numel(pnames) ~= numel(uPnames) 
        pnames(iPnames) = []; % remaining elements are duplicates
        error(message('MATLAB:table:addrmprop:DuplicateCustomProps',pnames{1}))
elseif any(isfield(t.arrayProps.TableCustomProperties, pnames))
        dup = find(matches(pnames,fieldnames(t.arrayProps.TableCustomProperties)),1);
        error(message('MATLAB:table:addrmprop:DuplicatesExistingCustomProps',pnames{dup},'table'))    
elseif any(isfield(t.varDim.customProps, pnames))
        dup = find(matches(pnames,fieldnames(t.varDim.customProps)),1);
        error(message('MATLAB:table:addrmprop:DuplicatesExistingCustomProps',pnames{dup},'variable'))
end

try
    for ii = 1:numel(pnames)
        if dimid(ii) == 1 % per-table
            t.arrayProps.TableCustomProperties.(pnames{ii}) = [];
        else % per-variable
            t.varDim = t.varDim.addprop(pnames{ii});
        end
    end
catch ME
    matlab.internal.datatypes.throwInstead(ME,...
        "MATLAB:AddField:InvalidFieldName", ...
        message("MATLAB:table:addrmprop:InvalidPropName", pnames{ii}));
end
end




function choiceNumsOut = getChoices(inputs,choices,errorID)

import matlab.internal.datatypes.getChoice

choiceNumsOut = zeros(size(inputs));
for ii = 1:numel(inputs)
    choiceNumsOut(ii) = getChoice(inputs{ii},choices,errorID);
end
end
