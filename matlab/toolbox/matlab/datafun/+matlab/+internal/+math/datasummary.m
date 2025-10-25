function S = datasummary(x,statfcns,statnames,isfcnhandle,dim)
%datasummary Return a struct containing the results of STATFCNS applied to
%   X.
%
%   FOR INTERNAL USE ONLY -- This feature is intentionally undocumented.
%   Its behavior may change, or it may be removed in a future release.

%   Copyright 2024 The MathWorks, Inc.

S = struct;
S.Size = size(x);
S.Type = class(x);
if isdatetime(x)
    S.TimeZone = x.TimeZone;
end

% For Numunique, nnz, and function handles, we must reshape the input so
% that we have a matrix and can work along columns. If dim is not 1, we
% need an additional permutation so that the operating dimension becomes 1
% in the reshaped data.
statIsNumuniqueOrNnz = matches(statnames,["NumUnique","NumNonzero"]);
applyStatAlongCols = isfcnhandle | statIsNumuniqueOrNnz;
if any(applyStatAlongCols)
    szout = size(x);
    dim = reshape(dim, 1, []);
    dim = min(dim, ndims(x)+1);
    if issparse(x) && any(dim > 2)
        % Permuting beyond second dimension not supported for sparse
        dim(dim > 2) = [];
    end
    if max(dim)>length(szout)
        szout(end+1:max(dim)) = 1;
    end
    tf = false(size(szout));
    tf(dim) = true;
    r = find(~tf);
    perm = [find(tf), r];
    xperm = permute(x, perm);
    xperm = reshape(xperm,[prod(szout(dim)), prod(szout(r))]);
    szout(dim) = 1;
end

% Apply each statistic
for jj = 1:numel(statnames)
    statname = statnames(jj);
    try
        if applyStatAlongCols(jj)
            if statIsNumuniqueOrNnz(jj)
                if isempty(xperm)
                    % NumNonzero and NumUnique for empty input returns 0
                    szout(~szout) = 1;
                    S.(statname) = zeros(szout);
                else
                    S.(statname) = reshape(applyToEachCol(xperm,statfcns{jj}),szout);
                end
            else % function handle
                outData = statfcns{jj}(xperm);
                if any(szout>1,"all") && isscalar(outData)
                    S.(statname) = reshape(applyToEachCol(xperm,statfcns{jj}),szout);
                else
                    S.(statname) = reshape(outData,szout);
                end
            end
        else
            S.(statname) = statfcns{jj}(x);
        end
    catch ME
        if isfcnhandle(jj)
            if (strcmp(ME.identifier,'MATLAB:getReshapeDims:notSameNumel'))
                error(message('MATLAB:summary:InvalidFunOutputSize'));
            elseif (strcmp(ME.identifier,'MATLAB:minrhs') || strcmp(ME.identifier,'MATLAB:TooManyInputs'))
                error(message('MATLAB:summary:InvalidFunNumInputs'));
            end
        end
        % For all other cases where the underlying function errors, we skip
        % the stat, rather than throw an error.
    end
end
end

%--------------------------------------------------------------------------
function N = applyToEachCol(x,fh)
xwidth = size(x,2);
N = zeros(1,xwidth);
for col = 1:xwidth
    N(col) = fh(x(:,col));
end
end