function data_rate_calc

clc
close all
save_figs=1;

% raw accelerometer
bytes_per_packet=89;
bits_per_byte=8;
seconds_per_packet=0.4;
raw_accel_bits_per_sec=bytes_per_packet*bits_per_byte/seconds_per_packet



% raw accelerometer
bytes_per_packet=58;
%bits_per_byte=8;
seconds_per_packet=1;
general_bits_per_sec=bytes_per_packet*bits_per_byte/seconds_per_packet


percent_active=1:100;


raw_accel_datarate=percent_active*0.01*raw_accel_bits_per_sec;
raw_accel_datarate_full=ones(1,100)*raw_accel_bits_per_sec;

general_datarate=ones(1,100)*general_bits_per_sec;

tot_datarate=raw_accel_datarate+general_datarate;

figure; 
plot(general_datarate,'g'); hold on
plot(raw_accel_datarate,'k'); hold on
plot(raw_accel_datarate_full,'--k'); hold on
plot(tot_datarate,'c'); hold on

title('Data rate trade-off as a function of user active time percentage.')
xlabel('Percentage of time active (%)')
ylabel('Average bits per second for general packet (green), raw accel. (black), both (cyan).')

if save_figs==1;
    papersize = [8,6];
    set(gcf,'PaperUnits','inches','PaperPositionMode','Manual','PaperSize',papersize,'PaperPosition',[0,0,papersize(1),papersize(2)])
    print(gcf, '-dpdf','Figures/data-rate-trade-off-01')
end

%% Run estimation of battery lifetime.
% this accounts for double the sensor consumption. 

raw_accel_batt_life=7.5992; % here accel is turned, nothing else.
general_packet_batt_life= 16.7322; % here accel is turned on, as well as ECG.
ecg_packet_batt_life = 19.6553; % ecg sensor consumes less than accel, accel turned off.
% raw ecg data rate
bytes_per_packet=93;
%bits_per_byte=8;
seconds_per_packet=0.252;
ecg_bits_per_sec=bytes_per_packet*bits_per_byte/seconds_per_packet

figure; stem(raw_accel_batt_life, raw_accel_bits_per_sec,'k'); hold on
stem(general_packet_batt_life, general_bits_per_sec,'g'); hold on
stem(ecg_packet_batt_life, ecg_bits_per_sec); hold on

%%
raw_accel_pc_per_hour=100/raw_accel_batt_life;
general_pc_per_hour=100/general_packet_batt_life;
ecg_pc_per_hour=100/ecg_packet_batt_life;
%100/batt_life=percent_per_hour;


figure; stem(raw_accel_pc_per_hour, raw_accel_bits_per_sec,'k'); hold on
stem(general_pc_per_hour, general_bits_per_sec,'g'); hold on
stem(ecg_pc_per_hour, ecg_bits_per_sec); hold on


%% Calculating battery life expectancy as a function of user activity.

gp_task=100/general_packet_batt_life; %percentage consumed per hour
ra_task=100/raw_accel_batt_life;


gp_task_pc=ones(1,100)*gp_task;
ra_task_pc=percent_active*0.01*ra_task;
ra_task_fix=ones(1,100)*ra_task;

total_task_pc=gp_task_pc+ra_task_pc;
total_task_pc_90=gp_task_pc+ra_task_pc*0.9;
total_task_pc_80=gp_task_pc+ra_task_pc*0.8;
total_task_pc_70=gp_task_pc+ra_task_pc*0.7;
total_task_pc_60=gp_task_pc+ra_task_pc*0.6;

figure; plot(gp_task_pc,'g'); hold on
plot(ra_task_pc,'k'); hold on
%plot(raw_accel_datarate_full,'--k'); hold on
plot(total_task_pc,'c'); hold on


figure; plot(100./gp_task_pc,'g'); hold on
plot(100./ra_task_fix,'--k'); hold on
%plot(raw_accel_datarate_full,'--k'); hold on
plot(100./total_task_pc,'c'); hold on
plot(100./total_task_pc_80,'--c'); hold on
plot(100./total_task_pc_60,'-.c'); hold on
title('Worst case scenario battery lifetime calculation');
ylabel('Battery lifetime (hours)');
xlabel('Percentage of time active (%)')

if save_figs==1;
    papersize = [8,6];
    set(gcf,'PaperUnits','inches','PaperPositionMode','Manual','PaperSize',papersize,'PaperPosition',[0,0,papersize(1),papersize(2)])
    print(gcf, '-dpdf','Figures/data-rate-trade-off-02')
end


