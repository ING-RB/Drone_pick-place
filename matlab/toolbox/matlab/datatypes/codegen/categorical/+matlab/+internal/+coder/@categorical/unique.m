function [b,i,j] = unique(a,varargin) %#codegen
%UNIQUE Unique values in a categorical array.

%   Copyright 2018-2020 The MathWorks, Inc.

narginchk(1,Inf);

% catch the case where a varargin input is categorical and is dispatched here.
coder.internal.assert(isa(a,'categorical'),'MATLAB:categorical:setmembership:UnknownInput');

acodes = a.codes;

% Rely on built-in's NaN handling if input contains any <undefined> elements
acodes = categorical.castCodesForBuiltins(acodes);

[hasStable, hasRows] = categorical.processSetMembershipFlags(varargin);

if hasStable
    [bcodes,i,j] = unique(acodes,varargin{:});
else
    % Need to sort the inputs.
    if hasRows
        % If rows flag is supplied, the inputs need to be sorted
        % row-wise.
        [sortedAcodes, sortedIA] = sortrows(acodes);
    else
        [sortedAcodes, sortedIA] = sort(acodes);
    end
    
    [bcodes,i,j] = unique(sortedAcodes,varargin{:});
    
    if nargout > 1
        % Map the indices back to their values in the original unsorted inputs,
        % before doing further processing.
        i = sortedIA(i); i = i(:);
        if nargout > 2
            % j contains the correct indices but their order is not correct.
            % Obtain the correct order by sorting the sortedIA indices and then
            % use that order to rearrange j.
            [~,ord] = sort(sortedIA);
            j = j(ord);
        end
    end
end

b = matlab.internal.coder.categorical(matlab.internal.coder.datatypes.uninitialized()); % preserve subclass
b.categoryNames = a.categoryNames;
b.isProtected = a.isProtected;
b.isOrdinal = a.isOrdinal;

if isfloat(bcodes)
    % Cast back to integer codes, including NaN -> <undefined>
    b.codes = categorical.castCodes(bcodes,a.numCategoriesUpperBound);
else
    b.codes = bcodes;
end



