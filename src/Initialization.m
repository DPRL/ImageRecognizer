function res = Initialization() % pymatbridge requires a return variable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Initialization.m
%
% initilizing the system by loading training data feature vectors and
% class labels;
%
% Authors: Siyu Zhu, Lei Hu, Richard Zanibbi
%	June-August 2012
% Copyright (c) 2012, Siyu Zhu, Lei Hu, Richard Zanibbi
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

load symbolCodeAs;
load gridVecAs;
global trsc;
trsc = symbolCode;
global trgv;
trgv = gridVecA;
isOpen = matlabpool('size') > 0;
if isOpen
else
    matlabpool open
        end
        disp('Initialization Done!')
        res = 0; % Return variable must be set to something        
end
