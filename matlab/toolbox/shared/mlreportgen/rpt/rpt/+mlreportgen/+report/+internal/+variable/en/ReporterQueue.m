classdef ReporterQueue< handle
% ReporterQueue manages a queue of variable reporters. It has methods
% for initiating a queue, appending reporters to the queue, and
% sequentially executing the reporters. A reporter queue makes it
% possible to linearize reporting of hierarchical objects, such as
% cell arrays and MCOS objects. In particular, this can be done by
% initializing the queue with a hierarchical object reporter that
% generates and appends to the queue reporters for each of the objects
% embedded in the variable owned by the object. Running the queue
% executes the toplevel reporter which adds reporters to the queue that
% themselves may add reporters to the queue. The queue runs until it is
% exhausted or reaches an optional reporter object limit.
%
% ReporterQueue is a singleton class. Use the static method
% mlreportgen.report.internal.variable.ReporterQueue.instance to get
% the queue instance.

     
    % Copyright 2018 The MathWorks, Inc.

    methods
        function out=ReporterQueue
        end

        function out=add(~) %#ok<STOUT>
            % add(this, reporter) adds reporter to the end the queue
        end

        function out=clear(~) %#ok<STOUT>
            % clear(this) empties the queue of any reporters left from the
            % previous run.
        end

        function out=getReporterID(~) %#ok<STOUT>
            % id = getReporterID(this) returns a unique id for the reporter
        end

        function out=init(~) %#ok<STOUT>
            % init(this, reportOptions, varName, varValue) clears
            % the queue, creates a reporter for the specified varName/Value,
            % and adds it to the queue.
        end

        function out=instance(~) %#ok<STOUT>
            % instance = instance() Static method to return the
            % persistent reporter queue object.
        end

        function out=pop(~) %#ok<STOUT>
            % reporter = pop(this) pops the reporter from the front of the
            % queue and returns it.
        end

        function out=run(~) %#ok<STOUT>
            % content = run(this) executes the reporters in the queue
            % until there are no more reporters or it reaches the limit
            % specified by the report options object limit. This function
            % also returns the content after executing all the reporters in
            % the queue.
        end

    end
    properties
        % The reporter queue with FIFO implementation
        FIFO;

    end
end
