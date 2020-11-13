function [Xr,outs] = run_test(Phi,y,r,alg_names, max_time)
% This function runs different algorithms (indicated by alg_name)
% for a given matrix completion problem with entry mask Phi and provided 
% data y up to a max time.
% =========================================================================
% Parameters
% ----------
% Phi:  (d1 x d2) sparse matrix containing m non zero entries.  The indices
% of the non zero entries correspond to the data vector (y).
% y:    (m x 1) vector of samples. Provided matrix entry values,
%       ordered in according to linear indices of non-zero entries of Phi.
% r:    Target rank to be used.
% alg_name:     (1 x nr_algos) cell of character strings. Indicating which 
%               algorithm to use.
% Returns
% ----------
% Xr:   (1 x nr_algos_total) cell. The i-th cell contains algorithmic
%       iterates of i-th algorithm.
% outs: (1 x nr_algos_total) cell. The i-th cell contains additional
%       information about the progress of the i-th algorithm.
% Author: Josh Engels, adopted from test code by Christian Kuemmerle 2020.

[d1,d2]=size(Phi);
Omega = find(Phi);
nr_algos = length(alg_names);

outs  = cell(1,nr_algos);
Xr    = cell(1,nr_algos);
for alg_num = 1:nr_algos
    current_alg = alg_names{alg_num};
    
    if (any(strcmp(["ScaledASD", "ASD", "NIHT_Matrix", "CGIHT_Matrix"], current_alg)))
        alg_func = str2func(current_alg + "_outp");
        start = make_start_x_IHT_ASD(current_alg,d1,d2,r,Omega,y);
        [Xr{alg_num},outs{alg_num}] = alg_func(d1,d2,r,Omega,y,start,max_time);
    end
    
    if(current_alg == "R3MC") 
        [rowind,colind]=find(Phi);
        input = struct;
        input.d1     = d1;
        input.d2     = d2;
        input.r      = r;
        input.Phi    = Phi;
        input.y      = y;
        input.data_ls.rows = rowind;
        input.data_ls.cols = colind;
        input.data_ls.entries = input.y;
        input.data_ls.nentries = length(input.y);
        input = initialize_R3MC(input,false);
        [~, outs{alg_num}] = R3MC_adp(input, max_time);
        Xr{alg_num} = outs{alg_num}.X;
    end
    
    if strcmp(current_alg,'LMaFit')
        [~,~,Out] = lmafit_mc_adp(d1,d2,r,Omega,y, max_time);
        outs{alg_num}=Out;
        outs{alg_num}.N=Out.iter;
        Xr{alg_num} = cell(1,outs{alg_num}.N);
        for kk=1:outs{alg_num}.N
            Xr{alg_num}{kk}={Out.Xhist{kk},Out.Yhist{kk}'};
        end
    end
    
    if strcmp(current_alg,'ScaledGD')
        input.d1 = d1;
        input.d2 = d2;
        [input.rowind,input.colind]=find(Phi);
        [input.Omega] = find(Phi);
        input.y = y;
        [Xr{alg_num},outs{alg_num}] = ScaledGD(input, r, max_time);
    end
    
    if strcmp(current_alg, 'MatrixIRLS')        
        opts = getDefaultOpts_IRLS;
        input.d1     = d1;
        input.d2     = d2;
        input.r      = r;
        input.Phi    = Phi;
        input.y      = y;
        [~,outs{alg_num}] = MatrixIRLS(input,0, opts, max_time);
        Xr{alg_num} = cell(1,outs{alg_num}.N);
        for kk=1:outs{alg_num}.N 
            Xr{alg_num}{kk}=outs{alg_num}.X{kk};
        end
    end
    
end