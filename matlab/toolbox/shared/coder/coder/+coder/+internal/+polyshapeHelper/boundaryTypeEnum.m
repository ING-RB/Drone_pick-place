classdef boundaryTypeEnum < uint8
%

%   Copyright 2022 The MathWorks, Inc.
    
    %#codegen
        
    enumeration
        %% Boundary Types Enums %%
        SolidCW(0)
        SolidCCW(1)
        UserAuto(2)
        AutoSolid(3)
        AutoHole(4)
        Invalid(5)
    end
end
