function str = generateFoldersDisplayString(folders, initialIndent)
%generateFoldersDisplayString    utility for generating a
%   display string for the Folders property that can be re-used
%   in subclasses.
%
%   See also matlab.io.datastore.FoldersPropertyProvider

%   Copyright 2019-2022 The MathWorks, Inc.

    import matlab.io.internal.common.display.cellArrayDisp;

    if nargin < 2
        % By trial and error, it looks we have 21 spaces before the
        % "Folders: " string in the ImageDatastore display.
        foldersPropertyIndent = 21;
    else
        % Use the subclass-provided input.
        foldersPropertyIndent = initialIndent;
    end

    % Set up the initial arrays required to call cellArrayDisp.
    foldersPropertyWhitespace = repmat(' ', 1, foldersPropertyIndent);
    foldersPropertyPrelude = [sprintf(foldersPropertyWhitespace) 'Folders: '];

    % Avoid calling cellArrayDisp if the Folders property is empty.
    if isempty(folders)
        foldersDisplayString = '{0×1 cell}';
    else
        nextLineSpacing = sprintf(repmat(' ', 1, numel(foldersPropertyPrelude)));
        foldersDisplayString = cellArrayDisp(folders, true, nextLineSpacing);
    end

    % Assemble into the full property display string.
    str = [foldersPropertyPrelude foldersDisplayString];
end
