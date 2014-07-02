function load_bioharness
clc
close all

%% file of interest (long recording)
% /2013-04-19/measurements/2013-04-23 gp test/08/bioharness2.csv

%%

[filename, pathname] = uigetfile('*.csv', ' Please select the "BIOHARNESS" Input file');
valid_filename=0;
% Searching for the breathing String in the filename
bioharness_StrinG_Search = strfind(filename, 'bioharness');
if((isempty(bioharness_StrinG_Search)))
    %valid_filename=1;
    disp('Invalid File or No File Selected ');
    return
else
    valid_filename=1;    
end
%Do if a file with validname has been found
if(valid_filename)
    %concatenate the pathname with the filename
    CompletePathwFilename = strcat(pathname,filename);
    %Open the file & extract the data
    fid = fopen(CompletePathwFilename);
    %data = textscan(fid,'%s %f','HeaderLines',1,'Delimiter',',','CollectOutput',1);
    %data_manual = textscan(fid,'%f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f','HeaderLines',3,'Delimiter','|');
    data=csvread(CompletePathwFilename,3);
    fclose(fid);
end


%figure;
t_vec=data(:,4)./1000;
%plot(t_vec)
%size(t_vec)
midnight=find(diff(t_vec)<-23.9*3600)
if ~isempty(midnight)
    vec_t2 = [t_vec(1:midnight); t_vec(midnight+1:length(t_vec))+24*3600];
    %length(vec_t)
    %length(vec_t2)
    %hold on; plot(vec_t2,'r');
    t_vec=vec_t2;
    clearvars vec_t2
end

t_vec=t_vec./3600;
%figure; plot(t_vec)
t_vec=t_vec-t_vec(1);
%figure; plot(t_vec)
max(t_vec)


%% Processing to detect no peak accelerometer events
peak_accel=data(:,9);
%win_len=fs; % this is to do it in blocks of one second.
packet=1; % samples per packet
win_len=2*packet; % divide into 2 second windows.
%prev_peak=0;
range_th=0.3; % quantisation step value = 0.1;
no_sig_flag=zeros(size(t_vec));
for i=1:floor(length(peak_accel)/win_len)
    ind_start=1+((i-1)*win_len);
    ind_end=i*win_len;
    block=peak_accel(ind_start:ind_end);
    peak=max(block);
    if peak>range_th
        no_sig_flag(ind_start:ind_end)=1; % if at the start only flat one win_len
    end 
    %prev_range=0;
    %prev_range=(1/15)*pack_range+(14/15)*prev_range; % roughly equivalent window is 10 packet lengths.
end


%% Second processing to detect no peak accelerometer events
packet=1; % No. of peak accel. samples per packet
win_len=packet; % analyse in 1 second windows.
range_th=0.3; % quantisation step value = 0.01;
sig_flag=zeros(size(t_vec));
prev_max=[0 0 0 0];
for i=1:floor(length(peak_accel)/win_len)
    ind_start=1+((i-1)*win_len);
    ind_end=i*win_len;
    block=peak_accel(ind_start:ind_end);
    peak=max([prev_max block]);
    if peak>range_th
        sig_flag(ind_start:ind_end)=1; % only update the present sample.
    end 
    prev_max=[prev_max(2:4) max(block)]; % update the rolling buffer to hold the values of the last five peaks. Discard the oldest one.
end



%% Plotting

figure;

ax(1)=subplot(4,1,1); plot(t_vec,data(:,5)); ylabel('Heart Rate');
title('General packet and peak accelerometer detection')
ax(2)=subplot(4,1,2); plot(t_vec,data(:,6)); ylabel('Resp Rate');
ax(3)=subplot(4,1,3); plot(t_vec,data(:,8)); ylabel('Position');
ax(4)=subplot(4,1,4); plot(t_vec,peak_accel); ylabel('Peak Accel.'); hold on
ax(4)=subplot(4,1,4); plot(t_vec,no_sig_flag,'c'); ylabel('Peak Accel. and signal flag');
xlabel('time (hours)');
linkaxes(ax,'x');
zoom xon;

figure;

ax2(1)=subplot(2,1,1); plot(t_vec,peak_accel); ylabel('Peak Accel. value');
title('Peak accelerometer detection')
%ax2(2)=subplot(2,1,2); plot(t_vec,no_sig_flag,'c'); ylabel('Activity signal flag'); ylim([0 1.2]); hold on
ax2(2)=subplot(2,1,2); plot(t_vec,sig_flag,'c'); ylabel('Activity signal flag'); ylim([0 1.2])
%ax2(3)=subplot(4,1,3); plot(t_vec,data(:,8)); ylabel('Position');
%ax2(4)=subplot(4,1,4); plot(t_vec,peak_accel); ylabel('Peak Accel.'); hold on
%ax2(4)=subplot(4,1,4); plot(t_vec,no_sig_flag,'c'); ylabel('Peak Accel. and signal flag');
xlabel('time (hours)');
linkaxes(ax2,'x');
zoom xon;

%return

papersize = [8,6];
set(gcf,'PaperUnits','inches','PaperPositionMode','Manual','PaperSize',papersize,'PaperPosition',[0,0,papersize(1),papersize(2)])
print(gcf, '-dpdf','Figures/peak-accel-det-01')

xlim([6 8.5])
papersize = [8,6];
set(gcf,'PaperUnits','inches','PaperPositionMode','Manual','PaperSize',papersize,'PaperPosition',[0,0,papersize(1),papersize(2)])
print(gcf, '-dpdf','Figures/peak-accel-det-02')


xlim([6.395 6.395+(180/3600)])
papersize = [8,6];
set(gcf,'PaperUnits','inches','PaperPositionMode','Manual','PaperSize',papersize,'PaperPosition',[0,0,papersize(1),papersize(2)])
print(gcf, '-dpdf','Figures/peak-accel-det-03')
