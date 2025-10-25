function data = readallHadoop(ds, mr)
%readallHadoop    Set up readall to work on an HDFS cluster

%   Copyright 2020 The MathWorks, Inc.

    % Run calculation against gcmr using data locality information
    import matlab.bigdata.internal.executor.ExecutionTask
    import matlab.bigdata.internal.executor.DatastorePartitionStrategy
    import matlab.io.datastore.internal.read.ReadallProcessorFactory

    numOutputs = 1;
    N = numpartitions(ds);
    task = ExecutionTask.createAllToOneTask(...
        [], ReadallProcessorFactory(ds), numOutputs, ...
        "ExecutionPartitionStrategy", DatastorePartitionStrategy(ds, N));

    import matlab.io.datastore.internal.read.ReadallOutputHandler
    import matlab.bigdata.internal.executor.SimpleTaskGraph

    executor = mr.getPartitionedArrayExecutor();
    taskGraph = SimpleTaskGraph(task, task);
    outputHandler = matlab.io.datastore.internal.read.ReadallOutputHandler();
    executor.executeWithHandler(taskGraph, outputHandler);
    data = outputHandler.Data;
end