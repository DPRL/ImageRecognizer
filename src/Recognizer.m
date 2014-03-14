function res = Recognizer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Recognizer.m
%
% Generate isolated symbol image from input image and bounding box 
% information (output of Segmenter). Recognize symbol class using Nearest 
% Neighbor method. Output is ICDAR symbol code. 
%
% Authors: Siyu Zhu, Lei Hu, Richard Zanibbi
%	June-August 2012
% Copyright (c) 2012, Siyu Zhu, Lei Hu, Richard Zanibbi
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	tic
	global trsc
	global trgv
	%% loading testing vectors;
	im1 = symbolImage();
	%% Generating grid vectors;
	n = 5;
	tegv = zeros(length(im1), n*n);
	parfor i=1:length(im1)
	    im = im1{i};
	    im = imresize(im, [n, n], 'bilinear');
	    v = im(:);
	    tegv(i, :)=v;
	end

	%% Classification
	sc = NNclassifier(trsc, trgv, tegv);
	%% Convert Infty to Unicode;
	symbolClass = cell(length(sc), 1);
	for i=1:length(sc)
	       symbolClass{i} = Code2Class(sc{i});
	%      symbolClass(i) = sc(i);
	end

	%% Open segmentation file for reference;
	filename = 'segments.csv';
	fid=fopen(filename);
	f=textscan(fid, '%s', 'delimiter', '\n');
	fclose('all');
	f = f{1};
	n = cellfun(@(x) textscan(x, '%s', 'delimiter', ','), f, 'UniformOutput', 0);
	n = cellfun(@(x) x{1}, n, 'UniformOutput', 0);

	%% Write classfication results to file;
    fid = fopen('symbolClass.csv', 'w');
    for i=1:length(symbolClass)
        fprintf(fid, '%s', symbolClass{i});
        for j=1:length(n{i})
            fprintf(fid, ',%s', n{i}{j});
        end
        fprintf(fid, '\n');
    end
	fclose('all');
	toc
	res = 0;
end

%% 1-Nearest Neighbor Classifier;
function sc = NNclassifier(trsc, trgv, tegv)
	sc = cell(size(tegv, 1), 1);
	for i = 1:size(tegv, 1)
	    gv = tegv(i, :);
	    gv = repmat(gv, [length(trsc), 1]);
        whos gv trgv
	    dis = sum((gv - trgv).^2, 2);
	    [~, d]=min(dis);
	    sc(i) = trsc(d);
	end
end

%% generate symbol image from segments.csv, bb.csv and cc*.tiff files and
% pass the image map using 'imCell';
function imCell = symbolImage()
	% Read bb.csv file and save bounding box information in x1, y1, x2, y2.
	filename = 'bb.csv';
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
	x1=str2double(x1);
	x2=str2double(x2);
	y1=str2double(y1);
	y2=str2double(y2);

	for i =1 :length(x1)
	    X1 = x1(i);
	    X1 = max(X1, 1);
	    x1(i) = X1;
	    Y1 = y1(i);
	    Y1 = max(Y1, 1);
	    y1(i) = Y1;
	end
	% Read segments.csv file and tiff files. 
	% segments.csv tells which CCs are belonging to the same symbol.
	% tiff files provide the CCs' shape;
	% bb.csv tells CCs' position.
	filename = 'segments.csv';
	fid=fopen(filename);
	f=textscan(fid, '%s', 'delimiter', '\n');
	fclose('all');
	f = f{1};
	n = cellfun(@(x) textscan(x, '%s', 'delimiter', ','), f, 'UniformOutput', 0);
	imCell = cell(1, length(n));
	for i=1:length(n)
	    m = n{i}{1};
	    mnum = cellfun(@(x) strrep(x, 'cc', ''), m, 'UniformOutput', false);
	    mnum = str2double(mnum);
	    canvas = zeros(max(y2(mnum+1)), max(x2(mnum+1)));
	    for j=1:length(m)
		% in case that tiff image has four layers, we give the code below:
		clear im1
		im = imread([m{j}, '.tiff']);
		if size(im, 3)==4
		    r = im(:, :, 1);
		    g = im(:, :, 2);
		    b = im(:, :, 3);
		    im1(:, :, 1) = r;
		    im1(:, :, 2) = g;
		    im1(:, :, 3) = b;
		else
		    im1 = im;
		end
		% convert im to double with dynamic range from 0 to 1;
		% the foreground is 1 and background is 0.
		im1=double(im1);
		im1=im1/max(im1(:));
		im1 = im2bw(im1);
		im1 = 1- im1;
		% canvas is the symbol image we produced;
		% one CC each time;
		canvas(y1(mnum(j)+1):y1(mnum(j)+1)+size(im1, 1)-1, x1(mnum(j)+1):x1(mnum(j)+1)+size(im1, 2)-1)=im1;
	    end
	    % eventually canvas is cropped to contain the minimum image area.
	%    canvas = canvas(min(y1(mnum+1)):end, min(x1(mnum+1)):end);
	    ymin_canvas = find(sum(canvas, 1), 1, 'first');
	    ymax_canvas = find(sum(canvas, 1), 1, 'last');
	    xmin_canvas = find(sum(canvas, 2), 1, 'first');
	    xmax_canvas = find(sum(canvas, 2), 1, 'last');
	    canvas = canvas(xmin_canvas:xmax_canvas, ymin_canvas:ymax_canvas);
	    imCell{i}=canvas;
	end
