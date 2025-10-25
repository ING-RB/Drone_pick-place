function parseTranslationInput(data)
%This method is for internal use only. It may be removed in the future.

%parseTranslationInput Parse translation inputs to se3 constructor
%   parseTranslationInput(DATA) validates the numeric input DATA
%   and ensures that it is a 1-by-3 or N-by-3 array of translation vectors

%   Copyright 2022-2024 The MathWorks, Inc.

%#codegen

% Validate the 3D translation
    robotics.internal.validation.validateNumericMatrix(data, "se3", "transl", "ncols", 3);
end
