function mustBeValidTimeUnit(value,optionalInputs)
arguments
    value
    optionalInputs.AllowAuto = false
end
mustBeTextScalar(value);
validTimeUnits = controllibutils.utGetValidTimeUnits;
if optionalInputs.AllowAuto
    validTimeUnits = [{'auto'}; validTimeUnits(:,1)];
else
    validTimeUnits = validTimeUnits(:,1);
end
mustBeMember(value,validTimeUnits);
end