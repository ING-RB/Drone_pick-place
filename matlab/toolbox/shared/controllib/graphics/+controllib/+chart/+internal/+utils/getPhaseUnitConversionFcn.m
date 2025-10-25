function conversionFcn = getPhaseUnitConversionFcn(oldUnit,newUnit)
conversionFcn = @(x) x;
if ~strcmp(oldUnit,newUnit)
    if strcmp(newUnit,'deg')
        conversionFcn = @(x) rad2deg(x);
    else
        conversionFcn = @(x) deg2rad(x);
    end
end
end