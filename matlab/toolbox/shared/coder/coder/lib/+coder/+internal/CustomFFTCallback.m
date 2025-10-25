% Inherit from this class if you would like to implement your own FFT algorithm
% to use in code generation instead of relying on the defaults.
% To tell codegen to use a custom fft callback, set the CustomFFTCallback property
% in the codegen config to the name of the custom callback class. The custom callback
% class must be a subclass of CustomFFTCallback.
%#codegen

%   Copyright 2017-2023 The MathWorks, Inc.
classdef(Abstract, Hidden) CustomFFTCallback
    methods (Abstract)
        % fft(x, lens, dims, isInverse,isSymmetric) performs one or more N-dimensional FFTs
        % using the floating point input data, x.
        %
        % Specification:
        % This function computes one or more N dimensional transforms using the
        % input data x. The dimensionality of each transform (N) shall be called the
        % rank and is determined by the number of elements of the dims, or equivalently
        % the lens vector.
        % Before any processing is done, x is resized such that the new size of x
        % satisfies size(x, dims(i)) == lens(i) for all i. That is, x is resized
        % along the dimensions contained in dims such that these dimensions
        % have lengths contained in lens. x is zero padded along dimensions where
        % the length increases, and truncated along dimensions where the length decreases.
        % Note that the number of dimensions of x may be less than
        % than the number of dimensions after the resize, for instance,
        % if max(dims) > ndims(x). The implementation is not required to actually perform this
        % resize, but the function must behave as if the resize did occur.
        %
        % After the resize of x, each N dimensional FFT
        % is computed as if it were the N dimensional array x(idx) where idx is the
        % cell array given as idx(i) = ':' if i is an element of dims, and idx(i) = k_i
        % for some scalar k_i otherwise. For each combination of the k_i, an ND transform
        % is performed and placed in its corresponding slab in the output matrix y.
        % For example, if x is an 10x10x10x10 array and dims is the vector [2, 3], each
        % transform would be a 2 dimensional transform performed on the 2D array
        % x(i, :, j, :) for scalars i and j. For each combination of i, and j, a 2D
        % transform is performed and placed in the slab y(i, :, j, :) of the output.
        %
        % For forward transforms, the output type is always complex, however it
        % will satisfy a conjugate symmetry requirement should the input be real.
        % For reverse transforms the output is also complex and will never satisfy
        % a conjugate symmetry requirement. A possible enhancement is
        % to add the a symmetry flag which indicates that the input is conjugate
        % symmetric on a reverse transform, in which case we can make the output real.
        % If x is of type single, so is y. If x is of type double, so is y.
        %
        % Note that the first 2 conditions may be temporarily violated for compilation on MATLAB
        % function blocks where the first pass occurs in ambiguous types mode where all variables
        %
        % Input Parameters:
        % x      - The input data as a multidimensional array
        % lens   - A row vector specifying the output size of y in the dimensions dims.
        %          The input, x, is reshaped by truncating or zero padding such that
        %          size(x, dims(i)) = lens(i) before computing the fft.
        % dims   - A set of dimensions of x which define slabs of x that are computed
        %          as a single ND fft. The remaining dimensions of x are the dimensions on which
        %          these slabs are stacked.
        %          The rank of the fft to compute (ie the N in N-dimensional) is taken
        %          to be numel(dims), which we require to be equal to numel(lens).
        % isInverse - True if we are to compute an inverse fft on the input. False otherwise
        %
        % isSymmetric - This parameter is applicable only when computing inverse fourier transform.
        %               If true, we compute the symmetric inverse fourier
        %               transform. Currently we support only one dimensional symmetric ifft,ie, if isSymmetric
        %               is true, lens and dims must be scalars. Symmetric inverse transform is defined
        %               for a conjugate symmetric sequence. A vector y is conjugate symmetric if y(2:end) is equal to
        %               conj(y(end:-1:2)). The ifft of y is real. Only the first floor(lens/2) + 1 elements of y
        %               are used in computation. Neither MATLAB nor code generation enforces that input must be
        %               conjugate symmetric. If the input is not conjugate symmetric and isSymmetric is true ifft will 
        %               produce a real result using first floor(lens/2) + 1 elements. For example if y = 1:10 and lens = 10,
        %               then the algorithm uses the first 6 elements of y and computes the ifft of [1 2 3 4 5 6 5 4 3 2].
        %               If lens is greater than or equal to 2*size(x,dims),then dimension dims of x is padded with zeros
        %               such that size(x,dims) = floor(lens/2) + 1.
        %               
        %               
        %               In MATLAB if no symmetry flags are passed to ifft, then  it checks if the input is conjugate
        %               symmetric or not and uses the appropriate algorithm. This makes the output complexity
        %               dynamic. In code generation, we use the symmetric  algorithm only if specified by the user.
        %                
        %       
        %               
        % Input Invariants:
        % This function is called only when the inputs satisfy the following invariants
        %   - lens and dims must be nonempty compile time vectors of
        %     type coder.internal.indexIntClass
        %   - isInverse is of type logical
        %   - isSymmetric is of type logical and is true only if isInverse
        %     is true
        %   - x is a full array of type double or single (real or complex)
        %   - x is nonempty
        %   - dims contains no duplicates and is sorted from low to high
        %   - min(lens) >= 1
        %   - min(dims) >= 1
        %   - numel(dims) == numel(lens)
        %   - dims and numel(lens) are compile time constants
        %   - dims and lens must be scalars when isSymmetric is true.
        % Size Propagation Requirements:
        % The output, y, must satisfy the following requirements.
        % - size(y, dims(i)) matches the size information for lens(i).
        % - size(y, i) for i not in dims matches the size information for size(x, i).
        %
        % Example: Suppose x is a 4x5x30x2 (4D) array of doubles with rank = 2 and
        % lens = [22 17] and dims = [1 3]. coder.internal.fft
        % will compute 5*2 = 10, 2-D ffts where each fft is a slab of
        % size 22 x 3 along the first and third dimensions. The slabs are stacked as in a 2D array
        % along the 2nd and 4th dimension. Before doing any computations, we first pad the
        % input with zeros along the 1st dimension so it has length 22 and truncate the input
        % along the 3rd dimension so it has length 17. We then compute the 2D fft of each slab
        % and return the result y as a 22x5x17x2 (4D) array. In particular, (after padding
        % and truncation of x) we have y(:, i, :, j) = fft2(x(:, i, :, j)) for each valid i and j.
        y = fft(obj, x, lens, dims, isInverse,isSymmetric);
    end

    methods (Static, Access = protected)
