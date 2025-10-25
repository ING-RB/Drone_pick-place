%setContent Set list content
%  setContent(lm,content) specifies the content to be made into a list.
%  The content must be specified as a cell array that contains any of the
%  following types of content:
%         - Character vectors
%         - Strings
%         - Numeric values
%         - DocBoox XML Paragraph elements
%         - DocBook XML Text nodes
%         - DocBook XML Link elements
%
%     To create a nested list, specify content as a nested cell array. For
%     example, if content is specified as {'item1', {'nestedItem1',
%     'nestedItem2'}, 'item2'}, the generated list will have the following
%     layout:
%
%         1. item1
%             1. nestedItem1
%             2. nestedItem2
%         2. item2

% Copyright 2021 MathWorks, Inc.