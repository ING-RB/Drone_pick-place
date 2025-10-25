function qavg = meanrot(q, varargin)
%MEANROT Quaternion average rotation
%   QAVG = MEANROT(Q) returns the average rotation represented by the
%   elements of Q along the first array dimension whose size does not
%   equal 1.
%
%   - If Q is a vector, then MEANROT(Q) returns the mean of the elements.
%   - If Q is a matrix, then MEANROT(Q) returns a row vector containing the
%   mean of each column.
%   - If Q is a multidimensional array, then MEANROT(Q) operates along the
%   first array dimension whose size does not equal 1, treating the
%   elements as vectors. This dimension becomes 1 while the sizes of all
%   other dimensions remain the same.
%
%   MEANROT(Q,DIM) takes the mean along dimension DIM of Q.
%
%   MEANROT(...,NANFLAG) specifies how NaN values are treated. The default
%   is 'includenan':
%
%     'includenan' - the MEANROT of a vector containing NaN values is NaN.
%     'omitnan'    - the MEANROT of a vector containing NaN values is the
%                    MEANROT of all non-NaN elements. If all elements are
%                    NaN, the result is NaN.
%
%
%   The algorithm used in MEANROT is described in :
%
%   F. Landis Markley, Yang Cheng, John Lucas Crassidis, and Yaakov Oshman.
%   "Averaging Quaternions", Journal of Guidance, Control, and Dynamics,
%   Vol. 30, No. 4 (2007), pp. 1193-1197.
%
%   Example:
%       e = [40 20 10; 50 10 5; 45 70 1];
%       q = quaternion(e, 'eulerd', 'ZYX', 'frame');
%       qavg = meanrot(q);
%       eulerd(qavg, 'ZYX', 'frame')
%
%   See also QUATERNION, NORMALIZE

%   Copyright 2018-2024 The MathWorks, Inc.

%#codegen


% Codegen: DIM and NANFLAG must be passed as coder.Constant() if used.
%   prefer_const is used throughout to propagate constants.
%   Arguments are parsed at compile time as they determine sizes.

    narginchk(1,3);
    coder.internal.prefer_const(q);
    coder.internal.prefer_const(varargin);
    sz = size(q.a);

    % Preallocate/define for coder
    inclnan = false;
    dim = 0;

    [inclnan(:), dim(:)] =  coder.const(@parseargs, sz, varargin{:});

    q = normalize(q);

    % Handle out of bounds dim, just as mean() does.
    nd = numel(sz);
    if dim > nd
        qavg = q;
        return;
    end

    % Flip around so dim is 1st dimension
    pv = zeros(1,nd);

    if dim == 1
        pv(:) =  1:nd;
        szperm = sz;
    elseif dim == nd
        pv(:) = [dim 1:(dim-1)];
        szperm = sz(pv);
    else
        pv(:) = [ dim, 1:(dim-1) (dim+1):nd];
        szperm = sz(pv);
    end

    N= prod(szperm(2:end)); %compute the number of answers to compute
    szfinal = [1 szperm(2:end)]; %the size of the final vector. The first (prod) dimension becomes 1


    % MATLAB does not allow easy indexing of the input or output
    % quaternion ( using (:,i) notation) from within the class method.
    % Index the parts instead.

    % Input parts
    a = permute(q.a, pv);
    b = permute(q.b, pv);
    c = permute(q.c, pv);
    d = permute(q.d, pv);

    oa = zeros(1,N, "like", a);
    ob = zeros(1,N, "like", b);
    oc = zeros(1,N, "like", c);
    od = zeros(1,N, "like", d);

    for ii=1:N %Number of final products to compute

        qc = [a(:,ii) b(:,ii) c(:,ii) d(:,ii)];

        nanidx = any(isnan(qc),2);
        anynan = any(nanidx);
        if inclnan
            if anynan
                ocompact = nan(1,4, "like", a);
            else
                ocompact = vectorMeanrot(qc);
            end
        else % omitnan
            if all(nanidx)
                ocompact = nan(1,4, "like", a);
            else
                qcNoNan = qc(~nanidx,:);
                ocompact = vectorMeanrot(qcNoNan);
            end
        end

        % Pack into output
        oa(ii) = ocompact(1);
        ob(ii) = ocompact(2);
        oc(ii) = ocompact(3);
        od(ii) = ocompact(4);

    end
    on = sqrt(oa.^2 + ob.^2 + oc.^2 + od.^2);
    oa = oa./on;
    ob = ob./on;
    oc = oc./on;
    od = od./on;

    oresha = reshape(oa, szfinal);
    oreshb = reshape(ob, szfinal);
    oreshc = reshape(oc, szfinal);
    oreshd = reshape(od, szfinal);

    qavga = ipermute(oresha, pv);
    qavgb = ipermute(oreshb, pv);
    qavgc = ipermute(oreshc, pv);
    qavgd = ipermute(oreshd, pv);

    qavg = buildOutput(q, qavga, qavgb, qavgc, qavgd);

