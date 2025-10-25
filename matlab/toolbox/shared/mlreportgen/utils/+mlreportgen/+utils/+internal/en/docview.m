%DOCVIEW opens an RTF/DOC viewer.
%    DOCVIEW(FILENAME) will launch an RTF/DOC file viewer for the
%    file in FILENAME.
%
%    If called with the syntax [STATUS,MESSAGE]=DOCVIEW(FILENAME), STATUS
%    will return a 1 if the file viewer was launched correctly.  If the
%    viewer was not launched, DOCVIEW will return a 0 in STATUS and a
%    description of the error in MESSAGE.
%
%    If the computer is a PC with Microsoft Word, the following commands
%    may be called in the form DOCVIEW(FILENAME,COMMAND1,COMMAND2)
%      'updatefields' - updates fields in the document
%      'updatedocxfields' - updates fields in a docx document
%      'convertdocxtopdf' - converts a DOCX file to pdf (Windows only)
%      'showdocxaspdf'    - converts a DOCX file to pdf and displays it.
%                           (Windows only)
%      'unlinkdocxsubdoc' - removes all subdocument links and copies the
%                           subdocument content into the master document
%      'printdoc'         - prints the document
%      'printdocscaled'   - prints the document scaled to locale-specific 
%                           page size, e.g., US Letter or A4
%      'closeapp'         - closes Word after all other commands are run
%
%    See also RPTVIEWFILE

     
    %   Copyright 1997-2024 The MathWorks, Inc.

