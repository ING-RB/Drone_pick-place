function [codes,ia,ib] = setmembershipHelper(setfun,acodes,bcodes,varargin) %#codegen
%SETMEMBERSHIPHELPER Utility for categorical set function methods.

%   Copyright 2020 The MathWorks, Inc.

% In codegen, if the stable flag is not supplied, then the core set functions
% require the inputs to be sorted(or row-sorted if 'rows' is supplied). So parse
% the flags to determine if/what kind of sorting is required. If required, sort
% the inputs before calling the core functions and remap the output indices to
% the original unsorted order.

[hasStable, hasRows] = categorical.processSetMembershipFlags(varargin);
if hasStable
    if nargout == 3
        [codes,ia,ib] = setfun(acodes,bcodes,varargin{:});
    elseif nargout == 2
        [codes,ia] = setfun(acodes,bcodes,varargin{:});
    else
        codes = setfun(acodes,bcodes,varargin{:});
    end
else
    % Need to sort the inputs.
    if hasRows
        % If rows flag is supplied, the inputs need to be sorted
        % row-wise.
        [sortedAcodes, sortedIA] = sortrows(acodes);
        [sortedBcodes, sortedIB] = sortrows(bcodes);  
    else
        [sortedAcodes, sortedIA] = sort(acodes);
        [sortedBcodes, sortedIB] = sort(bcodes);
    end

    % Avoid extra work of remapping the indices if indices are not
    % requested in the output.
    if nargout == 3
        [codes, ia, ib] = setfun(sortedAcodes,sortedBcodes,varargin{:});
        ia = sortedIA(ia); ia = ia(:);
        ib = sortedIB(ib); ib = ib(:);
    elseif nargout == 2
        [codes, ia] = setfun(sortedAcodes,sortedBcodes,varargin{:});
        ia = sortedIA(ia); ia = ia(:);
    else
        codes = setfun(sortedAcodes,sortedBcodes,varargin{:});
    end
end