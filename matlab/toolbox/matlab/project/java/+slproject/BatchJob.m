classdef BatchJob < handle
    % BatchJob - Define project batch job.
    % To create a batch job, inherit from this class. You can run batch
    % jobs from the project tools or using the project API.
    %
    % The following example runs the checkcode function on files in the
    % batch job and returns any messages.
    % classdef CheckCodeBatchJob < slproject.BatchJob
    %     methods
    %         function initialize(~, ~, ~)
    %         end
    %         
    %         function result = run(~, file)
    %            problems = checkcode(file);
    %            result = [problems.message];
    %         end
    %         
    %         function finalize(~)
    %         end
    %     end
    % end
    
    % Copyright 2012-2021 The MathWorks, Inc.
    
    methods (Abstract = true, Access = public)
        
        % initialize - Initialization method for the batch job.
        % This method is called before the run method.
        %
        % Usage:
        %
        % obj.initialize(project, files, varargin)
        %
        % Where:
        %
        % project - slproject.ProjectManager - The project manager for the
        % project from which this batch job is being run.
        %
        % files - cell array of strings - A cell array of the absolute
        % paths for all the files included in this batch job.
        %
        initialize(obj, project, files)
        
        % run - Run method for the batch job.
        % When the batch job is run, this method is called once for each
        % file in the batch job.
        %
        % Usage:
        %
        % result = obj.run(file)
        %
        % Where:
        %
        % file - string - The absolute path to a file included in the 
        % batch job.
        %
        result = run(obj, file)
        
        % finalize - Finalization method for the batch job.
        % This method is called after the run method has been called for 
        % all files included in the batch job.
        %
        % Usage:
        %
        % obj.finalize()
        %
        finalize(obj)
        
    end
    
end

