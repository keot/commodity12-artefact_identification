function breathing %(data)
clc
clear all
close all

%% file of interes
% /home/eduardo/Dropbox/COMMODITY12/Week-Logs/2013-04-19/measurements/2013-04-20 night extra 4/breathing.txt

save_figs=1; % 1 save figures, 0 skip saving.
use_hours=1; % 1 use hours, 2 use sec.

%%

%cd ../measurements/
%
[filename, pathname] = uigetfile('*.txt', ' Please select the "BREATHING" Input file');
valid_filename=0;
% Searching for the breathing String in the filename
breathing_StrinG_Search = strfind(filename, 'breathing');
if((isempty(breathing_StrinG_Search)))
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
    data=csvread(CompletePathwFilename,3);
    fclose(fid);
end
%



t = data(:,1);
%t = t - t(1);
t= t./1000;

ind=0;
vec_t=zeros(1,length(t)*18);
for i=1:length(t)
    for j=1:18
        ind=ind+1;
        vec_t(ind)=t(i)+(j-1)*(56/1000);
    end
end
%figure; plot(vec_t);
%figure; plot(vec_t);
%figure; plot(diff(vec_t));
midnight=find(diff(vec_t)<-23.9*3600);
if ~isempty(midnight)
    vec_t2 = [vec_t(1:midnight) vec_t(midnight+1:length(vec_t))+24*3600];
    %length(vec_t)
    %length(vec_t2)
    %hold on; plot(vec_t2,'r');
    vec_t=vec_t2;
    clearvars vec_t2
