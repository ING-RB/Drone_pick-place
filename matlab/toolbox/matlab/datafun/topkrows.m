function [B,I] = topkrows(A,k,varargin)
% Syntax:
%   B = topkrows(A,k)
%   B = topkrows(A,k,col)
%   B = topkrows(___,direction)
%   B = topkrows(___,ComparisonMethod=method)
%   [B,I] = topkrows(___)
%
% For more information, see documentation

%   Copyright 2017-2024 The MathWorks, Inc.

% Check number of inputs
narginchk(2,Inf);

% Special cases for cellstr, string, and large k, otherwise call builtin
AIsStringOrCellStr = isstring(A) || iscellstr(A);
doFullSort = isnumeric(k) && isscalar(k) && k > 2048 && k >= 0.2*size(A,1) && ~ischar(A) && ~issparse(A); % for performance
if doFullSort && ~isreal(A)
    % Stricter limitations on complex input for performance
    doFullSort = size(A,2) < 16 || (size(A,2) < 32 && size(A,1) > 8e4);
end
if AIsStringOrCellStr || doFullSort
    % sortrows will do most of the error checking, so we only need to do
    % checks specific to topkrows.

    % check type of k
    if ~(isnumeric(k) && isscalar(k) && isreal(k) && isfinite(k) && (k >= 0) && (k == fix(k)))
        error(message('MATLAB:topkrows:InvalidK'));
    end
    
    % adjust k if needed
    if k > size(A,1)
        k = size(A,1);
    end

    % Check if direction and col are specified
    hascol = false;
    hasdir = false;

    if nargin > 2
        % If first varargin is numeric, assume it is the col argument
        hascol = isnumeric(varargin{1});
    end

    % sortrows allows negative col, but the full sort optimization does not
    if hascol && ~AIsStringOrCellStr && any(varargin{1} < 1,"all")
        error(message('MATLAB:topkrows:ColNotIndexVec'));
    end

    indStart = 1 + hascol;
    numVarargin = numel(varargin);
    if indStart <= numVarargin
        % Check for strings ascend, descend, or cell containing them
        arg = varargin{indStart};
        if any(matlab.internal.math.checkInputName(arg,["ascend" "descend"])) ...
                || iscell(arg) ...
                || (isstring(arg) && all(startsWith(arg, {'a','d'}, 'IgnoreCase', true)))
            hasdir = true;
        end
        
        indStart = indStart + hasdir;
        if AIsStringOrCellStr
            % Name-value arguments are not supported
            if indStart + 1 <= numVarargin
                error(message('MATLAB:topkrows:NoNameValue'));
            end
        else
            % Only ComparisonMethod is supported
            for ii = indStart:2:numVarargin
                if ~matlab.internal.math.checkInputName(varargin{ii},"ComparisonMethod")
                    error(message('MATLAB:topkrows:NameValueNames'));
                end
            end
        end
    end
    
    if isstring(A) || (doFullSort && ~AIsStringOrCellStr)
        if hasdir
            % sortrows A
            if (nargout > 1)
                [AS,IS] = sortrows(A,varargin{:},'MissingPlacement','last');
            else
                AS = sortrows(A,varargin{:},'MissingPlacement','last');
            end
        else
            if hascol
                % sortrows A
                if (nargout > 1)
                    [AS,IS] = sortrows(A,varargin{1},'descend',varargin{2:end},'MissingPlacement','last');
                else
                    AS = sortrows(A,varargin{1},'descend',varargin{2:end},'MissingPlacement','last');
                end
            else
                % sortrows A
                if (nargout > 1)
                    [AS,IS] = sortrows(A,'descend',varargin{:},'MissingPlacement','last');
                else
                    AS = sortrows(A,'descend',varargin{:},'MissingPlacement','last');
                end
            end
        end
        
        % extract first k rows from all list
        B = AS(1:k,:);
        if (nargout > 1)
            I = IS(1:k,:);
        end
    else
        % Treating '' as empty character as opposed to missing.
        % this is same behavior as sortrows
        if hasdir
            % sortrows A
            [~,IS] = sortrows(string(A),varargin{:},'MissingPlacement','last');
        else
            if hascol
                % sortrows A
                [~,IS] = sortrows(string(A),varargin{1},'descend',varargin{2:end},'MissingPlacement','last');
            else
                % sortrows A
                [~,IS] = sortrows(string(A),'descend',varargin{:},'MissingPlacement','last');
            end
        end
        
        % extract first k rows from all list
        I = IS(1:k,:);
        B = A(I,:);
    end
else
    try
        % Call builtin for remaining types
        if nargout > 1
            [B,I] = matlab.internal.math.topkrows(A,k,varargin{:});
        else
            B = matlab.internal.math.topkrows(A,k,varargin{:});
        end
    catch ME
        throw(ME);
    end
end
if isempty(A) && (size(A,1) == size(A,2))
    B = reshape(B,[0 0]);
    if nargout > 1
        I = reshape(I,[0 1]);
    end
end
