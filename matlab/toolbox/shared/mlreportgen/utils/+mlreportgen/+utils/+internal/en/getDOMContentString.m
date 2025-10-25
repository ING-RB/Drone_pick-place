%mlreportgen.utils.internal.getDOMContentString concatenates all content from given DOM elements into a single string.
%
%   contentStr = mlreportgen.utils.internal.getDOMContentString(inlineElems)
%   extracts text content from each inline element in inlineElems,
%   specified as an array of inline DOM elements, strings or character
%   vectors. The functon combines the content into a single string. Image,
%   CustomElement, are CharEntity elements are skipped.

 
%   Copyright 2020-2021 The MathWorks, Inc.

