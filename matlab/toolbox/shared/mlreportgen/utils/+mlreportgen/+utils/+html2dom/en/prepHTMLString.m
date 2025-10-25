%PREPHTMLSTRING Prepares HTML string for conversion to DOM.
%   htmlStr = prepHTMLString(htmlStr) prepares the HTML string specified
%   by htmlStr for conversion to the MATLAB Report Generator's
%   internal document object model (DOM). This function corrects 
%   invalid markup and parses the HTML file to compute the element 
%   CSS properties specified by the file's style sheet and style 
%   attributes. It then generates an HTML string that can be converted 
%   to a DOM API representation, using a DOM HTML object.
%
%   htmlStr = prepHTMLString(htmlStr, "Tidy", false) is the same
%   as prepHTMLString(htmlStr) except it does not correct for invalid
%   HTML markup. 
%
%   See also mlreportgen.dom.HTML,
%   mlreportgen.utils.html2dom.prepHTMLFile,
%   mlreportgen.utils.tidy

     
    %   Copyright 2019-2020 Mathworks, Inc.

