% Inherit from this class if you would like to implement your own FFT algorithm
% to use in code generation instead of relying on the defaults.
% To tell codegen to use a custom fft callback, set the CustomFFTCallback property
% in the codegen config to the name of the custom callback class. The custom callback
% class must be a subclass of CustomFFTCallback.
%#codegen

%   Copyright 2017-2023 The MathWorks, Inc.
classdef(Abstract, Hidden) Custom1DColFFTCallback < coder.internal.Custom1DFFTCallback
    methods (Abstract)
        % Overview:
        % fft1dCol(x, isInverse) performs one or more 1D-dimensional FFTs
        % along the first dimension of the ND-array x.
        %
        % Input Invariants:
        % This function is called only when the inputs satisfy the following invariants
        %   - isInverse is of type logical
        %   - x is a full array of type double or single (real or complex)
        %   - x is nonempty
        % Note that the first condition may be temporarily violated for compilation on MATLAB
        % function blocks where the first pass occurs in ambiguous types mode where all variables
        % are assumed to have type double.
        %
        % Behavior: This function computes one or more one dimensional transforms using the
        % input data x. Each transform is computed along the first dimension and stored in
        % the corresponding location in the output vector y. For example, if x is a 10x10x10x10
        % array we compute the 1D transform of x(:, i, j, k) for every
        % possible combination of scalars i, j and k.
        %
        % Input Parameters:
        % x      - The input data as a multidimensional array
        % isInverse - True if we are to compute an inverse fft on the input. False otherwise
        y = fft1dCol(obj, x, len, isInverse,isSymmetric);
    end

    methods (Sealed)
        function y = fft1d(obj, x, len, dim, isInverse,isSymmetric)
            coder.inline('always');
            coder.internal.prefer_const(isSymmetric); 
            % Performs a permutation to bring the operating dimension to the column.
            ONE = coder.internal.indexInt(1);
            TWO = coder.internal.indexInt(2);
            if dim == ONE
                y = obj.fft1dCol(x, len, isInverse,isSymmetric);
            elseif coder.internal.isConst(isrow(x)) && isrow(x) && (dim == TWO)
                sz = coder.internal.indexInt(size(x,2));
                xCol = coder.internal.matrixReshapeValExpr(x,sz,ONE);
                yCol = obj.fft1dCol(xCol,len,isInverse,isSymmetric);
                y = coder.internal.matrixReshapeValExpr(yCol,ONE,len);
            else
                perm = coder.internal.dimToForePermutation(eml_max(dim, coder.internal.ndims(x)), dim);
                xPerm = permute(x,perm);
                yPerm = obj.fft1dCol(xPerm, len, isInverse,isSymmetric);
                y = ipermute(yPerm, perm);
            end
        end
    end
end
