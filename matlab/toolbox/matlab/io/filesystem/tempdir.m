function tmp_dir = tempdir
    persistent temporary;
    if isempty(temporary)
        if ispc
            % Follow the behavior of Win32 GetTempPath
            tmp_dir = getenv('TMP');
            if ( isempty(tmp_dir) )
                tmp_dir = getenv('TEMP');
            end
            if ( isempty(tmp_dir) )
                tmp_dir = getenv('USERPROFILE');
            end
            if ( isempty(tmp_dir) )
                tmp_dir = 'C:\temp'; % Should never be needed
            end
        else
            % Follow the POSIX standard
            tmp_dir = getenv('TMPDIR');
            if ( isempty(tmp_dir) )
                tmp_dir = getenv('TMP'); % Compatibility with previous MATLAB releases
            end
            if ( isempty(tmp_dir) )
                tmp_dir = '/tmp';
            end
        end
    
        % resolve soft links
        try
            % if canonicalizepath fails, use original tmp_dir
            tmp_dir = builtin('_canonicalizepath', tmp_dir);
        end
        if (tmp_dir(end) ~= filesep)
            tmp_dir = [tmp_dir filesep];
        end
        temporary = tmp_dir;
    else
        tmp_dir = temporary;
    end
end

%   Copyright 1984-2023 The MathWorks, Inc.