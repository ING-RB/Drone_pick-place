function validateSourceFile(srcFilename)
% Validate the Source file

%   Copyright 2018-2023 The MathWorks, Inc.
if ~iscellstr(srcFilename)
    try
        validateattributes(srcFilename,{'char','string'},{'vector','row'});
    catch ME
        error(message('MATLAB:CPP:InvalidInputType','SourceFiles'));
    end
    if ismissing(srcFilename)
        error(message('MATLAB:CPP:InvalidInputType','SourceFiles'));
    end
else
    if ~isrow(srcFilename)
        error(message('MATLAB:CPP:InvalidInputType','SourceFiles'));
    end
end

if ~isempty(find(startsWith(srcFilename, "<"), 1))
    % atleast one srcFilename seems to refer to a 'RootPaths' key
    % defer validation
    return;
end

srcFilename = cellstr(convertStringsToChars(srcFilename));
for index = 1:length(srcFilename)
    % Error if the source file is a wildcard character
    if strfind(srcFilename{index}, '*') > 0
        error(message('MATLAB:CPP:InvalidInputType','SourceFiles'));
    end
    [~,~,ext] = fileparts(srcFilename{index});
    if (isempty(ext))
        % Passing space in cell array not throwing any error
        if ( isempty(deblank(srcFilename{index})) || exist(srcFilename{index}) == 7)
            continue;
        end
    end
    if isempty(dir(srcFilename{index}))
        error(message('MATLAB:CPP:FileNotFound',srcFilename{index}));
    end
    % Check for duplicate entry
    for i = index+1:length(srcFilename)
        if strcmp(srcFilename{i},srcFilename{index})
            error(message('MATLAB:CPP:DuplicateSourceEntry',srcFilename{index}));
        end
    end
    % Validate extension of source.
    if ~isempty(ext)
        if (~strcmp(ext,'.cpp') && ~strcmp(ext,'.cxx') && ~strcmp(ext,'.c'))
            error(message('MATLAB:CPP:IncorrectSourceExtension'));
        end
    else
        % Supporting Source files taking in hpp file without extension
        error(message('MATLAB:CPP:IncorrectSourceExtension'));
    end
end
end
