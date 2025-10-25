function validateOutputDir(outdir)
% Validate output directory where XML and definition file will get generated

%   Copyright 2018-2023 The MathWorks, Inc.
% Check that the type of outputFolder is correct
try    
    validateattributes(outdir,{'char','string'},{'scalartext', 'nonempty'});
    if (startsWith(outdir, "<"))
        % Output directory seems to refer to a 'RootPaths' key
        % defer validation
        return;
    end

    outdir  = string(outdir);
    if((outdir.strlength~=0))
        if (~isfolder(outdir))
            mkdir(outdir);
        end
    else
        error(message('MATLAB:CPP:InvalidOutputFolder'));
    end
catch
     error(message('MATLAB:CPP:InvalidOutputFolder'));
end
end
