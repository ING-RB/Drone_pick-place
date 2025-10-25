function displayScalarObject(ds)
%DISPLAYSCALAROBJECT   Control the display of the datastore
%
%   This function is used to control the display of the SequentialDatastore.
%   It divides the display into a set of groups and helps organize the
%   display of the datastore.

%   Copyright 2022 The MathWorks, Inc.

% Header.
disp(getHeader(ds));

group = getPropertyGroups(ds);

% Custom display for "UnderlyingDatastores" property.
displayUnderlyingDatastores(ds.UnderlyingDatastores);
% Remove "UnderlyingDatastores" property from the group, since we just used
% custom display.
group.PropertyList = rmfield(group.PropertyList, 'UnderlyingDatastores');

matlab.mixin.CustomDisplay.displayPropertyGroups(ds, group);
disp(getFooter(ds));
end

function displayUnderlyingDatastores(underlyingDs)

% Based on length of char vector with spaces copied from before the
% "UnderlyingDatastores" of CombinedDatastore display, it looks we have 6
% spaces before it, use the same for SequentialDatastore.
underlyingDatastoresPropertyIndent = 6;
underlyingDatastoresPropertyPrelude = [repmat(' ', 1, underlyingDatastoresPropertyIndent) 'UnderlyingDatastores: '];
% To display size as m×n:
sizeMultiplicationSign = char(215);

% Start printing the "UnderlyingDatastores" property.
fprintf(underlyingDatastoresPropertyPrelude);
if isempty(underlyingDs)
    % Just display {0×1 cell} and return.
    disp(['{0', sizeMultiplicationSign, '1 cell}']);
else
    % Starting cell array of objects display.
    disp('{');

    underlyingDsLineSpacing = repmat(' ', 1, numel(underlyingDatastoresPropertyPrelude));
    numItems = numel(underlyingDs);
    % We need to expand only up to 3 "UnderlyingDatastores", so find class
    % names of only first 3.
    minNumItems = min(numItems, 3);
    for ii = 1 : minNumItems
        fprintf(underlyingDsLineSpacing);
        % Print the size and class as object inside the cell array and not
        % as cellstr, e.g.: [1×1 matlab.io.datastore.ImageDatastore].
        fprintf(['[', num2str(size(underlyingDs{ii}, 1)), sizeMultiplicationSign, num2str(size(underlyingDs{ii}, 2)), ' ', class(underlyingDs{ii}), ']']);
        if ii == minNumItems
            % For last UnderlyingDatastore, we don't print ';', so just add
            % newline.
            fprintf(newline);
        else
            disp(';');
        end
    end
    % For more than 3 UnderlyingDatastores, display ' ... and N more' line as well.
    if numItems > 3
        disp([underlyingDsLineSpacing, ' ... and ', num2str(numItems-3), ' more']);
    end

    % Close the cell array of objects display.
    underlyingDatastoresPropertyPostlude = [underlyingDsLineSpacing, '}'];
    disp(underlyingDatastoresPropertyPostlude);
end
end