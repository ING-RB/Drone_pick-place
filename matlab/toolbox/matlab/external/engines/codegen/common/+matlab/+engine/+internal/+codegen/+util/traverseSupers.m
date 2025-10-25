function [fromNodes, toNodes] = traverseSupers(metaClass)
    %traverseSupers Traverses the superclasses of a given meta.class
    % and returns the the inheritance information as edges that can
    % be used to create a directed acyclic graph.
    % For example: g = digraph(fromNodes, toNodes)
    % where FromNodes(1) and ToNodes(1) describes an edge or inheritance
    % structure in the graph using

    arguments (Input)
        metaClass (1,1) meta.class
    end
    arguments (Output)
        fromNodes (1,:) string
        toNodes   (1,:) string
    end

    fromNodes = [];
    toNodes = [];

    supers = metaClass.SuperclassList;
    for k = 1:length(supers)
        % Get the superclass nodes of each superclass
        [fromNodesTemp, toNodesTemp] = matlab.engine.internal.codegen.util.traverseSupers(supers(k)); % recurse up 1 superclass level

        % Add superclass nodes, and self node to the list of edges
        fromNodes = [fromNodes, fromNodesTemp, string(supers(k).Name)];
        toNodes = [toNodes, toNodesTemp, string(metaClass.Name)];
    end

end