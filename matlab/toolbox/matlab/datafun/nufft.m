function y = nufft(x, t, f, dim)
% NUFFT  Nonuniform Discrete Fourier Transform.
%
%   y = nufft(x,t) approximates the nonuniform discrete Fourier transform
%   (NUDFT) of an input x using sample points t.  For length N input vector
%   x, the NUDFT is a length N vector X with elements
%
%               N
%      X(k) =  sum  x(n)*exp(-j*2*pi*(k-1)*t(n)/N), 1 <= k <= N.
%              n=1
%
%   If t is specified as [], the sample points in the transform are
%   0:(N-1).
%
%   y = nufft(x,t,f) computes the NUDFT of an input x using sample points t
%   and query points f.  For length N input vector x, and length M vector
%   f, the NUDFT is a length M vector X with elements
%
%               N
%      X(k) =  sum  x(n)*exp(-j*2*pi*f(k)*t(n)), 1 <= k <= M.
%              n=1
%
%   If f is specified as [], the query points in the transform are
%   (0:(N-1))/N.
%
%   y = nufft(x,t,f,dim) computes the NUDFT across dimension dim of the
%   input.
%
%   See also fft ifft nufftn
%   Copyright 2019-2024 The MathWorks, Inc.

    % Parse the input array.
    if isinteger(x)
        if isa(x, 'uint64') || isa(x, 'int64')
            error(message('MATLAB:fftfcn:InvalidInputType'));
        end
        x = double(x);
    elseif islogical(x)
        x = double(x);
    elseif ~isfloat(x)
        error(message('MATLAB:fftfcn:InvalidInputType'));
    elseif issparse(x)
        error(message('MATLAB:nufft:nufftNoSparseArrays'));
    end
    % Find first non-singleton dimension.
    if nargin < 4
        dim = find(size(x)~=1,1,'first');
        if isempty(dim) % scalar case
            dim = 1;
        end
    else
        % Otherwise parse the dim argument.
        dim = matlab.internal.math.getdimarg(dim);
        dim = min(dim, ndims(x)+1);
    end
    N = size(x, dim);
    % Parse the sample points.
    if nargin < 2
        t = [];
    end
    [t, flipX] = parseGridVectorInput(class(x), t, N, 1, true);
    if flipX
        x = flip(x, dim);
    end
    % Parse the query points.
    if nargin < 3
        f = [];
    end
    [f, flipY] = parseGridVectorInput(class(x), f, N, 1/N, false);
    if isempty(x) || f.count == 0
        % Empty cases require no work.
        sz = size(x);
        sz(dim) = f.count;
        y = zeros(sz, class(x));
    else
        if isnumeric(t.values)
            t.values = cast(t.values, class(x));
        end
        if isnumeric(f.values)
            f.values = cast(f.values, class(x));
        end
        y = applyNUFFT(x, t, f, dim);
    end
    if flipY
        y = flip(y, dim);
    end
end
%--------------------------------------------------------------------------
function [y, flipX] = parseGridVectorInput(xcls, pts, nSamplePoints, ...
    defaultSpacing, isSamplePoints)
% Validate a grid input.
    emptyBrackets = isequal(pts, []);
    if ~isfloat(pts)
        error(message('MATLAB:nufft:invalidNodeDataType'));
    end
    if (~isvector(pts) && ~emptyBrackets) || ...
       ~allfinite(pts) || ~isreal(pts) || issparse(pts) 
        error(message('MATLAB:nufft:nodesNotFullReal'));
    end
    pts = cast(pts, xcls);
    if emptyBrackets
       nPts = nSamplePoints;
    else
        if isSamplePoints && (nSamplePoints ~= numel(pts))
            error(message('MATLAB:nufft:nufftSamplePointsMismatch'));
        end
        nPts = length(pts);
    end
    % Pack the grid vector into a structure.
    tf = matlab.internal.math.checkUniformNufftGrid(pts);
    flipX = false;
    if ~tf && matlab.internal.math.checkUniformNufftGrid(flip(pts))
        pts = flip(pts);
        flipX = true;
        tf = true;
    end
    y = struct('values', pts(:), 'count', nPts, 'uniform', tf);
    if y.uniform
        y.values = struct('offset', cast(0, xcls), ...
            'spacing', cast(defaultSpacing, xcls));
        if ~isempty(pts)
            y.values.offset = pts(1);
        end
        if numel(pts) > 1
            denom = y.count-1;
            y.values.spacing = cast((pts(end) - pts(1)) / denom, xcls);
        end
    end
end
%--------------------------------------------------------------------------
function y = applyNUFFT(x, t, f, dim)
% Selects the NUFFT branch and applies the corresponding algorithm.
    nufftType = 1 + 1-f.uniform + 2*(1-t.uniform);
    if nufftType ~= 1
        if ( (f.uniform && f.count <= 16) || (t.uniform && t.count <= 16) )
            nufftType = 4;
        end
    end
    switch nufftType
        case 1
            y = simpleTransform(x, t, f, dim);
        case 2
            y = uniformToNonUniform(x, t, f, dim);
        case 3
            y = nonUniformToUniform(x, t, f, dim);
        case 4
            y = nonUniformToNonuniform(x, t, f, dim);
    end
end
%--------------------------------------------------------------------------
function y = selectInDim(x, ind, dim)
% Selects a subset of an array in a given dimension.
    nd = ndims(x);
    cargs = repmat({':'}, 1, nd);
    cargs{dim} = ind;
    y = x(cargs{:});
