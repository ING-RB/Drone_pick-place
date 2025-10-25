function result = newCustomTask(file)
% newCustomTask - A project custom task.
%
% To create your own custom task, edit this function to perform the desired
% action on each file.
%
% Input arguments:
%  file - string - The absolute path to a file included in the custom task.
%  When you run the custom task, the project provides the file input for each
%  selected file.
%
% Output arguments:
%  result - user-specified type - The result output argument of your custom task.
%  The project displays the result in the Custom Task Results column.
%
% To use the custom task from the project:
%  1) On the Project tab, click Custom Task in the Tools Gallery.
%  2) Choose your custom task from the list.
%  3) Specify a report file used to save results.
%  4) Click Run Task.
%
% An example is shown below, which extracts Code Analyzer information for
% each file.


[~,~,ext] = fileparts(file);
switch ext
    case {'.m', '.mlx', '.mlapp'}
        result = checkcode(file, '-string');
    otherwise
        result = [];
end

end
