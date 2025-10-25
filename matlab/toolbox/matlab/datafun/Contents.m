% Data analysis and Fourier transforms.
%
% Basic operations.
%   sum          - Sum of elements.
%   prod         - Product of elements.
%   min          - Smallest component.
%   max          - Largest component.
%   clip         - Clip to range.
%   bounds       - Smallest and largest components.
%   isbetween    - Determine which elements are within specified range.
%   allbetween   - Determine whether all elements are within specified range.
%   mean         - Average or mean value.
%   median       - Median value.
%   prctile      - Percentiles.
%   quantile     - Quantiles.
%   iqr          - Interquartile range.
%   mode         - Mode, or most frequent value in a sample.
%   std          - Standard deviation.
%   var          - Variance.
%   sort         - Sort in ascending order.
%   sortrows     - Sort rows in ascending order.
%   issorted     - TRUE for sorted vector and matrices.
%   issortedrows - TRUE for matrices sorted by rows.
%   maxk         - Largest K components.
%   mink         - Smallest K components.
%   topkrows     - Top K sorted rows of matrix.
%   head         - Get first few rows of an array.
%   tail         - Get last few rows of an array.
%   summary      - Summary of an array.
%
% Moving and Cumulative statistics.
%   movsum       - Moving sum of elements.
%   movprod      - Moving product.
%   movmin       - Moving minimum.
%   movmax       - Moving maximum.
%   movmean      - Moving mean.
%   movmedian    - Moving median.
%   movstd       - Moving standard deviation.
%   movvar       - Moving variance.
%   movmad       - Moving median absolute deviation.
%   cumsum       - Cumulative sum of elements.
%   cumprod      - Cumulative product of elements.
%   cummin       - Cumulative smallest component.
%   cummax       - Cumulative largest component.
%
% Finite differences.
%   diff         - Difference and approximate derivative.
%   gradient     - Approximate gradient.
%   del2         - Discrete Laplacian.
%   trapz        - Trapezoidal numerical integration.
%   cumtrapz     - Cumulative trapezoidal numerical integration.
%
% Correlation.
%   corrcoef    - Correlation coefficients.
%   cov         - Covariance matrix.
%   subspace    - Angle between subspaces.
%   xcorr       - Cross-correlation.
%   xcov        - Cross-covariance.
%
% Filtering and convolution.
%   filter       - One-dimensional digital filter.
%   filter2      - Two-dimensional digital filter.
%   conv         - Convolution and polynomial multiplication.
%   conv2        - Two-dimensional convolution.
%   convn        - N-dimensional convolution.
%   deconv       - Deconvolution and polynomial division.
%   detrend      - Polynomial trend removal.
%
% Fourier transforms.
%   fft          - Discrete Fourier transform.
%   fft2         - Two-dimensional discrete Fourier transform.
%   fftn         - N-dimensional discrete Fourier Transform.
%   ifft         - Inverse discrete Fourier transform.
%   ifft2        - Two-dimensional inverse discrete Fourier transform.
%   ifftn        - N-dimensional inverse discrete Fourier Transform.
%   fftshift     - Shift zero-frequency component to center of spectrum.
%   ifftshift    - Inverse FFTSHIFT.
%   fftw         - Interface to FFTW library run-time algorithm tuning control.
%   nufft        - Nonuniform discrete Fourier transform.
%   nufftn       - N-dimensional nonuniform discrete Fourier transform.
%
% Missing data.
%   ismissing          - Find missing data.
%   standardizeMissing - Convert to standard missing data.
%   rmmissing          - Remove standard missing data.
%   fillmissing        - Fill standard missing data.
%   fillmissing2       - Fill standard missing data in two dimensions.
%
% Data preprocessing.
%   ischange     - Detect abrupt changes in data.
%   islocalmax   - Detect local maxima in data.
%   islocalmax2  - Detect local maxima in two dimensions.
%   islocalmin   - Detect local minima in data.
%   islocalmin2  - Detect local minima in two dimensions.
%   isoutlier    - Detect outliers in data.
%   isuniform    - Detect uniformly spaced data.
%   filloutliers - Replace outliers in data.
%   rmoutliers   - Remove outliers from data.
%   smoothdata   - Smooth noisy data.
%   smoothdata2  - Smooth noisy data in two dimensions.
%   trenddecomp  - Decompose data into trend, seasonal, and irregular components.
%   rescale      - Rescales the range of data.
%   normalize    - Normalizes data.
%
% Grouping.
%   discretize     - Group numeric data into bins or categories.
%   findgroups     - Find groups and return group numbers.
%   groupcounts    - Counts by group.
%   groupfilter    - Filter data by group.
%   groupsummary   - Summary computation by group.
%   grouptransform - Transformations by group.
%   histogram      - Histogram.
%   histcounts     - Histogram bin counts.
%   histogram2     - Bivariate histogram.
%   histcounts2    - Bivariate histogram bin counts.
%   pivot          - Summarize tabular data in a pivot table.
%   splitapply     - Split data into groups and apply function.
%
% Error metrics.
%   mape        - Mean absolute percentage error.
%   rmse        - Root mean squared error.

%   histc        - Histogram count.

%   Copyright 1984-2023 The MathWorks, Inc.
