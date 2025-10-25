function [tf,loc] = ismember(ain,bin,varargin) %#codegen
%ISMEMBER True for elements of a categorical array in a set.

%   Copyright 2020 The MathWorks, Inc.

narginchk(2,Inf);
coder.internal.assert(isa(ain,'categorical') || isa(bin,'categorical'),'MATLAB:categorical:setmembership:UnknownInput');

if isa(ain,'categorical')
    anames = ain.categoryNames;
    if coder.internal.isConst(size(anames))
        % Ensure anames is homogeneous
        coder.varsize('anames',[],[0 0]);
    end
    
    if isa(bin,'categorical')

        coder.internal.errorIf(ain.isOrdinal ~= bin.isOrdinal, ...
            'MATLAB:categorical:ismember:OrdinalMismatch');
        coder.internal.errorIf(ain.isOrdinal && ~isequal(ain.categoryNames,bin.categoryNames), ...
            'MATLAB:categorical:OrdinalCategoriesMismatch');
        
        bnames = bin.categoryNames;
        if coder.internal.isConst(size(bnames))
            % Ensure bnames is homogeneous
            coder.varsize('bnames',[],[0 0]);
        end
        
        % Convert b to a's categories
        bcodes = categorical.convertCodes(bin.codes,bnames,anames);
        acodes = cast(ain.codes, 'like', bcodes); % bcodes is always a higher or equivalent integer class as acodes
        b_invalidCode = categorical.invalidCode(bcodes);
    else
        acodes = ain.codes;
        if matlab.internal.coder.datatypes.isCharString(bin)
            % leave as a character vector
                b = strtrim(bin);
        elseif isstring(bin) && isscalar(bin)
            if ~ismissing(bin)
                % convert scalar string to char for category name
                b = strtrim(char(bin));
            else
                % missing strings map to the undefined category but can't
                % convert to char, so replace with ''.
                b = '';
            end
        else
            coder.internal.assert(matlab.internal.coder.datatypes.isCharStrings(bin), ...
                'MATLAB:categorical:ismember:TypeMismatch');
            b = matlab.internal.coder.datatypes.cellstr_strtrim(bin);
        end
        
        [~,bcodes] = matlab.internal.coder.datatypes.cellstr_ismember(b,anames);
        b_invalidCode = categorical.invalidCode(acodes); % bcodes is a subset of acodes
    end
else % ~isa(a,'categorical') && isa(b,'categorical')
    if  matlab.internal.coder.datatypes.isCharString(ain)
        % leave as a character vector
        a = strtrim(ain);
    elseif isstring(ain) && isscalar(ain) 
        if ~ismissing(ain)
            % Convert scalar string to char for category name.
            a = strtrim(char(ain));
        else
            % The missing strings map to the undefined category, but it
            % can't convert to char, so replace with ''.
            a = '';
        end
    else
        coder.internal.assert(matlab.internal.coder.datatypes.isCharStrings(ain), ...
                'MATLAB:categorical:ismember:TypeMismatch');
        a = matlab.internal.coder.datatypes.cellstr_strtrim(ain);
    end
    bnames = bin.categoryNames;
    if coder.internal.isConst(size(bnames))
        % Ensure bnames is homogeneous
        coder.varsize('bnames',[],[0 0]);
    end
    [~,acodes] = matlab.internal.coder.datatypes.cellstr_ismember(a,bnames);
    bcodes = bin.codes;
    b_invalidCode = categorical.invalidCode(bcodes); % acodes is a subset of bcodes
end

bcodes(bcodes==categorical.undefCode) = b_invalidCode; % prevent <undefined> in a and b from matching
if nargout < 2
    tf = ismember(acodes,bcodes,varargin{:});
else
    [tf,loc] = ismember(acodes,bcodes,varargin{:});
end
