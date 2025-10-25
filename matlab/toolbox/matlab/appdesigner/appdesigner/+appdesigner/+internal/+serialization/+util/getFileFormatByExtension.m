function fileFormat = getFileFormatByExtension (filepath)
    if endsWith(filepath, 'm', 'IgnoreCase', true)
        fileFormat = appdesigner.internal.serialization.FileFormat.Text;
    else
        fileFormat = appdesigner.internal.serialization.FileFormat.Binary;
    end
end