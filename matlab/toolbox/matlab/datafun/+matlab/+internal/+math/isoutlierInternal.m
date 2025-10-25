function [tf,lthresh,uthresh,center] = isoutlierInternal(a,method, wl, dim, p, sp, vars, maxoutliers, lowup, fmt)
% isoutlierInternal Helper function for isoutlier and rmoutliers
%
%   FOR INTERNAL USE ONLY -- This feature is intentionally undocumented.
%   Its behavior may change, or it may be removed in a future release.

%   Copyright 2016-2024 The MathWorks, Inc.


dim = min(dim, ndims(a)+1);

xistable = istabular(a);

if xistable
    if isequal(fmt,'tabular')
        a = a(:,vars);
        vars = 1:width(a);
        tf = a;
        % keep all properties of the input except for these:
        tf.Properties.VariableUnits = {};
        tf.Properties.VariableContinuity = {};
    else
        tf = false(size(a));
    end
    if nargout > 1
        if ismember(method, {'movmedian', 'movmean'})
            % with moving methods, the thresholds and center have the same
            % size as input
            lthresh = a(:,vars);
        elseif height(a) == 0
            lthresh = a(:,vars);
            lthresh = matlab.internal.datatypes.lengthenVar(lthresh,1);
        else
            % with other methods, thresholds and center has reduced
            % dimension along first dimension
            lthresh = a(1,vars);
        end
        uthresh = lthresh;
        center = lthresh;
    end
    for i = 1:length(vars)
        vari = a.(vars(i));
        if ~(isempty(vari) || iscolumn(vari))
            error(message('MATLAB:isoutlier:NonColumnTableVar'));
        end
        if ~isfloat(vari)
            error(message('MATLAB:isoutlier:NonfloatTableVar',...
                a.Properties.VariableNames{vars(i)}, class(vari)));
        end
        if ~isreal(vari)
            error(message('MATLAB:isoutlier:ComplexTableVar'));
        end
        [out, lt, ut, c] = matlab.internal.math.locateoutliers(vari, method, wl, p, ...
            sp, maxoutliers, ' ', lowup);
        if isequal(fmt,'tabular')
            tf.(i) = any(out,2);
        else
            tf(:,vars(i)) = any(out,2);
        end
        if nargout > 1
            lthresh.(i) = lt;
            uthresh.(i) = ut;
            center.(i) = c;
        end
    end
else
    asparse = issparse(a);
    % Avoid overhead for unnecessary permute calls
    if (dim > 1) && ~isscalar(a)
        dims = 1:max(ndims(a),dim);
        dims(1) = dim;
        dims(dim) = 1;
        if asparse && dim > 2
            % permuting beyond second dimension not supported for sparse
            a = full(a);
        end
        a = permute(a, dims);
    end
    [tf, lthresh, uthresh, center] = matlab.internal.math.locateoutliers(a, method, ...
        wl, p, sp, maxoutliers, ' ', lowup);

    if (dim > 1) && ~isscalar(a)
        tf = ipermute(tf, dims);
        if asparse
            % explicitly convert to sparse. If dim > 2, we have converted
            % to full previously
            tf = sparse(tf);
        end
        if nargout > 1
            lthresh = ipermute(lthresh, dims);
            uthresh = ipermute(uthresh, dims);
            center = ipermute(center, dims);
            if asparse
                lthresh = sparse(lthresh);
                uthresh = sparse(uthresh);
                center = sparse(center);
            end
        end
    end
end
end