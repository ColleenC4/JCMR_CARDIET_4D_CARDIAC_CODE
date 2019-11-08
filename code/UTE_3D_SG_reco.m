%% Script UTE 3D SG

clear all
close all
clc

%% DATA READING

p=readParams_Bruker(); % Sequence parameters

sizeR2=p.ACQ_size(1)/2;
sizeR=p.PVM_Matrix(1);
sizeR3=p.PVM_Matrix(1)/2+p.RampPoints;
nc=p.PVM_EncNReceivers;
NR=p.NR;
NR2=NR;

Ntime=30; % ----- Number of frames per cardiac/respiratory cycle -----

clear rawData;
rawData=readFIDMc(sizeR2,nc,[p.dirPath '/fid']); % Rawdata

for i=1:nc
    rawData{i}=reshape(rawData{i},sizeR2,[],NR); 
    rawData{i}=rawData{i}(:,:,1:NR2);
end

NR=NR2;

%% CARDIAC PEAKS DETECTION

y=abs(sum(double(rawData{4}(4,:)),1)); % 4 = Number of self-gating points (/5 acquired)
sigma =10;
sizef = 20;
x = linspace(-sizef / 2-1, sizef / 2, sizef); 
gaussFilter = exp(-x .^ 2 / (2 * sigma ^ 2)); 
gaussFilter = gaussFilter / sum (gaussFilter); % Normalize

yfilt = conv (y, gaussFilter,'same'); 

T = 0.004;                   % Sample time (TR)     % **** TO UPDATE AS A FUNCTION OF THE SEQUENCE PARAMETERS ****
Fs = 1/T;                    % Sampling frequency
L = length(y);               % Length of signal
t = (0:L-1)*T;               % Time vector

idx_COEUR=peakfinder(yfilt/max(yfilt),1/1000); % **** TO UPDATE AS A FUNCTION OF THE DATASET AMPLITUDE ****
 
figure;plot(t,yfilt);hold on;
title('[1] Cardiac Peaks');xlabel('Time (s)');ylabel('Amplitude');hold on;
plot(t(idx_COEUR),yfilt(idx_COEUR),'ro');hold on;

%% RESPIRATORY PEAKS DETECTION

yfilt_inv=1./yfilt;

idx_RESP=peakfinder(yfilt_inv/max(yfilt_inv),1/100); % **** TO UPDATE AS A FUNCTION OF THE DATASET AMPLITUDE (Surf. : 1/50 ; Volum. : 1/200)**** 

figure;plot(t,yfilt_inv);title('[2] Respiratory Peaks');xlabel('Time (s)');ylabel('Amplitude');hold on;
plot(t(idx_RESP),yfilt_inv(idx_RESP),'bo');hold on;

%% CARDIAC PEAKS SUPPRESSION DURING THE RESPIRATORY PHASE 

idx_COEUR(1)=[];
amp_COEUR=yfilt(idx_COEUR); 
nv_idx_COEUR=zeros(1,600000);

for i=16:(length(idx_COEUR)-1)
    moy_amp_COEUR=median(amp_COEUR((i-15):i)); % Median of the 15 previous peaks
    if amp_COEUR(i)<0.996*moy_amp_COEUR
        nv_idx_COEUR(i)=idx_COEUR(i); % If the peak amplitude is < 99.6% of the median, then its stored in a new vector
    end
end

D=find(nv_idx_COEUR==0);
nv_idx_COEUR(D)=[];
nv_idx_COEUR=sort(nv_idx_COEUR);
nv_idx_COEUR=unique(nv_idx_COEUR);

% Loop which delete the original values of the vector
for i=1:length(nv_idx_COEUR) 
    I=find(idx_COEUR==nv_idx_COEUR(i));
    idx_COEUR(I)=[];
end

figure;plot(t,yfilt);hold on;
title('[3] Cardiac data suppression during respiratory peaks');xlabel('Time (s)');ylabel('Amplitude');hold on;
plot(t(idx_COEUR),yfilt(idx_COEUR),'ro');hold on;

%% CARDIAC PEAKS INTERPOLATION

new_idx_COEUR=zeros(1,600000);
diff1=diff(idx_COEUR);
mediane=median(diff1); % Median cardiac cycle duration
grd_ecarts=find(diff1>1.2*mediane);
ecart_moyen=diff1;
ecart_moyen(grd_ecarts)=[];
ecart_moy=mean(ecart_moyen); %Mean cardiac cycle duration during all the experiment

