function groups = displayScalarObjectFiles(obj, groups, propName)
%DISPLAYSCALAROBJECTFILES Display Files property of the input object.
%   This utility uses evalc of the default display of the input object
%   and finds the correct indentation of the Files property and uses
%   cellArrayDisp utility to produce a custom display.
%
%   See also matlab.io.datastore.FileDatastore,
%            matlab.io.datastore.ParquetDatastore

%   Copyright 2018-2022 The MathWorks, Inc.
    import matlab.io.internal.common.display.cellArrayDisp;
    detailsStr = evalc('details(obj)');
    nsplits = strsplit(detailsStr, '\n');
    propWithColon = sprintf('%s: ',propName);
    filesStr = nsplits(contains(nsplits, propWithColon));
    % Find the indent spaces from details
    nFilesIndent = strfind(filesStr{1}, propWithColon) - 1;
    if nFilesIndent > 0
        % Properties
        filesIndent = [sprintf(repmat(' ',1,nFilesIndent)) propWithColon];
        nlspacing = sprintf(repmat(' ',1,numel(filesIndent)));
        if isempty(obj.(propName))
            nlspacing = '';
        end

        filesStrDisp = cellArrayDisp(obj.(propName), true, nlspacing);
        disp([filesIndent filesStrDisp]);
        % Remove the property from the groups. since custom
        % display is used for Files and Folders.
        groups.PropertyList = rmfield(groups.PropertyList, propName);
    end
end
