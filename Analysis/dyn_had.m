% Copyright 2018 Vicente Parot
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
function [sv, uhad, uref, uu] = dyn_had(obj_data, cal_data, ncomps)
%dyn_had   Dynamic hadamard demodulation. 
%   dyn_had(obj_data, cal_data, ncomps) analyzes a movie of a dynamic
%   object illuminated with periodic interleaved patterned illumination
%   using hadamard codes. Then, it calculates a low rank estimate of the
%   dynamic object movie as if illuminated uniformly, and a
%   hadamard-demodulated  optical section of the low rank dynamic object.
%
%   Input:
%       obj_data:   Matrix of size [npix nframes] with the patterned
%                   illumination movie, where npix is the number of pixels
%                   in the movie and nframes the number of timepoints. Odd
%                   frames should have been illuminated by a periodic
%                   repetition of the patterns in cal_data, while even
%                   frames should have been illuminated by their binary
%                   complement.
%       cal_data:	Matrix of size [npix hlen] with the calibration
%                   dataset, where hlen is the length of the hadamard code.
%       ncomps:     Number of PCA components to represent the dataset. This
%                   is an upper bound on the rank of the movie, so it
%                   should be enough to include as many as distinct
%                   dynamical objects are represented in the movie.
%
%   Output: data follows the notation of pca_eig, where a matrix M is
%       approximated by a truncated singular value decomposition U*S*V'.
%       sv:     Temporal functions of the dataset. The same temporal
%               functions are common to all output movies. These column
%               vectors incorporate their eigenvalue and thus sv is
%               orthogonal but not orthonormal. 
%       uhad:   Spatial functions demodulated from the patterned dataset,
%               representing the optical section. uhad*sv' is a matrix
%               of size [npix nframes] with an estimated movie of the
%               uniformly illuminated dynamical object optical section.
%       uref:   Spatial functions averaged from the patterned dataset,
%               representing the widefield reference. uref*sv' is a matrix
%               of size [npix nframes] with an estimated movie of the
%               uniformly illuminated dynamical object with no sectioning.
%       uu:     Spatial functions calculated by pca_eig from a filtered
%               version of obj_data. If correctly estimated, uref should be
%               similar to uu. uu*sv' approximates a filtered version of
%               obj_data that serves as a uniform illuminated reference for
%               extraction of dynamical signals.
%
%   See also vm, pca_eig, hadamard_bincode.
% 
%   2018 Vicente Parot
%   Cohen Lab - Harvard University

    mov_obj = vm(obj_data,[size(obj_data,1) 1]); % recast input matrix as vectorized movie with image dimensions [npix 1] (otherwise would need to know image dimensions, or require object inputs)
    hlen = size(cal_data,2); % hadamard code length
    interlen = hlen*2; % interleaved code length, double of hadamard length

    %% Filtered uniform movie
    % filter removes residual periodic illumination artifact from imperfect
    % illumination pattern projection
    ker = [0.5; ones([hlen-1 1]); 0.5]; % filter kernel, sliding window average
    ker = permute(ker,[3 2 1])./sum(ker);
    mov_obj_pairs = mov_obj.blnfun(@mean,2); % widefield movie from sum of pairs
    lf = mov_obj_pairs.imfilter(ker,'replicate'); % movie with low temporal frequency dynamics
    lf(lf<2) = 2; % avoid division errors
    nk = mov_obj_pairs(hlen/2+1:end-hlen/2).evnfun(@mean,hlen)./lf(hlen/2+1:end-hlen/2).evnfun(@mean,hlen); % extract normalized periodic component from movie
    nk = nk([hlen/2+1:end 1:hlen/2]); % rearrange frames in appropriate order
    % correct high-speed periodic intensity fluctuations. input movie must
    % have length of integer multiple of the pattern sequence. mov_uni has
    % half the frames of the input movie.
    mov_uni = mov_obj_pairs./nk.repmat([1 1 mov_obj_pairs.frames/hlen]); 
    % mov_uni should not have fluctuations that are periodic with the
    % period of the pattern sequence 

    %% Direct full estimation
    idx_map = mod((1:mov_obj.frames)-1,interlen)+1; % maps the frame index of the calibration data into the movie
    selftic = tic; % mark time before pca
    [uu, su, vu] = pca_eig(mov_uni(:,:),ncomps); % mov_uni is a uniform movie previously estimated.
    tpca = toc(selftic); % time after factorization
    uu = real(uu); % cast to avoid complex datatype from complex eigenvalues 
    sv = real(vu*su); % mov_uni(:,:) === uu*sv' where uu columns are orthonormal
    uhad = zeros([prod(mov_obj.imsz) ncomps]); % allocate memory for results
    uref = zeros([prod(mov_obj.imsz) ncomps]);
    residual_mov = mov_obj; % initialize residual as input movie
    disp 'estimating components ...'
    for comp = 1:ncomps % for each component of the USV decomposition
        sv3d = reshape(sv([1:end; 1:end],comp),1,1,[]); % arrange time trace along dimension 3
        ui = evnfun(residual_mov.*sv3d,@sum,interlen)./evnfun((mov_uni(1,1,[1:end; 1:end])*0+1).*sv3d.^2,@sum,interlen); % interpolate
        uhad(:,comp) = mean((ui(:,1:2:end) - ui(:,2:2:end)).*cal_data,2); % hadamard demodulation
        uref(:,comp) = mean(ui(:,:),2); % widefield reference
        residual_mov = residual_mov - ui(idx_map).*sv3d; % update residual
    end
    t_all = toc(selftic); % total time
    t_est = t_all-tpca; % time for estimation only 
    disp(['estimation took ' num2str(t_est) ' s, total ' num2str(t_all) ' s']);
