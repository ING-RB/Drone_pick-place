%mlreportgen.dom.TransientNode Defines a document TransientNode
%     A document node is an object that a document can contain and that
%     itself contains other objects.
%
%     TransientNode properties:
%         Children - Children of this node
%         Id       - Id of this node
%         Parent   - Parent of this node
%         Tag      - Id of this node

%     Copyright 2019 Mathworks, Inc.
%     Built-in class

%{
properties
     %Children Children of this document element
     %      Array of the elements that are children of this element. This
     %      property is read-only.
     Children;

     %Parent Parent of this document element
     %      The element that contains this element. An element may have 
     %      only one parent. This property is read-only.
     Parent;

end
%}