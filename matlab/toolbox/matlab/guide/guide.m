function varargout=guide(varargin)
%   Copyright 1984-2025 The MathWorks, Inc.

openTag = '';
closeTag = '';
guideFigFile = '';

% Open corresponding GUIDE app .m file if it exists
if nargin > 0
    try
        [varargin{:}] = convertStringsToChars(varargin{:});
        fileName = varargin{1};

        [filePath, appName] = fileparts(fileName);

        figFile = fullfile(filePath, [appName, '.fig']);
        matlabCodeFile = fullfile(filePath, [appName, '.m']);

        if isfile(figFile) && isfile(matlabCodeFile)
            openTag = sprintf('<a href="matlab:edit(''%s'')">', matlabCodeFile);
            closeTag = '</a>';
            guideFigFile = sprintf('''%s''', figFile);
        end
    catch
    end
end

error(message('MATLAB:guide:GUIDEHasBeenRemoved', openTag, closeTag, guideFigFile));

end