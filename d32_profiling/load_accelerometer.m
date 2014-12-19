function load_accelerometer
clc
close all
clear all
%% file of interest (long recording)
% /home/eduardo/Dropbox/COMMODITY12/Week-Logs/2013-04-19/measurements/2013-04-22 accel test/2013-04-22 accel test 14/accelerometer.csv

save_figs=1;
%%

[filename, pathname] = uigetfile('*.csv', ' Please select the "ACCELEROMETER" Input file');
valid_filename=0;
% Searching for the breathing String in the filename
accelerometer_StrinG_Search = strfind(filename, 'accelerometer');
if((isempty(accelerometer_StrinG_Search)))
    %valid_filename=1;
    disp('Invalid File or No File Selected ');
    return
else
    valid_filename=1;
end
%Do if a file with validname has been found
if(valid_filename)
    %concatenate the pathname with the filename
    CompletePathwFilename = strcat(pathname,filename)
    %Open the file & extract the data
    fid = fopen(CompletePathwFilename);
    %data = textscan(fid,'%s %f','HeaderLines',1,'Delimiter',',','CollectOutput',1);
    %data_manual = textscan(fid,'%f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f','HeaderLines',3,'Delimiter','|');
    data=csvread(CompletePathwFilename,3);
    fclose(fid);
