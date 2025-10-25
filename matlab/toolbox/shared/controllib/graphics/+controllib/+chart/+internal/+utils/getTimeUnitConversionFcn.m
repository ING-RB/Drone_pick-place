function conversionFcn = getTimeUnitConversionFcn(oldUnit,newUnit)
conversionFactor = tunitconv(char(oldUnit),char(newUnit));
conversionFcn = @(x) conversionFactor*x;
end