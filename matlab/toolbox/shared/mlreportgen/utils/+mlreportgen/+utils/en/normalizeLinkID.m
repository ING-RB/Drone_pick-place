%mlreportgen.utils.normalizeLinkID Normalize a link target ID
%   outID = mlreportgen.utils.normalizeLinkID(inID) converts the input
%   link target ID to an ID that is valid for DOCX, PDF, and HTML
%   reports. The output ID consists of an MD5 hash of the input ID
%   with "mw_" prefixed to the hash. The generated ID conforms to
%   the DOCX limitation on ID length and the PDF requirement that
%   an ID begin with an alphabetic character.

 
%   Copyright 2019 The MathWorks, Inc.

