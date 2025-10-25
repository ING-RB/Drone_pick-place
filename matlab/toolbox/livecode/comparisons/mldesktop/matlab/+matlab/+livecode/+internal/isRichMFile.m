function tf = isRichMFile(file)
%

% Copyright 2024 The MathWorks, Inc.

    arguments
        file {mustBeTextScalar, mustBeNonzeroLengthText}
    end

    [~, ~, ext] = fileparts(file);

    % Early return for MLX
    import matlab.livecode.internal.isMLXFile
    if strcmpi(ext,'.mlx') || isMLXFile(file)
        tf = false;
        return;
    end

    tf = matlab.desktop.editor.EditorUtils.isLiveCodeFile(file);
end