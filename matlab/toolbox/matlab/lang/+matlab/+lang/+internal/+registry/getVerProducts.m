function products = getVerProducts
    try
        products = {ver().Name}';
    catch
        products = {'MATLAB'};
    end
end

%   Copyright 2022 The MathWorks, Inc.
