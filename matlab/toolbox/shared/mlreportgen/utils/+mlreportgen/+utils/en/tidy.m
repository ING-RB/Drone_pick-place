%mlreportgen.utils.tidy Corrects and cleans up XML/HTML content
%
%   OUTSTR = mlreportgen.utils.tidy(STR) corrects and cleans XHTML STR
%
%   OUTSTR = mlreportgen.utils.tidy(STR, "OutputType", OUTPUTTYPE) corrects and 
%       cleans STR to OUTPUTTYPE.  OUTPUTTYPE can be "xml", "html", or "xhtml";
%
%   OUTSTR = mlreportgen.utils.tidy(STR, "ConfigFile", CONFIGFILE) corrects and 
%       cleans STR using CONFIGFILE options.  CONFIGFILE options
%       override OutputType parameter.  Default TIDY CONFIGFILEs are located
%       in matlab/toolbox/shared/mlreportgen/utils/resources folder.
%
%   OUTFILE = mlreportgen.utils.tidy(FILE) corrects and cleans XHTML FILE
%
%   OUTFILE = mlreportgen.utils.tidy(FILE, "OutputFile", OUTPUTFILE) 
%       corrects and cleans XHTML file and saves to OUTPUTFILE.
%
%   OUTSTR = mlreportgen.utils.tidy(FILE, "OutputType", OUTPUTTYPE) corrects and 
%       cleans FILE to OUTPUTTYPE.  OUTPUTTYPE can be "xml", "html", or "xhtml";
%
%   OUTSTR = mlreportgen.utils.tidy(FILE, "ConfigFile", CONFIGFILE) corrects and 
%       cleans FILE using CONFIGFILE options. CONFIGFILE option overrides 
%       OutputType parameter. Default TIDY CONFIGFILEs are located in 
%       matlab/toolbox/shared/mlreportgen/utils/resources folder.

     
    % Copyright 2018-2023 The MathWorks, Inc.

