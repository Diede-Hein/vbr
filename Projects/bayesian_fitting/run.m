%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Fit asthenospheric Vs and Q (using fit_seismic_observations.m) with the
% most likely state variables, varying temperature, melt fraction and
% grain size in the asthenosphere.
%
% Then, use this constraint on potential temperature and seismic LAB depth
% observations to fit a plate model, i.e. thermal plate thickness, zPlate
% (using fit_plate.m).
%
% This wrapper contains only the most commonly varied inputs - the location
% (lat, lon, depth, smoothing radius) that you would like to fit; the
% names of your files containing seismic observeables (Vs, Q, LAB depth);
% and the anelastic framework in which you would like to do your
% calculations.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
close all; clc

locs = [45, -111; 40.7, -117.5; 39, -109.8; 37.2, -100.9];
names = {'Yellowstone', 'BasinRange', 'ColoradoPlateau', 'Interior'};
zrange = [75, 105; 75, 105; 120, 150; 120, 150];
location_colors={[1,0,0];[1,0.6,0];[0,0.8,0];[0,0.3,0]};

% Extract the relevant values for the input depth range.
% Need to choose the attenuation method used for anelastic calculations
%       see possible methods by running vbrListMethods()
q_method = 'xfit_premelt'; %'eburgers_psp' 'xfit_mxw', 'xfit_premelt' 'andrade_psp'
fetch_data('./'); % builds data directories and fetches data
filenames.Vs = './data/vel_models/Shen_Ritzwoller_2016.mat';
filenames.Q = './data/Q_models/Dalton_Ekstrom_2008.mat';
filenames.LAB = './data/LAB_models/HopperFischer2018.mat';


q_methods = {'eburgers_psp', 'xfit_mxw', 'xfit_premelt', 'andrade_psp'};


RegionalFits=struct();
EnsemblePDF=struct();
firstRun=1;
for iq = 1:length(q_methods)
    q_method = q_methods{iq};
    disp(['Calculating inference for ',q_method])
    RegionalFits.(q_method)=struct();

    for il = 1:length(locs)
        location.lat = locs(il, 1); % degrees North\
        location.lon = locs(il, 2) + 360; % degrees East
        location.z_min = zrange(il, 1); % averaging min depth for asth.
        location.z_max= zrange(il, 2); % averaging max depth for asth.
        location.smooth_rad = 0.5;
        locname = names{il};
        disp(['     fitting ',locname])

        if firstRun==1
          [posterior_A,sweep] = fit_seismic_observations(filenames, location, q_method);
          firstRun=0;
        else
          [posterior_A,sweep] = fit_seismic_observations(filenames, location, q_method, sweep);
        end

        disp('        saving plots...')
        saveas(gcf, ['plots/output_plots/', names{il}, '_VQ_', q_method, '.png']);
        close
        saveas(gcf, ['plots/output_plots/', names{il}, '_Q_', q_method, '.png']);
        close
        saveas(gcf, ['plots/output_plots/', names{il}, '_V_', q_method, '.png']);
        close
        disp('        plots saved to plots/output_plots/')

        % calculate marginal P(phi,T|S)
        posterior = posterior_A.pS;
        posterior = posterior ./ sum(posterior(:));
        %sh = size(posterior);
        %p_marginal = sum(sum(posterior, 1), 2);
        %p_marginal_box = repmat(p_marginal, sh(1), sh(2), 1);
        %p_joint = sum(posterior .* p_marginal_box, 3);
        %p_joint=p_joint/sum(p_joint(:));
        p_joint = sum(posterior,3);
        if ~strcmp(q_method,'xfit_mxw')
          if ~isfield(EnsemblePDF,locname)
            EnsemblePDF.(locname).p_joint=p_joint;
            EnsemblePDF.(locname).post_T=posterior_A.T;
            EnsemblePDF.(locname).post_phi=posterior_A.phi;
          else
            EnsemblePDF.(locname).p_joint=EnsemblePDF.(locname).p_joint+p_joint;
          end
        end

        % store regional fits for combo plot
        RegionalFits.(q_method).(locname)=struct();
        RegionalFits.(q_method).(locname).p_joint=p_joint;
        RegionalFits.(q_method).(locname).phi_post=posterior_A.phi;
        RegionalFits.(q_method).(locname).T_post=posterior_A.T;

    end

end


N_models = 3; % (not including xfit_mxw)
for il = 1:length(locs)
  locname = names{il};
  EnsemblePDF.(locname).p_joint=EnsemblePDF.(locname).p_joint/ N_models; % equal weighting
end

plot_RegionalFits(RegionalFits,locs,names,location_colors);
plot_EnsemblePDFs(EnsemblePDF,locs,names,location_colors)
