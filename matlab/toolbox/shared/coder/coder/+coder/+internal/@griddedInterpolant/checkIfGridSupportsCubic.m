function info = checkIfGridSupportsCubic(gridVectors, defaultVectors)
    % helper function to test if the inputs can be used for cubic
    % interpolation

    %   Copyright 2022 The MathWorks, Inc.

    %#codegen

    n = numel(gridVectors);
    
    lengthTooShort = coder.const(false);
    notUniform = false;
    cls = coder.const(class(gridVectors{1}));

    for i = 1:n
        Xi = gridVectors{i};
        ni = numel(Xi);
        lengthTooShort = lengthTooShort | (ni < 3);
        if (lengthTooShort)
            break;
        end

        if (~defaultVectors)
            uniformXi = coder.internal.griddedInterpolant.isUniformVector(Xi, ni, cls);
            notUniform = notUniform | ~uniformXi;
            if (notUniform)
                break;
            end
        end
    end

    info = [lengthTooShort, notUniform];

end