% This assert is used for internal debugging to verify that coder.internal.fft.fft
% is correctly calling the callback. This assert should never be triggered in
% a production release.
function assertInvariant(x, lens, dims, isInverse,isSymmetric)
    errorId = 'Coder:builtins:Explicit';
    msg = 'Arguments violate invariant.';

    coder.internal.assert(...
        isa(lens, coder.internal.indexIntClass) || coder.internal.isAmbiguousTypes, ...
        errorId, msg,'IfNotConst','Fail');

    coder.internal.assert(...
        isvector(lens) && ~isempty(lens), ...
        errorId, msg,'IfNotConst','Fail');

    coder.internal.assert(...
        coder.internal.isConst(numel(lens)), ...
        errorId, msg,'IfNotConst','Fail');

    coder.internal.assert(...
        isa(dims, coder.internal.indexIntClass) || coder.internal.isAmbiguousTypes, ...
        errorId, msg,'IfNotConst','Fail');

    coder.internal.assert(...
        isvector(dims) && ~isempty(dims), ...
        errorId, msg,'IfNotConst','Fail');

    coder.internal.assert(...
        coder.internal.isConst(dims), ...
        errorId, msg,'IfNotConst','Fail');

    coder.internal.assert(...
        isa(isInverse, 'logical') || coder.internal.isAmbiguousTypes, ...
        errorId, msg,'IfNotConst','Fail');

    coder.internal.assert(...
        isa(isSymmetric, 'logical') || coder.internal.isAmbiguousTypes, ...
        errorId, msg,'IfNotConst','Fail');
    
    % symmetric option is valid only for ifft
    coder.internal.assert(isInverse || ~isSymmetric || coder.internal.isAmbiguousTypes,...
        errorId, msg,'IfNotConst','Fail')

    coder.internal.assert(...
        isfloat(x) || coder.internal.isAmbiguousTypes, ...
        errorId, msg,'IfNotConst','Fail');

    coder.internal.assert(...
        ~issparse(x), ...
        errorId, msg,'IfNotConst','Fail');

    coder.internal.assert(...
        dims_issorted(dims), ...
        errorId, msg,'IfNotConst','Fail');

    coder.internal.assert(...
        ~dims_hasdups(dims), ...
        errorId, msg,'IfNotConst','Fail');

    coder.internal.assert(...
        dims(1) >= 1, ...
        errorId, msg,'IfNotConst','Fail');

    coder.internal.assert(...
        numel(dims) == numel(lens),...
        errorId, msg, 'IfNotConst','Fail');
end
    end
end

% Assumes dims is sorted
function y = dims_hasdups(dims)
    y = false;
    if isscalar(dims)
        return;
    end
    coder.unroll();
    for i = 2:numel(dims)
        if dims(i) == dims(i-1)
            y = true;
            return;
        end
    end
end

function y = dims_issorted(dims)
    y = true;
    if isscalar(dims)
        return;
    end
    coder.unroll();
    for i = 2:numel(dims)
        if dims(i) < dims(i-1)
            y = false;
            return;
        end
    end
end

% LocalWords:  ffts builtins
