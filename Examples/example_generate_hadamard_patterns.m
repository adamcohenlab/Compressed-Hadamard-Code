% Supplementary Software and Data
%
% Example: Generate Hadamard optical sectioning microscopy patterns, in
% complement interleaved fashion to implement compressed hadamard imaging
% as decribed in "Compressed Hadamard Microscopy for high-speed optically
% sectioned neuronal activity recordings", by Vicente J. Parot*, Carlos
% Sing-Long*, Yoav Adam, Urs L. Boehm, Linlin Z. Fan, Samouil L. Farhi, and
% Adam E. Cohen.
%
% Copyright 2016-2017 Vicente Parot
% 
% Permission is hereby granted, free of charge, to any person obtaining a
% copy of this software and associated documentation files (the
% "Software"), to deal in the Software without restriction, including
% without limitation the rights to use, copy, modify, merge, publish,
% distribute, sublicense, and/or sell copies of the Software, and to permit
% persons to whom the Software is furnished to do so, subject to the
% following conditions:      
% 
% The above copyright notice and this permission notice shall be included
% in all copies or substantial portions of the Software.    
% 
% THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
% OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
% MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN
% NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
% DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
% OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE
% USE OR OTHER DEALINGS IN THE SOFTWARE.      
%

addpath(fullfile('..','Acquisition','DMD pattern generation'))
addpath(fullfile('..','Analysis'))
addpath(fullfile('..','Other software'))
addpath(fullfile('..','Other software','Hadamard matrices'))

% Define number of orthogonal locations.
% Usually as n = m - 1 with m a multiple of 4,
% in any case, m>n patterns are generated, with m as low as possible.
% The offset defines how orthogonal locations distribute in space; they
% should be equidistant from each other to minimize scattering crosstalk
% nlocations_and_offset = [11 3]; % [n offset]
nlocations_and_offset = [19 5]; % [n offset]
% nlocations_and_offset = [27 6]; % [n offset]
% nlocations_and_offset = [35 10]; % [n offset]
% nlocations_and_offset = [59 09];  % [n offset]
% nlocations_and_offset = [63 14]; % [n offset]

% optional parameter binning to group projection elements
binning = [1 1];

% Generate a matrix of size [1024 768]. randomization is always the same.
patterns_logical = alp_btd_to_logical(hadamard_patterns_scramble_nopermutation(nlocations_and_offset,binning));

% mask to limit illumination to a region of interest
illum_mask = imread(fullfile('Illumination mask','0.png'))'; 

% Interleave with complement in 3rd dimension, store as vectorized movie
toint = {... % to interleave matrices in 3d, place them in a cell to then use the permute-cell2mat-permute-reshape method
     patterns_logical & illum_mask ,...
    ~patterns_logical & illum_mask };
hadamard_patterns = vm(reshape(permute(cell2mat(permute(toint,[1 4 3 2])),[1 2 4 3]),size(toint{1},1),size(toint{1},2),[]));

% Crop the matrix around ROI for easier visualization
hadamard_patterns = hadamard_patterns(541:610,111:180,:);

% Display patterns as imagej stack style. note there are 2*m frames
figure(1)
moviesc(hadamard_patterns)
title 'illumination patterns'

% Generate corresponding hadamard codes
hadamard_codes = hadamard_bincode_nopermutation(nlocations_and_offset(1))'*2-1;

% Calculate correlation maps by projection onto code matrix.
hadamard_correlation_map = (hadamard_patterns(2:2:end)-hadamard_patterns(1:2:end))*hadamard_codes/hadamard_patterns.frames*2;

% Note the number of frames in each dataset.
whos hadamard_*

% Display correlation maps. note there are n frames
figure(2)
moviefixsc(hadamard_correlation_map)
title 'correlation maps'