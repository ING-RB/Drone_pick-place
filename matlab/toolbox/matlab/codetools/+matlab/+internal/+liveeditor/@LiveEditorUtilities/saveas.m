function saveas(javaRichDocument, fileName, varargin)
% saveas - saves MLX file as

import matlab.internal.liveeditor.LiveEditorUtilities

fileName = LiveEditorUtilities.resolveFileName(fileName);

import com.mathworks.services.mlx.MlxFileUtils
if MlxFileUtils.isMlxFile(fileName)
    error('matlab:internal:liveeditor:save', 'FileName must not be a Live Code file.');
end

pollForReadyExporter(javaRichDocument);
matlab.desktop.editor.internal.exportDocumentByID(...
    char(javaRichDocument.getUniqueKey()),...
    'Destination', fileName ,...
    varargin{:});
end

function pollForReadyExporter(javaRichDocument)
%Poll for 60 seconds to wait for document content to be rendered
for i = 1:60
    if javaRichDocument.isRendered
        return;
    end
    pause(1);
end
error('matlab:internal:liveeditor:saveas', 'Timeout error waiting for document to finish rendering');
end