end
%MsOfDay = 4
%sample no = 5
X=data(:,5:24);
X_vec = reshape(X.',[],1);  % Collect the row contents into a column vector

Y=data(:,25:44);
Y_vec = reshape(Y.',[],1);

Z=data(:,45:64);
Z_vec = reshape(Z.',[],1);

%t_vec = (data(:,4) + 20*data(:,5))./1000;
b=0:20:380; % milliseconds to add
c=ones(1,20);
% figure; plot(data(:,4),'r'); hold on
t_vec = data(:,4)*c; %expanded laterally to have 20 time samples per packet
b_matrix= ones(size(t_vec,1),1)*b; %create matrix of milliseconds to add
t_vec = t_vec + b_matrix;
t_vec = reshape(t_vec.',[],1);
% plot(t_vec,'g');
% figure; plot(diff(data(:,4)),'r'); hold on
% plot(diff(t_vec),'g');
clearvars b_matrix

t_vec=t_vec./1000;
t_vec = t_vec - t_vec(1); %remove the time offset
t_vec=t_vec./3600;
%plot(t_vec);
%plot(diff(t_vec));
%xyz 6,7 8
%mag_vec = sqrt(data(:,6).^2 + data(:,7).^2 + data(:,8).^2);
mag_vec = sqrt(X_vec.^2 + Y_vec.^2 + Z_vec.^2);




%% Processing to detect sections of significant amplitude variance with respect to ADC quantisation noise. 
% If a packet has less that two quatisation step variance in all 3 axis set "small_sig_flag" to 0.
% Then set to values 0.5, 1 and 3 as a progessive way to describe basic signal presence in either one, two or all three axes.

packet=20; % samples
win_len=3*packet; % 3 packet mean is approximately equivalent to a LPF at 0.83Hz. Fs=50Hz.
%prev_range=0
range_th=0.2; % quatisation steps from signal go in 0.1 increments
small_sig_flag=zeros(size(t_vec)); % remains 0 if signal is small, increases if signal is larger.
X_mean=zeros(size(t_vec)); % used for plotting, not processing.
Y_mean=zeros(size(t_vec)); % used for plotting, not processing.
Z_mean=zeros(size(t_vec)); % used for plotting, not processing.
for i=1:floor(length(X_vec)/win_len) % interpret in increments of 3 packets.
    ind_start=1+((i-1)*win_len);
    ind_end=i*win_len;
    
    blockX=X_vec(ind_start:ind_end); %using raw signal, not the magnitude.
    X_mean(ind_start:ind_end)=mean(blockX); % used for plotting, not processing.
    blockY=Y_vec(ind_start:ind_end); 
    Y_mean(ind_start:ind_end)=mean(blockY); % used for plotting, not processing.
    blockZ=Z_vec(ind_start:ind_end);
    Z_mean(ind_start:ind_end)=mean(blockZ); % used for plotting, not processing.
    
    pack_rangeX=max(blockX)-min(blockX);
    pack_rangeY=max(blockY)-min(blockY);
    pack_rangeZ=max(blockZ)-min(blockZ);
    if max([pack_rangeX pack_rangeY pack_rangeZ])<=range_th
        small_sig_flag(ind_start:ind_end)=0; % mark only one win_len
    elseif max([pack_rangeX pack_rangeY])<=range_th | max([pack_rangeX pack_rangeZ])<=range_th | max([pack_rangeY pack_rangeZ])<=range_th
        small_sig_flag(ind_start:ind_end)=0.5;
    elseif pack_rangeX<=range_th | pack_rangeY<=range_th | pack_rangeZ<=range_th
        small_sig_flag(ind_start:ind_end)=1;
    else
        small_sig_flag(ind_start:ind_end)=3;
    end
    %prev_range=pack_range;
end


max(t_vec)
%% peak detection




%% Plotting

figure;
%t_vec=data(:,4);

ax(1)=subplot(4,1,1); plot(t_vec,X_vec); ylabel('X, vertical (g)'); hold on
ax(1)=subplot(4,1,1); plot(t_vec,X_mean,'c'); ylabel('X, vertical'); hold on

ax(2)=subplot(4,1,2); plot(t_vec,Y_vec); ylabel('Y, lateral (g)'); hold on
ax(2)=subplot(4,1,2); plot(t_vec,Y_mean,'c'); ylabel('Y, lateral'); hold on

ax(3)=subplot(4,1,3); plot(t_vec,Z_vec); ylabel('Z, sagital (g)'); hold on
ax(3)=subplot(4,1,3); plot(t_vec,Z_mean,'c'); ylabel('Z, sagital'); hold on

ax(4)=subplot(4,1,4); plot(t_vec,mag_vec); ylabel('Mag vec'); hold on
ax(5)=subplot(4,1,4); plot(t_vec,small_sig_flag,'g'); ylabel('Mag vec (blue) & signal events (green)');
xlabel('time (hours)');

linkaxes(ax,'x');
zoom xon;

%figure; plot3(X_vec,Y_vec,t_vec);

%--
small_sig_flag_th=zeros(size(small_sig_flag));
small_sig_flag_th(find(small_sig_flag>2))=1;
%

%=========
figure;
%t_vec=data(:,4);
ax2(1)=subplot(4,1,1); plot(t_vec,X_vec); ylabel('X, vertical (g)'); hold on
title('Raw accelerometer data (blue) and potential sections of interest (green)')
%ax(1)=subplot(4,1,1); plot(t_vec,X_mean,'c'); ylabel('X, vertical'); hold on

ax2(2)=subplot(4,1,2); plot(t_vec,Y_vec); ylabel('Y, lateral (g)'); hold on
%ax(2)=subplot(4,1,2); plot(t_vec,Y_mean,'c'); ylabel('Y, lateral'); hold on

ax2(3)=subplot(4,1,3); plot(t_vec,Z_vec); ylabel('Z, sagital (g)'); hold on
%ax(3)=subplot(4,1,3); plot(t_vec,Z_mean,'c'); ylabel('Z, sagital'); hold on

%ax(4)=subplot(4,1,4); plot(t_vec,mag_vec); ylabel('Mag vec'); hold on
ax2(4)=subplot(4,1,4); plot(t_vec,small_sig_flag_th,'g'); ylim([0 1.2]); ylabel('Sections of interest');
xlabel('time (hours)');

linkaxes(ax2,'x');
zoom xon;

%=========
figure;
%t_vec=data(:,4);
ax3(1)=subplot(3,1,1); plot(t_vec,X_vec); ylabel('X, vertical (g)'); hold on
title('Raw accelerometer data (blue)')
%ax(1)=subplot(4,1,1); plot(t_vec,X_mean,'c'); ylabel('X, vertical'); hold on

ax3(2)=subplot(3,1,2); plot(t_vec,Y_vec); ylabel('Y, lateral (g)'); hold on
%ax(2)=subplot(4,1,2); plot(t_vec,Y_mean,'c'); ylabel('Y, lateral'); hold on

ax3(3)=subplot(3,1,3); plot(t_vec,Z_vec); ylabel('Z, sagital (g)'); hold on
%ax(3)=subplot(4,1,3); plot(t_vec,Z_mean,'c'); ylabel('Z, sagital'); hold on

xlabel('time (hours)');

linkaxes(ax3,'x');
zoom xon;

figure(2)

if save_figs==1
papersize = [8,6];
set(gcf,'PaperUnits','inches','PaperPositionMode','Manual','PaperSize',papersize,'PaperPosition',[0,0,papersize(1),papersize(2)])
print(gcf, '-dpdf','Figures/accel-sec-of-interest-01')

xlim([5.87 5.91])
papersize = [8,6];
set(gcf,'PaperUnits','inches','PaperPositionMode','Manual','PaperSize',papersize,'PaperPosition',[0,0,papersize(1),papersize(2)])
print(gcf, '-dpdf','Figures/accel-sec-of-interest-02')

xlim([5.877 5.887]);
subplot(4,1,1); ylim([-2 0]);
subplot(4,1,2); ylim([-1 1]);
subplot(4,1,3); ylim([-1 1]);
papersize = [8,6];
set(gcf,'PaperUnits','inches','PaperPositionMode','Manual','PaperSize',papersize,'PaperPosition',[0,0,papersize(1),papersize(2)])
print(gcf, '-dpdf','Figures/accel-sec-of-interest-03')

figure(3);
%xlim([0.236 0.243])
xlim([0.2365 0.2365+(20/3600)])
subplot(3,1,1); ylim([-2 0]);
subplot(3,1,2); ylim([-1 1]);
subplot(3,1,3); ylim([-1 1]);
papersize = [8,6];
set(gcf,'PaperUnits','inches','PaperPositionMode','Manual','PaperSize',papersize,'PaperPosition',[0,0,papersize(1),papersize(2)])
print(gcf, '-dpdf','Figures/accel-example-of walking-01')
end

