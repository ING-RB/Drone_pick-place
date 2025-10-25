function names = getNames(cellDataSource,~,~)
%

% Copyright 2020-2022 The MathWorks, Inc.

if isempty(cellDataSource.Names)
    names = matlab.unittest.internal.parameters.getParameterNames(cellDataSource.Cell);
    names = names(:).';

    legacyNames = matlab.unittest.internal.parameters.getLegacyParameterNames(cellDataSource.Cell);
    legacyNames =  legacyNames(:).';

    cellDataSource.Names = [names;legacyNames];
end
names = cellDataSource.Names;
end

