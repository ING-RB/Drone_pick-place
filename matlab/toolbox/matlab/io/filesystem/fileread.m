function out = fileread(filename,args)
    arguments
        filename {mustBeNonzeroLengthText, mustBeTextScalar}
        args.Encoding {mustBeTextScalar} = "";
    end
    
    [fid, msg] = fopen(filename, "r", "n", args.Encoding);
    
    if fid == -1
        error(message("MATLAB:fileread:cannotOpenFile", filename, msg));
    end
    
    try
        out = fread(fid, "*char")';
    catch ME
        fclose(fid);
        throw(ME);
    end
    
    fclose(fid);
end

% Copyright 1984-2023 The MathWorks, Inc.