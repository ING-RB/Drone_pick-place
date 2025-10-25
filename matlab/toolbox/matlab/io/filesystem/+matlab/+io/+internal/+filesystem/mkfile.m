%MKFILE Make new zero-byte file.
%   [SUCCESS,MESSAGE,MESSAGEID] = MKFILE(NEWFILE) creates the file
%   NEWFILE in the current directory, if NEWFILE represents a relative path.
%   Otherwise, NEWFILE represents an absolute path and MKFILE attempts to
%   create the file at the absolute path specified by NEWFILE in the root
%   of the current volume.
%   An absolute path starts in any one of a Windows drive letter, a UNC
%   path '\\' or a UNIX '/' character.
%
%   INPUT PARAMETERS:
%       NEWFILE:   Character vector or string scalar specifying the new
%                  file.
%
%   Name-Value Pairs:
%   ---------------------------------------------------------------------
%   "ReplacementRule" - Preserve or overwrite  existing file
%                          - "overwrite" - Overwrite existing file if new
%                                          file has the same name as the
%                                          existing file.
%                          - "preserve"  - Preserve existing file, error
%                                          if new file has the same name
%                                          as existing file.
%
%   RETURN PARAMETERS:
%       SUCCESS:   Logical scalar, defining the outcome of MKFILE.
%                  1 : MKFILE executed successfully. 0 : an error occurred.
%       MESSAGE:   String scalar, defining the error or warning message.
%                  empty string scalar: MKFILE executed successfully. message :
%                  an error or warning message, as applicable.
%       MESSAGEID: String scalar, defining the error or warning identifier.
%                  empty string scalar: MKFILE executed successfully. message id:
%                  the MATLAB error or warning message identifier (see
%                  ERROR, MException, WARNING, LASTWARN).
%
%   NOTE 1: UNC paths are supported.
%
%   See also MKDIR

%   Copyright 2021 The MathWorks, Inc.