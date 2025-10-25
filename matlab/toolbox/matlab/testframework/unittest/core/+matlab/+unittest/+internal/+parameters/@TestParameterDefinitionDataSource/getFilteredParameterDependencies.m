function filteredparams = getFilteredParameterDependencies(tpdDataSource,upLevelParams)
% Provide input Parameter objects for the TestParameterDefinition method.
% "filteredparams" contains Parameter objects that are filtered from
% "upLevelParams" to match the parameter properties accepted as inputs by
% the TPD method.

% Copyright 2020 The MathWorks, Inc
mcls = meta.class.fromName(tpdDataSource.TestClassName);
tpdMethod = findobj(mcls,'Name',tpdDataSource.TestParameterDefinitionMethodName);

inputCell = cell(1,numel(tpdMethod.InputNames));
for rowIdx = 1:numel(tpdMethod.InputNames)
    propName = tpdMethod.InputNames{rowIdx};
    
    % Filter the unused parameter inputs.
    inputCell{rowIdx} = upLevelParams{:}(strcmp({upLevelParams{:}.Property},propName));
end
filteredparams = [inputCell{:}];
end