new_it=0;

 for i=1:(length(idx_COEUR)-1) 
     diff_coeur=diff(idx_COEUR);
     
     if diff_coeur(i)>1.2*mediane % If the cardiac cycle is > to the median 
         
         new_i=0;
         
         for k=i-1:-1:1
             if diff_coeur(k)<1.2*mediane; 
                 new_i=new_i+1; 
             else
                 break
             end
         end
         
         m_before=mean(diff_coeur(i-new_i:i-1)); % Mean cardiac duration of the previous peaks
         m=round(diff_coeur(i)/m_before); % Calulates the number of cardiac peaks to interpolate
         
         if m>1
             for pResp=1:m-1 % Calculates the number of cardiac peaks to interpolate according to the respiratory peak length
                 new_idx_COEUR(new_it+1)=round(idx_COEUR(i)+((idx_COEUR(i+1)-idx_COEUR(i))/m*pResp)); %Vector new_idx_COEUR contains the new interpolated cardiac peaks values
                 new_it=new_it+1;
             end
         end
         new_it=new_it+1;
     end
 end

S=find(new_idx_COEUR==0);
new_idx_COEUR(S)=[];

%% CARDIAC ORIGINAL + INTERPOLATED VIEWING

amplitude_c=yfilt(idx_COEUR);
amplitude=median(amplitude_c)*(ones(1,length(new_idx_COEUR)));

figure;plot(t,yfilt);hold on;
title('[4] Cardiac peaks ORIGINAL + INTERPOLATED');xlabel('Time (s)');ylabel('Amplitude');hold on;
plot(t(idx_COEUR),yfilt(idx_COEUR),'ro');hold on;
plot(t(new_idx_COEUR),amplitude,'go');hold on;
legend('Self-Gated Signal','Original Cardiac Peaks','Interpolated Cardiac Peaks');

%% CARDIAC PEAKS RECUPERATION

amplitude_r=yfilt(idx_RESP);
amplitude_ci=yfilt(new_idx_COEUR); % Interpolated peaks amplitudes 

% Loop which calculates the mean gap between respiratory peaks and heart during a window (3 respiratory peaks)
i2=0;

for i=1:2:length(idx_RESP)-2
    debut=idx_RESP(i); % First resp. peak index of the window 
    fin=idx_RESP(i+2); % Last resp. peak index of the window 

    moy_amplitude_r=mean(amplitude_r(i:i+2)); % Mean amplitude of the respiration during the window
    indices_c=find(debut<idx_COEUR & idx_COEUR<fin); % Cardiac peaks index of this window
    moy_amplitude_c=mean(amplitude_c(indices_c)); % Mean cardiac amplitude during this window 
    ecart=moy_amplitude_c-moy_amplitude_r; % Mean gap between respiratory and cardiac peaks
    
    %2) Calculate the cardiac peaks gaps 
    
    indices_ci=find(debut<new_idx_COEUR & new_idx_COEUR<fin); % Cardiac peaks index to sort within the window
    
    %3) Loop which looks if the the new cardiac peaks are < or > 95% of the mean gap
    %l'écart moyen
    % If < : stay in vector new_idx_COEUR
    % If > : store in a new vector idx_RECUP
    
    for new_i=1:length(indices_ci)
        index=indices_ci(new_i); % Index = Cardiac peak index 
        ecart_ci=amplitude_ci(index)-moy_amplitude_r; % Mean gap between the respiratory and cardiac peaks
        if ecart_ci>0.95*ecart
            i2=i2+1;
            idx_RECUP(i2)=new_idx_COEUR(index); % New vector containing the new stable cardiac peaks
        end
    end
end

%% WHOLE HEART VECTOR

if exist('idx_RECUP','var') == 0
    % No retrieved values
    new_idx_COEUR2=[new_idx_COEUR zeros(1,length(idx_COEUR)-length(new_idx_COEUR))];
    idx_COEUR_entier=horzcat(idx_COEUR,new_idx_COEUR2);
    H=find(idx_COEUR_entier==0);
    idx_COEUR_entier(H)=[];
    idx_COEUR_entier=sort(idx_COEUR_entier); % Vector idx_COEUR_entier containing all the cardiac peaks (original + interpolated)
    
    figure;
    plot(t,yfilt);hold on;
    title('[6] Cardiac and Respiratory peaks');xlabel('Time (s)');ylabel('Amplitude');hold on;
    plot(t(idx_RESP),yfilt(idx_RESP),'bo');hold on;
    plot(t(idx_COEUR),yfilt(idx_COEUR),'ro');hold on;
    plot(t(new_idx_COEUR),amplitude,'go');hold on;
    legend('Self-Gated Signal','Respiration','Original Cardiac Peaks','Interpolated Cardiac Peaks');
    
