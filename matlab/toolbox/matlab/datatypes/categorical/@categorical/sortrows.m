function [b,varargout] = sortrows(a,varargin)
%

%   Copyright 2006-2024 The MathWorks, Inc. 

import matlab.internal.categoricalUtils.categoricalsortrows;

acodes = a.codes;
nCategories = numel(a.categoryNames);

for ii = 1:(nargin-2) % ComparisonMethod not supported.
    if matlab.internal.math.checkInputName(varargin{ii},{'ComparisonMethod'})
        error(message('MATLAB:sortrows:InvalidAbsRealType',class(a)));
    end
end

try
    % SORTROWS(A), SORTROWS(A,COL):
    noNVPairs = (nargin <= 1) || (nargin <= 2 && isnumeric(varargin{1}));
    % CATEGORICALSORTROWS uses counting sort, which is fast only for uint8
    % and uint16 but slower than builtin SORTROWS for larger types
    if noNVPairs
        if isa(acodes, 'uint8') || isa(acodes, 'uint16')
            if nargin == 1
                [bcodes,varargout{1:nargout-1}] = categoricalsortrows(acodes,nCategories);
            else
                [bcodes,varargout{1:nargout-1}] = categoricalsortrows(acodes,nCategories,varargin{:});
            end
        else % acodes is 'uint32' or 'uint64'
            % Make sure <undefined> sorts to the end when calling builtin SORTROWS
            acodes(acodes == categorical.undefCode) = invalidCode(acodes);
            if nargin == 1
                [bcodes,varargout{1:nargout-1}] = sortrows(acodes);
            else
                [bcodes,varargout{1:nargout-1}] = sortrows(acodes,varargin{:});
            end
            bcodes(bcodes == invalidCode(bcodes)) = a.undefCode; % set invalidCode back to <undefined> code
        end
    else
        [col, nanflag] = matlab.internal.math.sortrowsParseInputs(ismatrix(acodes),size(acodes,2),acodes,varargin{:});
        if nanflag == 0 % 'auto'
            % Same as above: Make sure <undefined> sorts to the end when calling builtin SORT
            acodes(acodes == categorical.undefCode) = invalidCode(acodes);
            [bcodes,varargout{1:nargout-1}] = sortrows(acodes,varargin{:});
            bcodes(bcodes == invalidCode(bcodes)) = a.undefCode;
        else
            % 'first' treats <undefined> as 0 for 'ascend' and intmax for 'descend'
            % 'last' treats <undefined> as intmax for 'ascend' and 0 for 'descend'
            [~,colind] = unique(abs(col),'stable'); % legacy repetead COL behavior
            col = col(colind);
            undefmask = acodes == categorical.undefCode;
            if nanflag == 1 % 'first'
                undefmask(:,abs(col(col > 0))) = 0;
            else % 'last'
                undefmask(:,abs(col(col < 0))) = 0;
            end
            bcodes = acodes;
            acodes(undefmask) = invalidCode(acodes);
            [~,ndx] = sortrows(acodes,varargin{:});
            bcodes = bcodes(ndx,:);
            if nargout > 1
                varargout{1} = ndx;
            end
        end
    end
catch ME
    throw(ME);
end

b = a; % preserve subclass
b.codes = bcodes;
