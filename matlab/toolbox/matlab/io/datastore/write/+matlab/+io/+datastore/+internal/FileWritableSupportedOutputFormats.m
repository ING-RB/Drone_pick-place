classdef FileWritableSupportedOutputFormats
%FILEWRITABLESUPPORTEDOUTPUTFORMATS Collection of SupportedOutputFormats
%   for all in-house file writable datastores

%   Copyright 2023 The MathWorks, Inc.

    properties (Constant)
        TabularTextDatastoreSupportedOutputFormats = ["txt", "csv", "dat", "asc"];
        SpreadsheetDatastoreSupportedOutputFormats = ["xlsx", "xls"];
        ParquetDatastoreSupportedOutputFormats = ["parquet", "parq"];
        TabularDatastoreSupportedOuptutFormats = [matlab.io.datastore.internal.FileWritableSupportedOutputFormats.TabularTextDatastoreSupportedOutputFormats, ...
            matlab.io.datastore.internal.FileWritableSupportedOutputFormats.SpreadsheetDatastoreSupportedOutputFormats, ...
            matlab.io.datastore.internal.FileWritableSupportedOutputFormats.ParquetDatastoreSupportedOutputFormats];
        ImageDatastoreSupportedOutputFormats = ["png", "jpg", "jpeg", "tif", "tiff"];
        AudioDatastoreSupportedOutputFormats = ["wav", "flac", "ogg", "opus", "mp3", "mp4", "m4a"];
        SupportedOutputFormats = [matlab.io.datastore.internal.FileWritableSupportedOutputFormats.TabularDatastoreSupportedOuptutFormats, ...
            matlab.io.datastore.internal.FileWritableSupportedOutputFormats.ImageDatastoreSupportedOutputFormats, ...
            matlab.io.datastore.internal.FileWritableSupportedOutputFormats.AudioDatastoreSupportedOutputFormats];
    end
end
