function m3i_cleanupOnEditorClose(fStudioString, fFilename)
%

%   Copyright 2008 The MathWorks, Inc.

    %Clearing the studio
    evalin('base', ['clear ' fStudioString ';']);
    
    %Deleting the temporary file
    delete(fFilename);
    
end
