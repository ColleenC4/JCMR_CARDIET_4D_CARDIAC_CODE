%----------------------------------------------------------------------------
%Function extracting rawdata from an Bruker FID files (4 canals)
%
%INPUT : sizeR => Size of the read matrix (number of sample per TR)
%        sizeP => Number of projection
%
%OUTPUT : rawData => complex matrix of size x=Nread / y=number of fid
%----------------------------------------------------------------------------



function rawData1=readFIDMc(sizeR,nc,infile)
if nargin<3 || isempty(infile)

%select file 

    rawData1=[];
    [filename,dirname]=uigetfile('*.*','Open MR rawData file');
    
    if isequal(filename,0) || isequal(dirname,0)
            return;
    end
    
    infile=[dirname,filename];

    cd(dirname);
end
%Read file
    fid=fopen(infile,'r','b');
    rawData=fread(fid,'int32=>int32','l');
    fclose(fid);

    
    rawData=reshape(rawData,double(2),[]);
    
    rawData=complex(rawData(1,:),rawData(2,:));
   
    %rawData=rawData(1:256*4*60000);
    
%    if sizeR*nc<=384 && sizeR*nc>256
%         sizeR2=384;
%     elseif sizeR*nc<=512 && sizeR*nc>384
%         sizeR2=512;
%     elseif sizeR*nc<=640 && sizeR*nc>512
%         sizeR2=640;
%    elseif sizeR*nc<=1024 && sizeR*nc>640
%        sizeR2=768;
%     elseif sizeR*nc <= 1152 && sizeR*nc > 1024
%         sizeR2=1152;
%    elseif sizeR*nc <= 3200 && sizeR*nc > 3000
%        sizeR2=3200;
%     else
%         sizeR2=sizeR*nc;
%     end
    
sizeR2=128*ceil(sizeR*nc/128);

    %rawData=rawData(1:floor(length(rawData)/sizeR2*sizeR2));
    rawData=reshape(rawData,sizeR2,[]);
    
    rawData=rawData(1:nc*sizeR,:);

    %%
    
    rawData1=cell(1,nc);
    
    for i=1:nc
        rawData1{i}=rawData((i-1)*sizeR+1:i*sizeR,:);
      %  rawData1{i}=reshape(rawData1{i},[],1);
    end
       
end