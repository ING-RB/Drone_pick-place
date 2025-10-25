function times = bench(count)
%BENCH  MATLAB Benchmark
%   BENCH times five different MATLAB tasks and compares the execution
%   speed with the speed of several other computers.  The five tasks are:
%
%    LU         LAPACK.                          Floating point, regular memory access.
%    FFT        Fast Fourier Transform.          Floating point, irregular memory access.
%    ODE        Ordinary diff. eqn.              Data structures and functions.
%    Sparse     Solve sparse system.             Sparse linear algebra.
%    Graphics   General graphics benchmark       Update graphics objects in a loop.
%
%   A final bar chart shows speed, which is inversely proportional to
%   time.  Here, longer bars are faster machines, shorter bars are slower.
%
%   BENCH runs each of the five tasks once.
%   BENCH(N) runs each of the five tasks N times.
%   BENCH(0) just displays the results from other machines.
%   T = BENCH(N) returns an N-by-5 array with the execution times.
%
%   The comparison data for other computers is stored in a text file:
%     fullfile(matlabroot, 'toolbox','matlab','general','bench.dat')
%
%   Fluctuations of five or 10 percent in the measured times of repeated
%   runs on a single machine are not uncommon.  Your own mileage may vary.
%
%   This benchmark is intended to compare performance of one particular
%   version of MATLAB on different machines.  It does not offer direct
%   comparisons between different versions of MATLAB.  The tasks and
%   problem sizes change from version to version.
%
%   The graphics tasks measure graphics performance, including software
%   or hardware support for OpenGL.  The command opengl info describes the
%   OpenGL support available on a particular machine.

%   Copyright 1984-2025 The MathWorks, Inc.

if nargin < 1, count = 1; end
times = zeros(count,5);
fig1 = figure;
set(fig1,'pos','default','menubar','none','numbertitle','off', ...
    'name',getString(message('MATLAB:bench:MATLABBenchmark')));
hax1 = axes('position',[0 0 1 1],'parent',fig1);
axis(hax1,'off');
text(.5,.6,getString(message('MATLAB:bench:MATLABBenchmark')),'parent',hax1,'horizontalalignment','center','fontsize',18)
task = text(.50,.42,'','parent',hax1,'horizontalalignment','center','fontsize',18);
drawnow
pause(1);

% Use a private stream to avoid resetting the global stream
stream = RandStream('mt19937ar');

problemsize = zeros(1, 4);

bench_lu(stream);
bench_fft(stream);
bench_ode;
bench_sparse;
bench_graphics(false);

for k = 1:count
    
    % LU, n = 5200.
    set(task,'string',getString(message('MATLAB:bench:LU')))
    drawnow
    [times(k,1), problemsize(1)] = bench_lu(stream);
    
    % FFT, n = 2^25.    
    set(task,'string',getString(message('MATLAB:bench:FFT')))
    drawnow
    [times(k,2), problemsize(2)] = bench_fft(stream);
    
    % ODE. van der Pol equation, mu = 1
    set(task,'string',getString(message('MATLAB:bench:ODE')))
    drawnow
    [times(k,3), problemsize(3)] = bench_ode;
    
    % Sparse linear equations
    set(task,'string',getString(message('MATLAB:bench:Sparse')))
    drawnow
    [times(k,4), problemsize(4)] = bench_sparse;
    
    % Graphics
    set(task,'string',getString(message('MATLAB:bench:GFX')))
    drawnow
    pause(1)
    times(k,5) = bench_graphics(true);
    
end  % loop on k

% Compare with other machines.

if exist('bench.dat','file') ~= 2
    warning(message('MATLAB:bench:noDataFileFound'))
    return
end
fp = fopen('bench.dat', 'rt');

% Skip over headings in first four lines.
for k = 1:4
    fgetl(fp);
end

% Read the comparison data

specs = {};
T = [];
details = {};
g = fgetl(fp);
m = 0;
desclength = 65;
while length(g) > 1
    m = m+1;
    specs{m} = g(1:desclength); %#ok<AGROW>
    T(m,:) = sscanf(g((desclength+1):end),'%f')'; %#ok<AGROW>
    details{m} = fgetl(fp); %#ok<AGROW>
    g = fgetl(fp);
end

% Close the data file
fclose(fp);

