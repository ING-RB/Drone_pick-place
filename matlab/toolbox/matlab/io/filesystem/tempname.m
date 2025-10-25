function tmp_name = tempname(dirname)
    if nargin > 0
        dirname = convertStringsToChars(dirname);
    end
    
    if nargin == 0
        dirname = tempdir;
    elseif ~ischar(dirname) || size(dirname, 1) ~= 1
        error(message('MATLAB:tempname:MustBeString'));
    end
    
    tmp_name = fullfile(dirname, ['tp' strrep(char(matlab.lang.internal.uuid),'-','_')]);
end

% Copyright 1984-2023 The MathWorks, Inc.