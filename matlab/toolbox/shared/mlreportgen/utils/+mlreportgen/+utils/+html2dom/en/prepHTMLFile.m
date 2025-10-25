%prepHTMLFile Preps an HTML file for conversion to DOM
%
%   preppedHTMLStr = prepHTMLFile(htmlFile) prepares the file specified
%   by htmlFile for conversion to the MATLAB Report Generator's
%   internal document object model (DOM). This function corrects 
%   invalid markup and parses the HTML file to compute the element 
%   CSS properties specified by the file's style sheet and style 
%   attributes. It then generates an HTML string that can be converted 
%   to a DOM API representation, using the DOM HTML object.
%
%   preppedHTMLStr = prepHTMLFile(htmlFile, "Tidy", false) is the same
%   as prepHTMLFile(htmlFile) except it does not correct for invalid
%   HTML markup.
%
%   preppedHTMLFile = prepHTMLFile(htmlFile, preppedHTMLFile) prepares 
%   the file specified by htmlFile for conversion to the MATLAB Report 
%   Generator's internal document object model (DOM). This function 
%   corrects invalid markup and parses the HTML file to compute the 
%   element CSS properties specified by the file's style sheet and style 
%   attributes. It then creates a prepped HTML file that can be converted 
%   to a DOM API representation, using the DOM HTMLFile object.
%
%   preppedHTMLStr = prepHTMLFile(htmlFile, preppedHTMLFile, "Tidy", false) 
%   is the same as prepHTMLFile(htmlFile, preppedHTMLFile) except it 
%   does not correct for invalid HTML markup.
%
%   See also mlreportgen.dom.HTMLFile,
%   mlreportgen.dom.HTML
%   mlreportgen.utils.html2dom.prepHTMLString
%   mlreportgen.utils.tidy

     
    %   Copyright 2019-2023 Mathworks, Inc.

