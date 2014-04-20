% LASSO - File containing experiments for Lasso Models
% This file contains all the equations with single features including:

clear all;

% Setting random state to get constant answers
randn('state',23432);
rand('state',3454);


%%%%%%%%%%%%%%%%%%% From File %%%%%%%%%%%%%%%%%%
fI = importdata('FPSEOnlyData');
fR = importdata('FPSESecuritiesData');
% fI = fI(1:100,1);
% fR = fR(1:100,1:50
% fR = fR(:,10:20);
T = size(fI, 1) - 1;
totalassets = size(fR,2);

R = [];
for i = 1:totalassets
    
    returns = [];
    
    for curr = 2:(T+1)
        returns = [returns, fR(curr, i) / fR(curr-1, i)];
    end
    
    R = [R; returns];
end

I = [];
for curr = 2:(T+1)
    I = [I; fI(curr) / fI(curr-1)];
end

% Calculating returns for Index
I = mean(R)';

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %%%%%%%%%%%%% Random modelled data %%%%%%%%%%%%%%
% totalassets = 200;
% T = 1000;
% assets = [];
% for i=1:totalassets
%     volatility = .1 + rand()/5-.1;
%     old_price = 100 - rand()*50-25;
% 
%     price = [];
%     for j=1:T
%         rnd = rand(); % generate number, 0 <= x < 1.0
%         change_percent = 2 * volatility * rnd;
%         if (change_percent > volatility)
%             change_percent = change_percent-(2 * volatility);
%         end
%         change_amount = old_price * change_percent;
%         new_price = old_price + change_amount;
%         price = [price; old_price/new_price];
%     end
%     assets = [ assets, price ];
% end
% R = assets';
% I = R'*(ones(totalassets,1)/totalassets);









%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%% Lasso Formulations %%%%%%%
%Initialize

delta = 0;
limit = 10;
iterations = 10;

cvx_n = totalassets;
cvx_R = R(1:cvx_n,:);
cvx_I = I;

errors_l = [];
zeros_l = [];
deltas_l = [];
elapsed_l = [];

for i=1:iterations
    i
    
    % CVX to find optimal value for Lasso
    tic
    cvx_begin quiet
        variable z_l(T)
        variable pimat_l(cvx_n)

        minimize(sum(power(I - transpose(cvx_R)*pimat_l, 2)) + delta*sum(pimat_l))

        subject to
            sum(pimat_l) <= 1
            pimat_l >= 0
    cvx_end
    elapsed=toc
    
    error_l = sum(abs(I - cvx_R'*pimat_l));
    zero_l = sum(pimat_l<.00001);
    
    errors_l    = [ errors_l, error_l ];
    zeros_l     = [ zeros_l, zero_l ];
    deltas_l    = [ deltas_l, delta ];
    elapsed_l   = [ elapsed_l,  elapsed];
    
    [elapsed, zero_l, delta]
    
    delta = delta + limit/iterations;
end

errors_l    = errors_l';
zeros_l     = zeros_l';
deltas_l    = deltas_l';
elapsed_l   = elapsed_l';

[ errors_l, zeros_l, deltas_l, elapsed_l ]


% path = 'Graphs/Lasso/delta_behaviour/';
% h1=figure(1);

% plot(deltas_l, zeros_l);
% savegraph(h1,'Delta','# Zero Elements','Deltas - Zeros',fullfile(path,'ftse100_delta_zero'));

% plot(deltas_l, zeros_l);
% savegraph(h1,'Delta','# Zero Elements','Deltas - Zeros',fullfile(path,'ftse100_delta_zero'));
% 
% plot(deltas_l, zeros_l);
% savegraph(h1,'Delta','# Zero Elements','Deltas - Zeros',fullfile(path,'ftse100_delta_zero'));





% X=R';
% X=mexNormalize(X);
% Y=I;
% Y=mexNormalize(I);
% 
% 
% % parameter of the optimization procedure are chosen
% param.pos=true;
% % param.L=50; % not more than 20 non-zeros coefficients (default: min(size(D,1),size(D,2)))
% param.lambda=0.03; % not more than 20 non-zeros coefficients
% param.numThreads=-1; % number of processors/cores to use; the default choice is -1
%                      % and uses all the cores of the machine
% param.mode=2;        % penalized formulation
% 
% tic
% alpha=mexLasso(Y,X,param);
% t=toc
% fprintf('%f signals processed per second\n',size(X,2)/t);
% alpha_full = full(alpha/sum(alpha));
% te_g = sum(abs(I-R'*alpha_full));
% 
% alpha_full_zeros=sum(alpha_full==0)
% pimat_l_zeros=sum(pimat_l<0.001)
% % pimats_cvx
% te
% te_g