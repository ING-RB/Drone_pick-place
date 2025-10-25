function S = load(varargin)
%CODER.LOAD Load data from MAT-file into workspace.
%   S = CODER.LOAD(FILENAME) loads the variables from a MAT-file into a
%   structure array, or data from an ASCII file into a double-precision
%   array.
%
%   S = CODER.LOAD(FILENAME, VARIABLES) loads only the specified variables
%   from a MAT-file.  VARIABLES uses one of the following forms:
%
%       VAR1, VAR2, ...          Load the listed variables.  Use the '*'
%                                wildcard to match patterns.  For example,
%                                load('myfile.mat','A*') loads all
%                                variables that start with A.
%       '-regexp', EXPRESSIONS   Load only the variables that match the
%                                specified regular expressions.  For more
%                                information on regular expressions, type
%                                "doc regexp" at the command prompt.
%
%   S = CODER.LOAD(FILENAME, '-mat', VARIABLES) forces LOAD to treat the
%   file as a MAT-file, regardless of the extension.  Specifying VARIABLES
%   is optional.
%
%   S = CODER.LOAD(FILENAME, '-ascii') forces LOAD to treat the file as an
%   ASCII file, regardless of the extension.
%
%   Notes:
%
%   The value loaded is treated as a compile-time constant. To load values
%   at run-time, use the LOAD command.

%   Copyright 2007-2019 The MathWorks, Inc.

    S = builtin('load', varargin{:});
end
