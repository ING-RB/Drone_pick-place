function [MIndExpand1, MIndExpand2] = implicitExpansionIndices(MInd1,MInd2)
%implicitExpansionIndices Get a set of object (matrix) indices for operations supporting implicit expansion
%   Some object array operations, e.g. times, should support implicit
%   expansion and we have a basic challenge of how we can find the matrices
%   that we should multiply in that case and what the output shape of the
%   object array should be.
%
%   This function helps with that by calculating the expanded indices for
%   both input object arrays, MIndExpand1, MIndExpand2.
%   A simple example: input indices ([1 2], [1 2]') will result in both
%   outputs to be [1 2; 1 2]. If the implicit expansion succeeds, the
%   outputs will be of the same size. If the input arrays have incompatible
%   sizes, an error will be thrown.
%
%   The expanded indices can then be used in two ways:
%   (1) size(MIndExpand1) determines the size of the resulting object array
%   (2) The indices in MIndExpand1 and MIndExpand2 can be used
%       element-by-element to perform the object array operation. For
%       example, for times, we can multiply T1(MIndExpand1(1)) *
%       T2(MIndExpand2(1)), and so on.

%   Copyright 2022-2024 The MathWorks, Inc.

%#codegen

% Use plus() to calculate implicit expansion of indices.
% Since we need index tuples (which matrices to operate on for each position
% in the output object array), we use a little trick: we use a complex
% number for the second index. The implicit expansion will then be complex,
% but each element will have index1 in the real part and index2 in the
% imaginary part.
% This line will fail if implicit expansion is not possible (incompatible
% input sizes).

% Make sure that code is generated for both single and double types
    coder.internal.assert(isfloat(MInd1), "");

    indTuples = MInd1 + MInd2*1i;

    MIndExpand1 = real(indTuples);
    MIndExpand2 = imag(indTuples);

end
