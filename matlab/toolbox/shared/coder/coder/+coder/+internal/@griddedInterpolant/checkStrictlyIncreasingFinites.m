function checkStrictlyIncreasingFinites(gridVectors)
    % checks if the vectors are sorted

    %   Copyright 2022 The MathWorks, Inc.

    %#codegen

    n = numel(gridVectors);
    for i=1:n
        coder.internal.griddedInterpolant.hasStrictlyIncreasingFinites(gridVectors{i});
    end

end
