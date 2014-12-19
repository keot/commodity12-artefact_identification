disp('Profiling filters into res_${filter_name}.');

addpath('filters');

total_dur = 0;

% SUCCESS
%disp('Profiling driftButterworth');
%tic;
%res_driftButterworth = filterProfiling(@driftButterworth);
%dur_driftButterworth = toc;
%total_dur = total_dur + dur_driftButterworth;
%saveResults('filter_profiling_driftButterworth.dat', res_driftButterworth);
%disp('');

% BROKEN SOMEHOW
disp('Profiling driftMeanMedian');
tic;
res_driftMeanMedian = filterProfiling(@driftMeanMedian);
dur_driftMeanMedian = toc;
total_dur = total_dur + dur_driftMeanMedian;
saveResults('filter_profiling_driftMeanMedian.dat', res_driftMeanMedian);
disp('');


% BROKEN SOMEHOW
disp('Profiling driftMedian');
tic;
res_driftMedian = filterProfiling(@driftMedian);
dur_driftMedian = toc;
total_dur = total_dur + dur_driftMedian;
saveResults('filter_profiling_driftMedian.dat', res_driftMedian);
disp('');


% BROKEN: Containers.Map
%disp('Profiling lowSnrStaticThreshold');
%tic;
%res_lowSnrStaticThreshold = filterProfiling(@lowSnrStaticThreshold);
%dur_lowSnrStaticThreshold = toc;
%total_dur = total_dur + dur_lowSnrStaticThreshold;
%saveResults('filter_profiling_lowSnrStaticThreshold.dat', res_lowSnrStaticThreshold);
%disp('');


% BROKEN: Containers.Map
%disp('Profiling mainsArraySlicing');
%tic;
%res_mainsArraySlicing = filterProfiling(@mainsArraySlicing);
%dur_mainsArraySlicing = toc;
%total_dur = total_dur + dur_mainsArraySlicing;
%saveResults('filter_profiling_mainsArraySlicing.dat', res_mainsArraySlicing);
%disp('');

% SUCCESS
%disp('Profiling mainsIirNotch');
%tic;
%res_mainsIirNotch = filterProfiling(@mainsIirNotch);
%dur_mainsIirNotch = toc;
%total_dur = total_dur + dur_mainsIirNotch;
%saveResults('filter_profiling_mainsIirNotch.dat', res_mainsIirNotch);
%disp('');

% BROKEN: Containers.Map
%disp('Profiling saturationStaticThreshold');
%tic;
%res_saturationStaticThreshold = filterProfiling(@saturationStaticThreshold);
%dur_saturationStaticThreshold = toc;
%total_dur = total_dur + dur_saturationStaticThreshold;
%saveResults('filter_profiling_saturationStaticThreshold.dat', res_saturationStaticThreshold);
%disp('');

disp('Done!');