% Determine the best 10 runs (if user asked for at least 10 runs)
if count > 10
    warning(message('MATLAB:bench:display10BestTrials', count));
    totaltimes = 100./sum(times, 2);
    [~, timeOrder] = sort(totaltimes, 'descend'); 
    selected = timeOrder(1:10);
else
    selected = 1:count;
end

meanValues = mean(T, 1);

% Add the current machine and sort
T = [T; times(selected, :)];
this = [zeros(m,1); ones(length(selected),1)];
if count==1
    % if a single BENCH run
    specs(m+1) = {getString(message('MATLAB:bench:ThisMachine', repmat(' ', 1, desclength-12)))};
    details{m+1} = getString(message('MATLAB:bench:YourMachine', version));
else
    for k = m+1:size(T, 1)
        ind = k-m; % this varies 1:length(selected)
        sel = num2str(selected(ind));
        specs(k) = {getString(message('MATLAB:bench:ThisMachineRunN', sel, repmat(' ', 1, desclength-18-length(sel))))}; %#ok<AGROW>
        details{k} = getString(message('MATLAB:bench:YourMachineRunN', version, sel));         %#ok<AGROW>
    end
end
scores = mean(bsxfun(@rdivide, T, meanValues), 2);
m = size(T, 1);

% Normalize by the sum of meanValues to bring the results in line with
% earlier implementation 
speeds = (100/sum(meanValues))./(scores);
[speeds,k] = sort(speeds);
specs = specs(k);
details = details(k);
T = T(k,:);
this = this(k);

% Modify string padding for machine names to be used as labels
specsLabels = strtrim(string(specs));
specsLabels = pad(specsLabels, max(strlength(specsLabels))+5, 'left');

% Horizontal bar chart. Highlight this machine with another color.

clf(fig1)

% Stretch the figure's width slightly to account for longer machine
% descriptions
units1 = get(fig1, 'Units');
set(fig1, 'Units', 'normalized');
pos1 = get(fig1, 'Position');
set(fig1, 'Position', pos1 + [-0.1 -0.1 0.2 0.1]);
set(fig1, 'Units', units1);

hax2 = axes('position',[.4 .1 .5 .8],'parent',fig1);
barh(hax2,speeds.*(1-this))
hold(hax2,'on')
barh(hax2,speeds.*this)
set(hax2,'xlim',[0 max(speeds)+.1],'xtick',0:10:max(speeds))
title(hax2,getString(message('MATLAB:bench:RelativeSpeed')))
axis(hax2,[0 max(speeds)+.1 0 m+1])
set(hax2,'ytick',1:m)
set(hax2,'yticklabel',specsLabels,'fontsize',9)
set(hax2,'OuterPosition',[0 0 1 1]);

% Display report in second figure
fig2 = figure('pos',get(fig1,'pos')+[50 -150 50 0], 'menubar','none', ...
    'numbertitle','off','name',getString(message('MATLAB:bench:MATLABBenchmarkTimes')));

% Defining layout constants - change to adjust 'look and feel'
% The names of the tests
TestNames = {getString(message('MATLAB:bench:LU')), ...
    getString(message('MATLAB:bench:FFT')), ...
    getString(message('MATLAB:bench:ODE')), ...
    getString(message('MATLAB:bench:Sparse')), ...
    getString(message('MATLAB:bench:GFX'))};

testDatatips = {getString(message('MATLAB:bench:LUOfMatrix', problemsize(1), problemsize(1))),...
    getString(message('MATLAB:bench:FFTOfVector', problemsize(2))),...
    getString(message('MATLAB:bench:SolutionFromTo', problemsize(3))),...
    getString(message('MATLAB:bench:SolvingSparseLinearSystem', problemsize(4), problemsize(4))),...    
    getString(message('MATLAB:bench:BernsteinPolynomialGraph')),...
    getString(message('MATLAB:bench:AnimatedLshapedMembrane'))};
% Number of test columns
NumTests = size(TestNames, 2);
NumRows = m+1;      % Total number of rows - header (1) + number of results (m)
TopMargin = 0.05; % Margin between top of figure and title row
BotMargin = 0.20; % Margin between last test row and bottom of figure
LftMargin = 0.03; % Margin between left side of figure and Computer Name
RgtMargin = 0.03; % Margin between last test column and right side of figure
CNWidth = 0.40;  % Width of Computer Name column
MidMargin = 0.03; % Margin between Computer Name column and first test column
HBetween = 0.005; % Distance between two rows of tests
WBetween = 0.015; % Distance between two columns of tests
% Width of each test column
TestWidth = (1-LftMargin-CNWidth-MidMargin-RgtMargin-(NumTests-1)*WBetween)/NumTests;
% Height of each test row
RowHeight = (1-TopMargin-(NumRows-1)*HBetween-BotMargin)/NumRows;
% Beginning of first test column
BeginTestCol = LftMargin+CNWidth+MidMargin;

