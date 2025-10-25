function [catM, catMInd] = concatenateFromIndices(catTuples, d, M1, M2)
%This function is for internal use only. It may be removed in the future.

%CONCATENATEFROMINDICES Concatenate spatial matrices based on complex indices
%   [CATM, CATMIND] = concatenateFromIndices(CATTUPLES, D, M1, M2) will
%   concatenate the data in M1 (d-by-d-by-N numeric array) and M2
%   (d-by-d-by-M numeric array) based on the complex indices in CATTUPLES.
%   The size of CATTUPLES determines the output size of CATMIND.
%   CATM is the concatenated numeric matrix (d-by-d-by-numel(catTuples))
%   and the associated size / index information in CATMIND.
%
%   Use this function in different concatenation functions, for example,
%   horzcat, vertcat, or cat. These concatenation functions can generate
%   CATTUPLES.

%   Copyright 2022-2024 The MathWorks, Inc.

%#codegen

% Extract the indices for M1 and M2 from the complex tuples
    MIndCat1 = real(catTuples);
    MIndCat2 = imag(catTuples);

    % Assign data to the output matrix. Since concatenation always happens in
    % complete block, we can ignore the actual contents of MIndCat1 and
    % MIndCat2 and simply assign matrices based on logical indexing.
    numMats = numel(MIndCat1);
    catM = zeros(d,d,numMats, "like", M1);
    catM(:,:,MIndCat1 > 0) = M1;
    catM(:,:,MIndCat2 > 0) = M2;

    % Generate shaped indices for concatenated matrix array
    catMInd = cast(reshape(1:numMats, size(MIndCat1)), "like", M1);

end
