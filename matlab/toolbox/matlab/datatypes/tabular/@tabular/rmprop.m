function this = rmprop(this,pnames)
%

%   Copyright 2018-2024 The MathWorks, Inc.

if nargout == 0
    error(message('MATLAB:table:addrmprop:NoLHS',upper(mfilename),',PNAMES'));
end

if isa(pnames,"pattern") && isscalar(pnames)
    fnamesPerVar = fieldnames(this.varDim.customProps);
    fnamesPerTab = fieldnames(this.arrayProps.TableCustomProperties);
    
    perVar = matches(fnamesPerVar,pnames);
    perTab = matches(fnamesPerTab,pnames);

    pnamesPerVar = fnamesPerVar(perVar);
    pnamesPerTab = fnamesPerTab(perTab);
else
    [istxt, pnames] = matlab.internal.datatypes.isText(pnames);

    if ~istxt
        error(message('MATLAB:table:addrmprop:PropNamesMustBeTextOrPattern'))
    end

    perVar = ismember(pnames,fieldnames(this.varDim.customProps));
    perTab = ismember(pnames,fieldnames(this.arrayProps.TableCustomProperties));

    pnamesPerVar = pnames(perVar);
    pnamesPerTab = pnames(perTab);
end

if nnz(perVar) > 0
    this.varDim = this.varDim.rmprop(pnamesPerVar);
end

if nnz(perTab) > 0
    this = this.rmPerTableProperty(pnamesPerTab);
end

% If pnames doesn't match anything, silently ignore it.
end
