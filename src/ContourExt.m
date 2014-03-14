function res = ContourExt(varargin)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ContourExt.m
% Usage: ContourExt('inputFileName', 'outputFileName');
%
% Extract contours from images 'cc1.tiff', 'cc2.tiff', etc. The
% bounding-box information is provided in 'inputFileName'{'bb.csv'} and contour
% coordinates are stored in file 'outputFileName'{'contour.csv'}.
%
% Authors: Siyu Zhu, Lei Hu, Richard Zanibbi
%	June-August 2012
% Copyright (c) 2012, Siyu Zhu, Lei Hu, Richard Zanibbi
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


tic
if nargin==2
    filename=varargin{1};
    filenamew=varargin{2};
elseif nargin==0
    filename = 'bb.csv';
    filenamew = 'contour.csv';
    disp('No input and output is specified, use ''bb.csv'' as input and ''Contour.csv''as output filenames.')
else
    error('Input must be two strings specify {''input''}, {''output''} csv filename or leave blank');
end



disp('Loading bb.csv file');
fid=fopen(filename);
f=textscan(fid, '%s', 'bufsize', 40960);
fclose('all');
f=f{1};
n=cellfun(@(x) textscan(x, '%s', 'delimiter', ','), f, 'UniformOutput', 0);
cc = cell(1, length(n)-1);
x1 = cell(1, length(n)-1);
x2 = cell(1, length(n)-1);
y1 = cell(1, length(n)-1);
y2 = cell(1, length(n)-1);

k=1;
for i=2:length(n)
    cc{k} = n{i}{1}{1};
    x1{k} = n{i}{1}{2};
    y1{k} = n{i}{1}{3};
    x2{k} = n{i}{1}{4};
    y2{k} = n{i}{1}{5};
    k = k+1;
end

x1=  cellfun(@str2num, x1);
y1=  cellfun(@str2num, y1);
filelistu = struct('name', {' '});
filelist = repmat(filelistu, [1, length(cc)]);

for i=1:length(cc)
    filelist(i).name = [cc{i}, '.tiff'];
end

disp('Open contour.csv file for writing');
fid = fopen(filenamew, 'w');

disp('Extracting countours from images');
for i=1:length(filelist)
    clear im
    im0 = imread([filelist(i).name]);
    if size(im0, 3)==4;
        r = im0(:, :, 1);
        g = im0(:, :, 2);
        b = im0(:, :, 3);
        im(:, :, 1)=r;
        im(:, :, 2)=g;
        im(:, :, 3)=b;
        im=im2bw(im);
    elseif size(im0, 3)==3;
        im=im2bw(im0);
    else
        im=im0;
    end
    im=1-im;
    bd = bwboundaries(im);
    for ii = 1:length(bd)
        fprintf(fid, '%s, ', [cc{i}]);
        fprintf(fid, '%s, ', ['contour', num2str(ii)]);
        if ii==1
            fprintf(fid, '%s, ', '*');
        else
            fprintf(fid, '%s, ', '-');
        end
        b0 = bd{ii};
        b1 = b0;
        b1(:, 2) = b0(:, 1)+y1(i);
        b1(:, 1) = b0(:, 2)+x1(i);
        b2 = b1';
        b2=b2(:);
        fprintf(fid, '%u, ', b2);
        fprintf(fid, '\n');
    end
end
res = 0;
disp('Done!');
toc
end
