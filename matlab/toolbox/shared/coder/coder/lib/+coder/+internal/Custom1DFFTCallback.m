% Inherit from this class if you would like to implement your own FFT algorithm
% to use in code generation instead of relying on the defaults.
% To tell codegen to use a custom fft callback, set the CustomFFTCallback property
% in the codegen config to the name of the custom callback class. The custom callback
% class must be a subclass of CustomFFTCallback.
%#codegen

%   Copyright 2017-2023 The MathWorks, Inc.
classdef(Abstract, Hidden) Custom1DFFTCallback < coder.internal.CustomFFTCallback
    methods (Abstract)
        % Overview:
        % fft1d(x, dim, isInverse,isSymmetric) performs one or more 1D-dimensional FFTs
        % along the dimension dim of the ND-array x.
        %
        % Input Invariants:
        % This function is called only when the inputs satisfy the following invariants
        %   - dim is a scalar of type coder.internal.indexIntClass
        %   - isInverse is of type logical
        %   - x is a nonempty full array of type double or single (real or complex)
        %   - dim >= 1
        %   - dim is a compile time constants
        % Note that the first 2 conditions may be temporarily violated for compilation on MATLAB
        % function blocks where the first pass occurs in ambiguous types mode where all variables
        % are assumed to have type double.
        %
        % Behavior: This function computes one or more one dimensional transforms using the
        % input data x. Each transform is computed along the dimension dim and stored in
        % the corresponding location in the output vector y. For example, if x is a 10x10x10x10
        % array, and dims is 2, we compute the 1D transform of x(i, :, j, k) for every
        % possible combination of scalars i, j and k.
        %
        % Input Parameters:
        % x      - The input data as a multidimensional array
        % dim    - The dimension along which to perform the transform
        % isInverse - True if we are to compute an inverse fft on the input. False otherwise
        y = fft1d(obj, x, len, dim, isInverse,isSymmetric);
    end

    methods (Sealed)
        function y = fft(obj, x, lens, dims, isInverse,isSymmetric)
            coder.inline('always');
            coder.internal.CustomFFTCallback.assertInvariant(x, lens, dims, isInverse,isSymmetric);

            y = obj.fftLoop(x, lens, dims, isInverse,isSymmetric);
        end
    end

    methods (Access = private)
        % Performs a simple multidimensional fft on x using recursion
        function y = fftLoop(obj, x, lens, dims, isInverse,isSymmetric)
            coder.inline('always');
            coder.internal.prefer_const(lens, dims);
            if isscalar(dims)
                y = obj.fft1d(x, lens(1), dims(1), isInverse,isSymmetric);
            else
                acc = obj.fft1d(x, lens(1), dims(1), isInverse,false);
                y = obj.fftLoop(acc, lens(2:end), dims(2:end), isInverse,isSymmetric);
            end
        end
    end
end