end




%%
function OutputSymbolClass = Code2Class(InputSymbolCode)
% this function is used to convert the hexadecimal infty code to its
% corresponding symbol class;
% InputSymbolCode is not a number but a string.

% get symbol code list;
%	SymbolCodeList = {};
%	defaultStr = '&#x58;'; % Upper X
	defaultStr = '&#x25a0;' % black square

	fid = fopen('final.txt');
	SymbolClassNum = 629;
	for i = 1:SymbolClassNum
	    tline = fgetl(fid);
	    CommaLocation = strfind(tline, ',');
            SemiColonLocation = strfind(tline, ';');
	    SymbolCode = tline(3:CommaLocation(1)-1); % 3rd charcter to first comma

	    inftyCode = tline(CommaLocation(2)+1:CommaLocation(3)-1);
	    icdarCode = Infty2Icdar(inftyCode);
	    if ~isempty(SemiColonLocation)
		SymbolClass = tline(CommaLocation(3)+1:length(tline)); % after last camma, before semicolon
	    else
       	        SymbolClass = defaultStr; % default string 
	    end
%	    if strcmp(icdarCode , 'X_upper')
%		SymbolClass = defaultStr;
%	    end
	    SymbolCodeList(i).SymbolCode = SymbolCode;
	    SymbolCodeList(i).SymbolClass = SymbolClass;
	end
	fclose(fid);
	% convert the code to its corresponding symbol class;
	% many symbols' codes are not in the code list "OcrCodeList.txt", such as '33f0','33f1','33f2' and so on
	SymbolCodeInList = 0;
    TemSymbolClass = defaultStr; % use defaultStr if the recognized symbol is not in the list.
    for i = 1:SymbolClassNum
        if(strcmp(InputSymbolCode, SymbolCodeList(i).SymbolCode))
            TemSymbolClass  = SymbolCodeList(i).SymbolClass;
            SymbolCodeInList = 1;
            break;
        end
    end
    OutputSymbolClass = TemSymbolClass;
	%% if (SymbolCodeInList==0)
	%%     TemSymbolClass  = 'int';% for the symbol whose code is not in the list, it will be recognized as 'int'
	%%     % special case for "int"
	%%     if(strcmp(InputSymbolCode, '33f0'))
	%%         TemSymbolClass  = 'int';
	%%     end
	%%     % special case for "sqrt"
	%%     if(strcmp(InputSymbolCode, '33f2'))
	%%         TemSymbolClass  = 'sqrt';
	%%     end
	%% end
	% convert the symbol class in infty to its icdar version
	% OutputSymbolClass = Infty2Icdar(TemSymbolClass);
end





