function workDir = setupWorkDir(workDir,reuse)
    % Create the directory if it doesn't exist.

%   Copyright 2020-2023 The MathWorks, Inc.

  if isfile(workDir)
     error(message("MATLAB:examples:InvalidWorkDir"));
  end

  if ~isfolder(workDir)
      createDir(workDir,workDir);
      return;
  elseif (numel(dir(workDir)) == 2)
      return;
  end

  if nargin < 2
      reuse = true;
  end

  if ~reuse
      i = 1;
      baseName = workDir;
      while isfolder(workDir)
          i = i + 1;
          workDir = baseName + string(i);
      end
      createDir(workDir,baseName);
  end

    function createDir(workDir,baseName)
        try 
            mkdir(workDir)
        catch e
            error(message("MATLAB:examples:UnableCreateWorkDir",baseName));
        end
    end

end