% Create headers

% Computer Name column header
uicontrol(fig2,'Style', 'text', 'Units', 'normalized', ...
    'Position', [LftMargin 1-TopMargin-RowHeight CNWidth RowHeight],...
    'String',  getString(message('MATLAB:bench:LabelComputerType')), 'Tag', 'Computer_Name','FontWeight','bold');

% Test name column header
for k=1:NumTests
    uicontrol(fig2,'Style', 'text', 'Units', 'normalized', ...
        'Position', [BeginTestCol+(k-1)*(WBetween+TestWidth) 1-TopMargin-RowHeight TestWidth RowHeight],...
        'String', TestNames{k}, 'Tag', TestNames{k}, 'FontWeight', 'bold', ...
        'Tooltip', testDatatips{k});
end
% For each computer
for k=1:NumRows-1
    VertPos = 1-TopMargin-k*(RowHeight+HBetween)-RowHeight;
    if this(NumRows - k)
        thecolor = '--mw-color-emphasized';
    else
        thecolor = '--mw-color-primary';
    end
    % Computer Name row header
    u = uicontrol(fig2,'Style', 'text', 'Units', 'normalized', ...
        'Position', [LftMargin VertPos CNWidth RowHeight],...
        'String', specs{NumRows-k}, 'Tag', specs{NumRows-k},...
        'Tooltip', details{NumRows-k}, 'HorizontalAlignment', 'left');
    matlab.graphics.internal.themes.specifyThemePropertyMappings(u, 'ForegroundColor', thecolor);
    % Test results for that computer
    for n=1:NumTests
        u = uicontrol(fig2,'Style', 'text', 'Units', 'normalized', ...
            'Position', [BeginTestCol+(n-1)*(WBetween+TestWidth) VertPos TestWidth RowHeight],...
            'String', sprintf('%.4f',T(NumRows-k, n)), ...
            'Tag', sprintf('Test_%d_%d',NumRows-k,n));
        matlab.graphics.internal.themes.specifyThemePropertyMappings(u, 'ForegroundColor', thecolor);
    end
end

% Warning text
uicontrol(fig2, 'Style', 'text', 'Units', 'normalized', ...
    'Position', [0.01 0.01 0.98 BotMargin-0.02], 'Tag', 'Disclaimer', ...
    'String', getString(message('MATLAB:bench:sprintf_PlaceTheCursorNearAComputerNameForSystemAndVersionDetai')) );

set([fig1 fig2], 'NextPlot', 'new');

% Log selected bench data
logBenchData(times(selected, :));

end
% ----------------------------------------------- %
function dydt = vanderpol(~,y)
%VANDERPOL  Evaluate the van der Pol ODEs for mu = 1
dydt = [y(2); (1-y(1)^2)*y(2)-y(1)];
end

function [t, n] = bench_lu(stream)
% LU
n = 5200;
reset(stream,0);
A = randn(stream,n,n);
tic
B = lu(A); 
t = toc;
end
% ----------------------------------------------- %
function [t, n] = bench_fft(stream)
% FFT
n = 2^25;
reset(stream,1);
x = randn(stream,1,n);
tic;
y = fft(x);
t = toc;
end


% ----------------------------------------------- %
function [t, n] = bench_ode
% ODE. van der Pol equation, mu = 1
F = @vanderpol;
y0 = [2; 0]; 
tspan = [0 eps];
[s,y] = ode45(F,tspan,y0);  %#ok Used  to preallocate s and y
tspan = [0 15000];
n = tspan(end);
tic
[s,y] = ode45(F,tspan,y0); %#ok Results not used -- strictly for timing
t = toc;
end
% ----------------------------------------------- %
function [t, n] = bench_sparse
% Sparse linear equations
n = 600;
A = delsq(numgrid('L',n));
n = size(A, 1);
b = sum(A)';
tic
x = A\b; %#ok Result not used -- strictly for timing
t = toc;
end
% ----------------------------------------------- %
function t = bench_graphics(isVisible)
% General graphics benchmark. Animate a line, update CData for image,
% rotate a surface, and translate scatter data.
lfigure = figure();
if isVisible
    lfigure.Visible = 'on';