%%
function OutputSymbolClass = Infty2Icdar(TemSymbolClass)
% this function is used to convert the symbol class in infty to its icdar
% version.

	% establish the mapping table;
	MappingTable = {};
	MappingTable{1}.icdar = '0'; MappingTable{1}.infty = 'zero';
	MappingTable{2}.icdar = '1'; MappingTable{2}.infty = 'one';
	MappingTable{3}.icdar = '2'; MappingTable{3}.infty = 'two';
	MappingTable{4}.icdar = '3'; MappingTable{4}.infty = 'three';
	MappingTable{5}.icdar = '4'; MappingTable{5}.infty = 'four';
	MappingTable{6}.icdar = '5'; MappingTable{6}.infty = 'five';
	MappingTable{7}.icdar = '6'; MappingTable{7}.infty = 'six';
	MappingTable{8}.icdar = '7'; MappingTable{8}.infty = 'seven';
	MappingTable{9}.icdar = '8'; MappingTable{9}.infty = 'eight';
	MappingTable{10}.icdar = '9'; MappingTable{10}.infty = 'nine';
	MappingTable{11}.icdar = '_plus'; MappingTable{11}.infty = 'plus';
	MappingTable{12}.icdar = '_dash'; MappingTable{12}.infty = 'minus';
	MappingTable{13}.icdar = '_equal'; MappingTable{13}.infty = 'equal';
	MappingTable{14}.icdar = 'geq'; MappingTable{14}.infty = 'geq';
	MappingTable{15}.icdar = 'lt'; MappingTable{15}.infty = 'less';
	MappingTable{16}.icdar = 'neq'; MappingTable{16}.infty = 'notequal';
	MappingTable{17}.icdar = 'leq'; MappingTable{17}.infty = 'leq';
	MappingTable{18}.icdar = 'int'; MappingTable{18}.infty = 'int';
	MappingTable{19}.icdar = 'times'; MappingTable{19}.infty = 'times';
	MappingTable{20}.icdar = 'sum'; MappingTable{20}.infty = 'Sigma';
	MappingTable{21}.icdar = 'sqrt'; MappingTable{21}.infty = 'sqrt';
	MappingTable{22}.icdar = 'lim'; MappingTable{22}.infty = '';
	MappingTable{23}.icdar = 'log'; MappingTable{23}.infty = '';
	MappingTable{24}.icdar = 'ldots'; MappingTable{24}.infty = '';
	MappingTable{25}.icdar = 'rightarrow'; MappingTable{25}.infty = 'rightarrow';
	MappingTable{26}.icdar = 'sin'; MappingTable{26}.infty = '';
	MappingTable{27}.icdar = 'tan'; MappingTable{27}.infty = '';
	MappingTable{28}.icdar = 'cos'; MappingTable{28}.infty = '';
	MappingTable{29}.icdar = 'pm'; MappingTable{29}.infty = 'pm';
	MappingTable{30}.icdar = 'div'; MappingTable{30}.infty = 'div';
	MappingTable{31}.icdar = '_excl'; MappingTable{31}.infty = 'exclamation';
	MappingTable{32}.icdar = 'left_bracket'; MappingTable{32}.infty = 'LeftBracket';
	MappingTable{33}.icdar = 'right_bracket'; MappingTable{33}.infty = 'RightBracket';
	MappingTable{34}.icdar = '_lparen'; MappingTable{34}.infty = 'LeftPar';
	MappingTable{35}.icdar = '_rparen'; MappingTable{35}.infty = 'RightPar';
	MappingTable{36}.icdar = 'infty'; MappingTable{36}.infty = 'infty';
	MappingTable{37}.icdar = 'a_lower'; MappingTable{37}.infty = 'a';
	MappingTable{38}.icdar = 'b_lower'; MappingTable{38}.infty = 'b';
	MappingTable{39}.icdar = 'c_lower'; MappingTable{39}.infty = 'c';
	MappingTable{40}.icdar = 'd_lower'; MappingTable{40}.infty = 'd';
	MappingTable{41}.icdar = 'e_lower'; MappingTable{41}.infty = 'e';
	MappingTable{42}.icdar = 'i_lower'; MappingTable{42}.infty = 'i';
	MappingTable{43}.icdar = 'j_lower'; MappingTable{43}.infty = 'j';
	MappingTable{44}.icdar = 'k_lower'; MappingTable{44}.infty = 'k';
	MappingTable{45}.icdar = 'n_lower'; MappingTable{45}.infty = 'n';
	MappingTable{46}.icdar = 'x_lower'; MappingTable{46}.infty = 'x';
	MappingTable{47}.icdar = 'y_lower'; MappingTable{47}.infty = 'y';
	MappingTable{48}.icdar = 'z_lower'; MappingTable{48}.infty = 'z';
	MappingTable{49}.icdar = 'A_upper'; MappingTable{49}.infty = 'A';
	MappingTable{50}.icdar = 'B_upper'; MappingTable{50}.infty = 'B';
	MappingTable{51}.icdar = 'C_upper'; MappingTable{51}.infty = 'C';
	MappingTable{52}.icdar = 'F_upper'; MappingTable{52}.infty = 'F';
	MappingTable{53}.icdar = 'X_upper'; MappingTable{53}.infty = 'X';
	MappingTable{54}.icdar = 'alpha'; MappingTable{54}.infty = 'alpha';
	MappingTable{55}.icdar = 'beta'; MappingTable{55}.infty = 'beta';
	MappingTable{56}.icdar = 'gamma'; MappingTable{56}.infty = 'gamma';
	MappingTable{57}.icdar = 'theta'; MappingTable{57}.infty = 'theta';
	MappingTable{58}.icdar = 'pi'; MappingTable{58}.infty = 'pi';
	MappingTable{59}.icdar = 'phi'; MappingTable{59}.infty = 'phi';

	% convert the symbol class in infty to its icdar version;
	SymbolClassNum = 59;
	% default symbol class is 'X_upper', which means if the symbol class
	% produced by the classifier is not in the icdar set, it will be consider
	% as 'X_upper'.
	OutputSymbolClass = 'X_upper';

	for i = 1:SymbolClassNum
            if(strcmp(TemSymbolClass, MappingTable{i}.infty))
                OutputSymbolClass = MappingTable{i}.icdar;
                break;
            end
        end
 

end


