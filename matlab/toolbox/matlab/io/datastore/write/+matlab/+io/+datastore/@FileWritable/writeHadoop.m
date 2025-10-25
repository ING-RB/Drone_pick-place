function writeHadoop(ds, location, compressStr, mr, nvStruct)
%writeHadoop    Set up writeall to work on an HDFS cluster
%

%   Copyright 2023 The MathWorks, Inc.
    origFileSep = ds.OrigFileSep;
    writeFcn = @(subds, partitionIndex) subds.writeSerial(location, ...
        compressStr.getCompressedString(partitionIndex, origFileSep), nvStruct);
 
    % Run calculation against gcmr using data locality information
    import matlab.bigdata.internal.executor.ExecutionTask
    import matlab.bigdata.internal.executor.FullfileDatastorePartitionStrategy
    import matlab.io.datastore.write.WriteallProcessorFactory
    import matlab.io.datastore.write.WriteallProcessor

    numOutputs = 1;
    task = ExecutionTask.createSimpleTask(...
        [], WriteallProcessorFactory(ds, writeFcn), numOutputs, ...
        "ExecutionPartitionStrategy", FullfileDatastorePartitionStrategy(ds));

    import matlab.bigdata.internal.executor.OutputHandler
    import matlab.bigdata.internal.executor.SimpleTaskGraph

    executor = mr.getPartitionedArrayExecutor();
    executor.executeWithHandler(SimpleTaskGraph(task, task), OutputHandler.empty());
end
