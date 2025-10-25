function displayScalarObject(ds)
%displayScalarObject controls the display of the datastore.
%   This function is used to control the display of the
%   tabulartextdatastore. It divides the display in a set of groups and
%   helps organize the datastore.

%   Copyright 2014-2022 The MathWorks, Inc.

import matlab.io.internal.common.display.cellArrayDisp;
import matlab.io.internal.validators.isCharVector;

% header
header = matlab.mixin.CustomDisplay.getSimpleHeader(ds);
disp(header);

% File Properties
filesIndent = '                      Files: ';
nFilesIndent = sprintf(repmat(' ',1,numel(filesIndent)));
if isempty(ds.Files)
    nFilesIndent = '';
end
filesStrDisp = cellArrayDisp(ds.Files, true, nFilesIndent);
varNamesDisp = cellArrayDisp(ds.VariableNames, false, '');
if isempty(ds.AlternateFileSystemRoots)
    altRootsDisp = '{}';
else
    altRootsDisp = char(join(string(size(ds.AlternateFileSystemRoots)), 'x'));
    altRootsDisp = ['{' altRootsDisp ' cell}'];
end
readVars = ds.ReadVariableNames;

disp([filesIndent, filesStrDisp]);

% Call a method on the Folders property mixin to get the correct string for
% its display.
% Use a custom number of indent spaces, since it seems like
% TabularTextDatastore is using one less than ImageDatastore's display spaces.
import matlab.io.datastore.FoldersPropertyProvider;
disp(FoldersPropertyProvider.generateFoldersDisplayString(ds.Folders, 20));

disp(['    ', '           FileEncoding: ''', ds.FileEncoding, '''']);
disp(['   ', 'AlternateFileSystemRoots: ', altRootsDisp]); 

% Apply PreserveVariableNames display in a conditional manner to ensure
% that 'true' and 'false' get printed instead of '1' and '0'.
if ds.PreserveVariableNames
    disp(['    ', '     VariableNamingRule: ', '''preserve''']);    
else
    disp(['    ', '     VariableNamingRule: ', '''modify''']);
end

if readVars
    disp(['    ', '      ReadVariableNames: ', 'true']);    
else
    disp(['    ', '      ReadVariableNames: ', 'false']);
end    

disp(['    ', '          VariableNames: ', varNamesDisp]);

disp(['    ', '         DatetimeLocale: ', ds.DatetimeLocale]);


fprintf('\n');

% Text Format Properties
textPropsTitle = getString(message('MATLAB:datastoreio:tabulartextdatastore:textProperties'));
disp(['  ', textPropsTitle]);
disp(['    ', '         NumHeaderLines: ', num2str(ds.NumHeaderLines)]);

if isCharVector(ds.Delimiter)
    disp(['    ', '              Delimiter: ''' , ds.Delimiter, '''']);
else
    delimDisp = cellArrayDisp(ds.Delimiter, false, '');
    disp(['    ', '              Delimiter: ', delimDisp]);
end

disp(['    ', '           RowDelimiter: ''', ds.RowDelimiter, '''']);

if isCharVector(ds.TreatAsMissing)
    disp(['    ', '         TreatAsMissing: ''', ds.TreatAsMissing, '''']);
else
    treatAsMissing = cellArrayDisp(ds.TreatAsMissing, false, '');
    disp(['    ', '         TreatAsMissing: ', treatAsMissing]);
end

disp(['    ', '           MissingValue: ', num2str(ds.MissingValue)]);
fprintf('\n');

% Advanced text Format Properties
formatsDisp  = cellArrayDisp(ds.TextscanFormats, false, '');
mDelimsAsOne = ds.MultipleDelimitersAsOne;
advancedPropsTitle = getString(message('MATLAB:datastoreio:tabulartextdatastore:advancedProperties'));
disp(['  ', advancedPropsTitle]);
disp(['    ', '        TextscanFormats: ', formatsDisp]);
disp(['    ', '               TextType: ''', ds.TextType '''']);
disp(['    ', '     ExponentCharacters: ''', ds.ExponentCharacters, '''']);

if isCharVector(ds.CommentStyle)
    disp(['    ', '           CommentStyle: ''', ds.CommentStyle, '''']);
else
    commentStyle = cellArrayDisp(ds.CommentStyle, false, '');
    disp(['    ', '           CommentStyle: ', commentStyle]);    
end

disp(['    ', '             Whitespace: ''', ds.Whitespace, '''']);

if mDelimsAsOne
    disp(['    ', 'MultipleDelimitersAsOne: ', 'true']);    
else
    disp(['    ', 'MultipleDelimitersAsOne: ', 'false']);
end    
fprintf('\n');

% Returned Table Properties
if feature('hotlinks')
    previewLink = '<a href="matlab: help(''matlab.io.datastore.TabularTextDatastore\preview'')">preview</a>';
    readLink = '<a href="matlab: help(''matlab.io.datastore.TabularTextDatastore\read'')">read</a>';
    readallLink = '<a href="matlab: help(''matlab.io.datastore.TabularTextDatastore\readall'')">readall</a>';
    retrievalPropsTitle = getString(message('MATLAB:datastoreio:tabulartextdatastore:retrievalPropertiesWithLinks', ...
                                      previewLink, readLink, readallLink));
else
    retrievalPropsTitle = getString(message('MATLAB:datastoreio:tabulartextdatastore:retrievalProperties'));    
end
disp(['  ', retrievalPropsTitle]);
svarNamesDisp = cellArrayDisp(ds.SelectedVariableNames, false, '');
sformatsDisp  = cellArrayDisp(ds.SelectedFormats, false, '');

disp(['    ', '  SelectedVariableNames: ', svarNamesDisp]);
disp(['    ', '        SelectedFormats: ', sformatsDisp]);
if isCharVector(ds.ReadSize)
    disp(['    ', '               ReadSize: ''', ds.ReadSize, '''']);
else
    disp(['    ', '               ReadSize: ', getString(message('MATLAB:datastoreio:tabulartextdatastore:rowsString', num2str(ds.ReadSize)))]);
end

disp(['    ', '             OutputType: ''', ds.OutputType, '''']);
if isCharVector(ds.RowTimes)
    disp(['    ', '               RowTimes: ''', ds.RowTimes, '''']);
else
    disp(['    ', '               RowTimes: ', '[]']);
end
fprintf('\n');

% Writing specific properties
writeTitle = getString(message('MATLAB:datastoreio:spreadsheetdatastore:writeProperties'));
disp(['  ', writeTitle]);
fprintf("     SupportedOutputFormats: [");
for ii = 1 : size(ds.SupportedOutputFormats,2) - 1
    fprintf("""%s""    ", ds.SupportedOutputFormats(ii));
end
fprintf("""%s""]", ds.SupportedOutputFormats(ii+1));
fprintf("\n");
fprintf("        DefaultOutputFormat: ""%s""\n", ds.DefaultOutputFormat);
