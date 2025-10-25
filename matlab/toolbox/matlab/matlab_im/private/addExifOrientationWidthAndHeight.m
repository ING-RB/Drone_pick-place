function info = addExifOrientationWidthAndHeight(info)
%ADDEXIFORIENTATIONWIDTHANDHEIGHT adds auto-oriented dimensions to info struct

% Copyright 2024 The MathWorks, Inc.

arguments
    info struct
end

numImages = length(info);

if isfield(info, 'Orientation')
    % if info has Orientation field, we need to add new fields after it and
    % account for possible sideways rotation

    % loop over images to figure out the corresponding
    % auto-oriented widths and heights
    autoOrientedWidth = cell(1, numImages);
    autoOrientedHeight = cell(1, numImages);
    for k = 1:numImages
        orientation = info(k).Orientation;

        % Exif Orientation values of 5,6,7,8 imply a sideways rotation
        if orientation >= 5 && orientation <= 8
            % The AutoOrientedWidth and AutoOrientedHeight are the size of
            % the image after it has been auto-oriented based on Exif
            % Orientation tag value, while Width and Height are the size of
            % the "raw" image as it is stored in the file. If the Exif
            % Orientation tag value implies a sideways rotation, the
            % AutoOrientedWidth and AutoOrientedHeight are the swapped
            % versions of Width and Height.
            autoOrientedWidth{k} = info(k).Height;
            autoOrientedHeight{k} = info(k).Width;
        else
            autoOrientedWidth{k}= info(k).Width;
            autoOrientedHeight{k} = info(k).Height;
        end
    end

    % insert new fields at the correct spot (after Orientation tag)
    fields = fieldnames(info);
    orientationIndex = find(strcmp(fields, 'Orientation'));
    % insert field names
    newFieldOrder = [fields(1:orientationIndex); ...
        'AutoOrientedWidth'; ...
        'AutoOrientedHeight'; ...
        fields(orientationIndex+1:end)];
    % insert field values (using cell arrays)
    cellInfo = struct2cell(info);
    cellInfoOrdered = [cellInfo(1:orientationIndex, :); ...
        autoOrientedWidth; ...
        autoOrientedHeight;...
        cellInfo(orientationIndex+1:end, :)];
    % convert back to struct
    info = cell2struct(cellInfoOrdered, newFieldOrder, 1);

else
    % add new fields at the end of the struct (without Orientation value,
    % auto-oriented widths and heights are the same as original widths and
    % heights)
    for k = 1:numImages
        info(k).AutoOrientedWidth = info(k).Width;
        info(k).AutoOrientedHeight = info(k).Height;
    end
end

end