function OutputSymbolClass = Code2Class(InputSymbolCode)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Code2Class.m
%
% this function is used to convert the hexadecimal infty code to its
% corresponding symbol class
% InputSymbolCode is not a number but a string
%
% Authors: Siyu Zhu, Lei Hu, Richard Zanibbi
%	June-August 2012
% Copyright (c) 2012, Siyu Zhu, Lei Hu, Richard Zanibbi
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%clc, clear all, close all;
%% get symbol code list
SymbolCodeList = {};
fid = fopen('OcrCodeList.txt');
SymbolClassNum = 628;
for i = 1:SymbolClassNum
    tline = fgetl(fid);
    CommaLocation = strfind(tline,',');
    SymbolCode = tline(3:CommaLocation(1)-1);
    SymbolClass = tline(CommaLocation(2)+1:length(tline));
    SymbolCodeList{i}.SymbolCode = SymbolCode;
    SymbolCodeList{i}.SymbolClass = SymbolClass;
end
fclose(fid);

%% convert the code to its corresponding symbol class

% many symbols' codes are not in the code list "OcrCodeList.txt", such as '33f0','33f1','33f2' and so on
SymbolCodeInList = 0;
for i = 1:SymbolClassNum
    if(strcmp(InputSymbolCode, SymbolCodeList{i}.SymbolCode))
        TemSymbolClass  = SymbolCodeList{i}.SymbolClass;
        SymbolCodeInList = 1;
        break;
    end
end


if (SymbolCodeInList==0)
    
    TemSymbolClass  = 'int';% for the symbol whose code is not in the list, it will be recognized as 'int'
    
    % special case for "int"
    if(strcmp(InputSymbolCode, '33f0'))
        TemSymbolClass  = 'int';
    end
    
    % special case for "sqrt"
    if(strcmp(InputSymbolCode, '33f2'))
        TemSymbolClass  = 'sqrt';
    end
    
end

%% convert the symbol class in infty to its icdar version
OutputSymbolClass = Infty2Icdar(TemSymbolClass);
end