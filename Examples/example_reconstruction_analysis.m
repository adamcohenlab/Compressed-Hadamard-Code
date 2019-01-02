% Supplementary Software and Data
%
% Example: From raw patterned illumination data, calculate Hadamard optical
% section movie, extract activity signals from an ROI, display in a figure.
% Replicates Fig 4b from "Compressed Hadamard Microscopy for high-speed
% optically sectioned neuronal activity recordings", by Vicente J. Parot*,
% Carlos Sing-Long*, Yoav Adam, Urs L. Boehm, Linlin Z. Fan, Samouil L.
% Farhi, and Adam E. Cohen.
%
% Copyright 2016-2018 Vicente Parot
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

rootdir = fullfile('Raw data');
datafolder = {
    '131722_cal_20_i_n20_9600p_1ms_10V'
    '161037_fov04_z20_20_i_n20_9600p_1ms_665lp_10V_OD1'
    '161740_fov04_z10_20_i_n20_9600p_1ms_665lp_10V_OD1'
};
cal_fname = 'processed_calibration.mat';
res_fname = 'reduced_roi_results.mat';

%% Code parameters
il = 20*2; % interleaved length containing 2 series of length 20
hl = il/2; % hadamard length, equal to half the interleaved length
hadtraces = hadamard_bincode_nopermutation(hl-1)'*2-1;

%% Format calibration data
caldir = fullfile(rootdir,datafolder{1});
cal_fpath = fullfile(caldir,cal_fname);
if ~exist(cal_fpath,'file')
    cdata = vm(caldir);
    cdata = cdata(2:end-1)-100;
    cdata = cdata(2001:end).pblc.evnfun(@mean,il);
    cmov = cdata(1:2:end) - cdata(2:2:end);
    cmov = cmov - cmov.mean;
    cmov = cmov./cmov.std;
    save(cal_fpath,...
        'cmov')

    % % alternative calibration processing method
    % % generates synthetic calibration pattern 
    % ccorr = cmov.blur(1)*hadtraces;
    % ccorr = cat(3,ccorr,-ccorr);
    % [~, idx] = max(ccorr.imresize(2).data,[],3);
    % rpattern20 = ones(size(idx));
    % rpattern20(idx>size(hadtraces,2)) = -1;
    % idx(idx>size(hadtraces,2)) = idx(idx>size(hadtraces,2)) - size(hadtraces,2);
    % sind = sparse(1:numel(idx),idx,rpattern20);
    % vmind = vm(full(sind),size(idx));
    % smov = vmind.imresize(.5)*hadtraces';
    % clear vmind sind ccorr
    % save(cal_fname,...
    %     'cmov',...
    %     'smov')
end
%%
for it_folder = 2:numel(datafolder)
    %% Format tissue data
    datadir = fullfile(rootdir,datafolder{it_folder});
    res_fpath = fullfile(datadir,res_fname);
    if exist(res_fpath,'file')
        continue
    end
    disp(datadir)
    tmov = vm(datadir); % read raw data
    tmov = tmov(2:end-1)-100; % remove offset

    load(cal_fpath)
    % fixes a synchronization error in one of the datasets
    switch datafolder{it_folder}(1:6) 
        case '161740'
            frame_sync_offset = 1;
            cmov = cmov([1+frame_sync_offset:end 1:frame_sync_offset]);
    end

    %%
    ncomps = 5;
    rng(0,'twister') % ensures multiple runs of eigs() will return repeatable results
    [sv, uhad, uref, uu] = dyn_had(tmov(:,:), cmov(:,:), ncomps);
    %%
    save(res_fpath,...
        'sv', ...
        'uhad', ...
        'uref', ...
        'uu', ...
        'ncomps')
end

%% Analysis
% manually defined ROIs to integrate cell excluding overlapping area
rois = {[
   11.5251   27.6025
   18.6321   32.8872
   24.2813   26.6913
   21.5478   18.4909
   25.3747    8.6503
   33.9396    6.8280
   39.4066    1.3610
    4.2358    1.1788
    1.8667    1.3610
    2.2312   23.4112
   11.5251   27.6025
    ],[
   20.0900   43.4567
   20.6367   35.2563
   25.1925   26.8736
   32.6640   24.8690
   43.9624   21.4066
   47.9715   12.6595
   48.1538    5.9169
   53.2563    7.1925
   60.7278   20.3132
   62.5501   32.1583
   61.6390   42.7278
   20.0900   43.4567
    ]};
%%