else
    % Retrieved values
    
    figure;plot(t,yfilt);hold on;
    title('[5] Original + "Retrieved" cardiac peaks');xlabel('Time (s)');ylabel('Amplitude');hold on;
    plot(t(idx_RESP),yfilt(idx_RESP),'bo');hold on;
    plot(t(idx_COEUR),yfilt(idx_COEUR),'ro');hold on;
    plot(t(new_idx_COEUR),amplitude,'go');hold on;
    plot(t(idx_RECUP),yfilt(idx_RECUP),'mo');hold on;
    legend('Self-Gated Signal','Stable','Interpolated','"Retrieved" stable peaks');
    
    for i=1:length(idx_RECUP) % Delete initial vector values
        J=find(new_idx_COEUR==idx_RECUP(i));
        new_idx_COEUR(J)=[];
    end
    
    idx_RECUP2=[idx_RECUP zeros(1,length(idx_COEUR)-length(idx_RECUP))];
    idx_COEUR=horzcat(idx_COEUR,idx_RECUP2);
    G=find(idx_COEUR==0);
    idx_COEUR(G)=[];
    idx_COEUR=sort(idx_COEUR);  % Vector idx_COEUR_entier contains the original cardiac peaks
    
    new_idx_COEUR2=[new_idx_COEUR zeros(1,length(idx_COEUR)-length(new_idx_COEUR))];
    idx_COEUR_entier=horzcat(idx_COEUR,new_idx_COEUR2);
    H=find(idx_COEUR_entier==0);
    idx_COEUR_entier(H)=[];
    idx_COEUR_entier=sort(idx_COEUR_entier); % Vector idx_COEUR_entier contains all the cardiac peaks (original + interpolated)
    
    amplitude_new=median(yfilt(new_idx_COEUR))*(ones(1,length(new_idx_COEUR))); 
    figure;
    plot(t,yfilt);hold on;
    title('[6] Cardiac and Respiratory Peaks');xlabel('Time (s)');ylabel('Amplitude');hold on;
    plot(t(idx_RESP),yfilt(idx_RESP),'bo');hold on;
    plot(t(idx_COEUR),yfilt(idx_COEUR),'ro');hold on;
    plot(t(new_idx_COEUR),amplitude_new,'go');hold on;
    legend('Self-Gated Signal','Respiration','Original Cardiac Peaks','Interpolated Cardiac Peaks');
end

%% RESPIRATORY AND CARDIAC FREQUENCIES 

mr=diff(t(idx_RESP));
freq_resp_pm=60/(sum(mr)/size(mr,2));
mr(size(idx_RESP,2))=mean(mr);
figure;plot(t(idx_RESP),60./mr);
title('[7] Respiratory frequency')
xlabel('Time (s)');
ylabel('Respiratory frequency');
fprintf('Median respi = %.1f\n',median(60./mr));
fprintf('Std respi = %.1f\n',std(60./mr));

mc=diff(t(idx_COEUR_entier));
bpm_coeur=60/(sum(mc)/size(mc,2));
mc(size(idx_COEUR_entier,2))=t(size(t,2))-t(size(idx_COEUR_entier,2)-1);
figure;
plot(t(idx_COEUR_entier),60./mc);
title('[8] Cardiac frequency')
xlabel('Time (s)');
ylabel('Cardiac frequency');
fprintf('Median cardiac = %.1f\n',median(60./mc));
fprintf('Std cardiac = %.1f\n',std(60./mc));

%% TRAJECTORY READING

fid=fopen([p.dirPath '/traj'],'r');
data=fread(fid,'double','l');
fclose(fid);

fsize=length(data);

traj=reshape(data,3,fsize/3)'; % Data reorganisation to have 3 columns and fsize/3 lines %traj : 210000x3

traj2=[];

for i=1:NR
    traj2=[traj2;traj]; % Copy of traj in traj2 NR  times : 42000000x3
end

traj=reshape(traj2,sizeR3,[],3); % Reorganisation %70x900000x3

%% DATA POSITION IN EACH CARDIAC PHASES

clear ktrajECG
ktrajECG=zeros(size(rawData{1},2)*size(rawData{1},3),1); 

% CASE 1 : idx_RESP          -> RESPIRATION
% CASE 2 : idx_COEUR         -> ORIGINAL CARDIAC PEAKS
% CASE 3 : idx_COEUR_entier  -> WHOLE HEART (ORIGINAL + INTERPOLATED)