end
%--------------------------------------------------------------------------
function y = simpleTransform(x, t, f, dim)
% Applies the NUFFT when both branches are uniform.
    M = f.count;
    N = t.count;
    % The input data must be modulated if the frequencies are shifted away
    % from zero.
    if f.values.offset ~= 0
        % Compute the phase factors for the shift.
        W = matlab.internal.math.unitPhaseFactor(f.values.offset, ...
            t.values.spacing);
        W = W.^((0:(N-1))');
        if dim > 1
            W = reshape(W, [ones(1, dim-1), N]);
        end
        x = x .* W;
    end
    % We can perform a standard FFT if this quantity is within eps of 1/M.
    scaleFactor = f.values.spacing * t.values.spacing;
    if M == 1
        % Single query point, which we are currently evaluating at f = 0.
        y = sum(x, dim);
    elseif N == 1
        % Single sample point, which we treat as t = 0.
        y = repmat(x, [ones(1, dim-1), M, ones(1, ndims(x)-dim)]);
    elseif (abs(scaleFactor - 1/M) <= eps(scaleFactor)) && (M >= N)
        % Simple FFT or Chirp-Z Transform, depending on the spacing of f.
        y = fft(x, M, dim);
    else
        % Choose an efficient transform size.
        P = matlab.internal.math.pickTransformLength(M+N-1);
        q = ((-N+1):max(N-1,M-1)).';
        % Reduce the scaling factor to be between 0 and 1 to avoid overflow
        % conditions.
        omega = matlab.internal.math.unitPhaseFactor(f.values.spacing,...
            t.values.spacing).^((q.^2)/2);
        if dim > 1
            omega = reshape(omega, [ones(1, dim-1), numel(omega)]);
        end
        % Convolution via FFT.
        % Pre-multiply the data.
        x = fft(x .* selectInDim(omega, N:(2*N-1), dim), P, dim);
        y = ifft(x .* ...
            fft(conj(selectInDim(omega, 1:(M+N-1), dim)), P, dim), P, dim);
        y = selectInDim(y, N:(M+N-1), dim) .* ...
            selectInDim(omega, N:(M+N-1), dim);
    end
    % The output may also need to be modulated if the input data is
    % shifted.
    if t.values.offset ~= 0
        Wc = matlab.internal.math.unitPhaseFactor(f.values.offset,...
            t.values.offset);
        Wf = matlab.internal.math.unitPhaseFactor(f.values.spacing,...
            t.values.offset);
        W = Wc .* (Wf.^((0:(M-1))'));
        if dim > 1
            W = reshape(W, [ones(1, dim-1), M]);
        end
        y = y .* W;
    end
end
%--------------------------------------------------------------------------
function y = uniformToNonUniform(x, t, f, dim)
% Transform uniformly-spaced data to non-uniformly spaced data.

    % Perform a Type-2 NUFFT.
    t2.values = linspace(t.values.offset,t.values.offset + t.values.spacing*(t.count-1),t.count);
    % Sample points are uniformly gridded.
    forig = f.values;
    [f, ~, phaseOffsets] = shiftAndScaleNodes(f, t2);
    p = [dim 1:dim-1 dim+1:ndims(x)];
    x = permute(x, p);
    y = matlab.internal.math.nufftinterp(x,[],f.values);
    phaseFactor = matlab.internal.math.unitPhaseFactor(forig, phaseOffsets);
    y = phaseFactor .* y;
    y = ipermute(y, p);
end
%--------------------------------------------------------------------------
function y = nonUniformToUniform(x, t, f, dim)
% Transform non-uniformly-spaced data to uniformly-spaced data.

    % Perform a Type-3 NUFFT.
    f2.values = linspace(f.values.offset,f.values.offset + f.values.spacing*(f.count-1),f.count);
    p = [dim 1:dim-1 dim+1:ndims(x)];
    x = permute(x, p);
    % Gridded nodes, but uniform.
    torig = t.values;
    [t, N, phaseOffsets] = shiftAndScaleNodes(t, f2);
    % Apply the pre-scaling.
    phasefactor = matlab.internal.math.unitPhaseFactor(torig, phaseOffsets);
    x = phasefactor.*x;
    y = matlab.internal.math.nufftinterp(x,t.values,N);
    y = ipermute(y, p);
end
%--------------------------------------------------------------------------
function y = nonUniformToNonuniform(x, t, f, dim)
% Transform uniformly-spaced data to non-uniformly spaced data.
    if isstruct(f.values)
        f.values = linspace(f.values.offset,f.values.offset + f.values.spacing*(f.count-1),f.count);
    end
    if isstruct(t.values)
        t.values = linspace(t.values.offset,t.values.offset + t.values.spacing*(t.count-1),t.count);
    end
    p = [dim 1:dim-1 dim+1:ndims(x)];
    x = permute(x, p);
    y = matlab.internal.math.nufftdirect(x, t.values, f.values);
    y = ipermute(y, p);
end

%--------------------------------------------------------------------------
function [nuNodes, N, phaseOffs] = shiftAndScaleNodes(nuNodes, gridNodes)
    % Compute phase shift and scale non-uniform nodes to turn uniform gridded
    % nodes into implicit nodes.
    % Compute the phase offsets, if there are any.
    % Gridded nodes, but uniform.
    % Determine the grid size.
    N = numel(gridNodes.values);
    assert(N > 1);
    % Shift the grid to be uniform.
    phaseOffs = min(gridNodes.values);
    delta = median(diff(gridNodes.values));
    % Rescale the non-uniform nodes by the uniform grid spacing, then
    % apply periodicity.
    nuNodes.values = mod(nuNodes.values * delta, 1);
end
