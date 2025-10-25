function names = getNames(structDataSource,~,~)
%

% Copyright 2020-2022 The MathWorks, Inc.

names = fieldnames(structDataSource.Struct);
names = [names(:).' ;names(:).'];
end

