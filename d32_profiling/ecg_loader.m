function ecg_loader %(data)
clc
clear all
close all

%%

save_figs=1; % 1 save figures, 0 skip saving.

% file of interest
% /home/eduardo/Dropbox/COMMODITY12/Week-Logs/2013-05-03/measurements/ecg long 2013-04-29/10/ecg.txt
% recording during lausanne meeting
% /home/eduardo/Dropbox/COMMODITY12/Week-Logs/2013-04-26/measurements/2013-04-26 ecg/05/ecg.txt

fs=250; % milliseconds
%%
[filename, pathname] = uigetfile('*.txt', ' Please select the "ECG" Input file');
valid_filename=0;
% Searching for the breathing String in the filename
breathing_StrinG_Search = strfind(filename, 'ecg');
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
%%



ecg_matrix=data(:,2:64);
ecg_vec=reshape(ecg_matrix.',[],1);

% just to check what the value range is. In ECG it is 0 to 1023. 
% max(ecg_vec) 
% min(ecg_vec)
% return


t_vec=data(:,1);
t_vec=t_vec./1000; %reduce from milliseconds to seconds.
clearvars data ecg_matrix
ind=0;
vec_t=zeros(1,length(t_vec)*63);
for i=1:length(t_vec)
    for j=1:63
        ind=ind+1;
        vec_t(ind)=t_vec(i)+(j-1)*(4/1000);
    end
end

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

vec_t=vec_t-vec_t(1);
vec_t=vec_t./3600; %reduce from seconds to hours.
%figure; plot(diff(vec_t));
figure(1);
ax(1)=subplot(5,1,1); plot(vec_t,ecg_vec);
ylabel('BioHarness ECG');
xlabel('time (hours)');

%% Detection of signal Saturation
sat_flag=zeros(size(vec_t)); % Max 949, Min 74.
sat_flag(find(ecg_vec>(949-1) | ecg_vec<(74+1)))=1;
%win_len=fs; % this is to do it in blocks of one second.
packet=63; % samples
win_len=packet;
%prev_pack=[0 0 0 0];
%range_th=5; % 5 quantisation steps.
%no_sig_flag=zeros(size(vec_t));
for i=1:floor(length(ecg_vec)/win_len)
    ind_start=1+((i-1)*win_len);
    ind_end=i*win_len;
    block=sat_flag(ind_start:ind_end);
    has_sat=~isempty(find(block==1,1)); % of some ones are found
    if has_sat==1
        sat_flag(ind_start:ind_end)=1; % flag the whole packet as saturated.
    end 
    %prev_range=pack_range;
end

%ax(2)=subplot(2,1,2); plot(vec_t,sat_flag,'k');
%figure(5); plot(vec_t,sat_flag,'k');
%figure(1);

%% Detection of no signal (no more than 5 quantisation stemps in last second or packet; max-min<5);
%% It seems that one packet length might not be enough as it triggers the flag between ECG R peaks.


%win_len=fs; % this is to do it in blocks of one second.
packet=63; % samples
win_len=packet;
prev_range=0
range_th=5; % quantisation step value = 1;
no_sig_flag=zeros(size(vec_t));
for i=1:floor(length(ecg_vec)/win_len)
    ind_start=1+((i-1)*win_len);
    ind_end=i*win_len;
    block=ecg_vec(ind_start:ind_end);
    pack_range=max(block)-min(block);
    if max([prev_range pack_range])<=range_th
        if i>win_len
            % Need for updating flag samples previous to the present packet.
            no_sig_flag(ind_start-win_len:ind_end)=1; % flag the last two packets
        else
            no_sig_flag(ind_start:ind_end)=1; % if at the start only flat one win_len
        end
    end 
    prev_range=pack_range;
end

%ax(3)=subplot(2,1,2); plot(vec_t,no_sig_flag,'r');
%ylim([-0.1 1.2])


%% Mains detector, this has been seen only in ECG signal. The ECG signal is sampled at 250Hz. 
%% Mains frequency is 50 Hz in both Poland and Switzerland so this ratio can be taken advantage of (1 sine cycle=5 samples).
%% Note, look at trans_variance over signal variance.
%split the signals in blocks of 5 samples, look at deviation in the 12 1st, 2nd, 3rd, 4th and 5th sample.

packet=63; % samples
win_len=packet;
var_th=2; % 5 quantisation steps.
mains_sig_flag=zeros(size(vec_t));
for i=1:floor(length(ecg_vec)/win_len)
    ind_start=1+((i-1)*win_len);
    ind_end=i*win_len;
    
    block=ecg_vec(ind_start:ind_end); % this corresponds to one bluetooth win_len.
    sig_mat=reshape(block(1:60),5,12);
    trans_var=zeros(1,5);
    for j=1:5
        trans_block=sig_mat(j,:); % Select rows 
        %i
        %j
        %trans_block
        %max(trans_block)
        %min(trans_block)
        trans_var(j)=max(trans_block)-min(trans_block);
    end
    %trans_var
    %size(trans_var)
    summary_trans_var=max(trans_var); % MAX is used to be conservative
    
    lin_var=zeros(1,12);
    for k=1:12
        lin_block=sig_mat(:,k); 
        lin_var(k)=max(lin_block)-min(lin_block);
    end
    %size(lin_var)
    summary_lin_var=min(lin_var);  % MIN is used to be conservative
    %size(summary_trans_var)
    %size(summary_lin_var)
    var_ratio=summary_trans_var/summary_lin_var;
    if summary_trans_var./summary_lin_var < 0.2
        % No need for updating flag samples previous to the present packet.
        %mains_sig_flag(ind_start:ind_end)=var_ratio.*ones(1,63); %1; % if at the start only flat one win_len
        mains_sig_flag(ind_start:ind_end)=1; % if at the start only flat one win_len
    end 
   
end


max(vec_t)
%% good signal label
%% AND all flags of signal areas of no/corrupted signal, then invert it to point at areas for MDs to look at.

good_sig_flag=zeros(size(vec_t));

good_sig_flag(find((mains_sig_flag+no_sig_flag+sat_flag)==0))=1;


%% Plotting section

ax(2)=subplot(5,1,2); plot(vec_t,mains_sig_flag.*0.7,'c'); ylim([-0.1 1.2]); ylabel('Mains detected')
ax(3)=subplot(5,1,3); plot(vec_t,no_sig_flag.*0.6,'r'); ylim([-0.1 1.2]); ylabel('No signal flag')
ax(4)=subplot(5,1,4); plot(vec_t,sat_flag.*0.5,'k'); ylim([-0.1 1.2]); ylabel('Signal saturation')

ax(5)=subplot(5,1,5); plot(vec_t,good_sig_flag.*0.4,'g'); ylim([-0.1 1.2]); ylabel('Non-corrupted signal'); hold on 
xlabel('time (hours)');
linkaxes(ax,'x');
zoom xon;


%% provide good signal time percentage value
%packet=63; % samples
win_len=fs*60; % one minute.
good_precent=zeros(size(good_sig_flag));
for i=1:floor(length(good_sig_flag)/win_len)
    ind_start=1+((i-1)*win_len);
    ind_end=i*win_len;
    
    block=good_sig_flag(ind_start:ind_end);
    good_precent(ind_start:ind_end)=sum(block)/win_len; % multiply by 100 later.
        
end
    
ax(6)=subplot(5,1,5); plot(vec_t,good_precent);
    


%% Detection of signal peaks (about 80 quantisation stemps in last 15 samples, going both up and down);
%% It seems that more than one packet length might might be necessary as some packets only carry signal between ECG R waves. 


%win_len=fs; % this is to do it in blocks of one second.
packet=63; % samples
win_len=packet;
prev_range=0
range_th=5; % quantisation step value = 1;
prev_sample=512 %to initialise the diff calculation.
diff_prev=0
diff_dir=0;
rise_det=0;
counter=0;
peak_sig_flag=zeros(size(vec_t));
peak_sig_flag2=zeros(size(vec_t));
for i=1:floor(length(ecg_vec)/win_len)
    ind_start=1+((i-1)*win_len);
    ind_end=i*win_len;
    block=ecg_vec(ind_start:ind_end);
    for j=1:length(block)
        if j==1 %this is if we are looking at the first sample of the packet.
            diff_val=block(j)-prev_sample;
        else
            diff_val=block(j)-block(j-1);
        end
        %diff_dir=sign(diff_val-diff_prev);
        %diff_dir=diff_val-diff_prev;
        diff_dir=diff_val;
        peak_sig_flag(ind_start+(j-1))=diff_dir;
        %j
        if diff_prev<=10 && diff_val>10
            rise_det=1;
        end
        if rise_det==1
            counter=counter+1;
        end
        if counter>0 && counter<20 && diff_prev<=-10 && diff_val>-10
            peak_sig_flag2(ind_start+(j-1)-counter:ind_start+(j-1))=1;
%             if vec_t(ind_start+(j-1))<0.01
%                 vec_t(ind_start+(j-1)) % display time on printout.
%                 diff_prev
%                 diff_val
%                 counter
%             end
            rise_det=0;
            counter=0;
        end
        if counter>20 % no detection so reset.
            rise_det=0;
            counter=0;
        end
        
        if j==length(block)
            prev_sample=block(j); % store the sample value of the last sample in the packet.
           % diff_prev=0; %diff_val % store the value of the last difference of the packet.
%             if i==2
%                 return
%             end
        end
        diff_prev=diff_val;
    end
    %---
    % Add if statement to cancel any detection that occurs during
    % corruption (an maybe also 1 sec before and after).
    %---
%     pack_range=max(block)-min(block);
%     if max([prev_range pack_range])<range_th
%         if i>win_len
%             % Need for updating flag samples previous to the present packet.
%             peak_sig_flag(ind_start-win_len:ind_end)=1; % flag the last two packets
%         else
%             peak_sig_flag(ind_start:ind_end)=1; % if at the start only flat one win_len
%         end
%     end 
%     prev_range=pack_range;
end
%ax(2)=subplot(5,1,2); hold on ; plot(vec_t,[0; 0.5+sign(diff(ecg_vec)).*0.5],'k'); ylim([-0.1 1.2]); ylabel('Mains detected and Diff')

%{ 
%Previous plotting for ECG R wave detections, this is for development as need to see Diff but for report use below.
figure; 
ax(6)=subplot(3,1,1); plot(vec_t,ecg_vec);
ax(7)=subplot(3,1,2); hold on ; plot(vec_t,[0; diff(ecg_vec)],'k');  ylabel('ECG diff')
ax(8)=subplot(3,1,2); hold on ; plot(vec_t,peak_sig_flag,'r');  ylabel('ECG diff'); grid on
%ax(9)=subplot(3,1,3); hold on ; plot(vec_t,peak_sig_flag2,'g'); ylim([0 1.2]);  ylabel('Mains detected and Diff')



%ecg_peak_det=good_sig_flag.*peak_sig_flag2;
good_sections=zeros(size(good_precent));
good_sections(find(good_precent>0.5))=1;
ecg_peak_det=good_sections.*peak_sig_flag2;
ax(9)=subplot(3,1,3); hold on ; plot(vec_t,ecg_peak_det,'g'); ylim([0 1.2]);  ylabel('ECG peak detections')
%}

%--
figure(2); 
ax(6)=subplot(2,1,1); plot(vec_t,ecg_vec); ylabel('ECG signal')
%ax(7)=subplot(3,1,2); hold on ; plot(vec_t,[0; diff(ecg_vec)],'k');  ylabel('ECG diff')
%ax(8)=subplot(3,1,2); hold on ; plot(vec_t,peak_sig_flag,'r');  ylabel('ECG diff'); grid on
%ax(9)=subplot(3,1,3); hold on ; plot(vec_t,peak_sig_flag2,'g'); ylim([0 1.2]);  ylabel('Mains detected and Diff')



%ecg_peak_det=good_sig_flag.*peak_sig_flag2;
peak_sig_flag2=good_sig_flag.*peak_sig_flag2; % remove peak detections from sections that are know not to have good signal.
good_sections=zeros(size(good_precent));
good_sections(find(good_precent>0.5))=1; % remove the peaks from the sections that have less than 50% of non-corructed signal.
ecg_peak_det=good_sections.*peak_sig_flag2;
ax(7)=subplot(2,1,2); hold on ; plot(vec_t,ecg_peak_det,'g'); ylim([0 1.2]);  ylabel('ECG peak detections')
xlabel('time (hours)');

%--
figure(20); 
ax(15)=subplot(2,1,1); plot(vec_t,ecg_vec); ylabel('ECG signal')
%ax(7)=subplot(3,1,2); hold on ; plot(vec_t,[0; diff(ecg_vec)],'k');  ylabel('ECG diff')
%ax(8)=subplot(3,1,2); hold on ; plot(vec_t,peak_sig_flag,'r');  ylabel('ECG diff'); grid on
%ax(9)=subplot(3,1,3); hold on ; plot(vec_t,peak_sig_flag2,'g'); ylim([0 1.2]);  ylabel('Mains detected and Diff')



%ecg_peak_det=good_sig_flag.*peak_sig_flag2;
% peak_sig_flag2=good_sig_flag.*peak_sig_flag2; % remove peak detections from sections that are know not to have good signal.
% good_sections=zeros(size(good_precent));
% good_sections(find(good_precent>0.5))=1; % remove the peaks from the sections that have less than 50% of non-corructed signal.
% ecg_peak_det=good_sections.*peak_sig_flag2;
ax(16)=subplot(2,1,2); hold on ; plot(vec_t,ecg_peak_det,'g'); ylim([0 1.2]);  ylabel('ECG peak detections');
ax(17)=subplot(2,1,2); hold on ; plot(vec_t,good_sections.*1.1); % ylim([0 1.2]);  ylabel('ECG peak detections')
xlabel('time (hours)');

no_peaks=size(find(diff(ecg_peak_det)>0.5))
no_sec_good=length(find(good_sections==1))*(1/fs)
%ecg_peak_det_over=ecg_vec.*ecg_peak_det';
%ax(8)=subplot(2,1,1); hold on; plot(vec_t,ecg_peak_det_over*0.9,'g'); ylabel('ECG signal')
%--

%--
figure(3); 
ax(8)=subplot(2,1,1); plot(vec_t,ecg_vec); ylabel('ECG signal')
ax(9)=subplot(2,1,2); plot(vec_t,mains_sig_flag,'c'); ylim([0 1.2]); ylabel('Mains detected')
xlabel('time (hours)');

figure(4); 
ax(10)=subplot(2,1,1); plot(vec_t,ecg_vec); ylabel('ECG signal')
ax(11)=subplot(2,1,2); plot(vec_t,sat_flag,'k'); ylim([0 1.2]); ylabel('Signal saturation')
xlabel('time (hours)');

figure(5); 
ax(12)=subplot(2,1,1); plot(vec_t,ecg_vec); ylabel('ECG signal')
ax(13)=subplot(2,1,2); plot(vec_t,no_sig_flag,'r'); ylim([0 1.2]); ylabel('Weak or no signal flag'); hold on
ax(14)=subplot(2,1,2); plot(vec_t,sat_flag,'k'); ylim([0 1.2]); % ylabel('Weak or no signal flag')
xlabel('time (hours)');

linkaxes(ax,'x');
zoom xon;

return

if save_figs==1
    figure(2)
    xlim([2 2.005])
    papersize = [8,6];
    set(gcf,'PaperUnits','inches','PaperPositionMode','Manual','PaperSize',papersize,'PaperPosition',[0,0,papersize(1),papersize(2)])
    print(gcf, '-dpdf','Figures/ecg-peak-det-01')
    
    xlim([0.432 0.437])
    papersize = [8,6];
    set(gcf,'PaperUnits','inches','PaperPositionMode','Manual','PaperSize',papersize,'PaperPosition',[0,0,papersize(1),papersize(2)])
    print(gcf, '-dpdf','Figures/ecg-peak-det-in-noise-01')
    
    figure(3); 
    %xlim([3.755 3.78])
    xlim([3.756 3.776])
    papersize = [8,6];
    set(gcf,'PaperUnits','inches','PaperPositionMode','Manual','PaperSize',papersize,'PaperPosition',[0,0,papersize(1),papersize(2)])
    print(gcf, '-dpdf','Figures/ecg-mains-det-01')
    
    % xlim([3.77 3.771])
    xlim([3.77111 3.77111+(1/3600)])
    papersize = [8,6];
    set(gcf,'PaperUnits','inches','PaperPositionMode','Manual','PaperSize',papersize,'PaperPosition',[0,0,papersize(1),papersize(2)])
    print(gcf, '-dpdf','Figures/ecg-mains-det-zoom-02')
    
    figure(4);
    xlim([3.76 3.764])
    papersize = [8,6];
    set(gcf,'PaperUnits','inches','PaperPositionMode','Manual','PaperSize',papersize,'PaperPosition',[0,0,papersize(1),papersize(2)])
    print(gcf, '-dpdf','Figures/ecg-sat-det-01')
    %ylim([0 1200]) This is the default that the figure printer sets the y
    %axis to.
    
%     %Script to save images of the figure with markers to show 949 and 74 signal saturation levels.
%     %manual unconstrained zoom
%     papersize = [8,6];
%     set(gcf,'PaperUnits','inches','PaperPositionMode','Manual','PaperSize',papersize,'PaperPosition',[0,0,papersize(1),papersize(2)])
%     print(gcf, '-dpdf','Figures/ecg-sat-det-zoom-01')
%     
%     %manual unconstrained zoom
%     ylim([0 250])
%     papersize = [8,6];
%     set(gcf,'PaperUnits','inches','PaperPositionMode','Manual','PaperSize',papersize,'PaperPosition',[0,0,papersize(1),papersize(2)])
%     print(gcf, '-dpdf','Figures/ecg-sat-det-zoom-02')
    
    figure(5);
    xlim([5.9 5.95])
    papersize = [8,6];
    set(gcf,'PaperUnits','inches','PaperPositionMode','Manual','PaperSize',papersize,'PaperPosition',[0,0,papersize(1),papersize(2)])
    print(gcf, '-dpdf','Figures/ecg-weak-sig-det-01')
    
end
%xlim([3.755 3.78])

return
xlim([2.02 2.03])
xlim([3.74 3.8]) % transition from signal to mains
xlim([5.88 5.96]) % transition from mains to no-signal
xlim([18.9 19.3]) % transition from mains to no-signal

    
    
    


