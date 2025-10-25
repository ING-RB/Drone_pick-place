function isValid = isObjectShapeValidForLayout(obj, displayConfiguration)
% Validate that the input object meets the shape constraints imposed by the
% display layout. For single line, the object must be a row vector. For
% columnar layouts, the object must not have more than 2 dimensions

% Copyright 2020-2021 The MathWorks, Inc.
    arguments
        obj
        displayConfiguration (1,1) matlab.display.DisplayConfiguration
    end
    import matlab.display.internal.DisplayLayout;
    isValid = false;
    
    switch displayConfiguration.DisplayLayout
        case DisplayLayout.SingleLine
            isValid = isrow(obj);
        case DisplayLayout.Columnar
            isValid = ismatrix(obj);
    end
end