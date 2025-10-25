%VISDIFF Compare two files or folders
%  VISDIFF(filename1,filename2) opens the Comparison Tool and presents the
%  differences between the two files or folders.
%
%  VISDIFF(filename1,filename2,type) opens the Comparison Tool and presents
%  the differences between the two files using the specified comparison
%  type. Supported options are 'xml', 'text' and 'binary'. This option does
%  not apply when comparing folders. If you do not specify a type, visdiff
%  uses the default comparison type for your selected files.
%
%  comparison = VISDIFF(...) compares two files and returns a comparison
%  object containing the differences between the two files. Use the
%  comparison object to generate reports programmatically. This syntax does
%  not open the Comparison Tool. Returning a comparison object is not 
%  supported for all comparison types. See visdiff documentation.
%
%  See also comparisons.Comparison

 
%  Copyright 1984-2023 The MathWorks, Inc.