% ***** CHOOSE AS A FUNCTION OF THE DESIRED RECONSTRUCTION : *****

list = {'1 (RESPIRATION)','2 (ORIGINAL CARDIAC PEAKS)','3 (WHOLE HEART (ORIGINAL+INTERPOLATED)'};
[reco] = listdlg('ListString',list);

switch(reco)
    case 1
        idxid=idx_RESP;
        mea=median(diff(idxid));
    case 2
        idxid=idx_COEUR;
        mea=median(diff(idxid));
    case 3
        idxid=idx_COEUR_entier;
        mea=median(diff(idxid));
end

conteurEx=0;
for i=1:length(ktrajECG)
    
    picBefore=idxid(find(idxid<i,1,'last')); % find(...) store the last element index of idxid < i in peakBefore
    picAfter=idxid(find(idxid>=i,1,'first')); % find(...) store the first element index of idxid >= i in peakAfter
    

    if isempty(picBefore)
        picBefore=idxid(1)-(idxid(10)-idxid(5))/5; % Starts the reading before the first point (-160.4)
    end
    
    if isempty(picAfter)
        picAfter=idxid(end)+(idxid(end)-idxid(end-3))/3; % Ends the reading after the last point (300160)
    end
   
    idxImg=1+floor((i-picBefore)/(picAfter-picBefore)*Ntime); % Defines the point position in the cycle (from 1 to Ntime)
    
    if idxImg>Ntime
        idxImg=Ntime;
    elseif idxImg<1
        idxImg=1;
    end
    
    if 0.8*mea<abs(picAfter-picBefore) & abs(picAfter-picBefore)<1.2*mea % Condition : the point is in the gap between 2 peaks 
        
        ktrajECG(i)=idxImg;
        

    else
        conteurEx=conteurEx+1;
    end
    
end

conteurEx
conteurEx/length(ktrajECG)

%% DATASETS CREATION FOR EACH PHASE

clear trajECG rawDataECG

for i =1:nc
    rawData{i}=reshape(rawData{i},sizeR2,[]); 
    rawData2{i}=rawData{i}(end-sizeR3+1:end,:);
end

traj=reshape(traj,sizeR3,[],3); % traj : 70x600000x3 double

rawDataECG=cell(Ntime,1);
for i=1:Ntime
    rawDataECG{i}=cell(nc,1);
    
    ktrajIdx=find(ktrajECG==i);
    
    for j=1:nc

            rawDataECG{i}{j}=rawData2{j}(:,ktrajIdx);
            trajECG{i}=traj(1:end,ktrajIdx,:);

    end
end

squeeze(rawDataECG);

% Number of projections per cycle

for i=1:Ntime
    proj_cycle(i)=size(trajECG{i},2);
end

fprintf('Total projections = %d\n',sum(proj_cycle));
fprintf('Total projections ratio (percent) = %.1d\n',(sum(proj_cycle)/(size((rawData{1}),2)))*100);

fprintf('Median projections per cycle = %d\n',median(proj_cycle));

%% RECONSTRUCTION

clear im
im=cell(Ntime,1);

for j=1:nc
    im{i}{j} = zeros(sizeR,sizeR,sizeR);
end

for i=1:Ntime
        % Calculating w : density compensation factor necessary for the gridding reconstruction
        numIter = 10
        effMtx  = sizeR
        osf     = 2
        verbose = 1
        
        % Reco
        w = sdc3_MAT(reshape(trajECG{i},[],3)',numIter,effMtx,verbose,osf);
        w = double(w); % float32
        
        % NUFFT
        wg =2;
        sw = 4;
        FT = gpuNUFFT(reshape(trajECG{i},[],3)',w,osf,wg,sw,[sizeR,sizeR,sizeR],[],true);
        % FT = gpuNUFFT(reshape(trajECG{i}{k},[],3)',w,osf,wg,sw,[sizeR,sizeR,sizeR],[],true);
        for j=1:nc
            im{i}{j} = FT'*reshape(rawDataECG{i}{j},[],1);
            %im{i}{j} = FT'*ones(size(reshape(rawDataECG{i}{j},[],1)));  %PSF
        end
end

for i=1:Ntime
      image_name(:,:,:,i)=sqrt(abs(im{i}{1}.^2)+abs(im{i}{2}.^2)+abs(im{i}{3}.^2)+abs(im{i}{4}.^2));
end


imagine(image_name)