% reload reconstructed data from depth 50 um
it_folder = 2;
datadir = fullfile(rootdir,datafolder{it_folder});
res_fpath = fullfile(datadir,'reduced_roi_results.mat');
load(res_fpath,...
    'sv', ...
    'uhad', ...
    'uref', ...
    'uu', ...
    'ncomps')
% extract time-integrated images 
w50img = mean(vm(uref*sv',tmov.imsz)); % widefield image
h50img = mean(vm(uhad*sv',tmov.imsz)); % hadamard image

% reload reconstructed data from depth 60 um
it_folder = 3;
datadir = fullfile(rootdir,datafolder{it_folder});
res_fpath = fullfile(datadir,'reduced_roi_results.mat');
load(res_fpath,...
    'sv', ...
    'uhad', ...
    'uref', ...
    'uu', ...
    'ncomps')
% extract time-integrated images 
w60img = mean(vm(uref*sv',tmov.imsz));
h60img = mean(vm(uhad*sv',tmov.imsz));
% extract time traces 
w60traces = apply_clicky_faster(rois,vm(uref*sv',tmov.imsz),'no');
h60traces = apply_clicky_faster(rois,vm(uhad*sv',tmov.imsz),'no');
wImgDisplaySaturation = prctile([w50img(:); w60img(:)],99.9);
hImgDisplaySaturation = prctile([h50img(:); h60img(:)],99.9);

figure
set(gcf,'position',[700 500 500 250])

subplotfcn = @subplot;
nxsub = 6;

subplotfcn(2,nxsub,1)
imshow(w50img',[0 wImgDisplaySaturation])
ylabel Widefield
title 'z = 50 \mum'
subplotfcn(2,nxsub,2)
imshow(w60img',[0 wImgDisplaySaturation])
hold on
h1 = plot(rois{1}(:,2),rois{1}(:,1),'linewidth',1);
h2 = plot(rois{2}(:,2),rois{2}(:,1),'linewidth',1);
text(mean(rois{1}(:,2)),prctile(rois{1}(:,1),40),'1','Color',h1.Color,'Fontsize',12)
text(prctile(rois{2}(:,2),60),mean(rois{2}(:,1)),'2','Color',h2.Color,'Fontsize',12)
title 'z = 60 \mum'
subplotfcn(2,nxsub,nxsub+1)
imshow(h50img',[0 hImgDisplaySaturation])
ylabel Hadamard
subplotfcn(2,nxsub,nxsub+2)
imshow(h60img',[0 hImgDisplaySaturation])

xfrac = .26;
yfrac = .7; 
subax = 400+(1:250*10);
subinset = 2.99*500:3.2*500;

tax = (subax - subax(1))/500;
iref = w60traces(:,1);
ihad = h60traces(:,1);
iref = vm(permute(iref,[3 2 1])).pblc.frameAverage;
ihad = vm(permute(ihad,[3 2 1])).pblc.frameAverage;
iref = iref(subax);
ihad = ihad(subax);

subplotfcn(2,nxsub,4:nxsub)
plot(tax,iref./prctile(iref,20)*100-100)
axis tight
xlim([0 5])
box off
title 'z = 60 \mum, ROI 1'
ylabel({'Widefield','\DeltaF/F'})
xticklabels([])
 
axp = get(gca,'position');
ax0 = axp(1:2);
ax1 = axp(1:2)+axp(3:4);
nax0 = [xfrac*ax0(1)+(1-xfrac)*ax1(1) yfrac*ax0(2)+(1-yfrac)*ax1(2)];
axes('position',[nax0 ax1-nax0])
plot(tax(subinset),iref(subinset),'linewidth',1)
axis tight
box off
set(gca,'xtick',[])
set(gca,'ytick',[])

subplotfcn(2,nxsub,nxsub+(4:nxsub))
plot(tax,ihad./prctile(ihad,20)*100-100)
axis tight
xlim([0 5])
box off
xlabel 'Time (s)'
ylabel({'Hadamard','\DeltaF/F'})
xticklabels([])

axp = get(gca,'position');
ax0 = axp(1:2);
ax1 = axp(1:2)+axp(3:4);
nax0 = [xfrac*ax0(1)+(1-xfrac)*ax1(1) yfrac*ax0(2)+(1-yfrac)*ax1(2)];
axes('position',[nax0 ax1-nax0])
plot(tax(subinset),ihad(subinset),'linewidth',1)
axis tight
box off
set(gca,'xtick',[])
set(gca,'ytick',[])
    f = gcf;
    f.PaperPosition = f.PaperPosition.*[0 0 1 1];
    f.PaperSize = f.PaperPosition(3:4);

saveas(gcf,'f4b.fig')
saveas(gcf,'f4b.pdf')
saveas(gcf,'f4b.png')






