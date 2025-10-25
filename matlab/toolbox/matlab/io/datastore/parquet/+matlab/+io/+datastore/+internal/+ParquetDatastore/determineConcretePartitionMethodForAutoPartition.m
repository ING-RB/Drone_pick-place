function concretePartitionMethod = determineConcretePartitionMethodForAutoPartition(readMode)
%determineConcretePartitionMethodForAutoPartition If the PartitionMethod is
% "auto", we can find the most suitable PartitionMethod.
%
% Currently we are choosing a ParitionMethod that would
% keep compatibility with previous parquetDatastore ReadSize.
% Previously ReadSize meant (ReadMode + implicit partitionMethod)

%   Copyright 2023 The MathWorks, Inc.

    switch(readMode)
      case "rowgroup"
        concretePartitionMethod = "rowgroup";
      case "numeric"
        concretePartitionMethod = "rowgroup";
      case "file"
        concretePartitionMethod = "file";
    end
end
