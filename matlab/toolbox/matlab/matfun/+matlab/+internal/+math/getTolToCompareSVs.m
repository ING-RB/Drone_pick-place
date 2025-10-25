function tol = getTolToCompareSVs(s, maxSizeA)
%getTolToCompareSVs Get tolerance used to compare singular values
% tol = getTolToCompareSVs(s, maxSizeA) returns a reasonable tolerance
% tolerance that can be used to compare which singular values should be
% treated as zero when compared to the larges singular value.

%   Copyright 2023-2024 The MathWorks, Inc.

if isempty(s)
    tol = 0;
else
    % Use max over first 2 dims to keep tol in correct ND shape if needed
    tol = maxSizeA * eps(max(s, [], [1 2]));

    % For non-finite SVs, we choose realmax as tolerance which causes all
    % finite SVs to be treated as zero. We overwrite tol instead of
    % branching for non-finite s to make this helper usable for page
    % functions too.
    if ~allfinite(s)
        tol(any(~isfinite(s), 1)) = realmax('like', s);
    end
end
end