else
    lfigure.Visible = 'off';
end

% Restore seed before setting it.
seed = rng;
cleanup = onCleanup(@()rng(seed));

nSteps = 15;

tl = tiledlayout(lfigure,2,2,'Padding','compact','TileSpacing','compact');

%% Animated line for scope like displays
ax1 = nexttile(tl,1);
nPoints = 3e3;
theta = linspace(0,2*pi,nPoints);
a = [2 3 3 1];
b = [1, 2, 4, 4];
lj_skip = nPoints / nSteps;

al = gobjects(4);
for i=1:4
    al(i) = animatedline('Parent',ax1,'LineStyle','-','SeriesIndex', i);
end

set(ax1,'XLim',[-1.1 1.1],'YLim',[-1.1 1.1],'Box','on');
title(ax1, 'Lissajous Plot');

%% Create Image
ax2 = nexttile(tl,2);
rng(0,'twister');
numImagePixels = 100; 
m = randn(numImagePixels);
mf = fftshift(fft2(m));
paramA = 2; 
d = ((1:numImagePixels)-(numImagePixels/2)-1).^2;
dd = sqrt(d(:) + d(:)');
filt = dd .^ -paramA; 
filt(isinf(filt))=1;
ff = mf .* filt;
s = ifft2(ifftshift(ff));
S = rescale(s,-1,1);
img = imagesc(ax2, S);
axis(ax2,'equal', 'tight');
colormap(ax2, 'sky');
title(ax2,'Cloud Image');

%% Rotating a Surface using hgtransform
ax3 = nexttile(tl,3);
tf_membrane = hgtransform(ax3);
ssz = 150;
m = membrane(1,ssz);
span = linspace(-1, 1, size(m,1));
surface(span, span, m, 'parent', tf_membrane);
shading(ax3,'interp');
box(ax3, 'on');
view(ax3, 3);
tf_membrane.Matrix = makehgtform('zrotate',pi/4); % just to compute limits
axis(ax3, 'tight', 'manual');
tf_membrane.Matrix = makehgtform;
title(ax3, 'Membrane')

%% Scatter Chart / Point Cloud pan display
ax4 = nexttile(tl,4);
tf_scatter = hgtransform(ax4);
x = randn(nPoints,1);
y = -1.5*x + randn(nPoints,1);
z = 1.5*x + randn(nPoints,1);
scatter3(x,y,z,[],-hypot(hypot(x,y),z),'.','parent',tf_scatter);
box(ax4, 'on');
colormap(ax4,turbo)
title(ax4, 'Point Cloud')
axis([-9 9 -9 9 -9 9]);

% Turn off some ticks to keep layout stable
xticks([ax3 ax4],[]);
yticks([ax3 ax4],[]);
zticks([ax3 ax4],[]);

% Turn off Interactions and Toolbar to improve creation time performance.
set([ax1 ax2 ax3 ax4], 'Toolbar', [], 'Interactions', []);

% Set limit modes on axes to 'manual' so they don't have to be computed.
set([ax1 ax2 ax3 ax4], 'XLimMode', 'manual', 'YLimMode', 'manual', 'ZLimMode', 'manual', ...
    'CLimMode', 'manual', 'ALimMode', 'manual');

drawnow;
tStart = tic;

%% Animate each item
for i =  1:nSteps
    % Animated Line update
    ix = (i-1)*lj_skip+1;
    for k = 1:4
        addpoints(al(k), sin(a(k).*theta(ix:ix+lj_skip-1)),...
            sin(b(k).*theta(ix:ix+lj_skip-1)));
    end

    % Update CData for Image to cause cloud to wrap
    set(img, 'CData', S(:,[i:end 1:i-1]));

    % Rotate the surface
    tf_membrane.Matrix = makehgtform('zrotate',i*2*pi/nSteps);

    % Pan the scatter / point cloud
    x = cospi(i*2/nSteps);
    y = sinpi(i*4/nSteps);
    tf_scatter.Matrix = makehgtform('translate',[x y 0]);

    drawnow;
end
t=toc(tStart);
close(lfigure);
end