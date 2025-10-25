function displayScalarObject(obj)
%displayScalarObject   Control the display of the datastore.
%
%   This function is used to control the display of the
%   ParquetDatastore. It divides the display in a set of groups and
%   helps organize the display of the datastore.

%   Copyright 2022-2023 The MathWorks, Inc.

import matlab.io.datastore.internal.util.displayScalarObjectFiles

disp(getHeader(obj));

fsGroup = makeFileSetGroup(obj);
pioGroup = makeParquetImportOptionsGroup(obj);
writeGroup = makeWriteallGroup(obj);

% Display the Files and Folders property first.
fsGroup = displayScalarObjectFiles(obj, fsGroup, 'Files');
fsGroup = displayScalarObjectFiles(obj, fsGroup, 'Folders');

matlab.mixin.CustomDisplay.displayPropertyGroups(obj, [fsGroup; pioGroup; writeGroup]);
disp(getFooter(obj));
end

function group = makeFileSetGroup(obj)
import matlab.mixin.util.PropertyGroup

if (obj.PartitionMethodDerivedFromAuto)
    PartitionMethodDisp = [obj.PartitionMethod, ' ', '(auto)'];
else
    PartitionMethodDisp = obj.PartitionMethod;
end

S = struct(Files = {obj.Files}, ...
    Folders = {obj.Folders}, ...
    AlternateFileSystemRoots = {obj.AlternateFileSystemRoots}, ...
    ReadSize = {obj.ReadSize}, ...
    PartitionMethod = {PartitionMethodDisp}, ...
    BlockSize = {[num2str(obj.BlockSize) ' bytes']});


group = PropertyGroup(S);
end

function group = makeParquetImportOptionsGroup(obj)
import matlab.mixin.util.PropertyGroup

S = struct(VariableNames         = {obj.VariableNames}, ...
    SelectedVariableNames = {obj.SelectedVariableNames}, ...
    VariableNamingRule    = {obj.VariableNamingRule}, ...
    OutputType            = {obj.OutputType}, ...
    RowTimes              = {obj.RowTimes}, ...
    RowFilter             = {obj.RowFilter});

msg = message("MATLAB:io:datastore:parquet:display:ReadProperties", obj.OutputType).getString();
group = PropertyGroup(S, msg);
end

function group = makeWriteallGroup(obj)
import matlab.mixin.util.PropertyGroup

S = struct(SupportedOutputFormats = {obj.SupportedOutputFormats}, ...
    DefaultOutputFormat    = {obj.DefaultOutputFormat});

msg = message("MATLAB:io:datastore:parquet:display:WriteProperties").getString();
group = PropertyGroup(S, msg);
end
