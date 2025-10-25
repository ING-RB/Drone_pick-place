%MATLABDRIVE Root folder of MATLAB Drive
%   M = MATLABDRIVE returns the name of the folder that contains the content of your MATLAB
%   Drive. If MATLAB is unable to find the MATLAB Drive folder, MATLABDRIVE returns an error.
%
%   MATLABDRIVE is used to produce platform dependent paths to the
%   location of the root MATLAB Drive folder.
%
%   Example
%   Get the full path to the project/data folder in your MATLAB Drive folder for the current system.
%      fullfile(matlabdrive, 'project', 'data')
%
%   See also FULLFILE, PATH, TEMPDIR, PREFDIR, MATLABROOT

%   Copyright 2020 The MathWorks, Inc.
%   Built-in function.
