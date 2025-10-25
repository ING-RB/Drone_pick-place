%setInheritnumType Specify whether to use compound list item numbers in nested lists
%  setInheritnumType(lm,type) specifies whether the generated list will use
%  compound list item numbers in nested lists.
%     Acceptable values are:
%         "ignore"    - Do not use compound list item
%                       numbers for nested lists. For example:
%
%                               1. item 1
%                                   1. nested item 1
%                                   2. nested item 2
%                               2. item 2
%
%         "inherit"   - Use compound list item numbers for nested
%                       lists. For example:
%
%                               1. item 1
%                                   1.1 nested item 1
%                                   1.2 nested item 2
%                               2. item 2
%
%   See also https://tdg.docbook.org/tdg/4.5/orderedlist.html

% Copyright 2021 MathWorks, Inc.