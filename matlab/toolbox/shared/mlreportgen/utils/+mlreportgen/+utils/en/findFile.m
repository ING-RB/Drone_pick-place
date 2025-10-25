%mlreportgen.utils.findFile Returns full file path
%
%    filePath = mlreportgen.utils.findFile(FILENAME) returns full 
%       file path for FILENAME. FILENAME can be a name with or 
%       without an extension.
%    
%    filePath = mlreportgen.utils.findFile(FILENAME, ...
%       'FileExtensions', [ext1, ext2]) returns filepath to FILENAME.
%       mlreportgen.utils.findFile uses specified file extensions to 
%       help find the filePath to FILENAME.
%
%	 filePath = mlreportgen.utils.findFile(FILENAME, ...
%       'FileMustExist', false) returns the filePath to FILENAME 
%       even if FILENAME does not exist. mlreportgen.utils.findFile 
%       returns the filePath as if FILENAME exists.

     
    %   Copyright 2017-2019 The MathWorks, Inc.

