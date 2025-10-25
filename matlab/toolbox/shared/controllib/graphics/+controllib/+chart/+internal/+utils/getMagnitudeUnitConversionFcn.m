function conversionFcn = getMagnitudeUnitConversionFcn(oldUnit,newUnit)
conversionFcn = @(x) x;
if ~strcmp(oldUnit,newUnit)
    if strcmp(newUnit,'dB')
        conversionFcn = @(x) mag2db(x);
    else
        conversionFcn = @(x) db2mag(x);
    end
end
end