function throwAndGoToError(err)
if numel(err.stack) > 0
    frame = err.stack(1);
    matlab.desktop.editor.openAndGoToLine(frame.file, frame.line);
end
rethrow(err);
end