end
vec_t = vec_t-vec_t(1);
%figure; plot(diff(vec_t))
data2=data(:,2:length(data(1,:)));
% ind=0;
% vec=zeros(1,length(data2(:,1))*length(data2(1,:)));
% for i=1:length(data2(:,1))
%     for j=1:length(data2(1,:))
%         ind=ind+1;
%         vec(ind)=data2(i,j);
%     end
% end
%vec2 = reshape(data2.',[],1);
vec = reshape(data2.',[],1);



%figure; plot(vec);
if use_hours==1
    vec_h=vec_t.*(1/3600);
else
    vec_h=vec_t; % do not divide by 3600 and keep the time vector in seconds.
end
%figure; plot(diff(vec_h))

%figure; plot(vec_t,vec);
%xlabel('time (seconds)');
%ylabel('breathing signal');
%title('raw breathing signal');

%% Processing for detection of weak or no signal in respiration band signal.
% Inputs: vet and vec_t containing signal and time stamp information respectively.
packet=18; % samples per packet
win_len=packet;
prev_range=0;
range_th=1; % quantisation step value = 1;
no_sig_flag=zeros(size(vec_t));
for i=1:floor(length(vec)/win_len)
    ind_start=1+((i-1)*win_len);
    ind_end=i*win_len;
    block=vec(ind_start:ind_end);
    pack_range=max(block)-min(block);
    if max([prev_range pack_range])<=range_th
        if i>win_len*30
            % Need for updating flag samples previous to the present packet.
            no_sig_flag(ind_start-win_len*30:ind_end)=1; % flag the last two packets
        else
            no_sig_flag(ind_start:ind_end)=1;  % if at the start of the recording mark only one win_len
        end
    end
    prev_range=(1/15)*pack_range+(14/15)*prev_range; % approx. equivalent time window to 15 packet lengths.
end


%% Processing for detection of peaks in respiration band signal.
% Inputs: vet and vec_t containing signal and time stamp information respectively.
packet=18; % samples per packet
win_len=packet;
%prev_range=0;
prev_range=zeros(1,10);
%range_th=1; % quantisation step value = 1;
peak_sig_flag=zeros(size(vec_t));
prev_range_sig=zeros(size(vec_t));
min_sig=zeros(size(vec_t));
max_sig=zeros(size(vec_t));
min_vec=zeros(1,10);
max_vec=zeros(1,10);
for i=1:floor(length(vec)/win_len)
    ind_start=1+((i-1)*win_len);
    ind_end=i*win_len;
    block=vec(ind_start:ind_end);
    
    min_vec(2:10)=min_vec(1:9);
    min_vec(1)=min(block);
    max_vec(2:10)=max_vec(1:9);
    max_vec(1)=max(block);
    pack_range=max(max_vec)-min(min_vec); % find difference between highest and lowest points over the last 10 packets.
    if pack_range>prev_range(10)*5 % if the last 10 packets have 3 times more variance than the
        % 10 packets that were acquired 10 packets ago then trigger.
        % the peaks rise over several packets so the variance in one single packet is not representative.
        %Instead you should keep track of the previous max and mins over
        %the last 10 packets and then look at the variance.
        if i>win_len
            % Need for updating flag samples previous to the present packet.
            %peak_sig_flag(ind_start-win_len:ind_end)=1; % flag the last two packets
            peak_sig_flag(ind_start-win_len:ind_end)=pack_range/prev_range(10); % flag the last two packets
        else
            %peak_sig_flag(ind_start:ind_end)=1;  % if at the start of the recording mark only one win_len
            peak_sig_flag(ind_start:ind_end)=pack_range/prev_range(10);  % if at the start of the recording mark only one win_len
        end
    end
    %prev_range=(1/15)*pack_range+(14/15)*prev_range; % approx. equivalent time window to 15 packet lengths.
    prev_range(2:10)=prev_range(1:9); % shift oldest sample out.
    prev_range(1)=pack_range; % approx. equivalent time window to 15 packet lengths.
    prev_range_sig(ind_start:ind_end)=pack_range;
    min_sig(ind_start:ind_end)=min(min_vec);
    max_sig(ind_start:ind_end)=max(max_vec);
end


%% Heart beat oscillation detection
heart_osc_flag=heart_in_resp(vec_t,vec);

%% Plotting
figure; plot(vec_h,vec);  ylabel('Raw breathing signal');
if use_hours==1
    xlabel('time (hours)');
else
    xlabel('time (seconds)');
end

figure; ax2(1)=subplot(3,1,1); plot(vec_h,vec);  ylabel('Raw breathing signal');
ax2(2)=subplot(3,1,2); plot(vec_h(1:length(vec_h)-1),diff(vec),'r'); ylabel('Difference of raw breathing signal');
ax2(3)=subplot(3,1,3); plot(vec_h,heart_osc_flag,'g'); ylabel('Oscillation detector'); ylim([0 1.2]);
if use_hours==1
    xlabel('time (hours)');
else
    xlabel('time (seconds)');
end
linkaxes(ax2,'x');
zoom xon;

figure(20); ax3(1)=subplot(2,1,1); plot(vec_h,vec);  ylabel('Raw breathing signal');
%ax2(2)=subplot(3,1,2); plot(vec_h(1:length(vec_h)-1),diff(vec),'r'); ylabel('Difference of raw breathing signal');
ax3(2)=subplot(2,1,2); plot(vec_h,heart_osc_flag,'g'); ylabel('Oscillation detector'); ylim([0 1.2]);
if use_hours==1
    xlabel('time (hours)');
else
    xlabel('time (seconds)');
end
linkaxes(ax3,'x');
zoom xon;

%return




figure(10); ax1(1)=subplot(2,1,1); plot(vec_h,vec);  ylabel('Raw breathing signal'); hold on
ax1(2)=subplot(2,1,2); plot(vec_h,peak_sig_flag,'g');  ylabel('Peak detector'); hold on
ax1(3)=subplot(2,1,1); plot(vec_h,512+prev_range_sig,'r');   hold on
ax1(4)=subplot(2,1,1); plot(vec_h,min_sig,'k--');   hold on
ax1(5)=subplot(2,1,1); plot(vec_h,max_sig,'k--');   hold on
%prev_range_sig
if use_hours==1
    xlabel('time (hours)');
else
    xlabel('time (seconds)');
end
linkaxes(ax1,'x');
zoom xon;


figure;
ax(1)=subplot(2,1,1); plot(vec_h,vec);  ylabel('Raw breathing signal'); title('Weak or absent breathing signal detection'); %ylim([0 1050]);

ax(2)=subplot(2,1,2); plot(vec_h,no_sig_flag,'m'); ylabel('Weak or no signal flag');
if use_hours==1
    xlabel('time (hours)');
else
    xlabel('time (seconds)');
end
ylim([0 1.2]);
linkaxes(ax,'x');
zoom xon;

if save_figs==1
    % last plotted figure
    subplot(2,1,1); ylim([0 1050]);
    papersize = [8,6];
    set(gcf,'PaperUnits','inches','PaperPositionMode','Manual','PaperSize',papersize,'PaperPosition',[0,0,papersize(1),papersize(2)])
    print(gcf, '-dpdf','Figures/breathing-weak-or-no-signal-01-all')
    
    subplot(2,1,1); xlim([0.5 3.5]); ylim([450 570]);
    papersize = [8,6];
    set(gcf,'PaperUnits','inches','PaperPositionMode','Manual','PaperSize',papersize,'PaperPosition',[0,0,papersize(1),papersize(2)])
    print(gcf, '-dpdf','Figures/breathing-weak-or-no-signal-02-nosig')
    
    %subplot(2,1,1); xlim([5.68 5.79]); ylim([460 560])
    %subplot(2,1,1); xlim([5.7 5.78]); ylim([460 560])
    subplot(2,1,1); xlim([5.745 5.785]); ylim([460 560])
    papersize = [8,6];
    set(gcf,'PaperUnits','inches','PaperPositionMode','Manual','PaperSize',papersize,'PaperPosition',[0,0,papersize(1),papersize(2)])
    print(gcf, '-dpdf','Figures/breathing-weak-or-no-signal-03-weaksig')
    
    %----------
    figure(1);
    if use_hours==1
        xlim([30940/3600 31030/3600]); ylim([440 1035])
    else
        xlim([30940 31030]); ylim([440 1035])
    end
    papersize = [8,6];
    set(gcf,'PaperUnits','inches','PaperPositionMode','Manual','PaperSize',papersize,'PaperPosition',[0,0,papersize(1),papersize(2)])
    print(gcf, '-dpdf','Figures/breathing-heart-beat-osc')
    
    if use_hours==1
        xlim([4280/3600 4380/3600]); ylim([512-100 512+100])
    else
        xlim([4280 4380]); ylim([512-100 512+100])
    end
    papersize = [8,6];
    set(gcf,'PaperUnits','inches','PaperPositionMode','Manual','PaperSize',papersize,'PaperPosition',[0,0,papersize(1),papersize(2)])
    print(gcf, '-dpdf','Figures/breathing-heart-beat-osc2')
    
    %----------
    
    figure(20);
    papersize = [8,6];
    set(gcf,'PaperUnits','inches','PaperPositionMode','Manual','PaperSize',papersize,'PaperPosition',[0,0,papersize(1),papersize(2)])
    print(gcf, '-dpdf','Figures/breathing-heart-beat-osc-all')
    
    
    if use_hours==1
        xlim([30940/3600 31030/3600]); subplot(2,1,1); ylim([440 1035])
    else
        xlim([30940 31030]); ylim([440 1035])
    end
    papersize = [8,6];
    set(gcf,'PaperUnits','inches','PaperPositionMode','Manual','PaperSize',papersize,'PaperPosition',[0,0,papersize(1),papersize(2)])
    print(gcf, '-dpdf','Figures/breathing-heart-beat-osc-b')
    
    if use_hours==1
        xlim([4280/3600 4380/3600]); subplot(2,1,1); ylim([512-100 512+100])
    else
        xlim([4280 4380]); ylim([512-100 512+100])
    end
    papersize = [8,6];
    set(gcf,'PaperUnits','inches','PaperPositionMode','Manual','PaperSize',papersize,'PaperPosition',[0,0,papersize(1),papersize(2)])
    print(gcf, '-dpdf','Figures/breathing-heart-beat-osc2-b')
    
end
return
