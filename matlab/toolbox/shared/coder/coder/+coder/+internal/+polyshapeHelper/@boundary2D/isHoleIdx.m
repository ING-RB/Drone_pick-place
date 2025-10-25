function b = isHoleIdx(bdObj, bdIdx)
%

%   Copyright 2022 The MathWorks, Inc.

%#codegen

bt = bdObj.bType(bdIdx);

negative_area = (bdObj.getArea(bdIdx) < 0.);
if (bt == coder.internal.polyshapeHelper.boundaryTypeEnum.SolidCW)
    b = negative_area;
elseif (bt == coder.internal.polyshapeHelper.boundaryTypeEnum.SolidCCW)
    b = ~negative_area;
elseif (bt == coder.internal.polyshapeHelper.boundaryTypeEnum.AutoSolid)
    b = false;
else
    b =  true;
end

end
