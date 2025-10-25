%importNode Import a node from one document into another
%    node = importNode(thisDoc,node,deep) imports a node from another
%    document into this document. Specifically, this method creates a copy
%    of the node to be imported, assigns ownership of the copy to this
%    document, and returns the copy. If the boolean argument deep is true,
%    the imported node is a deep copy of the source node; otherwise, it is
%    a shallow copy. The imported node has no parent. Use this document's
%    appendChild method to insert the imported node into the document tree.
%
%    node = importNode(thisDoc,node) imports a deep copy of the specified
%    node.
%
%    All imported nodes have the same node name, node type, namespace URI,
%    prefix, and local name as the source node. The imported node may have
%    additional information depending on its node type. The following list
%    describes the specific information copied for each type of node:
%
%    * ATTRIBUTE_NODE    
%      The ownerElement attribute is set to null and the specified flag is
%      set to true on the generated Attr object. The descendants of the
%      source Attr are recursively imported and the resulting nodes
%      reassembled to form the corresponding subtree. Note that the deep
%      argument has no effect on Attr nodes; they always carry their
%      children with them when imported.
%
%    * DOCUMENT_FRAGMENT_NODE
%      If the deep option is true, the descendants of the source
%      element are recursively imported and the resulting nodes reassembled
%      to form the corresponding subtree. Otherwise, this simply generates
%      an empty DocumentFragment.
%    
%    * DOCUMENT_NODE, DOCUMENT_TYPE_NODE
%      These types of nodes cannot be imported.
%
%    * ELEMENT_NODE
%      Specified attribute nodes of the source element are imported, and
%      the generated Attr nodes are attached to the generated Element node.
%      Default attributes are not copied. However, if the importing
%      document defines default attributes for the element being imported,
%      those attributes are assigned to the element. If the deep
%      argument is set to true, the descendants of the source element are
%      recursively imported and the resulting nodes reassembled to form the
%      corresponding subtree.
%
%    * ENTITY_NODE
%      Entity nodes can be imported. However, they cannot be added to the
%      document's DocumentType object because it is read-only. On import,
%      the publicId, systemId, and notationName attributes are copied. If a
%      deep import is requested, the descendants of the the source
%      Entity are recursively imported and the resulting nodes
%      reassembled to form the corresponding subtree.
%
%    * ENTITY_REFERENCE_NODE
%      Only the EntityReference itself is copied, even if a deep import
%      is requested, since the source and destination documents might have
%      defined the entity differently. If the importing document provides
%      a definition for the referenced entity, its value is assigned to the
%      imported entity reference.
%
%    * NOTATION_NODE
%      Notation nodes can be imported. However, they cannot be added to the
%      document's DocumentType, because it is read-only. On import, the
%      publicId and systemId attributes are copied. Note that the deep
%      argument has no effect on Notation nodes because they never have
%      children.
%
%    * PROCESSING_INSTRUCTION_NODE
%      The imported node copies its target and data values from those of
%      the source node.
%
%    * TEXT_NODE, CDATA_SECTION_NODE, COMMENT_NODE
%      These types of nodes copy their data and length attributes from
%      those of the source node.

%    Copyright 2020 MathWorks, Inc.
%    Built-in function.