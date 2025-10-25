function [tf,loc] = ismember(a,b,varargin)
%

%   Copyright 2006-2024 The MathWorks, Inc.

import matlab.internal.datatypes.isCharString
import matlab.internal.datatypes.isCharStrings

narginchk(2,Inf);

if ~iscategorical(a) && ~iscategorical(b) 
    % catch the case where a varargin input is categorical and is dispatched here.
    error(message('MATLAB:categorical:setmembership:UnknownInput'));
end

if isa(a,'categorical')
    acodes = a.codes;
    if isa(b,'categorical')
        if a.isOrdinal ~= b.isOrdinal
            error(message('MATLAB:categorical:ismember:OrdinalMismatch'));
        elseif a.isOrdinal && ~isequal(a.categoryNames,b.categoryNames)
            error(message('MATLAB:categorical:OrdinalCategoriesMismatch'));
        end
        % Convert b to a's categories
        bcodes = convertCodes(b.codes,b.categoryNames,a.categoryNames);
        acodes = cast(acodes, 'like', bcodes); % bcodes is always a higher or equivalent integer class as acodes
        b_invalidCode = invalidCode(bcodes);
    else
        if isCharStrings(b)
            % If the second input is a char row or cellstr, it might represent category
            % names or data. The latter is grandfathered in, leave b alone.
        elseif isstring(b)
            % If the second input is a scalar string, it might represent category names
            % or data, leave it alone. If the second input is a string array, it represents
            % category names (though not necessarily a's categories), validate them. The
            % mirror image is not accepted.
            if ~isscalar(b)
                b = checkCategoryNames(b,0,'MATLAB:categorical:ismember:TypeMismatch');
            end
        else
            error(message('MATLAB:categorical:ismember:TypeMismatch'));
        end
        [~,bcodes] = ismember(strtrim(b),a.categoryNames);
        b_invalidCode = invalidCode(acodes); % bcodes is a subset of acodes
    end
else % ~isa(a,'categorical') && isa(b,'categorical')
    if isCharString(a)
        % leave as a character vector
    elseif isstring(a) && isscalar(a) 
        if ~ismissing(a)
            % Convert scalar string to char for category name.
            a = char(a);
        else
            % The missing strings map to the undefined category, but it
            % can't convert to char, so replace with ''.
            a = '';
        end
    elseif isCharStrings(a)
        % If the first input is a char row or cellstr, it represents data, and is
        % grandfathered in, leave it alone.
    elseif isstring(a)
        error(message('MATLAB:categorical:ismember:TypeMismatchString'));
    else
        error(message('MATLAB:categorical:ismember:TypeMismatch'));
    end
    [~,acodes] = ismember(strtrim(a),b.categoryNames);
    bcodes = b.codes;
    b_invalidCode = invalidCode(bcodes); % acodes is a subset of bcodes
end

bcodes(bcodes==categorical.undefCode) = b_invalidCode; % prevent <undefined> in a and b from matching
if nargout < 2
    tf = ismember(acodes,bcodes,varargin{:});
else
    [tf,loc] = ismember(acodes,bcodes,varargin{:});
end
