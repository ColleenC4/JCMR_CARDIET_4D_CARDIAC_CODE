%
% [paramStructure]=backgroundPhaseCorrection(...)
%   [paramStructure]=backgroundPhaseCorrection('dirPath','/Usr/dir/')
%   [paramStructure]=backgroundPhaseCorrection('paramNameList',['PVM_Matrix',..])
%
% Author:   Aurélien TROTIER  (a.trotier@gmail.com)
% Date:     2016-05-26
% Partner:  I worked alone on this program
% Institute: CRMSB (Bordeaux)
%
% Function description:
%   Read parameters from a bruker experiments in acqp, method.
%
%    If optional parameters dirPath is pass, parameters were directly read in this directory.
%    If optional parameters paramNameList is pass, only parameters with the
%    same name were read.
%
% Input:
%
%  Optional:
%    'dirPath': (string) path to the folder of a bruker experiment
%    'paramNameList': (array of string) with the name of each parameters to
%    retrieve from files
%
% Output:
%	paramStructure : structure with the name of each parameters and its value
%
% Algorithm & bibliography:
%
%
% See also :
%   Implementation first done in Goa (Guerbet) and extract to simplify
%   process for research.
%
% To do :
%   read also reco
%

function [paramStructure]=readParams_Bruker(varargin)
%% init
dirPath=[];
paramNameList=[];

% parse optional input parameters
v = 1;
while v < numel(varargin)
    switch varargin{v}
        case 'dirPath'
            assert(v+1<=numel(varargin));
            v = v+1;
            dirPath = varargin{v};
        case 'paramsList'
            assert(v+1<=numel(varargin));
            v = v+1;
            paramNameList=varargin{v};
        otherwise
            fprintf('Unsupported parameter: %s',varargin{v});
    end
    v = v+1;
end

%%
if isempty(dirPath) %choose the directory
    dirPath=uigetdir('*.*','Open rawdata bruker directory');
    cd(dirPath);
    if isequal(dirPath,0)
        error('directory path is not well defined');
    end
end

%%

p = read_bru_experiment(dirPath);

paramStructure=p.method;
f=fieldnames(p.acqp);

for i=1:length(f)
    paramStructure.(f{i})=p.acqp.(f{i});
end

paramStructure.dirPath=dirPath;


end