function verifyJavaEnabled()
    if ~usejava("jvm")
        error(message("MATLAB:xslt:NoJavaAvailable"));
    end
end

% Copyright 2024 The MathWorks, Inc.