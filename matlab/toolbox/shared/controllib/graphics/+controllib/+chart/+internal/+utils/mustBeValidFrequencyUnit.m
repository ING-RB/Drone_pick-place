function mustBeValidFrequencyUnit(value,optionalInputs)
arguments
    value
    optionalInputs.AllowAuto = false
end
mustBeTextScalar(value);
validFrequencyUnits = controllibutils.utGetValidFrequencyUnits;
if optionalInputs.AllowAuto
    validFrequencyUnits = [{'auto'};validFrequencyUnits(:,1)];
else
    validFrequencyUnits = validFrequencyUnits(:,1);
end
mustBeMember(value,validFrequencyUnits);
end