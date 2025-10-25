%PDFMANAGE Control opening/reopening and closing of PDF files
%   This function manages (e.g., opens, closes, etc.) report generator 
%   PDF viewer.
%
%   Usage:
%       pdfmanage(action);
%       pdfmanage(action, filename);
% 
%   action   => indicates the operation to perform upon filename
%               action may be any one of the following strings:
%   filename => indicates which PDF file is being operated upon
%
%       All platforms:
%                   'open'          : opens the file in a viewer
%                                   : - returns false (0) for failure;
%                                   : - returns true (1) for success;
%                                   : - returns true (2) if file was already
%                                   :   open
%                   'close'         : closes the viewer if the given
%                                   :  file is open OR no file is given OR 
%                                   :  filename == 'all'
%                                   : - returns false (0) for failure;
%                                   : - returns true (1) for success;
%                                   : - returns true (2) if file was already
%                                   :   open
%                   'islocked'      : - returns true if the file is locked
%                                   :   by another process
%                   'isopen'        : - returns true if the file is open in
%                                   :   the PDF viewer
%               'isvieweravailable' : - returns true always

 
%   Copyright 2018 The MathWorks, Inc.