end


function [inclnan, dim] = parseargs(sz, varargin)

    coder.internal.prefer_const(varargin);
    coder.internal.prefer_const(sz);
    inclnan = true;
    dim = 1;

    switch nargin
      case 1
        % dim = firstNonsingleton
        dim = firstNonsingleton(sz);
      case 2
        v = varargin{1};
        if (isstring(v) && isscalar(v)) || ischar(v)
            % v is NANFLAG
            found = true;
            inclnan = getInclNan(v, 2);
            dim = firstNonsingleton(sz);

        elseif isa(v, 'numeric')
            % Check scalar positive integer
            coder.internal.assert(isscalar(v) && ...
                                  (v > 0) && (v == floor(v)), ...
                                  'shared_rotations:quaternion:MeanRotDimInt');
            dim = v;
            found = true;

        else
            found = false;
        end

        coder.internal.assert(found, ...
                              'shared_rotations:quaternion:MeanRot2Arg');


      otherwise % 3. limited by narginchk
        v1 = varargin{1};
        % Check scalar positive integer
        coder.internal.assert(isscalar(v1) && ...
                              (v1 > 0) && (v1 == floor(v1)), ...
                              'shared_rotations:quaternion:MeanRotDimInt');
        dim = v1;

        v2 = varargin{2};
        coder.internal.assert(isstring(v2) && isscalar(v2) || ...
                              ischar(v2), 'shared_rotations:quaternion:MeanRotNanFlag', ...
                              'omitnan', 'includenan');
        inclnan = getInclNan(v2, 3);

    end
end

function qavg = vectorMeanrot(qc)
% Basic meanrot algorithm. Assumes no nans
    M = qc' * qc;
    [v,d] = eig(M);
    % The eigenvalues and eigenvectors are guaranteed to be real because
    % the matrix M is square and symmetric. Adding a call to real() here to
    % help MATLAB Coder inference
    dr = real(d);
    [~,ii] = max(diag(dr));
    qavg = real(v(:,ii).');

    % Force positive angle. MATLAB Coder sometimes gives the negative
    % eigenvector above. This also fixes that issue so codegen and sim
    % match.

    if (qavg(1) < 0)
        qavg = -qavg;
    end
end

function dimc = firstNonsingleton(sz)

% Find the first nonsingleton dimension
    coder.internal.prefer_const(sz);

    dim = 1;
    for ii=1:numel(sz)
        if sz(ii) ~= 1
            dim = ii;
            break;
        end
    end
    dimc = dim;
end

function tf = getInclNan(str, argidx)
    coder.internal.prefer_const(str);
    coder.internal.prefer_const(argidx);

    % Determine if we include
    opts = {'includenan', 'omitnan'};
    fmt = validatestring(str, opts, 'meanrot', 'NANFLAG', argidx);
    tf = strcmp(fmt, opts{1});
end
