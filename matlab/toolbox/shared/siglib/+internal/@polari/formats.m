function formats
%FORMATS Supported data entry formats for polar data.
%  POLARPATTERN supports a number of data formats for polar display.
%
%  POLARPATTERN(D) creates polar plot based on matrix D.
%    Real length-M vector: D contains M magnitude values, with
%    angle assumed to be (0:M-1)/M*360 degrees.
%    Real MxN matrix: Columns of D contain M magnitude values
%      for N independent datasets, each column having the same
%      angle taken from the vector (0:M-1)/M*360 degrees.
%    Complex vector or matrix: D contains Cartesian coordinates
%      (x,y) of each point, where x=real(D) and y=imag(D). Each
%      complex value is converted to magnitude and angle for
%      display.  The set of angles can vary for each column if
%      D is a matrix.
%
% Magnitudes may be positive or negative when D is real; the
% radial axis is scaled such that the lowest (nearest -inf)
% value is at the origin and the highest (nearest +inf) value
% is at the outermost radius of the polar plot.  Negative
% magnitude values typically arise when data is passed in
% logarithmic form such as dB.
%
% POLARPATTERN(A,M) creates a polar plot where real vector A contains
% a set of angles in degrees and real vector M contains
% corresponding magnitudes.  For a matrix M, each column is an
% independent set of magnitudes, and all columns correspond to
% the same set of angles A.
%
% POLARPATTERN(A1,M1,A2,M2, ...) creates a polar plot from multiple
% data sets, where real vectors A1, A2, ... contain angles in
% degrees, and real matrices M1, M2, ... contain corresponding
% magnitudes.  Each matrix Mi must have its number of rows
% equal to the length of Ai, while A1, A2, ... may differ in
% length and value.  This supports non-uniformly sampled data.
%
% If magnitude data has units of "dB loss", set the DataUnits
% property to 'db loss', or use the Display > Data Units
% context menu.
%
% POLARPATTERN(A,R,IM) specifies angle vector A, magnitude vector R,
% and intensity matrix IM.  A must have length equal to
% size(IM,1), and R must have length equal to size(IM,2).  Only
% one intensity matrix may be displayed.
%
% All data formats work with the <a href="matlab:help internal.polari.add">add</a>, <a href="matlab:help internal.polari.replace">replace</a> and <a href="matlab:help internal.polari.animate">animate</a> functions.
%
% See also polarpattern

help internal.polari/formats
