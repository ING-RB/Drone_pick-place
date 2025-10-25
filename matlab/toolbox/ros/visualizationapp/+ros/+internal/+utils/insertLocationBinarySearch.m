function lowerBoundIndex = insertLocationBinarySearch(arr, target)
%insertLocationBinarySearch 

%   Copyright 2024 The MathWorks, Inc.

    lowerBoundIndex = -1; % Default value if target is not found
    
    left = 1;
    right = numel(arr);
    
    while left <= right
        mid = floor((left + right) / 2);
        
        if arr(mid) >= target
            lowerBoundIndex = mid;
            right = mid - 1;
        else
            left = mid + 1;
        end
    end
end