function conversionFcn = getFrequencyUnitConversionFcn(oldUnit,newUnit)
conversionFactor = funitconv(char(oldUnit),char(newUnit));
conversionFcn = @(x) conversionFactor*x;
end