function tc = norm(ta,opt)
%NORM tall vector and matrix norms.
%   Supported matrix X syntaxes:
%   C = NORM(X) 
%   C = NORM(X,2)
%   C = NORM(X,1)
%   C = NORM(X,Inf)
%   C = NORM(X,'fro')
%
%   Supported vector X syntaxes:
%   C = NORM(X)
%   C = NORM(X,P)
%   C = NORM(X,Inf)
%   C = NORM(X,-Inf)
%   C = NORM(X,'fro')
%
%   Supported N-D array X syntax:
%   C = NORM(X,'fro')
%
%   See also NORM.

%   Copyright 2016-2024 The MathWorks, Inc.

narginchk(1,2);
if nargin < 2
    opt = 2;
else
    tall.checkNotTall(upper(mfilename), 1, opt);
    if strncmpi(opt, 'inf', numel(opt))
        opt = inf;
    end
    if ~isNumericScalar(opt) && ~strncmpi(opt, 'fro', numel(opt))
        error(message('MATLAB:norm:unknownNorm'));
    end
end

if isNumericScalar(opt)
    % N-D arrays only support 'fro' which is also the only non-numeric
    % option at this point.
    ta = tall.validateMatrix(ta, 'MATLAB:norm:inputMustBe2D');
end
ta = tall.validateType(ta, mfilename, {'double','single'}, 1);

if strncmpi(opt, 'fro', numel(opt))
    tc = reducefun(@(x)norm(x,'fro'),ta);
elseif opt == 1
    tc = max(sum(abs(ta)),[],'includenan');
elseif opt == inf
    tc = tall(reduceInDefaultDim(@infNorm, ta));
elseif opt == 2
    % tc can be a scalar or the R factor from TSQR.
    tc = tall(reduceInDefaultDim(@twoNorm, ta));
    % Compute the two norm.
    tc = clientfun(@(x)norm(x,2),tc);
elseif opt == -inf
    % Error out if the input is not a vector.
    ta = tall.validateVector(ta, 'MATLAB:norm:unknownNorm');
    tc = reducefun(@(x)minusInfNorm(x(:)),ta);
    func = @(x,y)handleEmpty(x,y,opt);
    tc = clientfun(func,tc,size(ta));
else
    % Error out if the input is not a vector.
    ta = tall.validateVector(ta, 'MATLAB:norm:unknownNorm');
    tc = reducefun(@(x)norm(x(:),opt),ta);
    func = @(x,y)handleEmpty(x,y,opt);
    tc = clientfun(func,tc,size(ta));
end
% start with an unsized copy of ta's Adaptor
tmp = resetSizeInformation(ta.Adaptor);
% and then apply the known size.
tc.Adaptor = setKnownSize(tmp, [1 1]);
end

function tf = isNumericScalar(opt)
tf = isscalar(opt) && (isnumeric(opt) || islogical(opt)) && isreal(opt);
end
 
function x = handleEmpty(x, sz, opt)
if prod(sz) == 0 && opt == -inf
    % Handle empty vector input with -inf norm
    x = zeros(like=x);
elseif prod(sz) == 0 && isnan(opt)
    % Handle empty vector input with NaN norm
    x = nan(like=x);
end
end

function y = infNorm(x, dim)
if dim == 1
    % Compute maximum row sum
    if isrow(x)
        y = sum(abs(x));
    else
        y = norm(x,inf);
    end
else
    % tall row vector.
    y = norm(x,inf);
end
end

function y = twoNorm(x, dim)
if dim == 1
    if iscolumn(x)
        y = norm(x,2);
    else
        % Compute R factor using TSQR.
        y = qr(x);
        if any(isnan(y(:))) % nans in QR factors.
            if ~any(isnan(x(:))) % no nans in x
                if any(isinf(x(:))) % just infs in x
                    y(:) = inf;
                end
            end
        end
        if size(y,1) > size(y,2)
            y = y(1:size(y,2),:);
        end        
        y = triu(y); 
    end
else
   y = norm(x,2); 
end
end

function y = minusInfNorm(x)
% Handle empty chunks. 
% norm(x,-inf) = min(abs(x)) where x is a vector.
if isempty(x)
    % For an empty chunk, set the maximum value
    y = Inf*ones(1,like=x);
else
    y = norm(x,-inf);
end
end
