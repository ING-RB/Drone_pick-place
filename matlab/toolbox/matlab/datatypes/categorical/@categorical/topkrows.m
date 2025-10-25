function [b,i] = topkrows(a,k,varargin)
%

%   Copyright 2017-2024 The MathWorks, Inc. 

[varargin{:}] = convertStringsToChars(varargin{:});
for ii = 1:(nargin-2) % ComparisonMethod not supported.
    if matlab.internal.math.checkInputName(varargin{ii},{'ComparisonMethod'})
        error(message('MATLAB:topkrows:InvalidAbsRealType'));
    end
end

acodes = a.codes;
bcodes = acodes;

for ii = 1:(nargin-2) % Check if <undefined> codes need to be adjusted
    if (iscellstr(varargin{ii}) || matlab.internal.math.checkInputName(varargin{ii},{'ascend'}))
        % Use sortrows internal parser to find which columns are 
        % ascend/descend for NaN flags
        col = matlab.internal.math.sortrowsParseInputs(ismatrix(acodes),size(acodes,2),acodes,varargin{:});
        
        % Need extra check on col for repeated columns to place NaNs 
        % according to first occurence only 
        [~,ia] = unique(abs(col));
        col = col(ia);
        
        % Apply NaN mask to undefCode or 0
        undefmask = (acodes == categorical.undefCode);
        undefmask(:,abs(col(col < 0))) = 0;
        acodes(undefmask) = invalidCode(acodes); % Set invalidCode
    end
end

[~,i] = topkrows(acodes,k,varargin{:});

b = a; % preserve subclass
b.codes = bcodes(i,:);
