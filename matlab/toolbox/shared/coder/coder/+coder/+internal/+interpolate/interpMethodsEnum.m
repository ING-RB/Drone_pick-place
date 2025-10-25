classdef interpMethodsEnum < uint8
    enumeration
        %% Method Enums %%
        %% Common to scatteredInterpolant and griddedInterpolant
        LINEAR (0)
        NEAREST (1)
        NONE (8)
        %% griddedInterpolant
        PREVIOUS (2)
        NEXT (3)
        CUBIC (4)
        SPLINE (5)
        PCHIP (6)
        MAKIMA (7)
        %% scatteredInterpolant
        NATURAL (9)
        BOUNDARY (10)
    end
end