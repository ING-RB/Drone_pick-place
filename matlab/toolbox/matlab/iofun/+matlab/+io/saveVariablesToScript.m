%SAVEVARIABLESTOSCRIPT  Save workspace variables to MATLAB script
%
%   MATLAB.IO.SAVEVARIABLESTOSCRIPT(FILENAME) saves variables in the
%   current workspace to a MATLAB script named FILENAME.m.
%   - Variables for which MATLAB code cannot be generated are saved to a
%     companion MAT-file named FILENAME.mat.
%   - If either file already exists, it is overwritten. The filename cannot
%     match the name of any variable in the current workspace and can
%     optionally include the suffix .m.
%
%   MATLAB.IO.SAVEVARIABLESTOSCRIPT(FILENAME, VARNAMES) saves only
%   workspace variables specified by VARNAMES to a MATLAB script names
%   FILENAME.m. VARNAMES must be a string or a cell array of character
%   vectors.
%
%   MATLAB.IO.SAVEVARIABLESTOSCRIPT(..., 'MATFileVersion' F) specifies
%   MATLAB version whose syntax is used to save to MAT-files. F must be
%   one of the version numbers: 'v4', 'v6', 'v7', 'v7.3'.
%
%   MATLAB.IO.SAVEVARIABLESTOSCRIPT(..., 'MaximumArraySize' A) specifies
%   maximum array elements to save in MATLAB script. If the array size
%   exceeds this limit, it will be written in companion MAT file. A must be
%   an integer in the range of 1 to 10000. Default value is 1000.
%
%   MATLAB.IO.SAVEVARIABLESTOSCRIPT(..., 'MaximumNestingLevel', N)
%   specifies maximum number of object levels or array hierarchy to save.
%   If the object levels exceed this limit, it will be written in companion
%   MAT file. N must be an integer in the range of 1 to 200. Default value
%   is 20.
%
%   MATLAB.IO.SAVEVARIABLESTOSCRIPT(..., 'MaximumTextWidth', W) specifies
%   text wrap width during save. If a string exceed this limit, it will be
%   wrapped around and will be written in multi-line in MATLAB script. W
%   must be an integer in the range of 32 to 256. Default value is 76.
%
%   MATLAB.IO.SAVEVARIABLESTOSCRIPT(..., 'MultidimensionalFormat', D)
%   specifies dimensions of 2-D slice that represent n-D arrays of char,
%   logic or numeric data. D must be:
%       'rowvector' - (default) Save multidimensional variables as a single
%                     row vector.
%       integer cell array - Save a 2-D slice of multidimensional variables
%                            where the dimensions satisfy all the following
%                            criteria:
%                            - Dimensions are represented using two
%                              positive integers.
%                            - Two integers are less than or equal to
%                              the dimensions of the n-D array.
%                            - Second integer is greater than the first.
%
%   MATLAB.IO.SAVEVARIABLESTOSCRIPT(..., 'RegExp', R) specifies regular
%   expression matching. Only input arguments with string values can be
%   matched.
%
%   MATLAB.IO.SAVEVARIABLESTOSCRIPT(..., 'SaveMode', S) specifies the mode
%   in which MATLAB script is saved. S must be:
%       'create' - (default) Save variables to a new MATLAB script.
%       'update' - Only update variables that are already present in an
%                  existing MATLAB script.
%       'append' - Update variables that are already present in an existing
%                  MATLAB script and append new variables to the end of the
%                  script.
%
%   [V1, V2] = MATLAB.IO.SAVEVARIABLESTOSCRIPT(...) also returns V1,
%   containing a cell array containing variables that were saved to a
%   MATLAB script and V2 containing variables that could not be saved to a
%   script, but were saved to a MAT-file instead.
%
%   Example:
%       a = 72.3;
%       b = pi;
%       matlab.io.saveVariablesToScript('abfile.m', {'a', 'b'});
%
%   See also SAVE

%   Copyright 2013 The MathWorks, Inc.