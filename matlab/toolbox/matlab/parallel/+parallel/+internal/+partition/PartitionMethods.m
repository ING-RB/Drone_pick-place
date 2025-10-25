% Enumeration of the different ways to split a parallel pool

% Copyright 2024 The MathWorks, Inc.

classdef PartitionMethods

    properties
        PartitionMethod
    end

    enumeration
        Workers(parallel.internal.partition.PartitionMethodWorkers)
        MaxNumWorkersPerHost(parallel.internal.partition.PartitionMethodMaxNumWorkersPerHost)
        MaxNumWorkersPerGPU(parallel.internal.partition.PartitionMethodMaxNumWorkersPerGPU)
    end

    methods
        function obj = PartitionMethods(partitionMethod)
            arguments
                partitionMethod (1,1) parallel.internal.partition.PartitionMethod
            end
            obj.PartitionMethod = partitionMethod;
        end
    end

    methods (Static)
        function allowedPartitionMethods = listMethods()
            class = ?parallel.internal.partition.PartitionMethods;
            allowedPartitionMethods = {class.EnumerationMemberList.Name};
        end

        function partitionWorkers = getPartitionWorkers(name, pool, argument)
            try 
                allowedPartitionMethods = parallel.internal.partition.PartitionMethods.listMethods();
                if ~ismember(name, allowedPartitionMethods)
                    error(message("MATLAB:parallel:pool:InvalidPartitionMethod", ...
                        strjoin(strcat('"', allowedPartitionMethods, '"'), ", ")));
                end
                method = parallel.internal.partition.PartitionMethods.(name);
                method.PartitionMethod.validateArguments(pool, argument);
                partitionWorkers = method.PartitionMethod.partitionWorkers(pool, argument);
            catch E
                throwAsCaller(E);
            end
        end
    end
end
