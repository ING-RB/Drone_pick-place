function closeAndORDelete(fid,file)
%CLOSEANDORDELETE Close the file and delete if closing fails

% Copyright 2021-2022 The MathWorks, Inc.
    try
        fclose(fid);
    catch ME
        % check if memory ran out while writing the file, if so delete the file.
        if ME.identifier == "MATLAB:printf:OutOfSpace"
            delete(file);
            oldState = warning("backtrace", "off");
            warning(message("MATLAB:printf:OutOfSpace", file));
            % reset "backtrace" to its old state
            warning("backtrace", oldState);
        else
            throwAsCaller(ME);
        end
    end
end