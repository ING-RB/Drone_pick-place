function [sourceFiles, requiredFiles, status] = runFileAnalysisWithProgressDialog(sourceFiles)
    nodes = dependencies.internal.graph.Node.createFileNode([sourceFiles]);
    %progressDialog = dependencies.internal.widget.launchProgressDialog('analyzeAppDesignerFilesForProject', Debug=false);
    [graph, wasCancelled] = matlab.internal.project.creation.analyzeWithProgress(nodes);
    %progressDialog.close();
    sourceFiles = i_sortByNumberOfImpacted(sourceFiles, graph);
    requiredFiles = i_getRequiredFiles(sourceFiles, graph);
    status = ~wasCancelled;
end

function requiredFiles = i_getRequiredFiles (sourceFiles, graph)
    import dependencies.internal.graph.NodeFilter
    sourceFilesNodes = ...
        dependencies.internal.graph.Node.createFileNode(sourceFiles);
    requiredFilesFilter = ...
        NodeFilter.requiredBy(graph, sourceFilesNodes) & ...
        NodeFilter.nodeType("File") & ...
        NodeFilter.isResolved & ...
        ~NodeFilter.fileExtension(i_getDerivedExtensions());
    requiredFilesNodes = requiredFilesFilter.filter(graph.Nodes);
    requiredFiles = string([requiredFilesNodes.Location]);
end

function extensions = i_getDerivedExtensions ()
    extensions = "."+matlab.internal.project.creation.getDerivedExtensions();
end

function files = i_sortByNumberOfImpacted (files, graph)
    nodes = dependencies.internal.graph.Node.createFileNode(files);
    numberOfImpacted = arrayfun( ...
        @(node) i_getNumberOfImpacted(node, graph), nodes);
    [~, indices] = sort(numberOfImpacted);
    files = files(indices);
end

function number = i_getNumberOfImpacted (node, graph)
    import dependencies.internal.graph.NodeFilter
    filter = ...
        NodeFilter.impactedBy(graph, node) & ...
        NodeFilter.nodeType("File") & ...
        NodeFilter.isResolved;
    number = sum(filter.apply(graph.Nodes), "all");
end