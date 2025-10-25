function parseTranslationInput(data)
%This method is for internal use only. It may be removed in the future.

%parseTranslationInput Parse translation inputs to se2 constructor
%   parseTranslationInput(DATA) validates the numeric input DATA
%   and ensures that it is a 1-by-2 or N-by-2 array of translation vectors

%   Copyright 2022-2024 The MathWorks, Inc.

%#codegen

% Validate the 2D translation
    robotics.internal.validation.validateNumericMatrix(data, "se2", "transl", "ncols", 2);
end
